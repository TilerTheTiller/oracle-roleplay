-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Character System - Shared
--  Advanced multi-character system with per-character data
-- ═══════════════════════════════════════════════════════════════════════════

print("[DarkRP] Loading character system (shared)...")

DarkRP = DarkRP or {}
DarkRP.Characters = DarkRP.Characters or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Characters.Config = {
	-- Character limits
	maxCharacters = 1, -- Single character system
	minNameLength = 3,
	maxNameLength = 32,
	
	-- Starting values for new characters
	startingMoney = 5000,
	startingBankMoney = 0,
	startingHealth = 100,
	startingArmor = 0,
	startingHunger = 100,
	startingThirst = 100,
	
	-- Character deletion
	allowDeletion = true,
	deletionCooldown = 300, -- 5 minutes
	
	-- Character switching (disabled for single character)
	allowSwitching = false,
	switchCooldown = 0,
	
	-- Character names
	allowDuplicateNames = false,
	restrictedWords = {"admin", "moderator", "owner", "superadmin"},
	
	-- Available models
	maleModels = {
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_02.mdl",
		"models/player/group01/male_03.mdl",
		"models/player/group01/male_04.mdl",
		"models/player/group01/male_05.mdl",
		"models/player/group01/male_06.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/male_08.mdl",
		"models/player/group01/male_09.mdl",
	},
	femaleModels = {
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_02.mdl",
		"models/player/group01/female_03.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group01/female_05.mdl",
		"models/player/group01/female_06.mdl",
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Character Data Structure                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.CreateCharacterData(data)
	return {
		id = data.id or 0,
		steamid = data.steamid or "",
		name = data.character_name or data.name or "",
		model = data.model or DarkRP.Characters.Config.maleModels[1],
		money = tonumber(data.money) or DarkRP.Characters.Config.startingMoney,
		bankMoney = tonumber(data.bank_money) or DarkRP.Characters.Config.startingBankMoney,
		jobID = tonumber(data.job_id) or 1,
		position = Vector(
			tonumber(data.pos_x) or 0,
			tonumber(data.pos_y) or 0,
			tonumber(data.pos_z) or 0
		),
		angle = Angle(
			tonumber(data.angle_p) or 0,
			tonumber(data.angle_y) or 0,
			tonumber(data.angle_r) or 0
		),
		health = tonumber(data.health) or DarkRP.Characters.Config.startingHealth,
		armor = tonumber(data.armor) or DarkRP.Characters.Config.startingArmor,
		hunger = tonumber(data.hunger) or DarkRP.Characters.Config.startingHunger,
		thirst = tonumber(data.thirst) or DarkRP.Characters.Config.startingThirst,
		playtime = tonumber(data.playtime) or 0,
		lastPlayed = data.last_played or os.time(),
		createdAt = data.created_at or os.time(),
		isActive = tobool(data.is_active)
	}
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Validation Functions                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.ValidateName(name)
	if not name or name == "" then
		return false, "Character name cannot be empty"
	end
	
	if #name < DarkRP.Characters.Config.minNameLength then
		return false, "Character name is too short (min " .. DarkRP.Characters.Config.minNameLength .. " characters)"
	end
	
	if #name > DarkRP.Characters.Config.maxNameLength then
		return false, "Character name is too long (max " .. DarkRP.Characters.Config.maxNameLength .. " characters)"
	end
	
	-- Check for restricted words
	local lowerName = string.lower(name)
	for _, word in ipairs(DarkRP.Characters.Config.restrictedWords) do
		if string.find(lowerName, string.lower(word), 1, true) then
			return false, "Character name contains restricted word: " .. word
		end
	end
	
	-- Check for valid characters (alphanumeric, spaces, basic punctuation)
	if not string.match(name, "^[%w%s%-%_%.]+$") then
		return false, "Character name contains invalid characters"
	end
	
	return true
end

function DarkRP.Characters.ValidateModel(model)
	if not model or model == "" then
		return false, "Invalid model"
	end
	
	-- Check if model exists in allowed lists
	for _, mdl in ipairs(DarkRP.Characters.Config.maleModels) do
		if mdl == model then return true end
	end
	
	for _, mdl in ipairs(DarkRP.Characters.Config.femaleModels) do
		if mdl == model then return true end
	end
	
	return false, "Model not in allowed list"
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Utility Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.GetAllModels()
	local models = {}
	table.Add(models, DarkRP.Characters.Config.maleModels)
	table.Add(models, DarkRP.Characters.Config.femaleModels)
	return models
end

function DarkRP.Characters.GetModelGender(model)
	for _, mdl in ipairs(DarkRP.Characters.Config.maleModels) do
		if mdl == model then return "male" end
	end
	
	for _, mdl in ipairs(DarkRP.Characters.Config.femaleModels) do
		if mdl == model then return "female" end
	end
	
	return "unknown"
end

function DarkRP.Characters.FormatPlaytime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	else
		return string.format("%dm", minutes)
	end
end

print("[DarkRP] Character system (shared) loaded")
