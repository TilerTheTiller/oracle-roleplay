AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Grow Lamp"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Powered")
	self:NetworkVar("Float", 0, "FuelLevel")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_led_lamp01.mdl")
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
			id = "lamp_led",
			name = "LED Grow Lamp",
			model = "models/zerochain/props_growop2/zgo2_led_lamp01.mdl",
			radius = 150,
			growthBoost = 1.3,
			powerConsumption = 5
		}
		
		self:SetPowered(true)
		self:SetFuelLevel(100)
		self:SetHealth(100)
		
		-- Create dynamic light
		self.lightActive = true
	end
	
	if CLIENT then
		self.light = nil
		self.nextFlickerTime = 0
		self.glowSprite = Material("sprites/light_glow02_add")
	end
end

if SERVER then
	function ENT:SetupEquipmentData(equipmentData)
		if equipmentData then
			self.equipmentData = equipmentData
			if equipmentData.model then
				self:SetModel(equipmentData.model)
			end
		end
	end
	
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Check ownership
		if IsValid(self:GetOwner()) and self:GetOwner() ~= caller then
			DarkRP.Weed.Notify(caller, "You don't own this lamp!", DarkRP.Weed.NOTIFY_ERROR)
			return
		end
		
		-- Toggle power
		self:SetPowered(not self:GetPowered())
		
		local status = self:GetPowered() and "ON" or "OFF"
		DarkRP.Weed.Notify(caller, "Lamp turned " .. status, DarkRP.Weed.NOTIFY_HINT)
	end
	
	function ENT:Think()
		-- Consume power if active
		if self:GetPowered() and self.equipmentData then
			local consumption = self.equipmentData.powerConsumption or 5
			local newFuel = math.max(0, self:GetFuelLevel() - (consumption / 60))
			self:SetFuelLevel(newFuel)
			
			-- Turn off if out of fuel
			if newFuel <= 0 then
				self:SetPowered(false)
			end
		end
		
		self:NextThink(CurTime() + 1)
		return true
	end
	
	function ENT:OnTakeDamage(dmg)
		self:SetHealth(self:Health() - dmg:GetDamage())
		
		if self:Health() <= 0 then
			-- Create gibs
			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetMagnitude(2)
			effectdata:SetScale(1)
			effectdata:SetRadius(2)
			util.Effect("Explosion", effectdata)
			
			self:Remove()
		end
	end
	
	function ENT:OnRemove()
		-- Cleanup
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw light glow if powered
		if self:GetPowered() then
			local pos = self:GetPos() + self:GetUp() * 10
			local radius = (self.equipmentData and self.equipmentData.radius) or 150
			
			-- Flicker effect
			local flicker = 1.0
			if CurTime() > self.nextFlickerTime then
				flicker = math.Rand(0.9, 1.0)
				self.nextFlickerTime = CurTime() + math.Rand(0.05, 0.2)
			end
			
			-- Draw glow sprite
			local size = 40 * flicker
			render.SetMaterial(self.glowSprite)
			render.DrawSprite(pos, size, size, Color(255, 200, 100, 200 * flicker))
			
			-- Draw light
			if not self.light then
				self.light = DynamicLight(self:EntIndex())
			end
			
			if self.light then
				self.light.pos = pos
				self.light.r = 255
				self.light.g = 200
				self.light.b = 100
				self.light.brightness = 3 * flicker
				self.light.Decay = 1000
				self.light.Size = radius
				self.light.DieTime = CurTime() + 1
			end
			
			-- Draw range indicator when looking at it
			local ply = LocalPlayer()
			if IsValid(ply) then
				local trace = ply:GetEyeTrace()
				if trace.Entity == self then
					render.SetColorMaterial()
					render.DrawSphere(self:GetPos(), radius, 30, 30, Color(255, 200, 100, 10))
					render.DrawWireframeSphere(self:GetPos(), radius, 30, 30, Color(255, 200, 100, 100), true)
				end
			end
		end
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 0.1)
		return true
	end
	
	function ENT:OnRemove()
		if self.light then
			self.light.DieTime = CurTime()
		end
	end
end
