AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Weed Seed"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = false
ENT.AdminOnly = false

-- Override these in child entities
ENT.StrainID = "schwag"
ENT.StrainName = "Weed Seed"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StrainID")
	self:NetworkVar("String", 1, "StrainName")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_weedseeds.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Set strain data
		self:SetStrainID(self.StrainID)
		self:SetStrainName(self.StrainName)
		
		-- Auto-remove after 5 minutes if not picked up
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
		
		-- Try to find a pot to plant in
		local trace = caller:GetEyeTrace()
		local ent = trace.Entity
		
		if IsValid(ent) and ent:GetClass() == "darkrp_weed_pot" then
			-- Plant directly in the pot
			local success = DarkRP.Weed.Server.PlantSeed(ent, caller, self:GetStrainID())
			if success then
				self:Remove()
				return
			end
		else
			-- Pick up the seed
			DarkRP.Weed.Notify(caller, "Picked up " .. self:GetStrainName() .. " seed! Look at a pot and press E to plant.", DarkRP.Weed.NOTIFY_HINT)
			
			-- Give to player's inventory or set as held seed
			caller.heldSeed = {
				strainID = self:GetStrainID(),
				strainName = self:GetStrainName()
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
		
		-- Safety check: ensure cam.Start3D2D is always paired with cam.End3D2D
		local success = pcall(function()
			cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
				-- Use DarkRP.Weed font if available, fallback to default
				local font = "DarkRP.Weed.Medium"
				if not DarkRP or not DarkRP.Weed then
					font = "DermaDefault"
				end
				draw.SimpleTextOutlined(self:GetStrainName(), font, 0, 0, Color(200, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 200))
			cam.End3D2D()
		end)
		
		if not success then
			-- Ensure cam.End3D2D is called even if there's an error
			pcall(cam.End3D2D)
		end
	end
end
