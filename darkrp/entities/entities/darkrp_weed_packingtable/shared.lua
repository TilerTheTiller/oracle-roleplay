AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Weed Packing Table"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "JarsPlaced")
	self:NetworkVar("Bool", 0, "IsPacking")
	self:NetworkVar("Bool", 1, "HasAutoPacker")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_weedpacker.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize packing table data
		self:SetJarsPlaced(0)
		self:SetIsPacking(false)
		self:SetHasAutoPacker(false)
		
		self.placedJars = {}
		self.packingTime = 15 -- 15 seconds to pack
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Open packing menu
		net.Start("DarkRP.Weed.OpenPackingTable")
			net.WriteEntity(self)
			net.WriteTable(self.placedJars)
			net.WriteInt(self:GetJarsPlaced(), 8)
			net.WriteBool(self:GetIsPacking())
			net.WriteBool(self:GetHasAutoPacker())
		net.Send(caller)
	end
	
	function ENT:AddJar(strainID, strainName, grams, thc, quality, ply)
		if self:GetJarsPlaced() >= 4 then
			DarkRP.Weed.Notify(ply, "Packing table is full!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		if self:GetIsPacking() then
			DarkRP.Weed.Notify(ply, "Already packing!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		table.insert(self.placedJars, {
			strainID = strainID,
			strainName = strainName,
			grams = grams,
			thc = thc,
			quality = quality
		})
		
		self:SetJarsPlaced(#self.placedJars)
		
		DarkRP.Weed.Notify(ply, string.format("Added %s jar (%d/4)", strainName, self:GetJarsPlaced()), DarkRP.Weed.NOTIFY_HINT)
		
		-- Auto-pack if autopacker is enabled and 4 jars placed
		if self:GetHasAutoPacker() and self:GetJarsPlaced() >= 4 then
			self:StartPacking(ply)
		end
		
		return true
	end
	
	function ENT:StartPacking(ply)
		if self:GetJarsPlaced() < 4 then
			DarkRP.Weed.Notify(ply, "Need 4 jars to pack!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		self:SetIsPacking(true)
		
		DarkRP.Weed.Notify(ply, "Packing weed block...", DarkRP.Weed.NOTIFY_HINT)
		
		timer.Simple(self.packingTime, function()
			if not IsValid(self) then return end
			
			self:CompletePacking(ply)
		end)
		
		return true
	end
	
	function ENT:CompletePacking(ply)
		-- Check if all jars are same strain
		local firstStrain = self.placedJars[1].strainID
		local isMixed = false
		
		for i = 2, #self.placedJars do
			if self.placedJars[i].strainID ~= firstStrain then
				isMixed = true
				break
			end
		end
		
		-- Calculate total stats
		local totalGrams = 0
		local avgTHC = 0
		local avgQuality = 0
		local strainName = self.placedJars[1].strainName
		
		for _, jar in ipairs(self.placedJars) do
			totalGrams = totalGrams + jar.grams
			avgTHC = avgTHC + jar.thc
			avgQuality = avgQuality + jar.quality
		end
		
		avgTHC = avgTHC / #self.placedJars
		avgQuality = avgQuality / #self.placedJars
		
		-- Mixed strain penalty
		local priceMultiplier = 1.0
		if isMixed then
			priceMultiplier = 0.7
			strainName = "Mixed"
		end
		
		-- Create weed block entity (implement based on your inventory system)
		DarkRP.Weed.Notify(ply, string.format("Packed %s weed block! (%.1fg, %.1f%% THC)", strainName, totalGrams, avgTHC), DarkRP.Weed.NOTIFY_HINT)
		
		-- Clear table
		self.placedJars = {}
		self:SetJarsPlaced(0)
		self:SetIsPacking(false)
		
		return true
	end
	
	function ENT:ClearTable(ply)
		-- Return jars to player (implement inventory system)
		for _, jar in ipairs(self.placedJars) do
			DarkRP.Weed.Notify(ply, string.format("Returned %s jar", jar.strainName), DarkRP.Weed.NOTIFY_HINT)
		end
		
		self.placedJars = {}
		self:SetJarsPlaced(0)
		self:SetIsPacking(false)
		
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
		local pos = self:GetPos() + self:GetUp() * 50
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
			draw.SimpleText("Packing Table", "DarkRP.Weed.Medium", 0, -60, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("Jars: %d/4", self:GetJarsPlaced()), "DarkRP.Weed.Small", 0, -40, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if self:GetIsPacking() then
				draw.SimpleText("PACKING...", "DarkRP.Weed.Small", 0, -20, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			if self:GetHasAutoPacker() then
				draw.SimpleText("[AUTO]", "DarkRP.Weed.Tiny", 0, 0, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			draw.SimpleText("[E] Open", "DarkRP.Weed.Tiny", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end

-- Network strings
if SERVER then
	util.AddNetworkString("DarkRP.Weed.OpenPackingTable")
	util.AddNetworkString("DarkRP.Weed.PackingTable.AddJar")
	util.AddNetworkString("DarkRP.Weed.PackingTable.StartPacking")
	util.AddNetworkString("DarkRP.Weed.PackingTable.Clear")
	
	net.Receive("DarkRP.Weed.PackingTable.StartPacking", function(len, ply)
		local table = net.ReadEntity()
		
		if not IsValid(table) or table:GetClass() ~= "darkrp_weed_packingtable" then return end
		
		table:StartPacking(ply)
	end)
	
	net.Receive("DarkRP.Weed.PackingTable.Clear", function(len, ply)
		local table = net.ReadEntity()
		
		if not IsValid(table) or table:GetClass() ~= "darkrp_weed_packingtable" then return end
		
		table:ClearTable(ply)
	end)
end
