-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Visual Preferences - File-Based Persistence
--  Client-side visual settings for intro, effects, etc.
-- ═══════════════════════════════════════════════════════════════════════════

if SERVER then return end

DarkRP = DarkRP or {}
DarkRP.Visual = DarkRP.Visual or {}
DarkRP.Visual.Preferences = DarkRP.Visual.Preferences or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Default Preferences                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Visual.DefaultPreferences = {
	-- Intro settings
	enableIntroShake = true,
	introShakeIntensity = 1.0,
	enableIntroVignette = true,
	introVignetteStrength = 0.5,
	introMusicVolume = 0.5,
	introAutoSkip = false,
	
	-- Camera effects
	enableMotionBlur = false,
	motionBlurAmount = 0.5,
	enableDOF = false, -- Depth of Field
	dofFocalDistance = 512,
	dofAperture = 4,
	
	-- Visual effects
	enableBloom = true,
	bloomScale = 1.0,
	enableColorMod = false,
	colorModContrast = 1.0,
	colorModBrightness = 0.0,
	
	-- Performance
	disableParticles = false,
	reducedGraphics = false,
	maxFPS = 0, -- 0 = unlimited
	
	-- UI Effects
	enableScreenShake = true,
	screenShakeScale = 1.0,
	enableFlashEffects = true,
	enableSoundEffects = true,
	masterVolume = 1.0,
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  File Management                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Visual.GetPreferencesPath()
	return "darkrp/visual_preferences_" .. LocalPlayer():SteamID64() .. ".txt"
end

function DarkRP.Visual.SavePreferences()
	local prefs = DarkRP.Visual.Preferences
	
	-- Convert to Lua table format
	local lines = {}
	table.insert(lines, "-- DarkRP Visual Preferences")
	table.insert(lines, "-- Automatically generated")
	table.insert(lines, "")
	table.insert(lines, "return {")
	
	for key, value in SortedPairs(prefs) do
		local valueStr
		if type(value) == "string" then
			valueStr = string.format("%q", value)
		elseif type(value) == "boolean" then
			valueStr = tostring(value)
		elseif type(value) == "number" then
			valueStr = tostring(value)
		else
			valueStr = "nil"
		end
		table.insert(lines, string.format("	[\"%s\"] = %s,", key, valueStr))
	end
	
	table.insert(lines, "}")
	
	local content = table.concat(lines, "\n")
	local path = DarkRP.Visual.GetPreferencesPath()
	
	file.Write(path, content)
	
	print("[DarkRP:Visual] Preferences saved to: " .. path)
	return true
end

function DarkRP.Visual.LoadPreferences()
	local path = DarkRP.Visual.GetPreferencesPath()
	
	if not file.Exists(path, "DATA") then
		print("[DarkRP:Visual] No preferences file found, using defaults")
		DarkRP.Visual.Preferences = table.Copy(DarkRP.Visual.DefaultPreferences)
		return false
	end
	
	local content = file.Read(path, "DATA")
	if not content or content == "" then
		print("[DarkRP:Visual] Preferences file empty, using defaults")
		DarkRP.Visual.Preferences = table.Copy(DarkRP.Visual.DefaultPreferences)
		return false
	end
	
	local prefsFunc = CompileString(content, "DarkRP Visual Preferences", false)
	if not prefsFunc then
		print("[DarkRP:Visual] Failed to parse preferences file, using defaults")
		DarkRP.Visual.Preferences = table.Copy(DarkRP.Visual.DefaultPreferences)
		return false
	end
	
	local success, prefs = pcall(prefsFunc)
	if not success or not prefs then
		print("[DarkRP:Visual] Error loading preferences: " .. tostring(prefs))
		DarkRP.Visual.Preferences = table.Copy(DarkRP.Visual.DefaultPreferences)
		return false
	end
	
	-- Merge with defaults to ensure all keys exist
	DarkRP.Visual.Preferences = table.Merge(table.Copy(DarkRP.Visual.DefaultPreferences), prefs)
	
	print("[DarkRP:Visual] Preferences loaded successfully")
	
	-- Apply settings
	DarkRP.Visual.ApplyPreferences()
	
	return true
end

function DarkRP.Visual.ResetPreferences()
	DarkRP.Visual.Preferences = table.Copy(DarkRP.Visual.DefaultPreferences)
	DarkRP.Visual.SavePreferences()
	DarkRP.Visual.ApplyPreferences()
	print("[DarkRP:Visual] Preferences reset to defaults")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Preference Getters/Setters                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Visual.GetPreference(key, default)
	local value = DarkRP.Visual.Preferences[key]
	if value == nil then
		return default or DarkRP.Visual.DefaultPreferences[key]
	end
	return value
end

function DarkRP.Visual.SetPreference(key, value, dontSave)
	DarkRP.Visual.Preferences[key] = value
	
	if not dontSave then
		DarkRP.Visual.SavePreferences()
	end
	
	-- Apply specific settings immediately
	DarkRP.Visual.ApplyPreference(key, value)
	
	hook.Call("DarkRP.Visual.PreferenceChanged", nil, key, value)
end

function DarkRP.Visual.SetMultiplePreferences(prefTable, dontSave)
	for key, value in pairs(prefTable) do
		DarkRP.Visual.Preferences[key] = value
		DarkRP.Visual.ApplyPreference(key, value)
		hook.Call("DarkRP.Visual.PreferenceChanged", nil, key, value)
	end
	
	if not dontSave then
		DarkRP.Visual.SavePreferences()
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Apply Preferences                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Visual.ApplyPreference(key, value)
	-- Apply specific settings
	if key == "maxFPS" and value > 0 then
		RunConsoleCommand("fps_max", tostring(value))
	elseif key == "enableMotionBlur" then
		RunConsoleCommand("mat_motion_blur_enabled", value and "1" or "0")
	elseif key == "disableParticles" then
		RunConsoleCommand("r_drawparticles", value and "0" or "1")
	end
end

function DarkRP.Visual.ApplyPreferences()
	local prefs = DarkRP.Visual.Preferences
	
	-- Apply all relevant settings
	for key, value in pairs(prefs) do
		DarkRP.Visual.ApplyPreference(key, value)
	end
	
	print("[DarkRP:Visual] All preferences applied")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Utility Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Check if intro shake is enabled
function DarkRP.Visual.IsIntroShakeEnabled()
	return DarkRP.Visual.GetPreference("enableIntroShake", true)
end

-- Get intro shake intensity
function DarkRP.Visual.GetIntroShakeIntensity()
	return DarkRP.Visual.GetPreference("introShakeIntensity", 1.0)
end

-- Check if intro vignette is enabled
function DarkRP.Visual.IsIntroVignetteEnabled()
	return DarkRP.Visual.GetPreference("enableIntroVignette", true)
end

-- Get intro vignette strength
function DarkRP.Visual.GetIntroVignetteStrength()
	return DarkRP.Visual.GetPreference("introVignetteStrength", 0.5)
end

-- Get intro music volume
function DarkRP.Visual.GetIntroMusicVolume()
	return DarkRP.Visual.GetPreference("introMusicVolume", 0.5)
end

-- Check if screen shake is enabled
function DarkRP.Visual.IsScreenShakeEnabled()
	return DarkRP.Visual.GetPreference("enableScreenShake", true)
end

-- Get screen shake scale
function DarkRP.Visual.GetScreenShakeScale()
	return DarkRP.Visual.GetPreference("screenShakeScale", 1.0)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Console Commands                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add("darkrp_visual_reset", function(ply, cmd, args)
	DarkRP.Visual.ResetPreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "Visual preferences reset to defaults")
end)

concommand.Add("darkrp_visual_reload", function(ply, cmd, args)
	DarkRP.Visual.LoadPreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "Visual preferences reloaded")
end)

concommand.Add("darkrp_visual_save", function(ply, cmd, args)
	DarkRP.Visual.SavePreferences()
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "Visual preferences saved")
end)

concommand.Add("darkrp_visual_set", function(ply, cmd, args)
	if #args < 2 then
		print("Usage: darkrp_visual_set <key> <value>")
		return
	end
	
	local key = args[1]
	local value = args[2]
	
	-- Convert value to appropriate type
	if value == "true" then
		value = true
	elseif value == "false" then
		value = false
	elseif tonumber(value) then
		value = tonumber(value)
	end
	
	DarkRP.Visual.SetPreference(key, value)
	chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), 
		"Set " .. key .. " to " .. tostring(value))
end)

concommand.Add("darkrp_visual_get", function(ply, cmd, args)
	if #args < 1 then
		print("Usage: darkrp_visual_get <key>")
		return
	end
	
	local key = args[1]
	local value = DarkRP.Visual.GetPreference(key)
	
	print(key .. " = " .. tostring(value))
end)

concommand.Add("darkrp_visual_list", function(ply, cmd, args)
	print("\n=== DarkRP Visual Preferences ===")
	for key, value in SortedPairs(DarkRP.Visual.Preferences) do
		print(key .. " = " .. tostring(value))
	end
	print("=================================\n")
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Load preferences when client initializes
hook.Add("InitPostEntity", "DarkRP.Visual.LoadPreferences", function()
	timer.Simple(0.5, function()
		DarkRP.Visual.LoadPreferences()
	end)
end)

-- Save preferences when client disconnects
hook.Add("ShutDown", "DarkRP.Visual.SaveOnShutdown", function()
	DarkRP.Visual.SavePreferences()
end)

print("[DarkRP:Visual] Preferences system (file-based) loaded")
