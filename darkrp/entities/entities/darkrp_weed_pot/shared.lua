AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Weed Growing Pot"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StrainID")
	self:NetworkVar("Float", 0, "GrowthTime")
	self:NetworkVar("Float", 1, "Health")
	self:NetworkVar("Float", 2, "WaterLevel")
	self:NetworkVar("Float", 3, "FertilizerLevel")
	self:NetworkVar("Float", 4, "Quality")
	self:NetworkVar("Float", 5, "THC") -- THC percentage
	self:NetworkVar("Bool", 0, "HasPlant")
	self:NetworkVar("Bool", 1, "IsReady")
	self:NetworkVar("Bool", 2, "IsDead")
	self:NetworkVar("Bool", 3, "HasSoil")
	self:NetworkVar("Bool", 4, "HasPest")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_pot01.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize plant data
		self.plantData = {
			hasPlant = false,
			hasSoil = false,
			strainID = nil,
			strainName = nil,
			growthTime = 0,
			health = 100,
			waterLevel = 0,
			fertilizerLevel = 0,
			quality = 0,
			thc = 0,
			isReady = false,
			isDead = false,
			hasPest = false,
			pestInfectionTime = 0,
			plantedTime = 0,
			plantedBy = nil,
			lastWatered = 0,
			needsRepair = false,
			harvestCount = 0,
			stage = 0
		}
		
		-- Plant entity reference
		self.plantEntity = nil
		
		-- Equipment data
		self.equipmentData = {
			id = "pot_small",
			name = "Growing Pot",
			model = "models/zerochain/props_growop2/zgo2_pot01.mdl",
			capacity = 1,
			qualityBonus = 0
		}
		
		self:SetHealth(100)
	end
	
	if CLIENT then
		self.nextParticleTime = 0
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
		print("[Weed Pot] Use called by " .. (IsValid(caller) and caller:Nick() or "invalid"))
		
		if not IsValid(caller) or not caller:IsPlayer() then 
			print("[Weed Pot] Invalid caller")
			return 
		end
		
		-- Check ownership (allow interaction if no owner set)
		if IsValid(self:GetOwner()) and self:GetOwner() ~= caller then
			print("[Weed Pot] Ownership check failed")
			DarkRP.Weed.Notify(caller, "You don't own this pot!", DarkRP.Weed.NOTIFY_ERROR)
			return
		end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			print("[Weed Pot] Setting owner to " .. caller:Nick())
			self:SetOwner(caller)
			DarkRP.Weed.Notify(caller, "You now own this pot!", DarkRP.Weed.NOTIFY_HINT)
		end
		
		-- Check if player is holding a seed
		if caller.heldSeed and not (self.plantData and self.plantData.hasPlant) then
			print("[Weed Pot] Player has held seed: " .. caller.heldSeed.strainID)
			local success = DarkRP.Weed.Server.PlantSeed(self, caller, caller.heldSeed.strainID)
			if success then
				caller.heldSeed = nil
				DarkRP.Weed.Notify(caller, "Seed planted successfully!", DarkRP.Weed.NOTIFY_HINT)
			end
			return
		end
		
		-- Sync plant data to client before opening menu
		if self.plantData then
			print("[Weed Pot] Syncing plant data: hasPlant=" .. tostring(self.plantData.hasPlant))
			net.Start("DarkRP.Weed.PlantUpdate")
				net.WriteEntity(self)
				net.WriteTable(self.plantData)
			net.Send(caller)
		else
			print("[Weed Pot] WARNING: No plantData!")
		end
		
		-- Open interaction menu
		print("[Weed Pot] Sending OpenUI network message")
		net.Start("DarkRP.Weed.OpenUI")
			net.WriteEntity(self)
		net.Send(caller)
		print("[Weed Pot] OpenUI sent successfully")
	end
	
	function ENT:OnTakeDamage(dmg)
		self:SetHealth(self:Health() - dmg:GetDamage())
		
		if self:Health() <= 0 then
			-- Drop harvested weed if plant was ready
			if self.plantData and self.plantData.isReady then
				local yield = DarkRP.Weed.CalculateYield(self)
				local quality = self.plantData.quality
				local strain = DarkRP.Weed.Config.GetStrain(self.plantData.strainID)
				
				if strain and yield > 0 then
					-- Create a dropped weed item
					-- Implement based on your inventory system
				end
			end
			
			self:Remove()
		end
	end
	
	function ENT:Think()
		-- Sync networked vars with plant data
		if self.plantData then
			self:SetStrainID(self.plantData.strainID or "")
			self:SetGrowthTime(self.plantData.growthTime or 0)
			self:SetHealth(self.plantData.health or 0)
			self:SetWaterLevel(self.plantData.waterLevel or 0)
			self:SetFertilizerLevel(self.plantData.fertilizerLevel or 0)
			self:SetQuality(self.plantData.quality or 0)
			self:SetHasPlant(self.plantData.hasPlant or false)
			self:SetIsReady(self.plantData.isReady or false)
			self:SetIsDead(self.plantData.isDead or false)
			
			if self.plantData.hasPlant then
				DarkRP.Weed.Debug("Pot has plant: " .. tostring(self.plantData.strainID) .. " Growth: " .. tostring(self.plantData.growthTime))
			end
		end
		
		self:NextThink(CurTime() + 1)
		return true
	end
	
	function ENT:OnRemove()
		-- Cleanup
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw particles for healthy growing plant
		if self.plantData and self.plantData.hasPlant and not self.plantData.isDead then
			if self.plantData.health > 70 and CurTime() > self.nextParticleTime then
				local effectdata = EffectData()
				effectdata:SetOrigin(self:GetPos() + Vector(0, 0, 20) + VectorRand() * 10)
				effectdata:SetMagnitude(1)
				effectdata:SetScale(1)
				util.Effect("zgo2_dirt_vfx", effectdata)
				
				self.nextParticleTime = CurTime() + math.Rand(2, 5)
			end
		end
	end
	
	function ENT:Think()
		-- Update local plant data from networked vars
		if not self.plantData then
			self.plantData = {}
		end
		
		local oldHasPlant = self.plantData.hasPlant
		
		self.plantData.strainID = self:GetStrainID()
		self.plantData.growthTime = self:GetGrowthTime()
		self.plantData.health = self:GetHealth()
		self.plantData.waterLevel = self:GetWaterLevel()
		self.plantData.fertilizerLevel = self:GetFertilizerLevel()
		self.plantData.quality = self:GetQuality()
		self.plantData.hasPlant = self:GetHasPlant()
		self.plantData.isReady = self:GetIsReady()
		self.plantData.isDead = self:GetIsDead()
		
		-- Debug when plant status changes
		if oldHasPlant ~= self.plantData.hasPlant then
			DarkRP.Weed.Debug("Client: Plant status changed - hasPlant: " .. tostring(self.plantData.hasPlant))
		end
		
		-- Get strain name
		if self.plantData.strainID and self.plantData.strainID ~= "" then
			local strain = DarkRP.Weed.Config.GetStrain(self.plantData.strainID)
			if strain then
				self.plantData.strainName = strain.name
			else
				DarkRP.Weed.Debug("Client: Failed to get strain for ID: " .. self.plantData.strainID)
			end
		end
		
		self:NextThink(CurTime() + 0.5)
		return true
	end
	
	function ENT:OnRemove()
		-- Cleanup client effects
	end
end

function ENT:GetPot()
	return self
end
