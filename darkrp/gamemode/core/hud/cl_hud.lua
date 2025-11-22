-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Inline Bar HUD - PAS UI Integration
-- ═══════════════════════════════════════════════════════════════════════════

DarkRP = DarkRP or {}
DarkRP.HUD = DarkRP.HUD or {}

-- Wait for PAS UI to load
if not ui or not ui.col then
	timer.Simple(1, function()
		include("darkrp/gamemode/core/hud/cl_hud.lua")
	end)
	return
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.HUD.config = {
	enabled = true,
	x = 20,              -- Distance from left edge
	barHeight = 32,      -- Height of each bar
	barSpacing = 6,      -- Space between bars
	iconSize = 24,       -- Icon size
	padding = 8,         -- Internal padding
	cornerRadius = 6,    -- Rounded corner radius
	animSpeed = 5,       -- Animation speed multiplier
	minBarWidth = 150,   -- Minimum bar width
	maxBarWidth = 250    -- Maximum bar width
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Animation System                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.HUD.anims = {
	health = 100,
	armor = 0,
	money = 0,
	salary = 0
}

local function updateAnimations()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	
	local ft = FrameTime() * DarkRP.HUD.config.animSpeed
	
	-- Smooth value transitions
	DarkRP.HUD.anims.health = Lerp(ft, DarkRP.HUD.anims.health, ply:Health())
	DarkRP.HUD.anims.armor = Lerp(ft, DarkRP.HUD.anims.armor, ply:Armor())
	
	-- Money and salary animations
	if ply.GetMoney then
		DarkRP.HUD.anims.money = Lerp(ft, DarkRP.HUD.anims.money, ply:GetMoney())
	end
	
	if ply.GetSalary then
		DarkRP.HUD.anims.salary = Lerp(ft, DarkRP.HUD.anims.salary, ply:GetSalary())
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Helper Functions                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

local function formatMoney(amount)
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return "$" .. formatted
end

local function drawIcon(text, x, y, size, color)
	draw.SimpleText(text, "PANTHEON.16", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function lerpColor(from, to, fraction)
	return Color(
		Lerp(fraction, from.r, to.r),
		Lerp(fraction, from.g, to.g),
		Lerp(fraction, from.b, to.b),
		Lerp(fraction, from.a, to.a)
	)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Inline Bar Drawing                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

local function drawInlineBar(x, y, iconName, label, value, maxValue, color, showValue)
	local cfg = DarkRP.HUD.config
	local barWidth = cfg.maxBarWidth
	local barHeight = cfg.barHeight
	local pad = cfg.padding
	
	-- Calculate progress
	local progress = math.Clamp(value / maxValue, 0, 1)
	
	-- Background with PAS colors
	draw.RoundedBox(cfg.cornerRadius, x, y, barWidth, barHeight, ui.col.BackgroundCard)
	
	-- Progress bar with color interpolation
	local barColor = color
	if color == ui.col.MaterialRed and progress < 0.3 then
		-- Health low warning
		barColor = lerpColor(ui.col.MaterialRed, ui.col.MaterialGreen, progress / 0.3)
	end
	
	if progress > 0 then
		draw.RoundedBox(cfg.cornerRadius, x, y, barWidth * progress, barHeight, ColorAlpha(barColor, 200))
	end
	
	-- Icon using PAS icon system
	if ui.DrawIcon then
		ui.DrawIcon(iconName, x + pad + 10, y + barHeight / 2, 18, ui.col.TEXT)
	end
	
	-- Label
	draw.SimpleText(label, "PANTHEON.14", x + pad + 24, y + 7, ui.col.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	-- Value
	if showValue then
		local valueText = tostring(math.Round(value))
		if maxValue > 0 then
			valueText = valueText .. "/" .. maxValue
		end
		draw.SimpleText(valueText, "PANTHEON.16", x + barWidth - pad, y + barHeight / 2 - 1, ui.col.TEXT, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
	
	return barHeight
end

local function drawInfoBar(x, y, iconName, label, value, color)
	local cfg = DarkRP.HUD.config
	local barWidth = cfg.maxBarWidth
	local barHeight = cfg.barHeight
	local pad = cfg.padding
	
	-- Background
	draw.RoundedBox(cfg.cornerRadius, x, y, barWidth, barHeight, ui.col.BackgroundCard)
	
	-- Accent line
	draw.RoundedBox(0, x, y, 3, barHeight, color or ui.col.PANTHEON)
	
	-- Icon using PAS icon system
	if ui.DrawIcon then
		ui.DrawIcon(iconName, x + pad + 10, y + barHeight / 2, 18, color or ui.col.TEXT)
	end
	
	-- Label
	draw.SimpleText(label, "PANTHEON.12", x + pad + 24, y + 6, ui.col.TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	-- Value
	draw.SimpleText(value, "PANTHEON.16", x + pad + 24, y + 17, color or ui.col.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	return barHeight
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Main HUD Draw                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.HUD.Draw()
	if not DarkRP.HUD.config.enabled then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	
	updateAnimations()
	
	local cfg = DarkRP.HUD.config
	local x = cfg.x
	local spacing = cfg.barSpacing
	
	-- Start from bottom and work upward
	local y = ScrH() - 20  -- 20px from bottom
	
	-- Health bar (always shown)
	local maxHealth = ply:GetMaxHealth()
	y = y - cfg.barHeight
	drawInlineBar(x, y, "heart", "HEALTH", DarkRP.HUD.anims.health, maxHealth, ui.col.MaterialRed, true)
	
	-- Armor bar (only if player has armor)
	if ply:Armor() > 0 then
		y = y - cfg.barHeight - spacing
		drawInlineBar(x, y, "shield", "ARMOR", DarkRP.HUD.anims.armor, 100, ui.col.MaterialBlue, true)
	end
	
	-- Money bar
	y = y - cfg.barHeight - spacing
	drawInfoBar(x, y, "currency", "MONEY", formatMoney(DarkRP.HUD.anims.money), ui.col.MaterialGreen)
	
	-- Salary bar
	y = y - cfg.barHeight - spacing
	drawInfoBar(x, y, "currency", "SALARY", formatMoney(DarkRP.HUD.anims.salary), ui.col.MaterialYellow)
	
	-- Player info (name and job) at the top
	y = y - cfg.barHeight - spacing
	local name = ply:Nick()
	local job = "Citizen"
	
	-- Try to get job from DarkRP
	if ply.getDarkRPVar then
		job = ply:getDarkRPVar("job") or job
	elseif ply.GetJobName then
		job = ply:GetJobName() or job
	elseif team and team.GetName then
		job = team.GetName(ply:Team()) or job
	end
	
	-- Player info bar
	draw.RoundedBox(cfg.cornerRadius, x, y, cfg.maxBarWidth, cfg.barHeight, ui.col.BackgroundCard)
	
	-- Purple accent bar on left
	draw.RoundedBox(0, x, y, 3, cfg.barHeight, ui.col.PANTHEON)
	
	-- Name
	draw.SimpleText(name, "PANTHEON.16", x + cfg.padding + 8, y + 6, ui.col.TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	
	-- Job
	draw.SimpleText(job, "PANTHEON.12", x + cfg.padding + 8, y + 20, ui.col.PANTHEON_LIGHT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hook Registration                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("HUDPaint", "DarkRP.HUD.Draw", function()
	-- Don't draw during server intro
	if ServerIntro and ServerIntro.Active then return end
	
	DarkRP.HUD.Draw()
end)

-- Hide default HUD elements
local hideHUDElements = {
	["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudSuitPower"] = true
}

hook.Add("HUDShouldDraw", "DarkRP.HUD.HideElements", function(name)
	if hideHUDElements[name] then
		return false
	end
end)

-- Console commands
concommand.Add("darkrp_hud_toggle", function()
	DarkRP.HUD.config.enabled = not DarkRP.HUD.config.enabled
	chat.AddText(ui.col.PANTHEON, "[DarkRP] ", ui.col.TEXT, "HUD " .. (DarkRP.HUD.config.enabled and "enabled" or "disabled"))
end)

concommand.Add("darkrp_hud_reload", function()
	DarkRP.HUD.anims = {
		health = 100,
		armor = 0,
		money = 0,
		salary = 0
	}
	chat.AddText(ui.col.PANTHEON, "[DarkRP] ", ui.col.TEXT, "HUD reloaded")
end)

print("[DarkRP] Inline Bar HUD loaded (PAS UI Integration)")

