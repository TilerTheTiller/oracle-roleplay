AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Water Tank"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "WaterAmount")
	self:NetworkVar("Float", 1, "MaxCapacity")
	self:NetworkVar("Bool", 0, "IsRefilling")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_watertank.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize water data
		self:SetMaxCapacity(1000) -- 1000 liters
		self:SetWaterAmount(0)
		self:SetIsRefilling(false)
		
		self.connectedPots = {}
		self.refillStartTime = 0
		self.refillDuration = 10 -- 10 seconds to fill
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Check if already full
		if self:GetWaterAmount() >= self:GetMaxCapacity() then
			DarkRP.Weed.Notify(caller, "Water tank is full!", DarkRP.Weed.NOTIFY_HINT)
			return
		end
		
		-- Start refilling
		if not self:GetIsRefilling() then
			self:StartRefill(caller)
		end
	end
	
	function ENT:StartRefill(ply)
		self:SetIsRefilling(true)
		self.refillStartTime = CurTime()
		
		DarkRP.Weed.Notify(ply, "Refilling water tank...", DarkRP.Weed.NOTIFY_HINT)
		
		timer.Create("WaterTank_Refill_" .. self:EntIndex(), self.refillDuration, 1, function()
			if not IsValid(self) then return end
			
			self:SetWaterAmount(self:GetMaxCapacity())
			self:SetIsRefilling(false)
			
			if IsValid(ply) then
				DarkRP.Weed.Notify(ply, "Water tank refilled!", DarkRP.Weed.NOTIFY_HINT)
			end
		end)
	end
	
	function ENT:TakeWater(amount)
		local current = self:GetWaterAmount()
		if current < amount then
			return false, 0
		end
		
		self:SetWaterAmount(math.max(0, current - amount))
		return true, amount
	end
	
	function ENT:AddWater(amount)
		local current = self:GetWaterAmount()
		local max = self:GetMaxCapacity()
		local added = math.min(amount, max - current)
		
		self:SetWaterAmount(current + added)
		return added
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 1)
		return true
	end
	
	function ENT:OnRemove()
		timer.Remove("WaterTank_Refill_" .. self:EntIndex())
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw water level indicator
		local pos = self:GetPos() + self:GetUp() * 50
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		local waterPercent = (self:GetWaterAmount() / self:GetMaxCapacity()) * 100
		local color = Color(100, 200, 255)
		
		if self:GetIsRefilling() then
			color = Color(255, 200, 100)
		end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
			draw.SimpleText("Water Tank", "DarkRP.Weed.Medium", 0, -40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("%.0fL / %.0fL", self:GetWaterAmount(), self:GetMaxCapacity()), "DarkRP.Weed.Small", 0, -20, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("%.1f%%", waterPercent), "DarkRP.Weed.Small", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if self:GetIsRefilling() then
				draw.SimpleText("REFILLING...", "DarkRP.Weed.Small", 0, 20, Color(255, 200, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			elseif waterPercent < 100 then
				draw.SimpleText("[E] Refill", "DarkRP.Weed.Tiny", 0, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		cam.End3D2D()
	end
end
