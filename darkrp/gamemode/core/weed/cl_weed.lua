-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced Weed Growing System - Client
-- ═══════════════════════════════════════════════════════════════════════════

if not CLIENT then return end

-- Ensure DarkRP.Weed table exists (shared file should load first)
DarkRP.Weed = DarkRP.Weed or {}
DarkRP.Weed.Client = DarkRP.Weed.Client or {}
local WeedCL = DarkRP.Weed.Client

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Client Data                                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

WeedCL.PlantData = WeedCL.PlantData or {}
WeedCL.Inventory = WeedCL.Inventory or {}
WeedCL.ActiveEffects = WeedCL.ActiveEffects or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Fonts                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

surface.CreateFont("DarkRP.Weed.Title", {
	font = "Roboto",
	size = 32,
	weight = 800,
	antialias = true
})

surface.CreateFont("DarkRP.Weed.Large", {
	font = "Roboto",
	size = 24,
	weight = 700,
	antialias = true
})

surface.CreateFont("DarkRP.Weed.Medium", {
	font = "Roboto",
	size = 18,
	weight = 600,
	antialias = true
})

surface.CreateFont("DarkRP.Weed.Small", {
	font = "Roboto",
	size = 14,
	weight = 500,
	antialias = true
})

surface.CreateFont("DarkRP.Weed.Tiny", {
	font = "Roboto",
	size = 12,
	weight = 400,
	antialias = true
})

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  UI Helper Functions                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedCL.DrawRoundedBox(x, y, w, h, col, radius)
	radius = radius or 8
	draw.RoundedBox(radius, x, y, w, h, col)
end

function WeedCL.DrawProgressBar(x, y, w, h, progress, bgCol, fgCol, text)
	progress = math.Clamp(progress, 0, 100)
	
	-- Background
	WeedCL.DrawRoundedBox(x, y, w, h, bgCol or Color(40, 40, 40, 200))
	
	-- Foreground
	if progress > 0 then
		WeedCL.DrawRoundedBox(x + 2, y + 2, (w - 4) * (progress / 100), h - 4, fgCol or Color(100, 200, 100))
	end
	
	-- Text
	if text then
		draw.SimpleText(text, "DarkRP.Weed.Small", x + w / 2, y + h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function WeedCL.DrawShadowText(text, font, x, y, col, xalign, yalign)
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, 200), xalign, yalign)
	draw.SimpleText(text, font, x, y, col, xalign, yalign)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Plant Information Display                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedCL.DrawPlantInfo(ent)
	if not IsValid(ent) then return end
	if not ent.plantData then 
		DarkRP.Weed.Debug("DrawPlantInfo: No plantData")
		return 
	end
	if not ent.plantData.hasPlant then 
		DarkRP.Weed.Debug("DrawPlantInfo: hasPlant is false")
		return 
	end
	
	local plant = ent.plantData
	local strain = DarkRP.Weed.Config.GetStrain(plant.strainID)
	if not strain then 
		DarkRP.Weed.Debug("DrawPlantInfo: Invalid strain ID - " .. tostring(plant.strainID))
		return 
	end
	
	local pos = ent:GetPos() + Vector(0, 0, 50)
	local screenPos = pos:ToScreen()
	
	if not screenPos.visible then return end
	
	local x, y = screenPos.x, screenPos.y
	local distance = LocalPlayer():GetPos():Distance(ent:GetPos())
	
	-- Only show if close enough
	if distance > 500 then return end
	
	-- Calculate alpha based on distance
	local alpha = math.Clamp(255 - (distance / 500 * 255), 50, 255)
	
	-- Panel dimensions
	local panelW, panelH = 300, 160
	local panelX, panelY = x - panelW / 2, y - panelH / 2
	
	-- Background
	WeedCL.DrawRoundedBox(panelX, panelY, panelW, panelH, Color(30, 30, 30, alpha * 0.9))
	
	-- Header
	local headerCol = strain.color
	headerCol.a = alpha
	WeedCL.DrawRoundedBox(panelX, panelY, panelW, 30, headerCol)
	
	-- Strain name
	WeedCL.DrawShadowText(strain.name, "DarkRP.Weed.Medium", panelX + panelW / 2, panelY + 15, 
		Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	local offsetY = panelY + 40
	
	-- Growth progress
	local progress = DarkRP.Weed.CalculateGrowthProgress(ent)
	local stageIndex, stage = DarkRP.Weed.GetCurrentStage(ent)
	
	if plant.isDead then
		WeedCL.DrawShadowText("DEAD", "DarkRP.Weed.Large", panelX + panelW / 2, offsetY + 20, 
			Color(255, 50, 50, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	elseif plant.isReady then
		WeedCL.DrawShadowText("READY TO HARVEST!", "DarkRP.Weed.Medium", panelX + panelW / 2, offsetY + 10, 
			Color(100, 255, 100, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		local yield = DarkRP.Weed.CalculateYield(ent)
		WeedCL.DrawShadowText("Yield: ~" .. yield .. "g", "DarkRP.Weed.Small", panelX + panelW / 2, offsetY + 30, 
			Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		-- Stage
		WeedCL.DrawShadowText("Stage: " .. (stage and stage.name or "Unknown"), "DarkRP.Weed.Small", 
			panelX + 10, offsetY, Color(200, 200, 200, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		
		-- Progress bar
		WeedCL.DrawProgressBar(panelX + 10, offsetY + 20, panelW - 20, 20, progress, 
			Color(40, 40, 40, alpha * 0.8), Color(100, 200, 100, alpha), 
			string.format("%.1f%%", progress))
		
		offsetY = offsetY + 50
	end
	
	-- Health, Water, Fertilizer
	if not plant.isDead then
		local barW = (panelW - 40) / 3
		local barH = 15
		local barY = offsetY + 20
		
		-- Health
		local healthCol = DarkRP.Weed.GetHealthColor(plant.health)
		healthCol.a = alpha
		WeedCL.DrawProgressBar(panelX + 10, barY, barW, barH, plant.health, 
			Color(40, 40, 40, alpha * 0.8), healthCol)
		WeedCL.DrawShadowText("HP", "DarkRP.Weed.Tiny", panelX + 10 + barW / 2, barY - 10, 
			Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		-- Water
		local waterCol = plant.waterLevel > 50 and Color(100, 150, 255, alpha) or Color(255, 200, 100, alpha)
		WeedCL.DrawProgressBar(panelX + 15 + barW, barY, barW, barH, plant.waterLevel, 
			Color(40, 40, 40, alpha * 0.8), waterCol)
		WeedCL.DrawShadowText("H2O", "DarkRP.Weed.Tiny", panelX + 15 + barW + barW / 2, barY - 10, 
			Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		-- Fertilizer
		local fertCol = plant.fertilizerLevel > 50 and Color(200, 150, 100, alpha) or Color(255, 150, 100, alpha)
		WeedCL.DrawProgressBar(panelX + 20 + barW * 2, barY, barW, barH, plant.fertilizerLevel, 
			Color(40, 40, 40, alpha * 0.8), fertCol)
		WeedCL.DrawShadowText("FERT", "DarkRP.Weed.Tiny", panelX + 20 + barW * 2 + barW / 2, barY - 10, 
			Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Quality indicator
	if plant.quality > 0 then
		local qualityCol = DarkRP.Weed.GetQualityColor(plant.quality)
		qualityCol.a = alpha
		WeedCL.DrawShadowText("Quality: " .. plant.quality .. "%", "DarkRP.Weed.Small", 
			panelX + panelW / 2, panelY + panelH - 15, qualityCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Equipment Information Display                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedCL.DrawLampInfo(ent)
	if not IsValid(ent) then return end
	if not ent.equipmentData then return end
	
	local pos = ent:GetPos() + Vector(0, 0, 40)
	local screenPos = pos:ToScreen()
	
	if not screenPos.visible then return end
	
	local x, y = screenPos.x, screenPos.y
	local distance = LocalPlayer():GetPos():Distance(ent:GetPos())
	
	if distance > 400 then return end
	
	local alpha = math.Clamp(255 - (distance / 400 * 255), 50, 255)
	
	local panelW, panelH = 200, 80
	local panelX, panelY = x - panelW / 2, y - panelH / 2
	
	-- Background
	WeedCL.DrawRoundedBox(panelX, panelY, panelW, panelH, Color(30, 30, 30, alpha * 0.9))
	
	-- Header
	local powered = ent:GetPowered()
	local headerCol = powered and Color(100, 200, 255) or Color(100, 100, 100)
	headerCol.a = alpha
	WeedCL.DrawRoundedBox(panelX, panelY, panelW, 25, headerCol)
	
	-- Name
	WeedCL.DrawShadowText(ent.equipmentData.name, "DarkRP.Weed.Small", panelX + panelW / 2, panelY + 12, 
		Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Status
	local status = powered and "POWERED" or "OFF"
	local statusCol = powered and Color(100, 255, 100, alpha) or Color(255, 100, 100, alpha)
	WeedCL.DrawShadowText(status, "DarkRP.Weed.Small", panelX + panelW / 2, panelY + 40, 
		statusCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	
	-- Range
	if powered then
		WeedCL.DrawShadowText("Range: " .. (ent.equipmentData.radius or 0) .. " units", "DarkRP.Weed.Tiny", 
			panelX + panelW / 2, panelY + 60, Color(200, 200, 200, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  High Effect Rendering                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedCL.RenderHighEffects()
	if #WeedCL.ActiveEffects == 0 then return end
	
	local highestLevel = 0
	local activeEffect = nil
	
	-- Find highest level active effect
	for i = #WeedCL.ActiveEffects, 1, -1 do
		local effect = WeedCL.ActiveEffects[i]
		
		if effect.endTime < CurTime() then
			table.remove(WeedCL.ActiveEffects, i)
		elseif effect.level > highestLevel then
			highestLevel = effect.level
			activeEffect = effect
		end
	end
	
	if not activeEffect then return end
	
	local effectConfig = DarkRP.Weed.Config.GetHighEffect(highestLevel)
	if not effectConfig then return end
	
	-- Calculate fade based on time remaining
	local timeLeft = activeEffect.endTime - CurTime()
	local totalTime = activeEffect.duration
	local fade = math.Clamp(timeLeft / totalTime, 0, 1)
	
	-- Apply color modification
	if effectConfig.screenEffects and effectConfig.screenEffects.colormod then
		local colormod = table.Copy(effectConfig.screenEffects.colormod)
		
		-- Fade effect
		for k, v in pairs(colormod) do
			if type(v) == "number" then
				colormod[k] = v * fade
			end
		end
		
		DrawColorModify(colormod)
	end
	
	-- Apply motion blur
	if effectConfig.screenEffects and effectConfig.screenEffects.motionblur then
		DrawMotionBlur(effectConfig.screenEffects.motionblur * fade, 0.8, 0.01)
	end
	
	-- Apply blur
	if effectConfig.screenEffects and effectConfig.screenEffects.blur then
		local blurAmount = effectConfig.screenEffects.blur * fade
		if blurAmount > 0 then
			DrawBloom(0.65, blurAmount, 9, 9, 1, 1, 1, 1, 1)
		end
	end
	
	-- Draw high level indicator
	local screenW, screenH = ScrW(), ScrH()
	local indicatorText = "HIGH: Level " .. highestLevel
	
	surface.SetDrawColor(0, 0, 0, 100 * fade)
	surface.DrawRect(screenW - 160, 10, 150, 30)
	
	draw.SimpleText(indicatorText, "DarkRP.Weed.Small", screenW - 85, 25, 
		Color(100, 255, 100, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Interaction Menu                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function WeedCL.OpenPlantMenu(pot)
	if not IsValid(pot) then 
		DarkRP.Weed.Debug("OpenPlantMenu: Invalid pot")
		return 
	end
	
	-- Ensure plantData exists
	if not pot.plantData then
		DarkRP.Weed.Debug("OpenPlantMenu: No plantData, initializing...")
		pot.plantData = {
			hasPlant = pot:GetHasPlant() or false,
			strainID = pot:GetStrainID() or "",
			growthTime = pot:GetGrowthTime() or 0,
			health = pot:GetHealth() or 0,
			waterLevel = pot:GetWaterLevel() or 0,
			fertilizerLevel = pot:GetFertilizerLevel() or 0,
			quality = pot:GetQuality() or 0,
			isReady = pot:GetIsReady() or false,
			isDead = pot:GetIsDead() or false
		}
	end
	
	local plant = pot.plantData
	DarkRP.Weed.Debug("OpenPlantMenu: hasPlant = " .. tostring(plant.hasPlant) .. ", strainID = " .. tostring(plant.strainID))
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(400, 500)
	frame:Center()
	frame:SetTitle("")
	frame:SetDraggable(true)
	frame:ShowCloseButton(true)
	frame:MakePopup()
	
	frame.Paint = function(self, w, h)
		WeedCL.DrawRoundedBox(0, 0, w, h, Color(40, 40, 40, 250))
		
		-- Header
		local strain = DarkRP.Weed.Config.GetStrain(plant.strainID)
		if strain then
			WeedCL.DrawRoundedBox(0, 0, w, 50, strain.color)
			draw.SimpleText(strain.name, "DarkRP.Weed.Large", w / 2, 25, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			WeedCL.DrawRoundedBox(0, 0, w, 50, Color(100, 100, 100))
			draw.SimpleText("Weed Plant", "DarkRP.Weed.Large", w / 2, 25, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	local yPos = 60
	
	if plant.hasPlant then
		-- Stats panel
		local statsPanel = vgui.Create("DPanel", frame)
		statsPanel:SetPos(10, yPos)
		statsPanel:SetSize(380, 200)
		statsPanel.Paint = function(self, w, h)
			WeedCL.DrawRoundedBox(0, 0, w, h, Color(50, 50, 50, 200), 4)
			
			local strain = DarkRP.Weed.Config.GetStrain(plant.strainID)
			if not strain then return end
			
			local y = 10
			
			-- Growth
			local progress = DarkRP.Weed.CalculateGrowthProgress(pot)
			draw.SimpleText("Growth Progress:", "DarkRP.Weed.Medium", 10, y, Color(200, 200, 200))
			y = y + 25
			WeedCL.DrawProgressBar(10, y, w - 20, 25, progress, Color(30, 30, 30), Color(100, 200, 100), string.format("%.1f%%", progress))
			y = y + 35
			
			-- Stage
			local stageIndex, stage = DarkRP.Weed.GetCurrentStage(pot)
			if stage then
				draw.SimpleText("Stage: " .. stage.name, "DarkRP.Weed.Small", 10, y, Color(200, 200, 200))
				y = y + 25
			end
			
			-- Stats
			draw.SimpleText("Health: " .. plant.health .. "%", "DarkRP.Weed.Small", 10, y, DarkRP.Weed.GetHealthColor(plant.health))
			draw.SimpleText("Quality: " .. plant.quality .. "%", "DarkRP.Weed.Small", w / 2 + 10, y, DarkRP.Weed.GetQualityColor(plant.quality))
			y = y + 20
			
			draw.SimpleText("Water: " .. plant.waterLevel .. "%", "DarkRP.Weed.Small", 10, y, Color(100, 150, 255))
			draw.SimpleText("Fertilizer: " .. plant.fertilizerLevel .. "%", "DarkRP.Weed.Small", w / 2 + 10, y, Color(200, 150, 100))
			y = y + 20
			
			-- Pest warning
			if plant.hasPest or pot:GetHasPest() then
				draw.SimpleText("⚠ PEST INFECTION!", "DarkRP.Weed.Medium", w / 2, y, Color(255, 100, 50), TEXT_ALIGN_CENTER)
			end
			
			-- THC display
			local thc = pot:GetTHC() or plant.thc or 0
			if thc > 0 then
				draw.SimpleText("THC: " .. string.format("%.1f%%", thc), "DarkRP.Weed.Small", 10, y, Color(150, 255, 150))
			end
		end
		
		yPos = yPos + 210
		
		-- Actions
		if not plant.isDead and not plant.isReady then
			-- Cure Pest button (if plant has pests)
			if plant.hasPest or pot:GetHasPest() then
				local cureBtn = vgui.Create("DButton", frame)
				cureBtn:SetPos(10, yPos)
				cureBtn:SetSize(380, 40)
				cureBtn:SetText("🦟 Cure Pest Infection!")
				cureBtn:SetFont("DarkRP.Weed.Medium")
				cureBtn.DoClick = function()
					net.Start("DarkRP.Weed.PlantAction")
						net.WriteString("cure_pest")
						net.WriteEntity(pot)
					net.SendToServer()
					frame:Close()
				end
				cureBtn.Paint = function(self, w, h)
					local col = self:IsHovered() and Color(255, 150, 50) or Color(220, 120, 30)
					WeedCL.DrawRoundedBox(0, 0, w, h, col, 4)
				end
				
				yPos = yPos + 50
			end
			
			local waterBtn = vgui.Create("DButton", frame)
			waterBtn:SetPos(10, yPos)
			waterBtn:SetSize(380, 40)
			waterBtn:SetText("Water Plant")
			waterBtn:SetFont("DarkRP.Weed.Medium")
			waterBtn.DoClick = function()
				net.Start("DarkRP.Weed.PlantAction")
					net.WriteString("water")
					net.WriteEntity(pot)
				net.SendToServer()
				frame:Close()
			end
			
			yPos = yPos + 50
			
			local fertBtn = vgui.Create("DButton", frame)
			fertBtn:SetPos(10, yPos)
			fertBtn:SetSize(380, 40)
			fertBtn:SetText("Fertilize Plant")
			fertBtn:SetFont("DarkRP.Weed.Medium")
			fertBtn.DoClick = function()
				net.Start("DarkRP.Weed.PlantAction")
					net.WriteString("fertilize")
					net.WriteEntity(pot)
				net.SendToServer()
				frame:Close()
			end
			
			yPos = yPos + 50
		end
		
		if plant.isReady then
			local harvestBtn = vgui.Create("DButton", frame)
			harvestBtn:SetPos(10, yPos)
			harvestBtn:SetSize(380, 50)
			harvestBtn:SetText("HARVEST")
			harvestBtn:SetFont("DarkRP.Weed.Large")
			harvestBtn.DoClick = function()
				net.Start("DarkRP.Weed.PlantAction")
					net.WriteString("harvest")
					net.WriteEntity(pot)
				net.SendToServer()
				frame:Close()
			end
			harvestBtn.Paint = function(self, w, h)
				local col = self:IsHovered() and Color(100, 255, 100) or Color(80, 200, 80)
				WeedCL.DrawRoundedBox(0, 0, w, h, col, 4)
			end
			
			yPos = yPos + 60
		end
		
		-- Remove button
		local removeBtn = vgui.Create("DButton", frame)
		removeBtn:SetPos(10, yPos)
		removeBtn:SetSize(380, 35)
		removeBtn:SetText("Remove Plant")
		removeBtn:SetFont("DarkRP.Weed.Small")
		removeBtn.DoClick = function()
			net.Start("DarkRP.Weed.PlantAction")
				net.WriteString("remove")
				net.WriteEntity(pot)
			net.SendToServer()
			frame:Close()
		end
		removeBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and Color(255, 100, 100) or Color(200, 80, 80)
			WeedCL.DrawRoundedBox(0, 0, w, h, col, 4)
		end
	else
		-- No plant - show instructions for getting seeds
		local instructionsPanel = vgui.Create("DPanel", frame)
		instructionsPanel:SetPos(10, yPos)
		instructionsPanel:SetSize(380, 300)
		instructionsPanel.Paint = function(self, w, h)
			WeedCL.DrawRoundedBox(0, 0, w, h, Color(50, 50, 50, 200), 4)
			
			local y = 20
			draw.SimpleText("How to Plant:", "DarkRP.Weed.Large", w / 2, y, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			y = y + 40
			
			draw.SimpleText("1. Purchase weed seeds from the F4 menu", "DarkRP.Weed.Small", 20, y, Color(200, 200, 200))
			y = y + 25
			draw.SimpleText("2. Pick up the seed entity", "DarkRP.Weed.Small", 20, y, Color(200, 200, 200))
			y = y + 25
			draw.SimpleText("3. Look at this pot and press E", "DarkRP.Weed.Small", 20, y, Color(200, 200, 200))
			y = y + 25
			draw.SimpleText("4. The seed will be planted automatically!", "DarkRP.Weed.Small", 20, y, Color(200, 200, 200))
			y = y + 40
			
			draw.SimpleText("Available Strains:", "DarkRP.Weed.Medium", w / 2, y, Color(150, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			y = y + 30
			
			for _, strain in ipairs(DarkRP.Weed.Config.Strains) do
				draw.SimpleText("• " .. strain.name, "DarkRP.Weed.Tiny", 30, y, strain.color)
				y = y + 18
			end
		end
		
		yPos = yPos + 310
		
		local closeBtn = vgui.Create("DButton", frame)
		closeBtn:SetPos(10, yPos)
		closeBtn:SetSize(380, 40)
		closeBtn:SetText("Close")
		closeBtn:SetFont("DarkRP.Weed.Medium")
		closeBtn.DoClick = function()
			frame:Close()
		end
		closeBtn.Paint = function(self, w, h)
			local col = self:IsHovered() and Color(80, 80, 150) or Color(60, 60, 120)
			WeedCL.DrawRoundedBox(0, 0, w, h, col, 4)
		end
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Receivers                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Weed.PlantUpdate", function()
	local ent = net.ReadEntity()
	local data = net.ReadTable()
	
	if IsValid(ent) then
		ent.plantData = data
	end
end)

net.Receive("DarkRP.Weed.Notification", function()
	local message = net.ReadString()
	local type = net.ReadUInt(3)
	local duration = net.ReadFloat()
	
	notification.AddLegacy(message, type, duration)
	surface.PlaySound("buttons/button15.wav")
end)

net.Receive("DarkRP.Weed.HighEffect", function()
	local effectData = net.ReadTable()
	local duration = net.ReadFloat()
	
	local effect = {
		level = effectData.highlevel or 1,
		endTime = CurTime() + duration,
		duration = duration,
		data = effectData
	}
	
	table.insert(WeedCL.ActiveEffects, effect)
	
	-- Play ambient sound
	local effectConfig = DarkRP.Weed.Config.GetHighEffect(effect.level)
	if effectConfig and effectConfig.sounds and effectConfig.sounds.ambient then
		surface.PlaySound(effectConfig.sounds.ambient)
	end
end)

net.Receive("DarkRP.Weed.InventorySync", function()
	WeedCL.Inventory = net.ReadTable()
end)

print("[Weed Client] Registering net.Receive for DarkRP.Weed.OpenUI")
net.Receive("DarkRP.Weed.OpenUI", function()
	print("[Weed Client] ========================================")
	print("[Weed Client] OpenUI message received!")
	local ent = net.ReadEntity()
	print("[Weed Client] Entity: " .. (IsValid(ent) and ent:GetClass() or "invalid"))
	print("[Weed Client] Entity Index: " .. (IsValid(ent) and ent:EntIndex() or "N/A"))
	
	-- Small delay to ensure plant data is synced
	timer.Simple(0.1, function()
		if IsValid(ent) then
			print("[Weed Client] Opening plant menu for: " .. ent:GetClass())
			DarkRP.Weed.Debug("Opening plant menu for: " .. ent:GetClass())
			WeedCL.OpenPlantMenu(ent)
		else
			print("[Weed Client] ERROR: Entity became invalid before menu could open")
			DarkRP.Weed.Debug("Entity became invalid before menu could open")
		end
	end)
	print("[Weed Client] ========================================")
end)
print("[Weed Client] DarkRP.Weed.OpenUI receiver registered successfully")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("HUDPaint", "DarkRP.Weed.DrawPlantInfo", function()
	local ply = LocalPlayer()
	local trace = ply:GetEyeTrace()
	
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "darkrp_weed_pot" then
		if trace.HitPos:Distance(ply:GetPos()) <= 200 then
			WeedCL.DrawPlantInfo(trace.Entity)
		end
	elseif IsValid(trace.Entity) and trace.Entity:GetClass() == "darkrp_weed_lamp" then
		if trace.HitPos:Distance(ply:GetPos()) <= 200 then
			WeedCL.DrawLampInfo(trace.Entity)
		end
	end
end)

hook.Add("RenderScreenspaceEffects", "DarkRP.Weed.HighEffects", function()
	WeedCL.RenderHighEffects()
end)

DarkRP.Weed.Print("Client functions loaded")

return WeedCL
