AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "LED Grow Lamp"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsOn")
	self:NetworkVar("Bool", 1, "HasPower")
	self:NetworkVar("Float", 0, "LightRadius")
	self:NetworkVar("Float", 1, "GrowthBoost")
	self:NetworkVar("Entity", 0, "Owner")
	self:NetworkVar("Entity", 1, "PowerSource")
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
		
		-- Initialize lamp data
		self:SetLightRadius(150)
		self:SetGrowthBoost(1.3)
		self:SetIsOn(false)
		self:SetHasPower(false)
		
		self.equipmentData = {
			id = "lamp_led",
			name = "LED Grow Lamp",
			radius = 150,
			growthBoost = 1.3,
			powerConsumption = 5
		}
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Toggle lamp
		if self:GetHasPower() then
			self:SetIsOn(not self:GetIsOn())
			local status = self:GetIsOn() and "ON" or "OFF"
			DarkRP.Weed.Notify(caller, "Lamp turned " .. status, DarkRP.Weed.NOTIFY_HINT)
		else
			DarkRP.Weed.Notify(caller, "Lamp has no power! Connect to a generator.", DarkRP.Weed.NOTIFY_ERROR)
		end
	end
	
	function ENT:SetPowerSource(generator)
		if IsValid(generator) and generator:GetClass() == "darkrp_weed_generator" then
			self:SetPowerSource(generator)
			self:SetHasPower(generator:GetIsRunning())
		end
	end
	
	function ENT:Think()
		-- Check power source
		local powerSource = self:GetPowerSource()
		if IsValid(powerSource) and powerSource:GetIsRunning() then
			self:SetHasPower(true)
		else
			-- Check for nearby generators automatically
			local foundPower = false
			for _, ent in ipairs(ents.FindInSphere(self:GetPos(), 500)) do
				if IsValid(ent) and ent:GetClass() == "darkrp_weed_generator" then
					if ent:GetIsRunning() and not ent:GetNeedsMaintenance() then
						self:SetPowerSource(ent)
						self:SetHasPower(true)
						foundPower = true
						break
					end
				end
			end
			
			if not foundPower then
				self:SetHasPower(false)
				if self:GetIsOn() then
					self:SetIsOn(false)
				end
			end
		end
		
		self:NextThink(CurTime() + 2)
		return true
	end
end

if CLIENT then
	function ENT:Initialize()
		self.LightDynamic = DynamicLight(self:EntIndex())
	end
	
	function ENT:Draw()
		self:DrawModel()
		
		-- Dynamic light effect
		if self:GetIsOn() and self:GetHasPower() then
			if self.LightDynamic then
				self.LightDynamic.pos = self:GetPos() + self:GetUp() * 10
				self.LightDynamic.r = 200
				self.LightDynamic.g = 150
				self.LightDynamic.b = 255
				self.LightDynamic.brightness = 3
				self.LightDynamic.decay = 500
				self.LightDynamic.size = self:GetLightRadius()
				self.LightDynamic.dietime = CurTime() + 1
			end
		end
		
		-- Draw status
		local pos = self:GetPos() + self:GetUp() * 40
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		local statusColor = self:GetIsOn() and Color(100, 255, 100) or Color(200, 200, 200)
		if not self:GetHasPower() then
			statusColor = Color(255, 100, 100)
		end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.08)
			draw.SimpleText("LED Lamp", "DarkRP.Weed.Small", 0, -30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			local statusText = self:GetIsOn() and "ON" or "OFF"
			if not self:GetHasPower() then
				statusText = "NO POWER"
			end
			draw.SimpleText(statusText, "DarkRP.Weed.Tiny", 0, -15, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if self:GetHasPower() then
				local action = self:GetIsOn() and "Turn Off" or "Turn On"
				draw.SimpleText("[E] " .. action, "DarkRP.Weed.Tiny", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end
end
