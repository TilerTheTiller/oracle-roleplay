AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Drying Rack"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Owner")
	self:NetworkVar("Int", 0, "UsedSlots")
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
		
		-- Equipment data
		self.equipmentData = {
			id = "dryrack",
			name = "Drying Rack",
			model = "models/zerochain/props_growop2/zgo2_rack01.mdl",
			slots = 4,
			dryTime = 60
		}
		
		-- Drying slots
		self.dryingSlots = {}
		for i = 1, 4 do
			self.dryingSlots[i] = {
				occupied = false,
				strainID = nil,
				amount = 0,
				quality = 0,
				startTime = 0,
				endTime = 0
			}
		end
		
		self:SetUsedSlots(0)
		self:SetHealth(100)
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Check ownership
		if IsValid(self:GetOwner()) and self:GetOwner() ~= caller then
			DarkRP.Weed.Notify(caller, "You don't own this drying rack!", DarkRP.Weed.NOTIFY_ERROR)
			return
		end
		
		-- Open drying menu
		self:OpenDryingMenu(caller)
	end
	
	function ENT:OpenDryingMenu(ply)
		-- Send rack data to client
		net.Start("DarkRP.Weed.OpenUI")
			net.WriteString("dryrack")
			net.WriteEntity(self)
			net.WriteTable(self.dryingSlots)
		net.Send(ply)
	end
	
	function ENT:StartDrying(slotIndex, strainID, amount, quality)
		if not self.dryingSlots[slotIndex] then return false end
		if self.dryingSlots[slotIndex].occupied then return false end
		
		local dryTime = self.equipmentData.dryTime or 60
		
		self.dryingSlots[slotIndex] = {
			occupied = true,
			strainID = strainID,
			amount = amount,
			quality = quality,
			startTime = CurTime(),
			endTime = CurTime() + dryTime
		}
		
		self:SetUsedSlots(self:GetUsedSlots() + 1)
		return true
	end
	
	function ENT:CollectDried(slotIndex, ply)
		if not self.dryingSlots[slotIndex] then return false end
		if not self.dryingSlots[slotIndex].occupied then return false end
		
		local slot = self.dryingSlots[slotIndex]
		
		-- Check if done
		if CurTime() < slot.endTime then
			DarkRP.Weed.Notify(ply, "Not finished drying yet!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		-- Give dried weed to player
		-- Implement based on your inventory system
		DarkRP.Weed.Notify(ply, string.format("Collected %.1fg of dried weed", slot.amount), DarkRP.Weed.NOTIFY_HINT)
		
		-- Clear slot
		self.dryingSlots[slotIndex] = {
			occupied = false,
			strainID = nil,
			amount = 0,
			quality = 0,
			startTime = 0,
			endTime = 0
		}
		
		self:SetUsedSlots(self:GetUsedSlots() - 1)
		return true
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 1)
		return true
	end
	
	function ENT:OnTakeDamage(dmg)
		self:SetHealth(self:Health() - dmg:GetDamage())
		
		if self:Health() <= 0 then
			self:Remove()
		end
	end
	
	function ENT:OnRemove()
		-- Drop any drying weed
		for i, slot in ipairs(self.dryingSlots) do
			if slot.occupied then
				-- Create dropped item
			end
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw drying weed on rack
		if self.dryingSlots then
			for i, slot in ipairs(self.dryingSlots) do
				if slot.occupied then
					-- Could attach models to show weed drying
				end
			end
		end
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 0.5)
		return true
	end
end
