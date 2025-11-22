-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced Weed Growing System - Shared Functions
-- ═══════════════════════════════════════════════════════════════════════════

DarkRP.Weed = DarkRP.Weed or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Enumerations                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.PlantState = {
	SEED = 0,
	SEEDLING = 1,
	VEGETATIVE = 2,
	FLOWERING = 3,
	READY = 4,
	DEAD = 5
}

DarkRP.Weed.ProcessingState = {
	IDLE = 0,
	PROCESSING = 1,
	COMPLETE = 2,
	FAILED = 3
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Utility Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.Print(...)
	local args = {...}
	local msg = table.concat(args, ' ')
	MsgC(Color(100, 200, 100), '[DarkRP:Weed] ', Color(255, 255, 255), msg, '\n')
end

function DarkRP.Weed.Debug(...)
	local devMode = GetConVar("developer"):GetInt() > 0
	if DarkRP.Weed.Config and DarkRP.Weed.Config.Debug then
		local args = {...}
		local msg = table.concat(args, ' ')
		MsgC(Color(150, 150, 150), '[DarkRP:Weed:Debug] ', Color(200, 200, 200), msg, '\n')
	elseif devMode then
		local args = {...}
		local msg = table.concat(args, ' ')
		MsgC(Color(150, 150, 150), '[DarkRP:Weed:Debug] ', Color(200, 200, 200), msg, '\n')
	end
end

function DarkRP.Weed.Error(...)
	local args = {...}
	local msg = table.concat(args, ' ')
	MsgC(Color(255, 100, 100), '[DarkRP:Weed:Error] ', Color(255, 255, 255), msg, '\n')
	ErrorNoHalt('[DarkRP:Weed] ' .. msg .. '\n')
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Plant Growth Calculations                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.CalculateGrowthProgress(plant)
	if not IsValid(plant) then return 0 end
	
	local strain = DarkRP.Weed.Config.GetStrain(plant:GetStrainID())
	if not strain then return 0 end
	
	local currentTime = plant:GetGrowthTime()
	local totalTime = strain.growthTime
	
	return math.Clamp(currentTime / totalTime * 100, 0, 100)
end

function DarkRP.Weed.GetCurrentStage(plant)
	if not IsValid(plant) then return nil end
	
	local strain = DarkRP.Weed.Config.GetStrain(plant:GetStrainID())
	if not strain then return nil end
	
	local growthTime = plant:GetGrowthTime()
	local elapsed = 0
	
	for i, stage in ipairs(strain.stages) do
		elapsed = elapsed + stage.duration
		if growthTime <= elapsed or i == #strain.stages then
			return i, stage
		end
	end
	
	return #strain.stages, strain.stages[#strain.stages]
end

function DarkRP.Weed.CalculateYield(plant)
	if not IsValid(plant) then return 0 end
	
	local strain = DarkRP.Weed.Config.GetStrain(plant:GetStrainID())
	if not strain then return 0 end
	
	local health = plant:GetHealth()
	local quality = plant:GetQuality()
	
	-- Base yield based on health
	local healthMultiplier = health / 100
	local baseYield = math.random(strain.yieldMin, strain.yieldMax)
	local finalYield = baseYield * healthMultiplier
	
	-- Bonus from pot quality
	if IsValid(plant:GetPot()) then
		local potData = plant:GetPot().equipmentData
		if potData and potData.qualityBonus then
			finalYield = finalYield * (1 + potData.qualityBonus / 100)
		end
	end
	
	return math.floor(finalYield)
end

function DarkRP.Weed.CalculateQuality(plant)
	if not IsValid(plant) then return 0 end
	
	local strain = DarkRP.Weed.Config.GetStrain(plant:GetStrainID())
	if not strain then return 0 end
	
	local health = plant:GetHealth()
	local water = plant:GetWaterLevel()
	local fertilizer = plant:GetFertilizerLevel()
	
	-- Quality factors
	local healthFactor = health / 100
	local waterFactor = math.Clamp(water / strain.waterRequirement, 0, 1)
	local fertilizerFactor = math.Clamp(fertilizer / strain.fertilizerRequirement, 0, 1)
	
	-- Calculate average of all factors
	local avgFactor = (healthFactor + waterFactor + fertilizerFactor) / 3
	
	-- Map to strain's quality range
	local qualityRange = strain.qualityMax - strain.qualityMin
	local quality = strain.qualityMin + (qualityRange * avgFactor)
	
	return math.Clamp(math.floor(quality), 0, 100)
end

function DarkRP.Weed.CalculateValue(grams, quality, strainID)
	local strain = DarkRP.Weed.Config.GetStrain(strainID)
	if not strain then return 0 end
	
	-- Base value
	local baseValue = grams * strain.pricePerGram
	
	-- Quality multiplier (0.5x at 0% quality, 2x at 100% quality)
	local qualityMultiplier = 0.5 + (quality / 100 * 1.5)
	
	return math.floor(baseValue * qualityMultiplier)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Light Detection                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.IsNearLamp(pos, radius)
	radius = radius or DarkRP.Weed.Config.LightRadius
	
	local lamps = ents.FindByClass("darkrp_weed_lamp")
	
	for _, lamp in ipairs(lamps) do
		if IsValid(lamp) and lamp:GetPowered() then
			local lampRadius = lamp.equipmentData and lamp.equipmentData.radius or radius
			if lamp:GetPos():Distance(pos) <= lampRadius then
				return true, lamp
			end
		end
	end
	
	return false, nil
end

function DarkRP.Weed.GetNearbyLamps(pos, radius)
	radius = radius or DarkRP.Weed.Config.LightRadius
	local nearbyLamps = {}
	
	local lamps = ents.FindByClass("darkrp_weed_lamp")
	
	for _, lamp in ipairs(lamps) do
		if IsValid(lamp) and lamp:GetPowered() then
			local lampRadius = lamp.equipmentData and lamp.equipmentData.radius or radius
			if lamp:GetPos():Distance(pos) <= lampRadius then
				table.insert(nearbyLamps, lamp)
			end
		end
	end
	
	return nearbyLamps
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Data                                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.GetPlayerPotCount(ply)
	if not IsValid(ply) then return 0 end
	
	local count = 0
	local pots = ents.FindByClass("darkrp_weed_pot")
	
	for _, pot in ipairs(pots) do
		if IsValid(pot) and pot:GetOwner() == ply then
			count = count + 1
		end
	end
	
	return count
end

function DarkRP.Weed.GetPlayerLampCount(ply)
	if not IsValid(ply) then return 0 end
	
	local count = 0
	local lamps = ents.FindByClass("darkrp_weed_lamp")
	
	for _, lamp in ipairs(lamps) do
		if IsValid(lamp) and lamp:GetOwner() == ply then
			count = count + 1
		end
	end
	
	return count
end

function DarkRP.Weed.CanPlacePot(ply)
	if not IsValid(ply) then return false, "Invalid player" end
	
	local currentCount = DarkRP.Weed.GetPlayerPotCount(ply)
	local maxCount = DarkRP.Weed.Config.MaxPotsPerPlayer
	
	if currentCount >= maxCount then
		return false, "You have reached the maximum number of pots (" .. maxCount .. ")"
	end
	
	return true
end

function DarkRP.Weed.CanPlaceLamp(ply)
	if not IsValid(ply) then return false, "Invalid player" end
	
	local currentCount = DarkRP.Weed.GetPlayerLampCount(ply)
	local maxCount = DarkRP.Weed.Config.MaxLampsPerPlayer
	
	if currentCount >= maxCount then
		return false, "You have reached the maximum number of lamps (" .. maxCount .. ")"
	end
	
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  String Formatting                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.FormatTime(seconds)
	if seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		local mins = math.floor(seconds / 60)
		local secs = seconds % 60
		return string.format("%dm %ds", mins, secs)
	else
		local hours = math.floor(seconds / 3600)
		local mins = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", hours, mins)
	end
end

function DarkRP.Weed.FormatMoney(amount)
	if DarkRP and DarkRP.formatMoney then
		return DarkRP.formatMoney(amount)
	else
		return "$" .. string.Comma(math.floor(amount))
	end
end

function DarkRP.Weed.FormatPercentage(value, decimals)
	decimals = decimals or 0
	return string.format("%." .. decimals .. "f%%", value)
end

function DarkRP.Weed.FormatGrams(grams, decimals)
	decimals = decimals or 1
	return string.format("%." .. decimals .. "fg", grams)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Color Helpers                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.GetHealthColor(health)
	if health >= 80 then
		return Color(100, 255, 100)
	elseif health >= 50 then
		return Color(255, 255, 100)
	elseif health >= 25 then
		return Color(255, 200, 100)
	else
		return Color(255, 100, 100)
	end
end

function DarkRP.Weed.GetQualityColor(quality)
	if quality >= 90 then
		return Color(255, 215, 0) -- Gold
	elseif quality >= 75 then
		return Color(138, 43, 226) -- Purple
	elseif quality >= 50 then
		return Color(100, 150, 255) -- Blue
	elseif quality >= 25 then
		return Color(100, 255, 100) -- Green
	else
		return Color(150, 150, 150) -- Gray
	end
end

function DarkRP.Weed.GetTierColor(tier)
	local colors = {
		lowgrade = Color(100, 140, 60),
		midgrade = Color(80, 160, 70),
		highgrade = Color(60, 180, 80),
		premium = Color(120, 80, 180),
		exotic = Color(100, 200, 255)
	}
	
	return colors[tier] or Color(255, 255, 255)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Strings                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

if SERVER then
	util.AddNetworkString("DarkRP.Weed.PlantUpdate")
	util.AddNetworkString("DarkRP.Weed.PlantAction")
	util.AddNetworkString("DarkRP.Weed.OpenUI")
	util.AddNetworkString("DarkRP.Weed.Notification")
	util.AddNetworkString("DarkRP.Weed.HighEffect")
	util.AddNetworkString("DarkRP.Weed.ProcessingUpdate")
	util.AddNetworkString("DarkRP.Weed.InventorySync")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Notification Helper                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.Notify(ply, message, type, duration)
	if SERVER then
		net.Start("DarkRP.Weed.Notification")
			net.WriteString(message)
			net.WriteUInt(type or 0, 3)
			net.WriteFloat(duration or 3)
		if IsValid(ply) then
			net.Send(ply)
		else
			net.Broadcast()
		end
	else
		notification.AddLegacy(message, type or NOTIFY_GENERIC, duration or 3)
		surface.PlaySound("buttons/button15.wav")
	end
end

-- Notification types
DarkRP.Weed.NOTIFY_GENERIC = 0
DarkRP.Weed.NOTIFY_ERROR = 1
DarkRP.Weed.NOTIFY_UNDO = 2
DarkRP.Weed.NOTIFY_HINT = 3
DarkRP.Weed.NOTIFY_CLEANUP = 4

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Validation Functions                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.ValidateStrain(strainID)
	return DarkRP.Weed.Config.GetStrain(strainID) ~= nil
end

function DarkRP.Weed.ValidateProduct(productID)
	return DarkRP.Weed.Config.GetProduct(productID) ~= nil
end

function DarkRP.Weed.ValidateEquipment(category, equipmentID)
	return DarkRP.Weed.Config.GetEquipment(category, equipmentID) ~= nil
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Print("Shared functions loaded")

return DarkRP.Weed
