AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Soil Bag"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "SoilType")
	self:NetworkVar("Float", 0, "QualityBonus")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_soil.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize soil data
		self:SetSoilType("standard")
		self:SetQualityBonus(0)
		
		-- Auto-remove after 5 minutes if not used
		timer.Simple(300, function()
			if IsValid(self) then
				self:Remove()
			end
		end)
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Try to find a pot to add soil to
		local trace = caller:GetEyeTrace()
		local ent = trace.Entity
		
		if IsValid(ent) and ent:GetClass() == "darkrp_weed_pot" then
			-- Add soil to pot
			if ent.plantData and ent.plantData.hasSoil then
				DarkRP.Weed.Notify(caller, "Pot already has soil!", DarkRP.Weed.NOTIFY_ERROR)
				return
			end
			
			if ent.plantData and ent.plantData.hasPlant then
				DarkRP.Weed.Notify(caller, "Cannot add soil while plant is growing!", DarkRP.Weed.NOTIFY_ERROR)
				return
			end
			
			ent.plantData.hasSoil = true
			ent.plantData.soilQuality = self:GetQualityBonus()
			ent:SetHasSoil(true)
			
			DarkRP.Weed.Notify(caller, "Soil added to pot!", DarkRP.Weed.NOTIFY_HINT)
			self:Remove()
			return
		else
			-- Pick up the soil
			DarkRP.Weed.Notify(caller, "Picked up soil! Look at a pot and press E to add it.", DarkRP.Weed.NOTIFY_HINT)
			
			-- Store in player's "inventory"
			caller.heldSoil = {
				type = self:GetSoilType(),
				qualityBonus = self:GetQualityBonus()
			}
			
			self:Remove()
		end
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		local pos = self:GetPos() + Vector(0, 0, 10)
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		local success = pcall(function()
			cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
				local font = "DarkRP.Weed.Medium"
				if not DarkRP or not DarkRP.Weed then
					font = "DermaDefault"
				end
				draw.SimpleTextOutlined("Soil", font, 0, 0, Color(200, 150, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 200))
			cam.End3D2D()
		end)
		
		if not success then
			pcall(cam.End3D2D)
		end
	end
end
