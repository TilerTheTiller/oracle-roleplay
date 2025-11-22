AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Drying Rack"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "SlotsUsed")
	self:NetworkVar("Int", 1, "MaxSlots")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_rack01.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize drying rack data
		self:SetMaxSlots(4)
		self:SetSlotsUsed(0)
		
		self.dryingSlots = {}
		for i = 1, self:GetMaxSlots() do
			self.dryingSlots[i] = {
				occupied = false,
				strainID = nil,
				strainName = nil,
				grams = 0,
				thc = 0,
				quality = 0,
				startTime = 0,
				dryTime = 60 -- 60 seconds default
			}
		end
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Open drying menu
		net.Start("DarkRP.Weed.OpenDryingRack")
			net.WriteEntity(self)
			net.WriteTable(self.dryingSlots)
		net.Send(caller)
	end
	
	function ENT:AddWeed(slotID, strainID, strainName, grams, thc, quality)
		if not self.dryingSlots[slotID] then return false end
		if self.dryingSlots[slotID].occupied then return false end
		
		self.dryingSlots[slotID].occupied = true
		self.dryingSlots[slotID].strainID = strainID
		self.dryingSlots[slotID].strainName = strainName
		self.dryingSlots[slotID].grams = grams
		self.dryingSlots[slotID].thc = thc
		self.dryingSlots[slotID].quality = quality
		self.dryingSlots[slotID].startTime = CurTime()
		
		self:SetSlotsUsed(self:GetSlotsUsed() + 1)
		
		-- Start drying timer
		timer.Simple(self.dryingSlots[slotID].dryTime, function()
			if IsValid(self) and self.dryingSlots[slotID].occupied then
				self.dryingSlots[slotID].isDry = true
			end
		end)
		
		return true
	end
	
	function ENT:RemoveWeed(slotID, ply)
		if not self.dryingSlots[slotID] then return false end
		if not self.dryingSlots[slotID].occupied then return false end
		
		local slot = self.dryingSlots[slotID]
		
		-- Check if dry
		if not slot.isDry then
			DarkRP.Weed.Notify(ply, "Weed is still drying!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		-- Give dried weed to player (implement inventory system here)
		DarkRP.Weed.Notify(ply, string.format("Collected %.1fg of dried %s!", slot.grams, slot.strainName), DarkRP.Weed.NOTIFY_HINT)
		
		-- Clear slot
		self.dryingSlots[slotID] = {
			occupied = false,
			strainID = nil,
			strainName = nil,
			grams = 0,
			thc = 0,
			quality = 0,
			startTime = 0,
			dryTime = 60,
			isDry = false
		}
		
		self:SetSlotsUsed(self:GetSlotsUsed() - 1)
		
		return true
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 1)
		return true
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw status
		local pos = self:GetPos() + self:GetUp() * 60
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
			draw.SimpleText("Drying Rack", "DarkRP.Weed.Medium", 0, -40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("Slots: %d/%d", self:GetSlotsUsed(), self:GetMaxSlots()), "DarkRP.Weed.Small", 0, -20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("[E] Open", "DarkRP.Weed.Tiny", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end

-- Network strings
if SERVER then
	util.AddNetworkString("DarkRP.Weed.OpenDryingRack")
	util.AddNetworkString("DarkRP.Weed.DryingRack.AddWeed")
	util.AddNetworkString("DarkRP.Weed.DryingRack.RemoveWeed")
	
	net.Receive("DarkRP.Weed.DryingRack.RemoveWeed", function(len, ply)
		local rack = net.ReadEntity()
		local slotID = net.ReadInt(8)
		
		if not IsValid(rack) or rack:GetClass() ~= "darkrp_weed_dryingrack" then return end
		
		rack:RemoveWeed(slotID, ply)
	end)
end
