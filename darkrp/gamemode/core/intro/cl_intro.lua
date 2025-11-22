-- ═══════════════════════════════════════════════════════════════════════════
--  Server Intro System - Client
--  Cinematic camera and UI rendering
-- ═══════════════════════════════════════════════════════════════════════════

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

ServerIntro.Active = false
ServerIntro.StartTime = 0
ServerIntro.CurrentCamera = 1
ServerIntro.CameraStartTime = 0
ServerIntro.MusicChannel = nil

-- Load PANTHEON UI colors
if not ui or not ui.col then
	include("autorun/ui_init.lua")
end

-- Precache vignette material
local matVignette = Material("ui/vignette.png", "smooth")

-- Easing functions for smooth animations
math.ease = math.ease or {}
math.ease.InOutQuad = function(t)
	if t < 0.5 then
		return 2 * t * t
	else
		return -1 + (4 - 2 * t) * t
	end
end
math.ease.OutCubic = function(t)
	return 1 - math.pow(1 - t, 3)
end
math.ease.InOutCubic = function(t)
	if t < 0.5 then
		return 4 * t * t * t
	else
		return 1 - math.pow(-2 * t + 2, 3) / 2
	end
end

-- Use PANTHEON fonts
surface.CreateFont("ServerIntro.Title", {
	font = "Funnel Sans",
	size = 64,
	weight = 700,
	extended = true,
	antialias = true,
	shadow = false
})

surface.CreateFont("ServerIntro.Subtitle", {
	font = "Funnel Sans",
	size = 28,
	weight = 500,
	extended = true,
	antialias = true,
	shadow = false
})

surface.CreateFont("ServerIntro.Small", {
	font = "Funnel Sans",
	size = 18,
	weight = 400,
	extended = true,
	antialias = true,
	shadow = false
})

surface.CreateFont("ServerIntro.Icon", {
	font = "Funnel Sans",
	size = 48,
	weight = 700,
	extended = true,
	antialias = true,
	shadow = false
})

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Music URL Processing                                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Convert YouTube URL to streamable audio URL
function ServerIntro.ProcessMusicURL(url)
	if not url or url == "" then
		return nil
	end
	
	-- Check if it's a YouTube URL
	local isYouTube = string.find(url, "youtube%.com") or string.find(url, "youtu%.be")
	
	if isYouTube then
		-- Extract video ID
		local videoID = nil
		
		-- Try youtu.be format
		videoID = string.match(url, "youtu%.be/([%w-_]+)")
		
		-- Try youtube.com/watch?v= format
		if not videoID then
			videoID = string.match(url, "[?&]v=([%w-_]+)")
		end
		
		-- Try youtube.com/embed/ format
		if not videoID then
			videoID = string.match(url, "youtube%.com/embed/([%w-_]+)")
		end
		
		if videoID then
			-- Use a YouTube-to-audio proxy service
			-- Note: You may need to host your own proxy or use a reliable service
			local proxyURL = "https://api.soundcloud.com/tracks/" .. videoID .. "/stream"
			print("[Server Intro] Converting YouTube URL to audio stream: " .. videoID)
			
			-- Alternative: Return direct YouTube video ID for server-side processing
			return "youtube:" .. videoID
		else
			print("[Server Intro] Failed to extract YouTube video ID from: " .. url)
			return nil
		end
	end
	
	-- Return URL as-is for direct audio links
	return url
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Camera Functions                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.GetCurrentCameraPoint()
	local elapsed = CurTime() - ServerIntro.StartTime
	local cameraTime = 0
	
	for i, cam in ipairs(ServerIntro.Config.CameraPoints) do
		cameraTime = cameraTime + cam.duration
		if elapsed <= cameraTime then
			return i, cam, elapsed - (cameraTime - cam.duration)
		end
	end
	
	return #ServerIntro.Config.CameraPoints, ServerIntro.Config.CameraPoints[#ServerIntro.Config.CameraPoints], 0
end

function ServerIntro.LerpCamera(cam1, cam2, frac)
	local pos = LerpVector(frac, cam1.pos, cam2.pos)
	local ang = LerpAngle(frac, cam1.ang, cam2.ang)
	local fov = Lerp(frac, cam1.fov, cam2.fov)
	
	return pos, ang, fov
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Intro Control                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Start(config)
	print("[ServerIntro] Start function called with config:")
	print("  ServerName:", config.ServerName)
	print("  WelcomeText:", config.WelcomeText)
	print("  Duration:", config.Duration)
	
	ServerIntro.Config = config
	ServerIntro.Active = true
	ServerIntro.StartTime = CurTime()
	ServerIntro.CurrentCamera = 1
	ServerIntro.CameraStartTime = CurTime()
	
	-- Play music if URL is provided
	if config.MusicURL and config.MusicURL ~= "" then
		local processedURL = ServerIntro.ProcessMusicURL(config.MusicURL)
		
		if processedURL then
			-- Check if it's a YouTube video ID
			if string.StartWith(processedURL, "youtube:") then
				local videoID = string.sub(processedURL, 9)
				print("[Server Intro] YouTube playback not directly supported in GMod")
				print("[Server Intro] Please use a direct MP3/OGG link or convert YouTube URL")
				print("[Server Intro] Video ID: " .. videoID)
				
				-- Optional: Show notification to user
				chat.AddText(Color(255, 200, 0), "[Server Intro] ", 
					Color(255, 255, 255), "YouTube links require conversion. Use a direct audio link instead.")
			else
				-- Play direct audio URL
				sound.PlayURL(processedURL, "noplay", function(channel, errCode, errStr)
					if IsValid(channel) then
						ServerIntro.MusicChannel = channel
						channel:SetVolume(config.MusicVolume or 0.5)
						channel:Play()
					else
						print("[Server Intro] Failed to load music: " .. tostring(errStr))
					end
				end)
			end
		end
	end
	
	-- Hide HUD
	LocalPlayer():SetNoDraw(true)
	
	print("[Server Intro] Started client intro")
end

function ServerIntro.Stop()
	ServerIntro.Active = false
	
	-- Stop music
	if IsValid(ServerIntro.MusicChannel) then
		ServerIntro.MusicChannel:Stop()
		ServerIntro.MusicChannel = nil
	end
	
	-- Show player
	if IsValid(LocalPlayer()) then
		LocalPlayer():SetNoDraw(false)
	end
	
	-- Send skip notification to server
	net.Start("ServerIntro.Skip")
	net.SendToServer()
	
	-- Open character menu after intro finishes
	timer.Simple(0.5, function()
		if DarkRP and DarkRP.Characters and DarkRP.Characters.UI then
			-- Character menu will be opened by the server when it loads characters
			print("[Server Intro] Intro finished - waiting for character system")
		end
	end)
	
	print("[Server Intro] Stopped intro")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Input Blocking                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("PlayerBindPress", "ServerIntro.BlockInput", function(ply, bind, pressed)
	if not ServerIntro.Active then return end
	
	-- Allow skip bind
	if ServerIntro.Config.AllowSkip and (bind == "+jump" or bind == "+attack" or bind == "+use") then
		return false -- Allow skip key
	end
	
	return true -- Block all other input
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Rendering                                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("CalcView", "ServerIntro.CalcView", function(ply, pos, angles, fov)
	if not ServerIntro.Active then return end
	
	local elapsed = CurTime() - ServerIntro.StartTime
	if elapsed >= ServerIntro.Config.Duration then
		ServerIntro.Stop()
		return
	end
	
	local currentIdx, currentCam, camElapsed = ServerIntro.GetCurrentCameraPoint()
	
	-- Get next camera for smooth transition
	local nextIdx = currentIdx + 1
	if nextIdx > #ServerIntro.Config.CameraPoints then
		nextIdx = currentIdx
	end
	
	local nextCam = ServerIntro.Config.CameraPoints[nextIdx]
	local camFrac = camElapsed / currentCam.duration
	
	local camPos, camAng, camFov = ServerIntro.LerpCamera(currentCam, nextCam, camFrac)
	
	-- Apply shake effect
	if ServerIntro.Config.EnableShake then
		local shake = ServerIntro.Config.ShakeIntensity or 2
		camAng.p = camAng.p + math.sin(CurTime() * 2) * shake
		camAng.r = camAng.r + math.cos(CurTime() * 1.5) * shake
	end
	
	return {
		origin = camPos,
		angles = camAng,
		fov = camFov,
		drawviewer = false
	}
end)

hook.Add("HUDPaint", "ServerIntro.HUDPaint", function()
	if not ServerIntro.Active then return end
	
	-- Debug
	if not ServerIntro._DebugPrinted then
		print("[ServerIntro] HUDPaint active!")
		print("[ServerIntro] ServerName:", ServerIntro.Config.ServerName)
		print("[ServerIntro] WelcomeText:", ServerIntro.Config.WelcomeText)
		ServerIntro._DebugPrinted = true
	end
	
	local scrW, scrH = ScrW(), ScrH()
	local elapsed = CurTime() - ServerIntro.StartTime
	local alpha = 255
	local fadeToBlackAlpha = 0
	
	-- Fade in/out with smooth easing
	if elapsed < 1.5 then
		alpha = math.ease.InOutQuad(elapsed / 1.5) * 255
	elseif elapsed > ServerIntro.Config.Duration - 1.5 then
		-- Fade UI out
		alpha = (1 - math.ease.InOutQuad((elapsed - (ServerIntro.Config.Duration - 1.5)) / 1.5)) * 255
		-- Fade to black overlay at the very end
		local fadeStart = ServerIntro.Config.Duration - 1.0
		if elapsed > fadeStart then
			fadeToBlackAlpha = math.ease.InOutQuad((elapsed - fadeStart) / 1.0) * 255
		end
	end
	
	-- Full screen dark overlay with blur
	surface.SetDrawColor(0, 0, 0, alpha * 0.4)
	surface.DrawRect(0, 0, scrW, scrH)
	
	-- Vignette material overlay
	if ServerIntro.Config.EnableVignette and matVignette then
		surface.SetDrawColor(0, 0, 0, alpha * 0.8)
		surface.SetMaterial(matVignette)
		surface.DrawTexturedRect(0, 0, scrW, scrH)
	end
	
	-- Welcome text with slide-in animation
	local textAlpha = alpha
	local slideOffset = 0
	if elapsed < 2 then
		local progress = math.ease.OutCubic(elapsed / 2)
		textAlpha = alpha * progress
		slideOffset = (1 - progress) * 50
	end
	
	-- Minimal info box positioned at bottom left
	local cardWidth = 380
	local cardHeight = 140
	local cardX = 40
	local cardY = scrH - cardHeight - 40 + slideOffset
	
	-- Subtle card background with blur
	draw.RoundedBox(8, cardX, cardY, cardWidth, cardHeight, ColorAlpha(ui.col.BackgroundDark, textAlpha * 0.85))
	
	-- Purple accent left border
	draw.RoundedBoxEx(8, cardX, cardY, 4, cardHeight, ColorAlpha(ui.col.PANTHEON, textAlpha), true, false, false, true)
	
	-- Subtle card border
	surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, textAlpha * 0.4)
	surface.DrawOutlinedRect(cardX, cardY, cardWidth, cardHeight, 1)
	
	-- Small icon
	local iconY = cardY + 20
	surface.SetFont("ServerIntro.Subtitle")
	local iconText = "★"
	local iconW, iconH = surface.GetTextSize(iconText)
	surface.SetTextColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, textAlpha)
	surface.SetTextPos(cardX + 20, iconY)
	surface.DrawText(iconText)
	
	-- Server name (smaller, inline with icon)
	surface.SetFont("ServerIntro.Subtitle")
	local serverName = ServerIntro.Config.ServerName or "Server"
	local titleW, titleH = surface.GetTextSize(serverName)
	
	surface.SetTextColor(255, 255, 255, textAlpha)
	surface.SetTextPos(cardX + 20 + iconW + 10, iconY)
	surface.DrawText(serverName)
	
	-- Thin divider line
	local dividerY = iconY + titleH + 10
	surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, textAlpha * 0.3)
	surface.DrawRect(cardX + 20, dividerY, cardWidth - 40, 1)
	
	-- Welcome message (smaller)
	local welcomeY = dividerY + 15
	surface.SetFont("ServerIntro.Small")
	local welcomeText = ServerIntro.Config.WelcomeText or "Welcome!"
	local welcomeW, welcomeH = surface.GetTextSize(welcomeText)
	surface.SetTextColor(ui.col.TEXT_DIM.r, ui.col.TEXT_DIM.g, ui.col.TEXT_DIM.b, textAlpha * 0.9)
	surface.SetTextPos(cardX + 20, welcomeY)
	surface.DrawText(welcomeText)
	
	-- Minimal skip hint at bottom right
	if ServerIntro.Config.AllowSkip and ServerIntro.Config.ShowSkipHint then
		local skipText = "SPACE TO SKIP"
		surface.SetFont("ServerIntro.Small")
		local skipW, skipH = surface.GetTextSize(skipText)
		
		local skipBtnW = skipW + 30
		local skipBtnH = skipH + 16
		local skipX = scrW - skipBtnW - 40
		local skipY = scrH - 40 - skipBtnH
		
		-- Subtle pulsing
		local pulse = math.abs(math.sin(CurTime() * 2)) * 0.15 + 0.85
		
		-- Minimal button background
		draw.RoundedBox(6, skipX, skipY, skipBtnW, skipBtnH, ColorAlpha(ui.col.BackgroundDark, textAlpha * 0.7))
		
		-- Purple border with pulse
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, textAlpha * pulse * 0.8)
		surface.DrawOutlinedRect(skipX, skipY, skipBtnW, skipBtnH, 1)
		
		-- Button text
		surface.SetTextColor(ui.col.TEXT_DIM.r, ui.col.TEXT_DIM.g, ui.col.TEXT_DIM.b, textAlpha * pulse)
		surface.SetTextPos(skipX + (skipBtnW - skipW) / 2, skipY + (skipBtnH - skipH) / 2)
		surface.DrawText(skipText)
	end
	
	-- Minimal progress bar at bottom of info card
	local barWidth = cardWidth - 40
	local barHeight = 3
	local barX = cardX + 20
	local barY = cardY + cardHeight - 25
	
	-- Progress background
	draw.RoundedBox(2, barX, barY, barWidth, barHeight, ColorAlpha(ui.col.BackgroundLight, textAlpha * 0.6))
	
	-- Progress fill
	local progress = math.Clamp(elapsed / ServerIntro.Config.Duration, 0, 1)
	local fillWidth = barWidth * progress
	
	if fillWidth > 0 then
		draw.RoundedBox(2, barX, barY, fillWidth, barHeight, ColorAlpha(ui.col.PANTHEON, textAlpha * 0.9))
	end
	
	-- Small progress text
	local progressText = math.floor(progress * 100) .. "%"
	surface.SetFont("ServerIntro.Small")
	local progW, progH = surface.GetTextSize(progressText)
	surface.SetTextColor(ui.col.TEXT_DIM.r, ui.col.TEXT_DIM.g, ui.col.TEXT_DIM.b, textAlpha * 0.6)
	surface.SetTextPos(barX + barWidth - progW, barY - progH - 5)
	surface.DrawText(progressText)
	
	-- Fade to black at the very end
	if fadeToBlackAlpha > 0 then
		surface.SetDrawColor(0, 0, 0, fadeToBlackAlpha)
		surface.DrawRect(0, 0, scrW, scrH)
	end
end)

hook.Add("HUDShouldDraw", "ServerIntro.HideHUD", function(name)
	if ServerIntro.Active then
		-- Hide all default HUD elements during intro
		if name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo" or name == "CHudSecondaryAmmo" or
		   name == "CHudDamageIndicator" or name == "CHudDeathNotice" or name == "CHudChat" or 
		   name == "CHudCrosshair" or name == "DarkRP_HUD" then
			return false
		end
	end
end)

hook.Add("PlayerBindPress", "ServerIntro.SkipBind", function(ply, bind, pressed)
	if not ServerIntro.Active then return end
	if not ServerIntro.Config.AllowSkip then return end
	
	if pressed and bind == "+jump" then
		ServerIntro.Stop()
		return true
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Networking                                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("ServerIntro.Start", function()
	local config = net.ReadTable()
	print("[ServerIntro] Received intro start with config:")
	PrintTable(config)
	ServerIntro.Start(config)
end)

net.Receive("ServerIntro.SyncConfig", function()
	ServerIntro.Config = net.ReadTable()
	print("[Server Intro] Configuration synced")
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Admin Menu                                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.OpenAdminMenu()
	local frame = vgui.Create("DFrame")
	frame:SetSize(800, 600)
	frame:Center()
	frame:SetTitle("Server Intro Configuration")
	frame:MakePopup()
	
	local scroll = vgui.Create("DScrollPanel", frame)
	scroll:Dock(FILL)
	scroll:DockMargin(10, 10, 10, 60)
	
	local y = 10
	
	-- Helper function to create labeled controls
	local function AddControl(label, control)
		local lbl = vgui.Create("DLabel", scroll)
		lbl:SetPos(10, y)
		lbl:SetText(label)
		lbl:SizeToContents()
		
		control:SetParent(scroll)
		control:SetPos(200, y)
		control:SetSize(400, 25)
		
		y = y + 35
		return control
	end
	
	-- Enabled
	local enabledCheck = vgui.Create("DCheckBoxLabel")
	enabledCheck:SetText("Enable Intro")
	enabledCheck:SetValue(ServerIntro.Config.Enabled)
	AddControl("Enabled:", enabledCheck)
	
	-- Duration
	local durationSlider = vgui.Create("DNumSlider")
	durationSlider:SetMin(5)
	durationSlider:SetMax(60)
	durationSlider:SetDecimals(0)
	durationSlider:SetValue(ServerIntro.Config.Duration)
	AddControl("Duration (seconds):", durationSlider)
	
	-- Server name
	local serverName = vgui.Create("DTextEntry")
	serverName:SetValue(ServerIntro.Config.ServerName)
	AddControl("Server Name:", serverName)
	
	-- Welcome text
	local welcomeText = vgui.Create("DTextEntry")
	welcomeText:SetValue(ServerIntro.Config.WelcomeText)
	AddControl("Welcome Text:", welcomeText)
	
	-- Music URL
	local musicURL = vgui.Create("DTextEntry")
	musicURL:SetValue(ServerIntro.Config.MusicURL)
	AddControl("Music URL:", musicURL)
	
	-- Reward amount
	local rewardAmount = vgui.Create("DNumSlider")
	rewardAmount:SetMin(0)
	rewardAmount:SetMax(100000)
	rewardAmount:SetDecimals(0)
	rewardAmount:SetValue(ServerIntro.Config.RewardAmount)
	AddControl("Reward Amount:", rewardAmount)
	
	-- Save button
	local saveBtn = vgui.Create("DButton", frame)
	saveBtn:SetText("Save Configuration")
	saveBtn:Dock(BOTTOM)
	saveBtn:SetTall(40)
	saveBtn:DockMargin(10, 0, 10, 10)
	saveBtn.DoClick = function()
		-- Collect all values
		local newConfig = {
			Enabled = enabledCheck:GetChecked(),
			Duration = durationSlider:GetValue(),
			ServerName = serverName:GetValue(),
			WelcomeText = welcomeText:GetValue(),
			MusicURL = musicURL:GetValue(),
			RewardAmount = rewardAmount:GetValue()
		}
		
		-- Send to server
		net.Start("ServerIntro.UpdateConfig")
			net.WriteTable(newConfig)
		net.SendToServer()
		
		chat.AddText(Color(0, 255, 0), "[Server Intro] Configuration saved!")
		frame:Close()
	end
end

concommand.Add("server_intro_menu", function()
	if LocalPlayer():HasFlag('a') then
		ServerIntro.OpenAdminMenu()
	else
		chat.AddText(Color(255, 0, 0), "You don't have permission to use this!")
	end
end)

print("[Server Intro] Client module loaded")
