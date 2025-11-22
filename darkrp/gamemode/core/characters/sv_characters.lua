-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Character System - Server
--  Server-side character management with SQL persistence
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

print("[DarkRP] Loading character system (server)...")

DarkRP = DarkRP or {}
DarkRP.Characters = DarkRP.Characters or {}

-- Network strings
util.AddNetworkString("DarkRP.Characters.SendList")
util.AddNetworkString("DarkRP.Characters.Select")
util.AddNetworkString("DarkRP.Characters.Create")
util.AddNetworkString("DarkRP.Characters.Delete")
util.AddNetworkString("DarkRP.Characters.OpenMenu")
util.AddNetworkString("DarkRP.Characters.Updated")
util.AddNetworkString("DarkRP.Characters.Notify")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Internal State                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Characters._internal = {
	playerCharacters = {}, -- [steamid] = {characters table}
	activeCharacters = {}, -- [ply] = character data
	switchCooldowns = {}, -- [steamid] = timestamp
	deleteCooldowns = {} -- [steamid] = timestamp
}

local PLAYER = FindMetaTable("Player")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Meta Functions                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function PLAYER:GetActiveCharacter()
	return DarkRP.Characters._internal.activeCharacters[self]
end

function PLAYER:HasActiveCharacter()
	return DarkRP.Characters._internal.activeCharacters[self] ~= nil
end

function PLAYER:GetCharacterID()
	local char = self:GetActiveCharacter()
	return char and char.id or 0
end

function PLAYER:GetCharacterName()
	local char = self:GetActiveCharacter()
	return char and char.name or self:Nick()
end

function PLAYER:GetCharacterMoney()
	local char = self:GetActiveCharacter()
	return char and char.money or 0
end

function PLAYER:GetCharacterBankMoney()
	local char = self:GetActiveCharacter()
	return char and char.bankMoney or 0
end

function PLAYER:SetCharacterMoney(amount, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	amount = math.Clamp(amount, 0, DarkRP.Economy.config.maxMoney)
	char.money = math.floor(amount)
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Money updated: " .. DarkRP.Economy.FormatMoney(amount))
	end
	
	return true
end

function PLAYER:AddCharacterMoney(amount, reason, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	local newAmount = math.min(char.money + amount, DarkRP.Economy.config.maxMoney)
	char.money = newAmount
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Received " .. DarkRP.Economy.FormatMoney(amount) .. (reason and (" (" .. reason .. ")") or ""))
	end
	
	return true
end

function PLAYER:TakeCharacterMoney(amount, reason, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	if char.money < amount then
		if not silent then
			DarkRP.Characters.Notify(self, "Insufficient funds", true)
		end
		return false
	end
	
	char.money = math.max(char.money - amount, 0)
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Paid " .. DarkRP.Economy.FormatMoney(amount) .. (reason and (" (" .. reason .. ")") or ""))
	end
	
	return true
end

function PLAYER:CanAffordCharacter(amount)
	local char = self:GetActiveCharacter()
	return char and char.money >= amount
end

function PLAYER:SetCharacterBankMoney(amount, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	amount = math.Clamp(amount, 0, DarkRP.Economy.config.maxMoney)
	char.bankMoney = math.floor(amount)
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Bank balance updated: " .. DarkRP.Economy.FormatMoney(amount))
	end
	
	return true
end

function PLAYER:AddCharacterBankMoney(amount, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	local newAmount = math.min(char.bankMoney + amount, DarkRP.Economy.config.maxMoney)
	char.bankMoney = newAmount
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Added " .. DarkRP.Economy.FormatMoney(amount) .. " to bank")
	end
	
	return true
end

function PLAYER:TakeCharacterBankMoney(amount, silent)
	local char = self:GetActiveCharacter()
	if not char then return false end
	
	if char.bankMoney < amount then
		if not silent then
			DarkRP.Characters.Notify(self, "Insufficient bank balance", true)
		end
		return false
	end
	
	char.bankMoney = math.max(char.bankMoney - amount, 0)
	
	DarkRP.Characters.SaveCharacterMoney(self)
	
	if not silent then
		DarkRP.Characters.Notify(self, "Removed " .. DarkRP.Economy.FormatMoney(amount) .. " from bank")
	end
	
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Database Functions                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.LoadPlayerCharacters(ply, callback)
	if not IsValid(ply) then return end
	
	local steamID = ply:SteamID()
	
	local query = [[
		SELECT * FROM darkrp_characters 
		WHERE steamid = ?
		ORDER BY last_played DESC
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {steamID}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success and data then
				local characters = {}
				
				for _, charData in ipairs(data) do
					table.insert(characters, DarkRP.Characters.CreateCharacterData(charData))
				end
				
				DarkRP.Characters._internal.playerCharacters[steamID] = characters
				
				print("[DarkRP:Characters] Loaded " .. #characters .. " character(s) for " .. ply:Nick())
				
				if callback then callback(characters) end
				
				-- Check if player has an active character
				local hasActive = false
				for _, char in ipairs(characters) do
					if char.isActive then
						hasActive = true
						DarkRP.Characters.SelectCharacter(ply, char.id, true)
						break
					end
				end
				
				-- If no characters or no active character, open character menu
				if #characters == 0 or not hasActive then
					timer.Simple(0.5, function()
						if IsValid(ply) then
							DarkRP.Characters.OpenCharacterMenu(ply)
						end
					end)
				end
			else
				print("[DarkRP:Characters] Failed to load characters for " .. ply:Nick() .. ": " .. tostring(err))
				DarkRP.Characters._internal.playerCharacters[steamID] = {}
				
				if callback then callback({}) end
				
				-- Open character creation menu for new players
				timer.Simple(0.5, function()
					if IsValid(ply) then
						DarkRP.Characters.OpenCharacterMenu(ply)
					end
				end)
			end
		end)
	else
		print("[DarkRP:Characters] Database not connected")
		DarkRP.Characters._internal.playerCharacters[steamID] = {}
		
		if callback then callback({}) end
	end
end

function DarkRP.Characters.CreateCharacter(ply, name, model)
	if not IsValid(ply) then return false, "Invalid player" end
	
	-- Validate name
	local valid, err = DarkRP.Characters.ValidateName(name)
	if not valid then
		return false, err
	end
	
	-- Validate model
	valid, err = DarkRP.Characters.ValidateModel(model)
	if not valid then
		return false, err
	end
	
	local steamID = ply:SteamID()
	local characters = DarkRP.Characters._internal.playerCharacters[steamID] or {}
	
	-- Check character limit
	if #characters >= DarkRP.Characters.Config.maxCharacters then
		return false, "Maximum character limit reached (" .. DarkRP.Characters.Config.maxCharacters .. ")"
	end
	
	-- Check for duplicate names
	if not DarkRP.Characters.Config.allowDuplicateNames then
		for _, char in ipairs(characters) do
			if string.lower(char.name) == string.lower(name) then
				return false, "You already have a character with this name"
			end
		end
	end
	
	local cfg = DarkRP.Characters.Config
	
	-- Insert into database
	local query = [[
		INSERT INTO darkrp_characters 
		(steamid, character_name, model, money, bank_money, job_id, health, armor, hunger, thirst)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {
			steamID,
			name,
			model,
			cfg.startingMoney,
			cfg.startingBankMoney,
			1, -- Default job
			cfg.startingHealth,
			cfg.startingArmor,
			cfg.startingHunger,
			cfg.startingThirst
		}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success then
				-- Reload character list
				DarkRP.Characters.LoadPlayerCharacters(ply, function(chars)
					if #chars > 0 then
						-- Select the newly created character
						local newChar = chars[#chars]
						DarkRP.Characters.SelectCharacter(ply, newChar.id)
						DarkRP.Characters.Notify(ply, "Character '" .. name .. "' created successfully!")
					end
				end)
				
				print("[DarkRP:Characters] " .. ply:Nick() .. " created character: " .. name)
			else
				print("[DarkRP:Characters] Failed to create character: " .. tostring(err))
				DarkRP.Characters.Notify(ply, "Failed to create character: " .. tostring(err), true)
			end
		end)
		
		return true
	else
		return false, "Database not connected"
	end
end

function DarkRP.Characters.SelectCharacter(ply, characterID, silent)
	if not IsValid(ply) then return false end
	
	local steamID = ply:SteamID()
	local characters = DarkRP.Characters._internal.playerCharacters[steamID]
	
	if not characters then
		return false, "No characters loaded"
	end
	
	-- Find character
	local selectedChar = nil
	for _, char in ipairs(characters) do
		if char.id == characterID then
			selectedChar = char
			break
		end
	end
	
	if not selectedChar then
		return false, "Character not found"
	end
	
	-- Check switch cooldown
	if not silent and DarkRP.Characters._internal.switchCooldowns[steamID] then
		local timeLeft = DarkRP.Characters.Config.switchCooldown - (os.time() - DarkRP.Characters._internal.switchCooldowns[steamID])
		if timeLeft > 0 then
			DarkRP.Characters.Notify(ply, "Please wait " .. timeLeft .. " seconds before switching characters", true)
			return false
		end
	end
	
	-- Set as active character
	DarkRP.Characters._internal.activeCharacters[ply] = selectedChar
	DarkRP.Characters._internal.switchCooldowns[steamID] = os.time()
	
	-- Update database to mark this character as active
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query([[
			UPDATE darkrp_characters 
			SET is_active = CASE WHEN id = ? THEN 1 ELSE 0 END
			WHERE steamid = ?
		]], {characterID, steamID})
	end
	
	-- Apply character data to player
	ply:SetModel(selectedChar.model)
	ply:SetHealth(selectedChar.health)
	ply:SetArmor(selectedChar.armor)
	
	-- Always spawn at default spawn point
	ply:Spawn()
	
	if not silent then
		DarkRP.Characters.Notify(ply, "Switched to character: " .. selectedChar.name)
	end
	
	hook.Call("DarkRP.Characters.Selected", nil, ply, selectedChar)
	
	print("[DarkRP:Characters] " .. ply:Nick() .. " selected character: " .. selectedChar.name)
	
	return true
end

function DarkRP.Characters.DeleteCharacter(ply, characterID)
	if not IsValid(ply) then return false end
	
	if not DarkRP.Characters.Config.allowDeletion then
		return false, "Character deletion is disabled"
	end
	
	local steamID = ply:SteamID()
	local characters = DarkRP.Characters._internal.playerCharacters[steamID]
	
	if not characters then
		return false, "No characters loaded"
	end
	
	-- Find character
	local charToDelete = nil
	local charIndex = nil
	for i, char in ipairs(characters) do
		if char.id == characterID then
			charToDelete = char
			charIndex = i
			break
		end
	end
	
	if not charToDelete then
		return false, "Character not found"
	end
	
	-- Check if it's the active character
	local activeChar = DarkRP.Characters._internal.activeCharacters[ply]
	if activeChar and activeChar.id == characterID then
		return false, "Cannot delete active character. Switch to another character first."
	end
	
	-- Check delete cooldown
	if DarkRP.Characters._internal.deleteCooldowns[steamID] then
		local timeLeft = DarkRP.Characters.Config.deletionCooldown - (os.time() - DarkRP.Characters._internal.deleteCooldowns[steamID])
		if timeLeft > 0 then
			return false, "Please wait " .. timeLeft .. " seconds before deleting another character"
		end
	end
	
	-- Delete from database
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query([[
			DELETE FROM darkrp_characters WHERE id = ? AND steamid = ?
		]], {characterID, steamID}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success then
				-- Remove from memory
				table.remove(characters, charIndex)
				DarkRP.Characters._internal.deleteCooldowns[steamID] = os.time()
				
				DarkRP.Characters.Notify(ply, "Character '" .. charToDelete.name .. "' deleted")
				
				-- Send updated character list
				DarkRP.Characters.SendCharacterList(ply)
				
				print("[DarkRP:Characters] " .. ply:Nick() .. " deleted character: " .. charToDelete.name)
			else
				print("[DarkRP:Characters] Failed to delete character: " .. tostring(err))
				DarkRP.Characters.Notify(ply, "Failed to delete character", true)
			end
		end)
		
		return true
	else
		return false, "Database not connected"
	end
end

-- Position saving disabled - players always spawn at default spawn points
--[[
function DarkRP.Characters.SaveCharacterPosition(ply)
	if not IsValid(ply) then return end
	
	local char = ply:GetActiveCharacter()
	if not char then return end
	
	local pos = ply:GetPos()
	local ang = ply:EyeAngles()
	
	-- Update in memory
	char.position = pos
	char.angle = ang
	
	-- Update in database (commented out - position not saved)
	-- DarkRP.database.Query("UPDATE darkrp_characters SET pos_x = ?, pos_y = ?, pos_z = ?, angle_p = ?, angle_y = ?, angle_r = ? WHERE id = ?", {...})
end
--]]

function DarkRP.Characters.SaveCharacterMoney(ply)
	if not IsValid(ply) then return end
	
	local char = ply:GetActiveCharacter()
	if not char then return end
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query([[
			UPDATE darkrp_characters 
			SET money = ?, bank_money = ?
			WHERE id = ?
		]], {char.money, char.bankMoney, char.id})
	end
end

function DarkRP.Characters.SaveCharacterData(ply)
	if not IsValid(ply) then return end
	
	local char = ply:GetActiveCharacter()
	if not char then return end
	
	-- Update character data
	char.health = ply:Health()
	char.armor = ply:Armor()
	char.position = ply:GetPos()
	char.angle = ply:EyeAngles()
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		local pos = char.position
		local ang = char.angle
		
		DarkRP.database.Query([[
			UPDATE darkrp_characters 
			SET money = ?, bank_money = ?, health = ?, armor = ?,
			    pos_x = ?, pos_y = ?, pos_z = ?,
			    angle_p = ?, angle_y = ?, angle_r = ?
			WHERE id = ?
		]], {
			char.money, char.bankMoney, char.health, char.armor,
			pos.x, pos.y, pos.z, ang.p, ang.y, ang.r,
			char.id
		})
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.SendCharacterList(ply)
	if not IsValid(ply) then return end
	
	local steamID = ply:SteamID()
	local characters = DarkRP.Characters._internal.playerCharacters[steamID] or {}
	
	net.Start("DarkRP.Characters.SendList")
		net.WriteUInt(#characters, 8)
		for _, char in ipairs(characters) do
			net.WriteUInt(char.id, 32)
			net.WriteString(char.name)
			net.WriteString(char.model)
			net.WriteUInt(char.money, 32)
			net.WriteUInt(char.bankMoney, 32)
			net.WriteUInt(char.jobID, 16)
			net.WriteUInt(char.playtime, 32)
			net.WriteBool(char.isActive)
		end
	net.Send(ply)
end

function DarkRP.Characters.OpenCharacterMenu(ply)
	if not IsValid(ply) then return end
	
	DarkRP.Characters.SendCharacterList(ply)
	
	timer.Simple(0.1, function()
		if IsValid(ply) then
			net.Start("DarkRP.Characters.OpenMenu")
			net.Send(ply)
		end
	end)
end

function DarkRP.Characters.Notify(ply, message, isError)
	if not IsValid(ply) then return end
	
	net.Start("DarkRP.Characters.Notify")
		net.WriteString(message)
		net.WriteBool(isError or false)
	net.Send(ply)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Receivers                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Characters.Create", function(len, ply)
	if not IsValid(ply) then return end
	
	local name = net.ReadString()
	local model = net.ReadString()
	
	DarkRP.Characters.CreateCharacter(ply, name, model)
end)

net.Receive("DarkRP.Characters.Select", function(len, ply)
	if not IsValid(ply) then return end
	
	local characterID = net.ReadUInt(32)
	
	DarkRP.Characters.SelectCharacter(ply, characterID)
end)

net.Receive("DarkRP.Characters.Delete", function(len, ply)
	if not IsValid(ply) then return end
	
	local characterID = net.ReadUInt(32)
	
	DarkRP.Characters.DeleteCharacter(ply, characterID)
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("PlayerInitialSpawn", "DarkRP.Characters.PlayerSpawn", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			DarkRP.Characters.LoadPlayerCharacters(ply)
		end
	end)
end)

hook.Add("PlayerDisconnected", "DarkRP.Characters.PlayerDisconnect", function(ply)
	DarkRP.Characters.SaveCharacterData(ply)
	
	local steamID = ply:SteamID()
	DarkRP.Characters._internal.playerCharacters[steamID] = nil
	DarkRP.Characters._internal.activeCharacters[ply] = nil
end)

-- Save character data periodically
timer.Create("DarkRP.Characters.AutoSave", 300, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if ply:HasActiveCharacter() then
			DarkRP.Characters.SaveCharacterData(ply)
		end
	end
	
	print("[DarkRP:Characters] Auto-saved all character data")
end)

hook.Add("ShutDown", "DarkRP.Characters.Shutdown", function()
	for _, ply in ipairs(player.GetAll()) do
		DarkRP.Characters.SaveCharacterData(ply)
	end
	print("[DarkRP:Characters] Saved all character data")
end)

print("[DarkRP] Character system (server) loaded")
