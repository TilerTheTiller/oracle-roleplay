-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced Weed Growing System - Server
-- ═══════════════════════════════════════════════════════════════════════════

if not SERVER then return end

DarkRP.Weed.Server = DarkRP.Weed.Server or {}
local WeedSV = DarkRP.Weed.Server

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Data Management                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

WeedSV.PlayerData = WeedSV.PlayerData or {}

function WeedSV.InitPlayerData(ply)
	if not IsValid(ply) then return end
	
	WeedSV.PlayerData[ply:SteamID()] = {
		inventory = {},
		stats = {
			totalHarvests = 0,
			totalGrams = 0,
			totalEarned = 0,
			plantsGrown = 0,
			deadPlants = 0
		},
		activeEffects = {},
		lastSave = CurTime()
	}
	
	-- Load from database if you have one
	-- WeedSV.LoadPlayerData(ply)
end

function WeedSV.GetPlayerData(ply)
	if not IsValid(ply) then return nil end
	return WeedSV.PlayerData[ply:SteamID()]
end

function WeedSV.SavePlayerData(ply)
	if not IsValid(ply) then return end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return end
	
	data.lastSave = CurTime()
	
	-- Save to database
	-- Example: Save to DarkRP's database or MySQL
	-- If using DarkRP's MySQLite:
	-- MySQLite.query(...)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Plant Growth System                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedSV.UpdatePlantGrowth()
	local plants = ents.FindByClass("darkrp_weed_pot")
	
	for _, pot in ipairs(plants) do
		if not IsValid(pot) then continue end
		
		local plant = pot.plantData
		if not plant or not plant.hasPlant then continue end
		
		local strain = DarkRP.Weed.Config.GetStrain(plant.strainID)
		if not strain then continue end
		
		-- Check if plant is dead
		if plant.health <= DarkRP.Weed.Config.DeathThreshold then
			WeedSV.KillPlant(pot)
			continue
		end
		
		-- Check if ready for harvest
		if plant.growthTime >= strain.growthTime then
			plant.isReady = true
			pot:SetNWBool("WeedPlant.IsReady", true)
			continue
		end
		
		-- Calculate growth modifiers
		local growthMultiplier = 1.0
		
		-- Light bonus
		if DarkRP.Weed.Config.RequireLight then
			local hasLight, lamp = DarkRP.Weed.IsNearLamp(pot:GetPos())
			if hasLight and IsValid(lamp) then
				local lampData = lamp.equipmentData
				if lampData and lampData.growthBoost then
					growthMultiplier = growthMultiplier * lampData.growthBoost
				end
			else
				-- Penalty for no light
				growthMultiplier = growthMultiplier * 0.3
			end
		end
		
		-- Water requirement check
		if plant.waterLevel < strain.waterRequirement * 0.5 then
			growthMultiplier = growthMultiplier * 0.5
			plant.health = math.max(0, plant.health - DarkRP.Weed.Config.HealthDecayRate)
		end
		
		-- Fertilizer bonus
		if plant.fertilizerLevel >= strain.fertilizerRequirement then
			growthMultiplier = growthMultiplier * 1.2
		end
		
		-- Update growth time
		plant.growthTime = plant.growthTime + (DarkRP.Weed.Config.GrowthTickRate * growthMultiplier)
		
		-- Consume resources
		plant.waterLevel = math.max(0, plant.waterLevel - DarkRP.Weed.Config.WaterConsumptionRate)
		plant.fertilizerLevel = math.max(0, plant.fertilizerLevel - DarkRP.Weed.Config.FertilizerConsumptionRate)
		
		-- Update health
		if plant.waterLevel > strain.waterRequirement * 0.7 and plant.fertilizerLevel > strain.fertilizerRequirement * 0.5 then
			plant.health = math.min(100, plant.health + DarkRP.Weed.Config.HealthRegenRate)
		end
		
		-- Pest system - random infection chance
		if not plant.hasPest and math.random(1, 1000) <= 2 then -- 0.2% chance per tick
			plant.hasPest = true
			plant.pestInfectionTime = CurTime()
			pot:SetHasPest(true)
			
			local owner = pot:GetOwner()
			if IsValid(owner) then
				DarkRP.Weed.Notify(owner, "Your " .. plant.strainName .. " has been infected with pests!", DarkRP.Weed.NOTIFY_ERROR)
			end
		end
		
		-- Pest damage
		if plant.hasPest then
			plant.health = math.max(0, plant.health - (DarkRP.Weed.Config.HealthDecayRate * 2)) -- Double decay
			growthMultiplier = growthMultiplier * 0.5 -- Half growth speed
		end
		
		-- Calculate THC based on care quality
		local thcMultiplier = 1.0
		
		-- Water level affects THC
		if plant.waterLevel >= strain.waterRequirement * 0.9 then
			thcMultiplier = thcMultiplier * 1.2
		elseif plant.waterLevel < strain.waterRequirement * 0.5 then
			thcMultiplier = thcMultiplier * 0.7
		end
		
		-- Light affects THC
		local hasLight, lamp = DarkRP.Weed.IsNearLamp(pot:GetPos())
		if hasLight and IsValid(lamp) then
			if lamp:GetClass() == "darkrp_weed_lamp_sodium" then
				thcMultiplier = thcMultiplier * 1.3
			elseif lamp:GetClass() == "darkrp_weed_lamp_led" then
				thcMultiplier = thcMultiplier * 1.2
			end
		else
			thcMultiplier = thcMultiplier * 0.6
		end
		
		-- Fertilizer affects THC
		if plant.fertilizerLevel >= strain.fertilizerRequirement then
			thcMultiplier = thcMultiplier * 1.15
		end
		
		-- Soil quality affects THC
		if plant.soilQuality then
			thcMultiplier = thcMultiplier * plant.soilQuality
		end
		
		-- Pest reduces THC
		if plant.hasPest then
			thcMultiplier = thcMultiplier * 0.5
		end
		
		-- Update THC based on strain's base THC range
		local baseTHC = (strain.thcMin + strain.thcMax) / 2
		plant.thc = math.Clamp(baseTHC * thcMultiplier, strain.thcMin * 0.5, strain.thcMax * 1.2)
		pot:SetTHC(plant.thc)
		
		-- Update quality
		plant.quality = DarkRP.Weed.CalculateQuality(pot)
		
		-- Update model based on stage
		local stageIndex, stage = DarkRP.Weed.GetCurrentStage(pot)
		if stage and stage.model then
			if IsValid(pot.plantEntity) then
				if pot.plantEntity:GetModel() ~= stage.model then
					pot.plantEntity:SetModel(stage.model)
					pot.plantEntity:SetModelScale(stage.size or 1.0, 0.5)
					
					local greenness = 150 + (stageIndex * 20)
					pot.plantEntity:SetColor(Color(200, math.min(255, greenness), 200))
				end
			else
				local plant = ents.Create("prop_physics")
				if IsValid(plant) then
					plant:SetModel(stage.model)
					plant:SetPos(pot:GetPos() + Vector(0, 0, 8))
					plant:SetAngles(pot:GetAngles())
					plant:Spawn()
					plant:SetModelScale(stage.size or 1.0, 0.5)
					plant:SetParent(pot)
					plant:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
					
					local phys = plant:GetPhysicsObject()
					if IsValid(phys) then
						phys:EnableMotion(false)
					end
					
				pot.plantEntity = plant
				end
			end
		end
		
		-- Sync to client
		WeedSV.SyncPlantToClient(pot)
	end
end

function WeedSV.KillPlant(pot)
	if not IsValid(pot) then return end
	
	local plant = pot.plantData
	if not plant then return end
	
	plant.isDead = true
	plant.health = 0
	pot:SetNWBool("WeedPlant.IsDead", true)
	
	-- Update owner stats
	local owner = pot:GetOwner()
	if IsValid(owner) then
		local data = WeedSV.GetPlayerData(owner)
		if data then
			data.stats.deadPlants = data.stats.deadPlants + 1
		end
		
		DarkRP.Weed.Notify(owner, "Your " .. plant.strainName .. " plant has died!", DarkRP.Weed.NOTIFY_ERROR)
	end
	
	-- Change model to dead plant
	pot:SetColor(Color(100, 80, 60))
	
	WeedSV.SyncPlantToClient(pot)
end

function WeedSV.SyncPlantToClient(pot)
	if not IsValid(pot) then return end
	
	local plant = pot.plantData
	if not plant then return end
	
	net.Start("DarkRP.Weed.PlantUpdate")
		net.WriteEntity(pot)
		net.WriteTable(plant)
	net.Broadcast()
end

-- Start growth timer
timer.Create("DarkRP.Weed.GrowthTick", DarkRP.Weed.Config.GrowthTickRate, 0, function()
	WeedSV.UpdatePlantGrowth()
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Plant Actions                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedSV.PlantSeed(pot, ply, strainID)
	if not IsValid(pot) or not IsValid(ply) then 
		DarkRP.Weed.Error("PlantSeed: Invalid pot or player")
		return false 
	end
	
	DarkRP.Weed.Debug("PlantSeed called with strainID: " .. tostring(strainID))
	
	local strain = DarkRP.Weed.Config.GetStrain(strainID)
	if not strain then
		DarkRP.Weed.Error("PlantSeed: Invalid strain - " .. tostring(strainID))
		DarkRP.Weed.Notify(ply, "Invalid strain!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	DarkRP.Weed.Debug("Found strain: " .. strain.name)
	
	-- Check if pot already has a plant
	if pot.plantData and pot.plantData.hasPlant then
		DarkRP.Weed.Notify(ply, "This pot already has a plant!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	-- Check if pot has soil
	if not pot:GetHasSoil() then
		DarkRP.Weed.Notify(ply, "This pot needs soil before planting!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	DarkRP.Weed.Debug("Initializing plant data...")
	
	-- Initialize plant data
	pot.plantData = {
		hasPlant = true,
		strainID = strainID,
		strainName = strain.name,
		growthTime = 0,
		health = 100,
		waterLevel = 100,
		fertilizerLevel = 50,
		quality = 50,
		isReady = false,
		isDead = false,
		plantedTime = CurTime(),
		plantedBy = ply:SteamID(),
		hasSoil = true,
		soilQuality = pot.soilQuality or 1.0,
		thc = 0,
		hasPest = false,
		pestInfectionTime = 0,
		harvestCount = 0,
		stage = 1
	}
	
	DarkRP.Weed.Debug("Plant data initialized, creating plant entity...")
	
	-- Create plant entity as child of pot
	local firstStage = strain.stages[1]
	if firstStage and firstStage.model then
		DarkRP.Weed.Debug("Creating plant entity with model: " .. firstStage.model)
		
		-- Remove old plant entity if it exists
		if IsValid(pot.plantEntity) then
			pot.plantEntity:Remove()
		end
		
		-- Create new plant entity
		local plant = ents.Create("prop_physics")
		if IsValid(plant) then
			plant:SetModel(firstStage.model)
			plant:SetPos(pot:GetPos() + Vector(0, 0, 8))
			plant:SetAngles(pot:GetAngles())
			plant:Spawn()
			plant:SetModelScale(firstStage.size or 0.3, 0.5)
			plant:SetParent(pot)
			plant:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
			
			plant:SetColor(Color(200, 255, 200))
			plant:SetRenderMode(RENDERMODE_TRANSCOLOR)
			
			local phys = plant:GetPhysicsObject()
			if IsValid(phys) then
				phys:EnableMotion(false)
			end
			
			pot.plantEntity = plant
			DarkRP.Weed.Debug("Plant entity created successfully")
		else
			DarkRP.Weed.Error("Failed to create plant entity!")
		end
	else
		DarkRP.Weed.Error("No first stage or model found for strain!")
	end
	
	-- Update owner stats
	local data = WeedSV.GetPlayerData(ply)
	if data then
		data.stats.plantsGrown = data.stats.plantsGrown + 1
		DarkRP.Weed.Debug("Updated player stats: " .. data.stats.plantsGrown .. " plants grown")
	end
	
	DarkRP.Weed.Debug("Syncing plant to client...")
	WeedSV.SyncPlantToClient(pot)
	
	DarkRP.Weed.Print("Successfully planted " .. strain.name .. " for " .. ply:Nick())
	DarkRP.Weed.Notify(ply, "Planted " .. strain.name .. "!", DarkRP.Weed.NOTIFY_HINT)
	
	return true
end

function WeedSV.WaterPlant(pot, ply, amount)
	if not IsValid(pot) or not IsValid(ply) then return false end
	
	local plant = pot.plantData
	if not plant or not plant.hasPlant then
		DarkRP.Weed.Notify(ply, "No plant to water!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	if plant.isDead then
		DarkRP.Weed.Notify(ply, "This plant is dead!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	amount = amount or 20
	plant.waterLevel = math.min(100, plant.waterLevel + amount)
	
	WeedSV.SyncPlantToClient(pot)
	DarkRP.Weed.Notify(ply, "Watered plant (+" .. amount .. "%)", DarkRP.Weed.NOTIFY_HINT)
	
	-- Play water effect
	local effectdata = EffectData()
	effectdata:SetOrigin(pot:GetPos() + Vector(0, 0, 20))
	effectdata:SetScale(2)
	util.Effect("WaterSplash", effectdata)
	
	return true
end

function WeedSV.FertilizePlant(pot, ply, amount)
	if not IsValid(pot) or not IsValid(ply) then return false end
	
	local plant = pot.plantData
	if not plant or not plant.hasPlant then
		DarkRP.Weed.Notify(ply, "No plant to fertilize!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	if plant.isDead then
		DarkRP.Weed.Notify(ply, "This plant is dead!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	amount = amount or 15
	plant.fertilizerLevel = math.min(100, plant.fertilizerLevel + amount)
	
	WeedSV.SyncPlantToClient(pot)
	DarkRP.Weed.Notify(ply, "Fertilized plant (+" .. amount .. "%)", DarkRP.Weed.NOTIFY_HINT)
	
	return true
end

function WeedSV.CurePest(pot, ply)
	if not IsValid(pot) or not IsValid(ply) then return false end
	
	local plant = pot.plantData
	if not plant or not plant.hasPlant then
		DarkRP.Weed.Notify(ply, "No plant to cure!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	if not plant.hasPest then
		DarkRP.Weed.Notify(ply, "This plant has no pests!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	-- Cure the pest
	plant.hasPest = false
	plant.pestInfectionTime = 0
	pot:SetHasPest(false)
	
	-- Restore some health
	plant.health = math.min(100, plant.health + 20)
	
	WeedSV.SyncPlantToClient(pot)
	DarkRP.Weed.Notify(ply, "Cured pest infection! (+" .. 20 .. "% health)", DarkRP.Weed.NOTIFY_HINT)
	
	return true
end

function WeedSV.HarvestPlant(pot, ply)
	if not IsValid(pot) or not IsValid(ply) then return false end
	
	local plant = pot.plantData
	if not plant or not plant.hasPlant then
		DarkRP.Weed.Notify(ply, "No plant to harvest!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	if not plant.isReady then
		DarkRP.Weed.Notify(ply, "Plant is not ready to harvest!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	local strain = DarkRP.Weed.Config.GetStrain(plant.strainID)
	if not strain then return false end
	
	-- Initialize harvest tracking if not exists
	if not plant.harvestCount then
		plant.harvestCount = 0
	end
	
	-- Calculate total yield for full harvest
	local totalYield = DarkRP.Weed.CalculateYield(pot)
	local quality = plant.quality
	local thc = plant.thc or ((strain.thcMin + strain.thcMax) / 2)
	
	-- Multi-press mechanic: requires 3-5 presses to fully harvest
	local requiredPresses = math.random(3, 5)
	plant.harvestCount = plant.harvestCount + 1
	
	-- Calculate chunk yield for this press (divide total by required presses)
	local chunkYield = totalYield / requiredPresses
	
	if plant.harvestCount >= requiredPresses then
		-- Final harvest - give remaining yield
		chunkYield = totalYield - ((requiredPresses - 1) * (totalYield / requiredPresses))
		
		DarkRP.Weed.Notify(ply, string.format("Final harvest! Collected %.1fg of %s (THC: %.1f%%, Quality: %d%%)", 
			chunkYield, strain.name, thc, quality), DarkRP.Weed.NOTIFY_HINT)
		
		-- Give player the harvested weed chunk
		WeedSV.GiveWeedItem(ply, plant.strainID, chunkYield, quality, thc)
		
		-- Update stats
		local data = WeedSV.GetPlayerData(ply)
		if data then
			data.stats.totalHarvests = data.stats.totalHarvests + 1
			data.stats.totalGrams = data.stats.totalGrams + totalYield
		end
		
		-- Reset pot
		pot.plantData = {
			hasPlant = false,
			strainID = nil,
			strainName = nil,
			growthTime = 0,
			health = 0,
			waterLevel = 0,
			fertilizerLevel = 0,
			quality = 0,
			isReady = false,
			isDead = false,
			hasSoil = false,
			soilQuality = 1.0,
			thc = 0,
			hasPest = false,
			pestInfectionTime = 0,
			harvestCount = 0,
			stage = 0
		}
		
		-- Remove plant entity
		if IsValid(pot.plantEntity) then
			pot.plantEntity:Remove()
			pot.plantEntity = nil
		end
		
		-- Reset networkvars
		pot:SetHasSoil(false)
		pot:SetHasPest(false)
		pot:SetTHC(0)
		
		WeedSV.SyncPlantToClient(pot)
		
		return true, totalYield, quality, thc
	else
		-- Partial harvest - give chunk
		DarkRP.Weed.Notify(ply, string.format("Harvesting... Collected %.1fg (%d/%d presses)", 
			chunkYield, plant.harvestCount, requiredPresses), DarkRP.Weed.NOTIFY_HINT)
		
		-- Give player the harvested weed chunk
		WeedSV.GiveWeedItem(ply, plant.strainID, chunkYield, quality, thc)
		
		-- Reduce plant model size slightly to show progress
		if IsValid(pot.plantEntity) then
			local newScale = 1.0 - (plant.harvestCount / requiredPresses * 0.3)
			pot.plantEntity:SetModelScale(newScale, 0.2)
		end
		
		WeedSV.SyncPlantToClient(pot)
		
		return false -- Not fully harvested yet
	end
end

function WeedSV.RemovePlant(pot, ply)
	if not IsValid(pot) or not IsValid(ply) then return false end
	
	local plant = pot.plantData
	if not plant or not plant.hasPlant then
		DarkRP.Weed.Notify(ply, "No plant to remove!", DarkRP.Weed.NOTIFY_ERROR)
		return false
	end
	
	-- Reset pot
	pot.plantData = {
		hasPlant = false,
		strainID = nil,
		strainName = nil,
		growthTime = 0,
		health = 0,
		waterLevel = 0,
		fertilizerLevel = 0,
		quality = 0,
		isReady = false,
		isDead = false
	}
	
	-- Remove plant entity
	if IsValid(pot.plantEntity) then
		pot.plantEntity:Remove()
		pot.plantEntity = nil
	end
	
	WeedSV.SyncPlantToClient(pot)
	DarkRP.Weed.Notify(ply, "Removed plant", DarkRP.Weed.NOTIFY_HINT)
	
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Inventory System                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedSV.GiveWeedItem(ply, strainID, grams, quality, thc)
	if not IsValid(ply) then return false end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return false end
	
	thc = thc or 15 -- Default THC if not provided
	
	-- Find existing stack or create new
	local found = false
	for _, item in ipairs(data.inventory) do
		if item.type == "weed_raw" and item.strainID == strainID and math.abs(item.quality - quality) < 5 and math.abs((item.thc or 15) - thc) < 2 then
			item.amount = item.amount + grams
			found = true
			break
		end
	end
	
	if not found then
		table.insert(data.inventory, {
			type = "weed_raw",
			strainID = strainID,
			amount = grams,
			quality = quality,
			thc = thc,
			timestamp = os.time()
		})
	end
	
	WeedSV.SyncInventory(ply)
	return true
end

function WeedSV.RemoveWeedItem(ply, itemIndex, amount)
	if not IsValid(ply) then return false end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return false end
	
	local item = data.inventory[itemIndex]
	if not item then return false end
	
	if amount >= item.amount then
		table.remove(data.inventory, itemIndex)
	else
		item.amount = item.amount - amount
	end
	
	WeedSV.SyncInventory(ply)
	return true
end

function WeedSV.SyncInventory(ply)
	if not IsValid(ply) then return end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return end
	
	net.Start("DarkRP.Weed.InventorySync")
		net.WriteTable(data.inventory)
	net.Send(ply)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Effects System                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedSV.ApplyEffect(ply, effectData)
	if not IsValid(ply) or not effectData then return end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return end
	
	-- Apply immediate effects
	if effectData.healthBoost and effectData.healthBoost > 0 then
		ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + effectData.healthBoost))
	end
	
	if effectData.armorBoost and effectData.armorBoost > 0 then
		ply:SetArmor(math.min(ply:GetMaxArmor(), ply:Armor() + effectData.armorBoost))
	end
	
	-- Store active effect
	local effect = {
		startTime = CurTime(),
		endTime = CurTime() + effectData.duration,
		data = effectData
	}
	
	table.insert(data.activeEffects, effect)
	
	-- Send to client for visual effects
	net.Start("DarkRP.Weed.HighEffect")
		net.WriteTable(effectData)
		net.WriteFloat(effectData.duration)
	net.Send(ply)
	
	DarkRP.Weed.Notify(ply, "You feel the effects...", DarkRP.Weed.NOTIFY_HINT)
	
	-- Set timer to remove effect
	timer.Simple(effectData.duration, function()
		if IsValid(ply) then
			WeedSV.RemoveEffect(ply, effect)
		end
	end)
end

function WeedSV.RemoveEffect(ply, effect)
	if not IsValid(ply) then return end
	
	local data = WeedSV.GetPlayerData(ply)
	if not data then return end
	
	for i, e in ipairs(data.activeEffects) do
		if e == effect then
			table.remove(data.activeEffects, i)
			break
		end
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Receivers                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Weed.PlantAction", function(len, ply)
	if not IsValid(ply) then return end
	
	local action = net.ReadString()
	local entity = net.ReadEntity()
	
	if not IsValid(entity) then 
		DarkRP.Weed.Debug("Invalid entity received from player: " .. ply:Nick())
		return 
	end
	
	DarkRP.Weed.Debug("Received action: " .. action .. " from " .. ply:Nick() .. " for entity: " .. entity:GetClass())
	
	if action == "plant" then
		local strainID = net.ReadString()
		DarkRP.Weed.Debug("Planting strain: " .. strainID)
		WeedSV.PlantSeed(entity, ply, strainID)
	elseif action == "water" then
		WeedSV.WaterPlant(entity, ply)
	elseif action == "fertilize" then
		WeedSV.FertilizePlant(entity, ply)
	elseif action == "harvest" then
		WeedSV.HarvestPlant(entity, ply)
	elseif action == "remove" then
		WeedSV.RemovePlant(entity, ply)
	elseif action == "cure_pest" then
		WeedSV.CurePest(entity, ply)
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("PlayerInitialSpawn", "DarkRP.Weed.InitPlayer", function(ply)
	WeedSV.InitPlayerData(ply)
end)

hook.Add("PlayerDisconnected", "DarkRP.Weed.SavePlayer", function(ply)
	WeedSV.SavePlayerData(ply)
	WeedSV.PlayerData[ply:SteamID()] = nil
end)

hook.Add("ShutDown", "DarkRP.Weed.SaveAll", function()
	for _, ply in ipairs(player.GetAll()) do
		WeedSV.SavePlayerData(ply)
	end
end)

-- Auto-save every 5 minutes
timer.Create("DarkRP.Weed.AutoSave", 300, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		WeedSV.SavePlayerData(ply)
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Console Commands (Admin)                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add("darkrp_weed_clear_all", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	
	local count = 0
	
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and (string.StartWith(ent:GetClass(), "darkrp_weed_")) then
			ent:Remove()
			count = count + 1
		end
	end
	
	local msg = "Removed " .. count .. " weed entities"
	if IsValid(ply) then
		DarkRP.Weed.Notify(ply, msg, DarkRP.Weed.NOTIFY_HINT)
	else
		print(msg)
	end
end)

concommand.Add("darkrp_weed_give_seed", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsSuperAdmin() then return end
	
	local target = ply
	if args[1] then
		target = player.GetByID(tonumber(args[1])) or ply
	end
	
	local strainID = args[2] or "schwag"
	
	if IsValid(target) then
		-- Give seed item (implement based on your inventory system)
		DarkRP.Weed.Notify(target, "Received " .. strainID .. " seed", DarkRP.Weed.NOTIFY_HINT)
	end
end)

DarkRP.Weed.Print("Server functions loaded")

return WeedSV
