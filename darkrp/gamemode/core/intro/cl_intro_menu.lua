-- ═══════════════════════════════════════════════════════════════════════════
--  Server Intro System - Configuration Menu (PANTHEON UI)
--  Modern in-game GUI for complete intro customization
-- ═══════════════════════════════════════════════════════════════════════════

ServerIntro = ServerIntro or {}
ServerIntro.Menu = ServerIntro.Menu or {}

-- Load PANTHEON UI
if not ui or not ui.col then
	include("autorun/ui_init.lua")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Main Configuration Menu                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.Open()
	if IsValid(ServerIntro.Menu.Frame) then
		ServerIntro.Menu.Frame:Remove()
	end
	
	-- Ensure config exists with defaults
	ServerIntro.Config = ServerIntro.Config or {}
	print("[ServerIntro Menu] Opening menu with config:")
	PrintTable(ServerIntro.Config)
	
	local scrW, scrH = ScrW(), ScrH()
	local frameW, frameH = math.min(1100, scrW * 0.85), math.min(750, scrH * 0.9)
	
	-- Use PANTHEON frame component
	local frame = ui.components.CreateFrame("Server Intro Configuration", frameW, frameH, "settings")
	ServerIntro.Menu.Frame = frame
	
	-- Content container with padding
	local container = vgui.Create("DPanel", frame)
	container:Dock(FILL)
	container:DockMargin(0, 40, 0, 0)
	container.Paint = function() end
	
	-- Tab container
	local tabs = vgui.Create("DPropertySheet", container)
	tabs:Dock(FILL)
	tabs:DockMargin(15, 10, 15, 15)
	tabs:SetSkin("PANTHEON")
	
	-- Create tabs with icons  
	ServerIntro.Menu.CreateGeneralTab(tabs)
	ServerIntro.Menu.CreateCameraTab(tabs)
	ServerIntro.Menu.CreateRewardsTab(tabs)
	ServerIntro.Menu.CreateVisualTab(tabs)
	ServerIntro.Menu.CreateTestTab(tabs)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  General Settings Tab                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.CreateGeneralTab(tabs)
	local panel = vgui.Create("DPanel")
	panel:Dock(FILL)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(ui.col.BackgroundLight, 200))
	end
	
	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:DockMargin(15, 15, 15, 15)
	
	-- Ensure config exists
	ServerIntro.Config = ServerIntro.Config or {}
	
	-- Section header
	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:SetTall(40)
	header:DockMargin(0, 0, 0, 15)
	header.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(ui.col.PANTHEON, 30))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("Basic Configuration", "PANTHEON.18", 15, h/2, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	-- Helper to create labeled text entry
	local function CreateTextEntry(label, value, onEnter)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(70)
		container:DockMargin(0, 0, 0, 10)
		container.Paint = function() end
		
		local lbl = vgui.Create("DLabel", container)
		lbl:Dock(TOP)
		lbl:SetText(label)
		lbl:SetFont("PANTHEON.16")
		lbl:SetTextColor(ui.col.White)
		lbl:SetTall(25)
		
		local entry = vgui.Create("DTextEntry", container)
		entry:Dock(TOP)
		entry:SetTall(35)
		entry:SetText(value or "")
		entry:SetFont("PANTHEON.14")
		entry:SetSkin("PANTHEON")
		entry.OnEnter = function(self)
			onEnter(self:GetValue())
			notification.AddLegacy(label .. " updated!", NOTIFY_GENERIC, 2)
		end
		
		return entry
	end
	
	-- Helper to create slider
	local function CreateSlider(label, min, max, decimals, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(60)
		container:DockMargin(0, 0, 0, 10)
		container.Paint = function() end
		
		local lbl = vgui.Create("DLabel", container)
		lbl:Dock(TOP)
		lbl:SetText(label)
		lbl:SetFont("PANTHEON.16")
		lbl:SetTextColor(ui.col.White)
		lbl:SetTall(25)
		
		local slider = vgui.Create("DNumSlider", container)
		slider:Dock(TOP)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetDecimals(decimals)
		slider:SetValue(value)
		slider:SetSkin("PANTHEON")
		slider.OnValueChanged = onChange
		
		return slider
	end
	
	-- Helper to create checkbox
	local function CreateCheckbox(label, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(35)
		container:DockMargin(0, 0, 0, 5)
		container.Paint = function() end
		
		local check = vgui.Create("DCheckBoxLabel", container)
		check:Dock(LEFT)
		check:SetText(label)
		check:SetFont("PANTHEON.16")
		check:SetTextColor(ui.col.White)
		check:SetValue(value and 1 or 0)
		check:SizeToContents()
		check:SetSkin("PANTHEON")
		check.OnChange = onChange
		
		return check
	end
	
	-- Enabled checkbox
	CreateCheckbox("Intro Enabled", ServerIntro.Config.Enabled or false, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("Enabled")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	-- Server Name
	CreateTextEntry("Server Name", ServerIntro.Config.ServerName or "My Server", function(value)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("ServerName")
		net.WriteUInt(2, 8)
		net.WriteString(value)
		net.SendToServer()
	end)
	
	-- Welcome Text
	CreateTextEntry("Welcome Text", ServerIntro.Config.WelcomeText or "Welcome to our server!", function(value)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("WelcomeText")
		net.WriteUInt(2, 8)
		net.WriteString(value)
		net.SendToServer()
	end)
	
	-- Duration
	CreateSlider("Duration (seconds)", 5, 60, 0, ServerIntro.Config.Duration or 15, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("Duration")
		net.WriteUInt(3, 8)
		net.WriteFloat(val)
		net.SendToServer()
	end)
	
	-- Music URL
	CreateTextEntry("Music URL", ServerIntro.Config.MusicURL or "", function(value)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("MusicURL")
		net.WriteUInt(2, 8)
		net.WriteString(value)
		net.SendToServer()
	end)
	
	-- Music Volume
	CreateSlider("Music Volume", 0, 1, 2, ServerIntro.Config.MusicVolume or 0.5, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("MusicVolume")
		net.WriteUInt(3, 8)
		net.WriteFloat(val)
		net.SendToServer()
	end)
	
	-- Allow Skip
	CreateCheckbox("Allow Skip", ServerIntro.Config.AllowSkip or true, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("AllowSkip")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	-- Show Skip Hint
	CreateCheckbox("Show Skip Hint", ServerIntro.Config.ShowSkipHint, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("ShowSkipHint")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	tabs:AddSheet("General", panel, "icon16/cog.png")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Camera Settings Tab                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.CreateCameraTab(tabs)
	local panel = vgui.Create("DPanel")
	panel:Dock(FILL)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(ui.col.BackgroundLight, 200))
	end
	
	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:DockMargin(15, 15, 15, 15)
	
	-- Camera list
	local list = vgui.Create("DListView", scroll)
	list:Dock(TOP)
	list:SetTall(300)
	list:AddColumn("Point"):SetFixedWidth(50)
	list:AddColumn("Position"):SetFixedWidth(200)
	list:AddColumn("Angles"):SetFixedWidth(180)
	list:AddColumn("FOV"):SetFixedWidth(60)
	list:AddColumn("Duration"):SetFixedWidth(80)
	list:SetSkin("PANTHEON")
	
	local function RefreshCameraList()
		list:Clear()
		for i, point in ipairs(ServerIntro.Config.CameraPoints or {}) do
			local pos = string.format("%.0f, %.0f, %.0f", point.pos.x, point.pos.y, point.pos.z)
			local ang = string.format("%.0f, %.0f, %.0f", point.ang.p, point.ang.y, point.ang.r)
			list:AddLine(i, pos, ang, point.fov, point.duration .. "s")
		end
	end
	RefreshCameraList()
	
	-- Camera buttons
	local btnPanel = vgui.Create("DPanel", scroll)
	btnPanel:Dock(TOP)
	btnPanel:SetTall(50)
	btnPanel:DockMargin(0, 10, 0, 10)
	btnPanel.Paint = function() end
	
	local addBtn = vgui.Create("DButton", btnPanel)
	addBtn:SetText("Add Current Position")
	addBtn:SetFont("PANTHEON.16")
	addBtn:Dock(LEFT)
	addBtn:SetWide(200)
	addBtn:DockMargin(0, 0, 10, 0)
	addBtn:SetSkin("PANTHEON")
	addBtn.DoClick = function()
		local ply = LocalPlayer()
		net.Start("ServerIntro.AddCamera")
		net.WriteVector(ply:EyePos())
		net.WriteAngle(ply:EyeAngles())
		net.WriteFloat(90)
		net.WriteFloat(5)
		net.SendToServer()
		timer.Simple(0.1, RefreshCameraList)
		notification.AddLegacy("Camera point added!", NOTIFY_GENERIC, 3)
	end
	
	local removeBtn = vgui.Create("DButton", btnPanel)
	removeBtn:SetText("Remove Selected")
	removeBtn:SetFont("PANTHEON.16")
	removeBtn:Dock(LEFT)
	removeBtn:SetWide(150)
	removeBtn:DockMargin(0, 0, 10, 0)
	removeBtn:SetSkin("PANTHEON")
	removeBtn.DoClick = function()
		local selected = list:GetSelectedLine()
		if selected then
			net.Start("ServerIntro.RemoveCamera")
			net.WriteInt(selected, 16)
			net.SendToServer()
			timer.Simple(0.1, RefreshCameraList)
			notification.AddLegacy("Camera point removed!", NOTIFY_GENERIC, 3)
		end
	end
	
	local clearBtn = vgui.Create("DButton", btnPanel)
	clearBtn:SetText("Clear All")
	clearBtn:SetFont("PANTHEON.16")
	clearBtn:Dock(LEFT)
	clearBtn:SetWide(120)
	clearBtn:SetSkin("PANTHEON")
	clearBtn.DoClick = function()
		net.Start("ServerIntro.ClearCameras")
		net.SendToServer()
		timer.Simple(0.1, RefreshCameraList)
		notification.AddLegacy("All camera points cleared!", NOTIFY_GENERIC, 3)
	end
	
	-- Help text
	local help = vgui.Create("DLabel", scroll)
	help:Dock(TOP)
	help:SetText("Stand where you want a camera point, look in the direction you want, then click 'Add Current Position'.")
	help:SetFont("PANTHEON.14")
	help:SetTextColor(ui.col.TEXT_DIM)
	help:SetWrap(true)
	help:SetAutoStretchVertical(true)
	help:DockMargin(0, 10, 0, 0)
	
	tabs:AddSheet("Camera", panel, "icon16/camera.png")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Rewards Tab                                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.CreateRewardsTab(tabs)
	local panel = vgui.Create("DPanel")
	panel:Dock(FILL)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(ui.col.BackgroundLight, 200))
	end
	
	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:DockMargin(15, 15, 15, 15)
	
	-- Ensure config exists
	ServerIntro.Config = ServerIntro.Config or {}
	
	-- Section header
	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:SetTall(40)
	header:DockMargin(0, 0, 0, 15)
	header.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(ui.col.PANTHEON, 30))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("Steam Group Rewards", "PANTHEON.18", 15, h/2, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	-- Helper functions
	local function CreateTextEntry(label, value, onEnter)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(70)
		container:DockMargin(0, 0, 0, 10)
		container.Paint = function() end
		
		local lbl = vgui.Create("DLabel", container)
		lbl:Dock(TOP)
		lbl:SetText(label)
		lbl:SetFont("PANTHEON.16")
		lbl:SetTextColor(ui.col.White)
		lbl:SetTall(25)
		
		local entry = vgui.Create("DTextEntry", container)
		entry:Dock(TOP)
		entry:SetTall(35)
		entry:SetText(value or "")
		entry:SetFont("PANTHEON.14")
		entry:SetSkin("PANTHEON")
		entry.OnEnter = function(self)
			onEnter(self:GetValue())
			notification.AddLegacy(label .. " updated!", NOTIFY_GENERIC, 2)
		end
		
		return entry
	end
	
	local function CreateSlider(label, min, max, decimals, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(60)
		container:DockMargin(0, 0, 0, 10)
		container.Paint = function() end
		
		local lbl = vgui.Create("DLabel", container)
		lbl:Dock(TOP)
		lbl:SetText(label)
		lbl:SetFont("PANTHEON.16")
		lbl:SetTextColor(ui.col.White)
		lbl:SetTall(25)
		
		local slider = vgui.Create("DNumSlider", container)
		slider:Dock(TOP)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetDecimals(decimals)
		slider:SetValue(value)
		slider:SetSkin("PANTHEON")
		slider.OnValueChanged = onChange
		
		return slider
	end
	
	local function CreateCheckbox(label, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(35)
		container:DockMargin(0, 0, 0, 5)
		container.Paint = function() end
		
		local check = vgui.Create("DCheckBoxLabel", container)
		check:Dock(LEFT)
		check:SetText(label)
		check:SetFont("PANTHEON.16")
		check:SetTextColor(ui.col.White)
		check:SetValue(value and 1 or 0)
		check:SizeToContents()
		check:SetSkin("PANTHEON")
		check.OnChange = onChange
		
		return check
	end
	
	-- Reward Enabled
	CreateCheckbox("Enable Rewards", ServerIntro.Config.RewardEnabled, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("RewardEnabled")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	-- Steam Group ID
	CreateTextEntry("Steam Group ID", ServerIntro.Config.SteamGroup, function(value)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("SteamGroup")
		net.WriteUInt(2, 8)
		net.WriteString(value)
		net.SendToServer()
	end)
	
	-- Reward Amount
	CreateSlider("Reward Amount ($)", 0, 100000, 0, ServerIntro.Config.RewardAmount or 5000, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("RewardAmount")
		net.WriteUInt(3, 8)
		net.WriteFloat(val)
		net.SendToServer()
	end)
	
	-- Reward Message
	CreateTextEntry("Reward Message (use %s for amount)", ServerIntro.Config.RewardMessage, function(value)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("RewardMessage")
		net.WriteUInt(2, 8)
		net.WriteString(value)
		net.SendToServer()
	end)
	
	tabs:AddSheet("Rewards", panel, "icon16/award_star_gold_1.png")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Visual Settings Tab                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.CreateVisualTab(tabs)
	local panel = vgui.Create("DPanel")
	panel:Dock(FILL)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(ui.col.BackgroundLight, 200))
	end
	
	local scroll = vgui.Create("DScrollPanel", panel)
	scroll:Dock(FILL)
	scroll:DockMargin(15, 15, 15, 15)
	
	-- Section header
	local header = vgui.Create("DPanel", scroll)
	header:Dock(TOP)
	header:SetTall(40)
	header:DockMargin(0, 0, 0, 15)
	header.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, ColorAlpha(ui.col.PANTHEON, 30))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("Visual Effects", "PANTHEON.18", 15, h/2, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	
	local function CreateCheckbox(label, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(35)
		container:DockMargin(0, 0, 0, 5)
		container.Paint = function() end
		
		local check = vgui.Create("DCheckBoxLabel", container)
		check:Dock(LEFT)
		check:SetText(label)
		check:SetFont("PANTHEON.16")
		check:SetTextColor(ui.col.White)
		check:SetValue(value and 1 or 0)
		check:SizeToContents()
		check:SetSkin("PANTHEON")
		check.OnChange = onChange
		
		return check
	end
	
	local function CreateSlider(label, min, max, decimals, value, onChange)
		local container = vgui.Create("DPanel", scroll)
		container:Dock(TOP)
		container:SetTall(60)
		container:DockMargin(0, 0, 0, 10)
		container.Paint = function() end
		
		local lbl = vgui.Create("DLabel", container)
		lbl:Dock(TOP)
		lbl:SetText(label)
		lbl:SetFont("PANTHEON.16")
		lbl:SetTextColor(ui.col.White)
		lbl:SetTall(25)
		
		local slider = vgui.Create("DNumSlider", container)
		slider:Dock(TOP)
		slider:SetMin(min)
		slider:SetMax(max)
		slider:SetDecimals(decimals)
		slider:SetValue(value)
		slider:SetSkin("PANTHEON")
		slider.OnValueChanged = onChange
		
		return slider
	end
	
	-- Enable Vignette
	CreateCheckbox("Enable Vignette", ServerIntro.Config.EnableVignette, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("EnableVignette")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	-- Enable Shake
	CreateCheckbox("Enable Camera Shake", ServerIntro.Config.EnableShake, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("EnableShake")
		net.WriteUInt(1, 8)
		net.WriteBool(val)
		net.SendToServer()
	end)
	
	-- Shake Intensity
	CreateSlider("Shake Intensity", 0, 10, 1, ServerIntro.Config.ShakeIntensity or 2, function(self, val)
		net.Start("ServerIntro.UpdateConfig")
		net.WriteString("ShakeIntensity")
		net.WriteUInt(3, 8)
		net.WriteFloat(val)
		net.SendToServer()
	end)
	
	tabs:AddSheet("Visual", panel, "icon16/color_wheel.png")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Test Tab                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ServerIntro.Menu.CreateTestTab(tabs)
	local panel = vgui.Create("DPanel")
	panel:Dock(FILL)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, ColorAlpha(ui.col.BackgroundLight, 200))
	end
	
	local container = vgui.Create("DPanel", panel)
	container:Dock(FILL)
	container:DockMargin(20, 20, 20, 20)
	container.Paint = function() end
	
	-- Test button
	local testBtn = vgui.Create("DButton", container)
	testBtn:SetText("Preview Intro")
	testBtn:SetFont("PANTHEON.20")
	testBtn:Dock(TOP)
	testBtn:SetTall(60)
	testBtn:DockMargin(0, 0, 0, 20)
	testBtn:SetSkin("PANTHEON")
	testBtn.DoClick = function()
		RunConsoleCommand("pas", "playintro", LocalPlayer():Nick())
		timer.Simple(0.5, function()
			if IsValid(ServerIntro.Menu.Frame) then
				ServerIntro.Menu.Frame:Remove()
			end
		end)
	end
	
	-- Save config button
	local saveBtn = vgui.Create("DButton", container)
	saveBtn:SetText("Save Configuration to File")
	saveBtn:SetFont("PANTHEON.18")
	saveBtn:Dock(TOP)
	saveBtn:SetTall(50)
	saveBtn:DockMargin(0, 0, 0, 20)
	saveBtn:SetSkin("PANTHEON")
	saveBtn.DoClick = function()
		net.Start("ServerIntro.SaveConfig")
		net.SendToServer()
		notification.AddLegacy("Configuration saved!", NOTIFY_GENERIC, 3)
	end
	
	-- Info
	local info = vgui.Create("DLabel", container)
	info:Dock(TOP)
	info:SetText("Use the Preview button to test your intro settings.\n\nAll changes are saved automatically.\n\nUse 'Save Configuration to File' to write changes to the config file permanently.")
	info:SetFont("PANTHEON.16")
	info:SetTextColor(ui.col.TEXT_DIM)
	info:SetWrap(true)
	info:SetAutoStretchVertical(true)
	
	tabs:AddSheet("Test & Save", panel, "icon16/wrench.png")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Networking                                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("ServerIntro.ConfigUpdate", function()
	ServerIntro.Config = net.ReadTable()
	print("[ServerIntro Menu] Config received:")
	PrintTable(ServerIntro.Config)
end)

net.Receive("ServerIntro.OpenMenu", function()
	ServerIntro.Menu.Open()
end)
