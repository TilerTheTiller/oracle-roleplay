AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Generator"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "FuelAmount")
	self:NetworkVar("Float", 1, "MaxFuel")
	self:NetworkVar("Float", 2, "PowerOutput")
	self:NetworkVar("Bool", 0, "IsRunning")
	self:NetworkVar("Bool", 1, "NeedsMaintenance")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_generator01.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize generator data
		self:SetMaxFuel(100)
		self:SetFuelAmount(50) -- Start with 50% fuel
		self:SetPowerOutput(50)
		self:SetIsRunning(false)
		self:SetNeedsMaintenance(false)
		
		self.connectedDevices = {}
		self.lastFuelConsumption = CurTime()
		self.maintenanceTime = CurTime() + math.random(300, 600) -- Need maintenance in 5-10 minutes
		self.startPresses = 0
		self.lastPressTime = 0
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Check if needs maintenance
		if self:GetNeedsMaintenance() then
			self:PerformMaintenance(caller)
			return
		end
		
		-- Toggle generator on/off
		if self:GetIsRunning() then
			self:StopGenerator(caller)
		else
			self:StartGenerator(caller)
		end
	end
	
	function ENT:StartGenerator(ply)
		-- Check fuel
		if self:GetFuelAmount() <= 0 then
			DarkRP.Weed.Notify(ply, "Generator has no fuel!", DarkRP.Weed.NOTIFY_ERROR)
			return
		end
		
		-- Requires multiple presses to start (realistic)
		local curTime = CurTime()
		if curTime - self.lastPressTime > 3 then
			self.startPresses = 0
		end
		
		self.startPresses = self.startPresses + 1
		self.lastPressTime = curTime
		
		local pressesNeeded = math.random(3, 6)
		
		if self.startPresses < pressesNeeded then
			DarkRP.Weed.Notify(ply, string.format("Keep pressing! (%d/%d)", self.startPresses, pressesNeeded), DarkRP.Weed.NOTIFY_HINT)
			self:EmitSound("buttons/lever1.wav", 70, math.random(90, 110))
			return
		end
		
		-- Start generator
		self:SetIsRunning(true)
		self.startPresses = 0
		DarkRP.Weed.Notify(ply, "Generator started!", DarkRP.Weed.NOTIFY_HINT)
		self:EmitSound("vehicles/airboat/fan_motor_start.wav", 75, 100)
		
		-- Start fuel consumption timer
		timer.Create("Generator_FuelConsumption_" .. self:EntIndex(), 60, 0, function()
			if not IsValid(self) or not self:GetIsRunning() then return end
			
			self:ConsumeFuel(1) -- 1 fuel per minute
		end)
	end
	
	function ENT:StopGenerator(ply)
		self:SetIsRunning(false)
		DarkRP.Weed.Notify(ply, "Generator stopped!", DarkRP.Weed.NOTIFY_HINT)
		self:EmitSound("vehicles/airboat/fan_motor_shut_off1.wav", 75, 100)
		
		timer.Remove("Generator_FuelConsumption_" .. self:EntIndex())
	end
	
	function ENT:ConsumeFuel(amount)
		local current = self:GetFuelAmount()
		self:SetFuelAmount(math.max(0, current - amount))
		
		if self:GetFuelAmount() <= 0 then
			self:SetIsRunning(false)
			self:EmitSound("vehicles/airboat/fan_motor_shut_off1.wav", 75, 100)
			timer.Remove("Generator_FuelConsumption_" .. self:EntIndex())
		end
	end
	
	function ENT:AddFuel(amount)
		local current = self:GetFuelAmount()
		local max = self:GetMaxFuel()
		local added = math.min(amount, max - current)
		
		self:SetFuelAmount(current + added)
		return added
	end
	
	function ENT:PerformMaintenance(ply)
		self:SetNeedsMaintenance(false)
		self.maintenanceTime = CurTime() + math.random(300, 600)
		DarkRP.Weed.Notify(ply, "Generator maintenance complete!", DarkRP.Weed.NOTIFY_HINT)
		self:EmitSound("items/battery_pickup.wav", 75, 100)
	end
	
	function ENT:Think()
		-- Check if needs maintenance
		if self:GetIsRunning() and CurTime() > self.maintenanceTime and not self:GetNeedsMaintenance() then
			self:SetNeedsMaintenance(true)
			
			-- Chance to explode if not maintained
			if math.random(1, 100) <= 30 then
				self:Explode()
			end
		end
		
		-- Power nearby lamps/devices
		if self:GetIsRunning() and not self:GetNeedsMaintenance() then
			self:PowerNearbyDevices()
		end
		
		-- Generator running sound
		if self:GetIsRunning() and not self:GetNeedsMaintenance() then
			if not self.nextSoundTime or CurTime() > self.nextSoundTime then
				self:EmitSound("ambient/machines/diesel_engine_idle1.wav", 70, 100)
				self.nextSoundTime = CurTime() + 5
			end
		end
		
		self:NextThink(CurTime() + 1)
		return true
	end
	
	function ENT:PowerNearbyDevices()
		local powerRadius = 500 -- 500 units radius
		local myPos = self:GetPos()
		
		-- Find all lamps in radius
		for _, ent in ipairs(ents.FindInSphere(myPos, powerRadius)) do
			if not IsValid(ent) then continue end
			
			local class = ent:GetClass()
			if class == "darkrp_weed_lamp_led" or class == "darkrp_weed_lamp_sodium" then
				ent:SetPowerSource(self)
				ent:SetHasPower(true)
			end
			
			-- Also power water tanks if they exist
			if class == "darkrp_weed_watertank" then
				ent:SetHasPower(true)
			end
		end
	end
	
	function ENT:Explode()
		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		util.Effect("Explosion", effectdata)
		
		self:EmitSound("ambient/explosions/explode_" .. math.random(1, 9) .. ".wav", 100, 100)
		
		-- Damage nearby entities
		util.BlastDamage(self, IsValid(self:GetOwner()) and self:GetOwner() or self, self:GetPos(), 200, 50)
		
		self:Remove()
	end
	
	function ENT:OnRemove()
		timer.Remove("Generator_FuelConsumption_" .. self:EntIndex())
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw power radius when running
		if self:GetIsRunning() and not self:GetNeedsMaintenance() then
			local powerRadius = 500
			local myPos = self:GetPos()
			local dist = LocalPlayer():GetPos():Distance(myPos)
			
			if dist < 800 then
				-- Draw circle on ground
				local segments = 64
				local alpha = math.Clamp(255 - (dist / 800 * 200), 50, 150)
				
				render.SetColorMaterial()
				render.DrawBeam(myPos + Vector(0, 0, 5), myPos + Vector(0, 0, 5) + Vector(powerRadius, 0, 0), 2, 0, 1, Color(100, 200, 255, alpha))
				
				for i = 0, segments do
					local ang1 = (i / segments) * math.pi * 2
					local ang2 = ((i + 1) / segments) * math.pi * 2
					
					local x1 = math.cos(ang1) * powerRadius
					local y1 = math.sin(ang1) * powerRadius
					local x2 = math.cos(ang2) * powerRadius
					local y2 = math.sin(ang2) * powerRadius
					
					local pos1 = myPos + Vector(x1, y1, 5)
					local pos2 = myPos + Vector(x2, y2, 5)
					
					render.DrawBeam(pos1, pos2, 2, 0, 1, Color(100, 200, 255, alpha))
				end
			end
		end
		
		-- Draw status indicator
		local pos = self:GetPos() + self:GetUp() * 50
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		local fuelPercent = (self:GetFuelAmount() / self:GetMaxFuel()) * 100
		local statusColor = self:GetIsRunning() and Color(100, 255, 100) or Color(200, 200, 200)
		
		if self:GetNeedsMaintenance() then
			statusColor = Color(255, 100, 100)
		end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
			draw.SimpleText("Generator", "DarkRP.Weed.Medium", 0, -60, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			local statusText = self:GetIsRunning() and "RUNNING" or "OFFLINE"
			if self:GetNeedsMaintenance() then
				statusText = "NEEDS REPAIR!"
			end
			draw.SimpleText(statusText, "DarkRP.Weed.Small", 0, -40, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			draw.SimpleText(string.format("Fuel: %.1f%%", fuelPercent), "DarkRP.Weed.Small", 0, -20, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Range: 500 units", "DarkRP.Weed.Small", 0, 0, Color(100, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if self:GetNeedsMaintenance() then
				draw.SimpleText("[E] Repair", "DarkRP.Weed.Tiny", 0, 20, Color(255, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				local action = self:GetIsRunning() and "Stop" or "Start"
				draw.SimpleText("[E] " .. action, "DarkRP.Weed.Tiny", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end
end
