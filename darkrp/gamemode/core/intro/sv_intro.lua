-- ═══════════════════════════════════════════════════════════════════════════
--  Server Intro System - Server
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

ServerIntro = ServerIntro or {}
ServerIntro.Config = ServerIntro.Config or {}

-- Try to load from data folder first (saved configs)
if file.Exists("darkrp_intro/config.txt", "DATA") then
	local configCode = file.Read("darkrp_intro/config.txt", "DATA")
	if configCode and configCode ~= "" then
		local configFunc = CompileString(configCode, "ServerIntro Config", false)
		if configFunc then
			local success, err = pcall(configFunc)
			if success then
				print("[Server Intro] Loaded config from data/darkrp_intro/config.txt")
			else
				ErrorNoHalt("[Server Intro] Error loading config: " .. tostring(err) .. "\n")
			end
		else
			ErrorNoHalt("[Server Intro] Failed to compile config\n")
		end
	end
elseif file.Exists("gamemodes/darkrp/gamemode/configs/sh_intro.lua", "GAME") then
	include("configs/sh_intro.lua")
	print("[Server Intro] Loaded config from gamemode/configs/sh_intro.lua")
else
	print("[Server Intro] Config file not found, using defaults")
end

util.AddNetworkString("ServerIntro.Start")
util.AddNetworkString("ServerIntro.Skip")
util.AddNetworkString("ServerIntro.CheckSteamGroup")
util.AddNetworkString("ServerIntro.SyncConfig")
util.AddNetworkString("ServerIntro.UpdateConfig")

-- Player data storage
ServerIntro.PlayerData = ServerIntro.PlayerData or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Database Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.LoadPlayerData(ply)
	local steamid = ply:SteamID()
	
	local query = [[
		SELECT seen_intro, received_reward FROM darkrp_intro_data WHERE steamid = ?
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {steamid}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success and data and #data > 0 then
				ServerIntro.PlayerData[ply] = {
					seenIntro = tobool(data[1].seen_intro),
					receivedReward = tobool(data[1].received_reward)
				}
			else
				ServerIntro.PlayerData[ply] = {
					seenIntro = false,
					receivedReward = false
				}
			end
			
			-- Start intro if not seen
			if not ServerIntro.PlayerData[ply].seenIntro and ServerIntro.Config.Enabled then
				timer.Simple(1, function()
					if IsValid(ply) then
						ServerIntro.StartIntro(ply)
					end
				end)
			else
				-- Player has seen intro or intro disabled, open character menu directly
				print("[Server Intro] Player " .. ply:Nick() .. " has seen intro or intro disabled, opening character menu")
				timer.Simple(1, function()
					if IsValid(ply) and DarkRP and DarkRP.Characters then
						DarkRP.Characters.OpenCharacterMenu(ply)
					end
				end)
			end
		end)
	else
		-- Fallback without database
		ServerIntro.PlayerData[ply] = {
			seenIntro = false,
			receivedReward = false
		}
		
		if ServerIntro.Config.Enabled then
			timer.Simple(1, function()
				if IsValid(ply) then
					ServerIntro.StartIntro(ply)
				end
			end)
		else
			-- Intro disabled, open character menu
			timer.Simple(1, function()
				if IsValid(ply) and DarkRP and DarkRP.Characters then
					DarkRP.Characters.OpenCharacterMenu(ply)
				end
			end)
		end
	end
end

function ServerIntro.SavePlayerData(ply, seenIntro, receivedReward)
	local steamid = ply:SteamID()
	
	local query = [[
		INSERT INTO darkrp_intro_data (steamid, seen_intro, received_reward)
		VALUES (?, ?, ?)
		ON DUPLICATE KEY UPDATE
			seen_intro = ?,
			received_reward = ?,
			last_seen = CURRENT_TIMESTAMP
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {
			steamid, 
			seenIntro and 1 or 0, 
			receivedReward and 1 or 0,
			seenIntro and 1 or 0,
			receivedReward and 1 or 0
		}, function(data, success, err)
			if not success then
				ErrorNoHalt("[Server Intro] Failed to save player data: " .. tostring(err) .. "\n")
			end
		end)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Intro Functions                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.StartIntro(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	
	-- Freeze player during intro
	ply:Freeze(true)
	
	-- Mark as seen
	if ServerIntro.PlayerData[ply] then
		ServerIntro.PlayerData[ply].seenIntro = true
		ServerIntro.SavePlayerData(ply, true, ServerIntro.PlayerData[ply].receivedReward)
	end
	
	-- Send intro data to client
	net.Start("ServerIntro.Start")
		net.WriteTable(ServerIntro.Config)
	net.Send(ply)
	
	print("[Server Intro] Started intro for " .. ply:Nick())
end

function ServerIntro.GiveReward(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	
	if not ServerIntro.PlayerData[ply] then return end
	if ServerIntro.PlayerData[ply].receivedReward then
		DarkRP.notify(ply, 2, 4, "You have already received the Steam group reward!")
		return
	end
	
	local amount = ServerIntro.Config.RewardAmount
	
	if ServerIntro.Config.RewardType == "money" then
		local currentMoney = ply:getDarkRPVar("money") or 0
		ply:setDarkRPVar("money", currentMoney + amount)
		
		local message = string.format(ServerIntro.Config.RewardMessage, DarkRP.formatMoney(amount))
		DarkRP.notify(ply, 0, 6, message)
	end
	
	-- Mark as received
	ServerIntro.PlayerData[ply].receivedReward = true
	ServerIntro.SavePlayerData(ply, ServerIntro.PlayerData[ply].seenIntro, true)
	
	print("[Server Intro] Gave reward to " .. ply:Nick())
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Networking                                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("ServerIntro.Skip", function(len, ply)
	if not IsValid(ply) then return end
	-- Unfreeze player
	ply:Freeze(false)
	print("[Server Intro] " .. ply:Nick() .. " skipped the intro")
	
	-- Open character menu after intro completes
	timer.Simple(0.5, function()
		if IsValid(ply) and DarkRP and DarkRP.Characters then
			DarkRP.Characters.OpenCharacterMenu(ply)
		end
	end)
end)

net.Receive("ServerIntro.CheckSteamGroup", function(len, ply)
	if not IsValid(ply) then return end
	
	-- For now, we'll use a simple check
	-- In production, you'd want to use the Steam API
	local isMember = math.random(1, 2) == 1 -- Placeholder
	
	if isMember then
		ServerIntro.GiveReward(ply)
	else
		DarkRP.notify(ply, 1, 4, "You must be in our Steam group to receive the reward!")
	end
end)

net.Receive("ServerIntro.UpdateConfig", function(len, ply)
	if not IsValid(ply) or not ply:HasFlag('a') then return end
	
	local config = net.ReadTable()
	
	-- Update configuration
	for k, v in pairs(config) do
		ServerIntro.Config[k] = v
	end
	
	-- Broadcast to all admins
	for _, pl in pairs(player.GetAll()) do
		if pl:HasFlag('a') then
			net.Start("ServerIntro.SyncConfig")
				net.WriteTable(ServerIntro.Config)
			net.Send(pl)
		end
	end
	
	print("[Server Intro] Configuration updated by " .. ply:Nick())
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("PlayerInitialSpawn", "ServerIntro.PlayerSpawn", function(ply)
	timer.Simple(0.5, function()
		if IsValid(ply) then
			ServerIntro.LoadPlayerData(ply)
		end
	end)
end)

hook.Add("PlayerDisconnected", "ServerIntro.PlayerDisconnect", function(ply)
	ServerIntro.PlayerData[ply] = nil
end)

-- Initialize database on load
hook.Add("DarkRP.Database.TablesInitialized", "ServerIntro.DBReady", function()
	print("[Server Intro] Database tables ready")
end)

print("[Server Intro] Server module loaded")
