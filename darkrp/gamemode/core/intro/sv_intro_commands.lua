-- ═══════════════════════════════════════════════════════════════════════════
--  Server Intro System - PAS Commands
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

-- Initialize ServerIntro table if it doesn't exist
ServerIntro = ServerIntro or {}

-- Network strings for configuration
util.AddNetworkString("ServerIntro.UpdateConfig")
util.AddNetworkString("ServerIntro.AddCamera")
util.AddNetworkString("ServerIntro.RemoveCamera")
util.AddNetworkString("ServerIntro.ClearCameras")
util.AddNetworkString("ServerIntro.SaveConfig")
util.AddNetworkString("ServerIntro.OpenMenu")
util.AddNetworkString("ServerIntro.ConfigUpdate")

-- Wait for PANTHEON to load before registering commands
local function RegisterCommands()
	if not pas or not pas.cmd then
		ErrorNoHalt("[Server Intro] PANTHEON command system not found!\n")
		return
	end

	-- Command: serverintro - Opens admin configuration menu
	pas.cmd.Create('serverintro', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		-- Send current config to client and open menu
		print("[Server Intro] Sending config to " .. pl:Nick())
		PrintTable(ServerIntro.Config)
		
		net.Start("ServerIntro.ConfigUpdate")
			net.WriteTable(ServerIntro.Config)
		net.Send(pl)
		
		timer.Simple(0.2, function()
			if IsValid(pl) then
				net.Start("ServerIntro.OpenMenu")
				net.Send(pl)
			end
		end)
		
		pas.log.Add('Command', pl:Nick() .. ' opened intro configuration menu')
	end)
		:SetFlag('a')
		:SetHelp('Open the server intro configuration menu')
		:SetIcon('icon16/cog.png')

	-- Command: playintro [player] - Force play intro for a player
	pas.cmd.Create('playintro', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pl
		
		if args[1] then
			target = pas.util.FindPlayer(args[1])
			if not IsValid(target) then
				pas.notify(pl, 'Player not found!', 1)
				return false
			end
		end
		
		ServerIntro.StartIntro(target)
		pas.notify(pl, 'Started intro for ' .. target:Nick(), 0)
		pas.log.Add('Command', pl:Nick() .. ' played intro for ' .. target:Nick())
	end)
		:SetFlag('a')
		:SetHelp('Force play the server intro for a player. Usage: !playintro [player]')
		:SetIcon('icon16/television.png')
		:AddArg('player', 'target (optional)')

	-- Command: resetintro [player] - Reset intro status for a player
	pas.cmd.Create('resetintro', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pl
		
		if args[1] then
			-- Find player by name
			local searchName = string.lower(args[1])
			for _, ply in pairs(player.GetAll()) do
				if string.find(string.lower(ply:Nick()), searchName, 1, true) then
					target = ply
					break
				end
			end
			
			if not IsValid(target) then
				pas.notify(pl, 'Player not found!', 1)
				return false
			end
		end
		
		if ServerIntro.PlayerData[target] then
			ServerIntro.PlayerData[target].seenIntro = false
			ServerIntro.PlayerData[target].receivedReward = false
			ServerIntro.SavePlayerData(target, false, false)
			
			pas.notify(pl, 'Reset intro status for ' .. target:Nick(), 0)
			pas.log.Add('Command', pl:Nick() .. ' reset intro status for ' .. target:Nick())
		else
			pas.notify(pl, 'Player data not found!', 1)
		end
	end)
		:SetFlag('a')
		:SetHelp('Reset intro status for a player. Usage: !resetintro [player]')
		:SetIcon('icon16/arrow_refresh.png')
		:AddArg('player', 'target (optional)')

	-- Command: givereward [player] - Manually give Steam group reward
	pas.cmd.Create('givereward', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pl
		
		if args[1] then
			-- Find player by name
			local searchName = string.lower(args[1])
			for _, ply in pairs(player.GetAll()) do
				if string.find(string.lower(ply:Nick()), searchName, 1, true) then
					target = ply
					break
				end
			end
			
			if not IsValid(target) then
				pas.notify(pl, 'Player not found!', 1)
				return false
			end
		end
		
		ServerIntro.GiveReward(target)
		pas.notify(pl, 'Gave reward to ' .. target:Nick(), 0)
		pas.log.Add('Command', pl:Nick() .. ' gave intro reward to ' .. target:Nick())
	end)
		:SetFlag('a')
		:SetHelp('Manually give Steam group reward to a player. Usage: !givereward [player]')
		:SetIcon('icon16/award_star_gold_1.png')
		:AddArg('player', 'target (optional)')

	print("[Server Intro] PANTHEON commands loaded")
end

-- Register commands when PANTHEON is ready
if pas and pas.cmd then
	RegisterCommands()
else
	hook.Add("PANTHEON_Loaded", "ServerIntro.RegisterCommands", function()
		RegisterCommands()
	end)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration Network Handlers                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Update config value
net.Receive("ServerIntro.UpdateConfig", function(len, pl)
	if not IsValid(pl) or not pl:HasFlag('a') then return end
	
	local key = net.ReadString()
	local dataType = net.ReadUInt(8)
	local value
	
	if dataType == 1 then -- Bool
		value = net.ReadBool()
	elseif dataType == 2 then -- String
		value = net.ReadString()
	elseif dataType == 3 then -- Number
		value = net.ReadFloat()
	end
	
	ServerIntro.Config[key] = value
	
	-- Broadcast config update to all clients
	net.Start("ServerIntro.ConfigUpdate")
	net.WriteTable(ServerIntro.Config)
	net.Broadcast()
	
	pas.log.Add('Command', pl:Nick() .. ' updated intro config: ' .. key .. ' = ' .. tostring(value))
end)

-- Add camera point
net.Receive("ServerIntro.AddCamera", function(len, pl)
	if not IsValid(pl) or not pl:HasFlag('a') then return end
	
	local pos = net.ReadVector()
	local ang = net.ReadAngle()
	local fov = net.ReadFloat()
	local duration = net.ReadFloat()
	
	table.insert(ServerIntro.Config.CameraPoints, {
		pos = pos,
		ang = ang,
		fov = fov,
		duration = duration
	})
	
	-- Broadcast update
	net.Start("ServerIntro.ConfigUpdate")
	net.WriteTable(ServerIntro.Config)
	net.Broadcast()
	
	pas.log.Add('Command', pl:Nick() .. ' added camera point to intro')
end)

-- Remove camera point
net.Receive("ServerIntro.RemoveCamera", function(len, pl)
	if not IsValid(pl) or not pl:HasFlag('a') then return end
	
	local index = net.ReadInt(16)
	table.remove(ServerIntro.Config.CameraPoints, index)
	
	-- Broadcast update
	net.Start("ServerIntro.ConfigUpdate")
	net.WriteTable(ServerIntro.Config)
	net.Broadcast()
	
	pas.log.Add('Command', pl:Nick() .. ' removed camera point from intro')
end)

-- Clear all camera points
net.Receive("ServerIntro.ClearCameras", function(len, pl)
	if not IsValid(pl) or not pl:HasFlag('a') then return end
	
	ServerIntro.Config.CameraPoints = {}
	
	-- Broadcast update
	net.Start("ServerIntro.ConfigUpdate")
	net.WriteTable(ServerIntro.Config)
	net.Broadcast()
	
	pas.log.Add('Command', pl:Nick() .. ' cleared all camera points from intro')
end)

-- Save config to file
net.Receive("ServerIntro.SaveConfig", function(len, pl)
	if not IsValid(pl) or not pl:HasFlag('a') then return end
	
	-- Build config content line by line to avoid string escaping issues
	local lines = {}
	table.insert(lines, "-- Server Intro System - Configuration")
	table.insert(lines, "")
	table.insert(lines, "ServerIntro = ServerIntro or {}")
	table.insert(lines, "ServerIntro.Config = ServerIntro.Config or {}")
	table.insert(lines, "")
	table.insert(lines, "-- Basic Settings")
	table.insert(lines, "ServerIntro.Config.Enabled = " .. tostring(ServerIntro.Config.Enabled))
	table.insert(lines, "ServerIntro.Config.Duration = " .. tostring(ServerIntro.Config.Duration))
	table.insert(lines, "ServerIntro.Config.WelcomeText = " .. string.format("%q", ServerIntro.Config.WelcomeText))
	table.insert(lines, "ServerIntro.Config.ServerName = " .. string.format("%q", ServerIntro.Config.ServerName))
	table.insert(lines, "ServerIntro.Config.MusicURL = " .. string.format("%q", ServerIntro.Config.MusicURL or ""))
	table.insert(lines, "ServerIntro.Config.MusicVolume = " .. tostring(ServerIntro.Config.MusicVolume))
	table.insert(lines, "")
	table.insert(lines, "-- Camera Points")
	table.insert(lines, "ServerIntro.Config.CameraPoints = {")
	
	for i, point in ipairs(ServerIntro.Config.CameraPoints or {}) do
		table.insert(lines, "\t{")
		table.insert(lines, string.format("\t\tpos = Vector(%.2f, %.2f, %.2f),", point.pos.x, point.pos.y, point.pos.z))
		table.insert(lines, string.format("\t\tang = Angle(%.2f, %.2f, %.2f),", point.ang.p, point.ang.y, point.ang.r))
		table.insert(lines, string.format("\t\tfov = %.0f,", point.fov))
		table.insert(lines, string.format("\t\tduration = %.0f", point.duration))
		if i < #ServerIntro.Config.CameraPoints then
			table.insert(lines, "\t},")
		else
			table.insert(lines, "\t}")
		end
	end
	
	table.insert(lines, "}")
	table.insert(lines, "")
	table.insert(lines, "-- Rewards")
	table.insert(lines, "ServerIntro.Config.SteamGroup = " .. string.format("%q", ServerIntro.Config.SteamGroup or ""))
	table.insert(lines, "ServerIntro.Config.RewardEnabled = " .. tostring(ServerIntro.Config.RewardEnabled))
	table.insert(lines, "ServerIntro.Config.RewardType = \"money\"")
	table.insert(lines, "ServerIntro.Config.RewardAmount = " .. tostring(ServerIntro.Config.RewardAmount))
	table.insert(lines, "ServerIntro.Config.RewardMessage = " .. string.format("%q", ServerIntro.Config.RewardMessage))
	table.insert(lines, "")
	table.insert(lines, "-- Visual Settings")
	table.insert(lines, "ServerIntro.Config.EnableShake = " .. tostring(ServerIntro.Config.EnableShake))
	table.insert(lines, "ServerIntro.Config.ShakeIntensity = " .. tostring(ServerIntro.Config.ShakeIntensity))
	table.insert(lines, "ServerIntro.Config.EnableVignette = " .. tostring(ServerIntro.Config.EnableVignette))
	table.insert(lines, "")
	table.insert(lines, "-- Skip Settings")
	table.insert(lines, "ServerIntro.Config.AllowSkip = " .. tostring(ServerIntro.Config.AllowSkip))
	table.insert(lines, "ServerIntro.Config.ShowSkipHint = " .. tostring(ServerIntro.Config.ShowSkipHint))
	table.insert(lines, "")
	table.insert(lines, "print(\"[Server Intro] Configuration loaded\")")
	
	local content = table.concat(lines, "\n")
	
	-- Create directory
	if not file.Exists("darkrp_intro", "DATA") then
		file.CreateDir("darkrp_intro")
	end
	
	-- Write config (use .txt extension due to GMod security)
	local configPath = "darkrp_intro/config.txt"
	file.Write(configPath, content)
	
	-- Verify
	timer.Simple(0.1, function()
		if not IsValid(pl) then return end
		
		if file.Exists(configPath, "DATA") then
			pas.notify(pl, 'Configuration saved to data/' .. configPath, 0)
			pas.log.Add('Command', pl:Nick() .. ' saved intro configuration')
			print("[Server Intro] Config saved: garrysmod/data/" .. configPath)
		else
			pas.notify(pl, 'Failed to write config file!', 1)
			print("[Server Intro] Failed to write config")
		end
	end)
end)
