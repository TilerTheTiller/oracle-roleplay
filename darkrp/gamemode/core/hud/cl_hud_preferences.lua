-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP HUD Preferences - File-Based Persistence
--  Client-side HUD customization settings
-- ═══════════════════════════════════════════════════════════════════════════

if SERVER then return end

DarkRP = DarkRP or {}
DarkRP.HUD = DarkRP.HUD or {}
DarkRP.HUD.Preferences = DarkRP.HUD.Preferences or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Default Preferences                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.HUD.DefaultPreferences = {
	-- Position settings
	healthBarX = 50,
	healthBarY = ScrH() - 100,
	armorBarX = 50,
	armorBarY = ScrH() - 70,
	moneyDisplayX = ScrW() - 200,
	moneyDisplayY = 50,
	jobDisplayX = 50,
	jobDisplayY = 50,
	
	-- Visibility settings
	showHealth = true,
	showArmor = true,
	showMoney = true,
	showJob = true,
	showAmmo = true,
	showCrosshair = true,
	
	-- Style settings
	hudScale = 1.0,
	hudOpacity = 255,
	useMinimalMode = false,
	colorTheme = "default", -- "default", "dark", "blue", "green"
	
	-- Misc
	showFPS = false,
	showPing = false,
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  File Management                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.HUD.GetPreferencesPath()
	return "darkrp/hud_preferences_" .. LocalPlayer():SteamID64() .. ".txt"
end

function DarkRP.HUD.SavePreferences()
	local prefs = DarkRP.HUD.Preferences
	
	-- Convert to JSON-like format
	local lines = {}
	table.insert(lines, "-- DarkRP HUD Preferences")
	table.insert(lines, "-- Automatically generated - do not edit manually unless you know what you're doing")
	table.insert(lines, "")
	table.insert(lines, "return {")
	
	for key, value in pairs(prefs) do
		local valueStr
		if type(value) == "string" then
			valueStr = string.format("%q", value)
		elseif type(value) == "boolean" then
			valueStr = tostring(value)
		else
			valueStr = tostring(value)
		end
		table.insert(lines, string.format("	[\"%s\"] = %s,", key, valueStr))
	end
	
	table.insert(lines, "}")
	
	local content = table.concat(lines, "\n")
	local path = DarkRP.HUD.GetPreferencesPath()
	
	file.Write(path, content)
	
	print("[DarkRP:HUD] Preferences saved to: " .. path)
	return true
end

function DarkRP.HUD.LoadPreferences()
	local path = DarkRP.HUD.GetPreferencesPath()
	
	if not file.Exists(path, "DATA") then
		print("[DarkRP:HUD] No preferences file found, using defaults")
		DarkRP.HUD.Preferences = table.Copy(DarkRP.HUD.DefaultPreferences)
		return false
	end
	
	local content = file.Read(path, "DATA")
	if not content or content == "" then
		print("[DarkRP:HUD] Preferences file empty, using defaults")
		DarkRP.HUD.Preferences = table.Copy(DarkRP.HUD.DefaultPreferences)
		return false
	end
	
	local prefsFunc = CompileString(content, "DarkRP HUD Preferences", false)
	if not prefsFunc then
		print("[DarkRP:HUD] Failed to parse preferences file, using defaults")
		DarkRP.HUD.Preferences = table.Copy(DarkRP.HUD.DefaultPreferences)
		return false
	end
	
	local success, prefs = pcall(prefsFunc)
	if not success or not prefs then
		print("[DarkRP:HUD] Error loading preferences: " .. tostring(prefs))
		DarkRP.HUD.Preferences = table.Copy(DarkRP.HUD.DefaultPreferences)
		return false
	end
	
	-- Merge with defaults to ensure all keys exist
	DarkRP.HUD.Preferences = table.Merge(table.Copy(DarkRP.HUD.DefaultPreferences), prefs)
	
	print("[DarkRP:HUD] Preferences loaded successfully")
	return true
end

function DarkRP.HUD.ResetPreferences()
	DarkRP.HUD.Preferences = table.Copy(DarkRP.HUD.DefaultPreferences)
	DarkRP.HUD.SavePreferences()
	print("[DarkRP:HUD] Preferences reset to defaults")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Preference Getters/Setters                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.HUD.GetPreference(key, default)
	local value = DarkRP.HUD.Preferences[key]
	if value == nil then
		return default or DarkRP.HUD.DefaultPreferences[key]
	end
	return value
end

function DarkRP.HUD.SetPreference(key, value, dontSave)
	DarkRP.HUD.Preferences[key] = value
	
	if not dontSave then
		DarkRP.HUD.SavePreferences()
	end
	
	hook.Call("DarkRP.HUD.PreferenceChanged", nil, key, value)
end

function DarkRP.HUD.SetMultiplePreferences(prefTable, dontSave)
	for key, value in pairs(prefTable) do
		DarkRP.HUD.Preferences[key] = value
		hook.Call("DarkRP.HUD.PreferenceChanged", nil, key, value)
	end
	
	if not dontSave then
		DarkRP.HUD.SavePreferences()
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Console Commands                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add("darkrp_hud_reset", function(ply, cmd, args)
	DarkRP.HUD.ResetPreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "HUD preferences reset to defaults")
end)

concommand.Add("darkrp_hud_reload", function(ply, cmd, args)
	DarkRP.HUD.LoadPreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "HUD preferences reloaded")
end)

concommand.Add("darkrp_hud_save", function(ply, cmd, args)
	DarkRP.HUD.SavePreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "HUD preferences saved")
end)

-- Example: darkrp_hud_set hudScale 1.5
concommand.Add("darkrp_hud_set", function(ply, cmd, args)
	if #args < 2 then
		print("Usage: darkrp_hud_set <key> <value>")
		return
	end
	
	local key = args[1]
	local value = args[2]
	
	-- Try to convert value to appropriate type
	if value == "true" then
		value = true
	elseif value == "false" then
		value = false
	elseif tonumber(value) then
		value = tonumber(value)
	end
	
	DarkRP.HUD.SetPreference(key, value)
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), 
		"Set " .. key .. " to " .. tostring(value))
end)

concommand.Add("darkrp_hud_get", function(ply, cmd, args)
	if #args < 1 then
		print("Usage: darkrp_hud_get <key>")
		return
	end
	
	local key = args[1]
	local value = DarkRP.HUD.GetPreference(key)
	
	print(key .. " = " .. tostring(value))
end)

concommand.Add("darkrp_hud_list", function(ply, cmd, args)
	print("\n=== DarkRP HUD Preferences ===")
	for key, value in SortedPairs(DarkRP.HUD.Preferences) do
		print(key .. " = " .. tostring(value))
	end
	print("==============================\n")
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Load preferences when client initializes
hook.Add("InitPostEntity", "DarkRP.HUD.LoadPreferences", function()
	timer.Simple(0.5, function()
		DarkRP.HUD.LoadPreferences()
	end)
end)

-- Save preferences when client disconnects
hook.Add("ShutDown", "DarkRP.HUD.SaveOnShutdown", function()
	DarkRP.HUD.SavePreferences()
end)

print("[DarkRP:HUD] Preferences system (file-based) loaded")
