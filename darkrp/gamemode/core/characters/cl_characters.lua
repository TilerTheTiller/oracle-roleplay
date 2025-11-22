-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Character System - Client (Single Character System)
--  Simplified character UI for single character per player
-- ═══════════════════════════════════════════════════════════════════════════

print("[DarkRP] Loading character system (client)...")

DarkRP = DarkRP or {}
DarkRP.Characters = DarkRP.Characters or {}
DarkRP.Characters.UI = {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Data Storage                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Characters.UI.character = nil
DarkRP.Characters.UI.activeFrame = nil

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Fonts                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

surface.CreateFont("DRP.Char.Title", {
	font = "Funnel Sans",
	size = 64,
	weight = 200,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Subtitle", {
	font = "Funnel Sans",
	size = 20,
	weight = 300,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Name", {
	font = "Funnel Sans",
	size = 28,
	weight = 600,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Info", {
	font = "Funnel Sans",
	size = 15,
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Label", {
	font = "Funnel Sans",
	size = 12,
	weight = 500,
	extended = true,
	antialias = true
})

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  3D Character Model Panel                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

local PANEL = {}

function PANEL:Init()
	self.Model = nil
	self.ModelPath = ""
	self.CamPos = Vector(-80, 0, 72)
	self.LookAt = Vector(0, 0, 62)
	self.FOV = 32
	self.TargetRotation = 180
	self.CurrentRotation = 180
	self.AutoRotate = true
	self.RotateSpeed = 0.2
end

function PANEL:SetModel(model)
	if self.ModelPath == model then return end
	
	self.ModelPath = model
	
	if IsValid(self.Model) then
		self.Model:Remove()
	end
	
	self.Model = ClientsideModel(model, RENDERGROUP_OPAQUE)
	
	if IsValid(self.Model) then
		self.Model:SetNoDraw(true)
		local seq = self.Model:LookupSequence("idle_all_01") or self.Model:LookupSequence("idle") or 0
		self.Model:ResetSequence(seq)
	end
end

function PANEL:OnRemove()
	if IsValid(self.Model) then
		self.Model:Remove()
	end
end

function PANEL:Think()
	if self.AutoRotate then
		self.TargetRotation = self.TargetRotation + self.RotateSpeed
	end
	self.CurrentRotation = Lerp(FrameTime() * 3, self.CurrentRotation, self.TargetRotation)
end

function PANEL:LayoutEntity(ent)
	if not IsValid(ent) then return end
	ent:SetAngles(Angle(0, self.CurrentRotation, 0))
	ent:FrameAdvance(FrameTime())
end

function PANEL:OnMousePressed(keyCode)
	if keyCode == MOUSE_LEFT then
		self.Dragging = true
		self.DragStart = gui.MouseX()
		self.DragStartRotation = self.TargetRotation
	end
end

function PANEL:OnMouseReleased(keyCode)
	if keyCode == MOUSE_LEFT then
		self.Dragging = false
	end
end

function PANEL:OnCursorMoved(x, y)
	if self.Dragging then
		local delta = (gui.MouseX() - self.DragStart) * 0.5
		self.TargetRotation = self.DragStartRotation + delta
		self.AutoRotate = false
	end
end

function PANEL:Paint(w, h)
	if IsValid(self.Model) then
		local x, y = self:LocalToScreen(0, 0)
		
		cam.Start3D(self.CamPos, (self.LookAt - self.CamPos):Angle(), self.FOV, x, y, w, h)
			cam.IgnoreZ(true)
			render.SuppressEngineLighting(true)
			render.SetLightingOrigin(self.Model:GetPos())
			render.ResetModelLighting(0.4, 0.4, 0.4)
			render.SetColorModulation(1, 1, 1)
			render.SetBlend(1)
			
			-- Studio lighting
			render.SetModelLighting(0, 0.6, 0.6, 0.7)
			render.SetModelLighting(1, 0.2, 0.2, 0.3)
			render.SetModelLighting(2, 0.4, 0.4, 0.5)
			render.SetModelLighting(3, 0.4, 0.4, 0.5)
			render.SetModelLighting(4, 0.5, 0.5, 0.6)
			render.SetModelLighting(5, 0.1, 0.1, 0.2)
			
			self:LayoutEntity(self.Model)
			self.Model:DrawModel()
			
			render.SuppressEngineLighting(false)
			cam.IgnoreZ(false)
		cam.End3D()
	end
	
	return true
end

vgui.Register("DRP_CharModel", PANEL, "DPanel")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Main Character Screen                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.UI.OpenMenu()
	if not ui or not ui.col then
		timer.Simple(0.5, function() DarkRP.Characters.UI.OpenMenu() end)
		return
	end
	
	if IsValid(DarkRP.Characters.UI.activeFrame) then
		DarkRP.Characters.UI.activeFrame:Remove()
	end
	
	local char = DarkRP.Characters.UI.character
	local scrW, scrH = ScrW(), ScrH()
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(scrW, scrH)
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	
	DarkRP.Characters.UI.activeFrame = frame
	
	frame.FadeIn = 0
	frame.StartTime = SysTime()
	
	frame.Paint = function(self, w, h)
		self.FadeIn = math.min(1, (SysTime() - self.StartTime) * 2)
		local alpha = 255 * self.FadeIn
		
		-- Dark base
		surface.SetDrawColor(12, 12, 15, alpha)
		surface.DrawRect(0, 0, w, h)
		
		-- Subtle vignette effect
		for i = 1, 3 do
			local vignetteAlpha = (40 - i * 10) * self.FadeIn
			surface.SetDrawColor(0, 0, 0, vignetteAlpha)
			surface.DrawRect(0, 0, w * 0.2, h)
			surface.DrawRect(w * 0.8, 0, w * 0.2, h)
		end
		
		-- Top gradient overlay
		surface.SetDrawColor(0, 0, 0, 80 * self.FadeIn)
		surface.DrawRect(0, 0, w, h * 0.3)
		
		local title = char and "WELCOME BACK" or "CREATE CHARACTER"
		draw.SimpleText(title, "DRP.Char.Title", w / 2, h * 0.15, ColorAlpha(ui.col.White, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Center panel
	local panelW = scrW * 0.55
	local panelH = scrH * 0.65
	local mainPanel = vgui.Create("DPanel", frame)
	mainPanel:SetSize(panelW, panelH)
	mainPanel:SetPos((scrW - panelW) / 2, (scrH - panelH) / 2)
	mainPanel.Paint = function(self, w, h) end
	
	-- Model preview (full panel, no background)
	local modelPanel = vgui.Create("DRP_CharModel", mainPanel)
	modelPanel:SetSize(panelW, panelH * 0.75)
	modelPanel:SetPos(0, 0)
	
	if char then
		modelPanel:SetModel(char.model)
	end
	
	-- Info panel (floating at bottom, with background)
	local infoPanel = vgui.Create("DPanel", mainPanel)
	infoPanel:SetSize(panelW * 0.85, panelH * 0.22)
	infoPanel:SetPos(panelW * 0.075, panelH * 0.76)
	infoPanel.Paint = function(self, w, h)
		-- Outer glow
		for i = 1, 3 do
			local offset = i * 2
			local glowAlpha = (20 - i * 6) * frame.FadeIn
			draw.RoundedBox(12 + i, -offset, -offset, w + offset * 2, h + offset * 2, ColorAlpha(ui.col.PANTHEON, glowAlpha))
		end
		
		-- Background with gradient
		draw.RoundedBox(12, 0, 0, w, h, ColorAlpha(Color(18, 18, 22), 240 * frame.FadeIn))
		draw.RoundedBox(12, 0, 0, w, h * 0.5, ColorAlpha(Color(25, 25, 30), 80 * frame.FadeIn))
		
		-- Border with gradient effect
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 60 * frame.FadeIn)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		-- Top accent line
		surface.SetDrawColor(ui.col.PANTHEON_LIGHT.r, ui.col.PANTHEON_LIGHT.g, ui.col.PANTHEON_LIGHT.b, 40 * frame.FadeIn)
		surface.DrawRect(20, 0, w - 40, 1)
		
		if not char then
			draw.SimpleText("Create your character to begin", "DRP.Char.Info", w / 2, h / 2, ColorAlpha(ui.col.TEXT_DIM, 200 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end
		
		local yPos = 15
		
		-- Character name with underline
		draw.SimpleText(char.name, "DRP.Char.Name", w / 2, yPos, ColorAlpha(ui.col.White, 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		surface.SetFont("DRP.Char.Name")
		local nameW = surface.GetTextSize(char.name)
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 100 * frame.FadeIn)
		surface.DrawRect(w / 2 - nameW / 2, yPos + 32, nameW, 2)
		
		yPos = yPos + 50
		
		local statW = w / 3
		local statX1 = statW / 2
		local statX2 = w / 2
		local statX3 = w - statW / 2
		
		-- Draw stat boxes with icons
		local function DrawStat(x, label, value, color, icon)
			local iconY = yPos
			
			-- Icon
			if icon then
				local iconMat = ui.icons and ui.icons.materials and ui.icons.materials[icon]
				if not iconMat then
					iconMat = Material("ui/" .. icon .. ".png", "smooth mips")
				end
				
				if iconMat and not iconMat:IsError() then
					surface.SetDrawColor(color.r, color.g, color.b, 150 * frame.FadeIn)
					surface.SetMaterial(iconMat)
					surface.DrawTexturedRect(x - 10, iconY, 20, 20)
				end
			end
			
			draw.SimpleText(label, "DRP.Char.Label", x, iconY + 28, ColorAlpha(ui.col.TEXT_DIM, 180 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(value, "DRP.Char.Info", x, iconY + 45, ColorAlpha(color, 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
		
		DrawStat(statX1, "WALLET", "$" .. string.Comma(char.money), ui.col.PANTHEON_LIGHT, "wallet")
		DrawStat(statX2, "BANK", "$" .. string.Comma(char.bankMoney), ui.col.PANTHEON_LIGHT, "coins")
		DrawStat(statX3, "PLAYTIME", DarkRP.Characters.FormatPlaytime(char.playtime), Color(100, 200, 255), "calendar")
	end
	
	-- Bottom buttons
	local btnW = char and (char.isActive and 400 or 380) or 320
	local btnPanel = vgui.Create("DPanel", frame)
	btnPanel:SetSize(btnW, 55)
	btnPanel:SetPos((scrW - btnW) / 2, scrH * 0.86)
	btnPanel.Paint = function() end
	
	if char then
		local playBtn = vgui.Create("DButton", btnPanel)
		playBtn:SetSize(char.isActive and 400 or 180, 55)
		playBtn:SetPos(0, 0)
		playBtn:SetText("")
		playBtn.Hover = 0
		
		playBtn.Paint = function(self, w, h)
			self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
			
			-- Glow effect on hover
			if self.Hover > 0 then
				for i = 1, 2 do
					local offset = i * 2
					local glowAlpha = (15 - i * 5) * self.Hover
					draw.RoundedBox(8 + i, -offset, -offset, w + offset * 2, h + offset * 2, ColorAlpha(ui.col.PANTHEON, glowAlpha))
				end
			end
			
			local col = ColorAlpha(ui.col.PANTHEON, 200 + self.Hover * 55)
			draw.RoundedBox(8, 0, 0, w, h, col)
			
			-- Shine effect
			if self.Hover > 0 then
				draw.RoundedBox(8, 0, 0, w, h * 0.4, ColorAlpha(ui.col.White, 15 * self.Hover))
			end
			
			local txt = char.isActive and "CURRENTLY PLAYING" or "CONTINUE"
			draw.SimpleText(txt, "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		playBtn.DoClick = function()
			if char.isActive then
				frame:Remove()
				return
			end
			
			net.Start("DarkRP.Characters.Select")
				net.WriteUInt(char.id, 32)
			net.SendToServer()
			
			frame:Remove()
		end
		
		if not char.isActive and DarkRP.Characters.Config.allowDeletion then
			local deleteBtn = vgui.Create("DButton", btnPanel)
			deleteBtn:SetSize(190, 55)
			deleteBtn:SetPos(190, 0)
			deleteBtn:SetText("")
			deleteBtn.Hover = 0
			
			deleteBtn.Paint = function(self, w, h)
				self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
				
				local col = ColorAlpha(Color(60, 30, 30), 150 + self.Hover * 105)
				draw.RoundedBox(8, 0, 0, w, h, col)
				
				surface.SetDrawColor(200, 80, 80, 60 + self.Hover * 100)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				
				local txtCol = self.Hover > 0.5 and Color(255, 120, 120) or ui.col.White
				draw.SimpleText("DELETE", "DRP.Char.Info", w / 2, h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			deleteBtn.DoClick = function()
				Derma_Query(
					"Delete your character '" .. char.name .. "'?\n\nThis action cannot be undone.",
					"Confirm Deletion",
					"Delete",
					function()
						net.Start("DarkRP.Characters.Delete")
							net.WriteUInt(char.id, 32)
						net.SendToServer()
						frame:Remove()
					end,
					"Cancel"
				)
			end
		end
	else
		local createBtn = vgui.Create("DButton", btnPanel)
		createBtn:SetSize(320, 55)
		createBtn:SetPos(0, 0)
		createBtn:SetText("")
		createBtn.Hover = 0
		
		createBtn.Paint = function(self, w, h)
			self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
			
			local col = ColorAlpha(ui.col.PANTHEON, 200 + self.Hover * 55)
			draw.RoundedBox(8, 0, 0, w, h, col)
			
			if self.Hover > 0 then
				draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(ui.col.White, 10 * self.Hover))
			end
			
			draw.SimpleText("CREATE CHARACTER", "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		createBtn.DoClick = function()
			frame:Remove()
			DarkRP.Characters.UI.OpenCreationMenu()
		end
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Character Creation Menu                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.UI.OpenCreationMenu()
	if not ui or not ui.col then
		timer.Simple(0.5, function() DarkRP.Characters.UI.OpenCreationMenu() end)
		return
	end
	
	local scrW, scrH = ScrW(), ScrH()
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(scrW, scrH)
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	
	frame.FadeIn = 0
	frame.StartTime = SysTime()
	
	frame.Paint = function(self, w, h)
		self.FadeIn = math.min(1, (SysTime() - self.StartTime) * 2)
		local alpha = 255 * self.FadeIn
		
		surface.SetDrawColor(12, 12, 15, alpha)
		surface.DrawRect(0, 0, w, h)
		
		draw.RoundedBox(0, 0, 0, w, 3, ColorAlpha(ui.col.PANTHEON, alpha))
		
		draw.SimpleText("CREATE CHARACTER", "DRP.Char.Title", w / 2, h * 0.12, ColorAlpha(ui.col.White, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Customize your character", "DRP.Char.Subtitle", w / 2, h * 0.165, ColorAlpha(ui.col.TEXT_DIM, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	local contentW = scrW * 0.65
	local contentH = scrH * 0.55
	
	local content = vgui.Create("DPanel", frame)
	content:SetSize(contentW, contentH)
	content:SetPos((scrW - contentW) / 2, scrH * 0.25)
	content.Paint = function(self, w, h)
		draw.RoundedBox(12, 0, 0, w, h, ColorAlpha(Color(20, 20, 25), 200 * frame.FadeIn))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 30 * frame.FadeIn)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	
	-- Model preview
	local modelPanel = vgui.Create("DRP_CharModel", content)
	modelPanel:SetSize(contentW * 0.42, contentH)
	modelPanel:SetPos(0, 0)
	
	local selectedModel = DarkRP.Characters.Config.maleModels[1]
	local selectedGender = "male"
	modelPanel:SetModel(selectedModel)
	
	-- Customization panel
	local customPanel = vgui.Create("DPanel", content)
	customPanel:SetSize(contentW * 0.56, contentH)
	customPanel:SetPos(contentW * 0.44, 0)
	customPanel.Paint = function() end
	
	local scroll = vgui.Create("DScrollPanel", customPanel)
	scroll:Dock(FILL)
	scroll:DockMargin(25, 25, 25, 25)
	
	local sbar = scroll:GetVBar()
	sbar:SetWide(5)
	sbar.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, ColorAlpha(Color(30, 30, 35), 100))
	end
	sbar.btnGrip.Paint = function(self, w, h)
		draw.RoundedBox(3, 0, 0, w, h, ColorAlpha(ui.col.PANTHEON, 150))
	end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end
	
	-- Name section
	local nameLabel = vgui.Create("DLabel", scroll)
	nameLabel:Dock(TOP)
	nameLabel:SetTall(22)
	nameLabel:SetFont("DRP.Char.Info")
	nameLabel:SetText("CHARACTER NAME")
	nameLabel:SetTextColor(ui.col.White)
	
	local nameEntry = vgui.Create("DTextEntry", scroll)
	nameEntry:Dock(TOP)
	nameEntry:DockMargin(0, 8, 0, 25)
	nameEntry:SetTall(40)
	nameEntry:SetFont("DRP.Char.Info")
	nameEntry:SetPlaceholderText("Enter name...")
	
	nameEntry.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(Color(30, 30, 35), 200))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 60)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		self:DrawTextEntryText(ui.col.White, ui.col.PANTHEON, ui.col.White)
	end
	
	-- Gender section
	local genderLabel = vgui.Create("DLabel", scroll)
	genderLabel:Dock(TOP)
	genderLabel:SetTall(22)
	genderLabel:SetFont("DRP.Char.Info")
	genderLabel:SetText("GENDER")
	genderLabel:SetTextColor(ui.col.White)
	
	local genderPanel = vgui.Create("DPanel", scroll)
	genderPanel:Dock(TOP)
	genderPanel:DockMargin(0, 8, 0, 25)
	genderPanel:SetTall(45)
	genderPanel.Paint = function() end
	
	local maleBtn = vgui.Create("DButton", genderPanel)
	maleBtn:SetSize((genderPanel:GetWide() - 8) / 2, 45)
	maleBtn:SetPos(0, 0)
	maleBtn:SetText("")
	maleBtn.Hover = 0
	
	maleBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
		
		local isSelected = selectedGender == "male"
		local col = isSelected and ui.col.PANTHEON or ColorAlpha(Color(30, 30, 35), 200)
		if self.Hover > 0 and not isSelected then
			col = ColorAlpha(Color(40, 40, 45), 200)
		end
		
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		if not isSelected then
			surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 60 + self.Hover * 60)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		
		draw.SimpleText("MALE", "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	local femaleBtn = vgui.Create("DButton", genderPanel)
	femaleBtn:SetSize((genderPanel:GetWide() - 8) / 2, 45)
	femaleBtn:SetPos((genderPanel:GetWide() + 8) / 2, 0)
	femaleBtn:SetText("")
	femaleBtn.Hover = 0
	
	femaleBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
		
		local isSelected = selectedGender == "female"
		local col = isSelected and ui.col.PANTHEON or ColorAlpha(Color(30, 30, 35), 200)
		if self.Hover > 0 and not isSelected then
			col = ColorAlpha(Color(40, 40, 45), 200)
		end
		
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		if not isSelected then
			surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 60 + self.Hover * 60)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		
		draw.SimpleText("FEMALE", "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Model selection
	local modelLabel = vgui.Create("DLabel", scroll)
	modelLabel:Dock(TOP)
	modelLabel:SetTall(22)
	modelLabel:SetFont("DRP.Char.Info")
	modelLabel:SetText("MODEL")
	modelLabel:SetTextColor(ui.col.White)
	
	local modelGrid = vgui.Create("DGrid", scroll)
	modelGrid:Dock(TOP)
	modelGrid:DockMargin(0, 8, 0, 0)
	modelGrid:SetCols(3)
	modelGrid:SetColWide(90)
	modelGrid:SetRowHeight(90)
	
	local function PopulateModels()
		modelGrid:Clear()
		
		local models = selectedGender == "male" and DarkRP.Characters.Config.maleModels or DarkRP.Characters.Config.femaleModels
		
		for _, mdl in ipairs(models) do
			local btn = vgui.Create("DButton")
			btn:SetSize(85, 85)
			btn:SetText("")
			
			btn.Hover = 0
			
			btn.Paint = function(self, w, h)
				self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
				
				local isSelected = selectedModel == mdl
				local col = ColorAlpha(Color(30, 30, 35), 200)
				local borderCol = isSelected and ui.col.PANTHEON or Color(50, 50, 60)
				local borderAlpha = isSelected and 255 or (60 + self.Hover * 100)
				
				draw.RoundedBox(8, 0, 0, w, h, col)
				surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, borderAlpha)
				surface.DrawOutlinedRect(0, 0, w, h, isSelected and 2 or 1)
			end
			
			local icon = vgui.Create("SpawnIcon", btn)
			icon:SetModel(mdl)
			icon:Dock(FILL)
			icon:DockMargin(2, 2, 2, 2)
			
			btn.DoClick = function()
				selectedModel = mdl
				modelPanel:SetModel(mdl)
				modelPanel.TargetRotation = modelPanel.TargetRotation + 360
			end
			
			modelGrid:AddItem(btn)
		end
	end
	
	PopulateModels()
	
	maleBtn.DoClick = function()
		selectedGender = "male"
		selectedModel = DarkRP.Characters.Config.maleModels[1]
		modelPanel:SetModel(selectedModel)
		PopulateModels()
	end
	
	femaleBtn.DoClick = function()
		selectedGender = "female"
		selectedModel = DarkRP.Characters.Config.femaleModels[1]
		modelPanel:SetModel(selectedModel)
		PopulateModels()
	end
	
	-- Bottom buttons
	local btnPanel = vgui.Create("DPanel", frame)
	btnPanel:SetSize(scrW * 0.65, 60)
	btnPanel:SetPos((scrW - scrW * 0.65) / 2, scrH * 0.86)
	btnPanel.Paint = function() end
	
	local createBtn = vgui.Create("DButton", btnPanel)
	createBtn:SetSize(320, 55)
	createBtn:SetPos(0, 0)
	createBtn:SetText("")
	createBtn.Hover = 0
	
	createBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
		
		local col = ColorAlpha(ui.col.PANTHEON, 200 + self.Hover * 55)
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		if self.Hover > 0 then
			draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(ui.col.White, 10 * self.Hover))
		end
		
		draw.SimpleText("CREATE CHARACTER", "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	createBtn.DoClick = function()
		local name = nameEntry:GetValue()
		
		if name == "" or #name < DarkRP.Characters.Config.minNameLength then
			Derma_Message("Character name must be at least " .. DarkRP.Characters.Config.minNameLength .. " characters.", "Invalid Name", "OK")
			return
		end
		
		if #name > DarkRP.Characters.Config.maxNameLength then
			Derma_Message("Character name must be less than " .. DarkRP.Characters.Config.maxNameLength .. " characters.", "Invalid Name", "OK")
			return
		end
		
		net.Start("DarkRP.Characters.Create")
			net.WriteString(name)
			net.WriteString(selectedModel)
		net.SendToServer()
		
		frame:Remove()
	end
	
	local cancelBtn = vgui.Create("DButton", btnPanel)
	cancelBtn:SetSize(320, 55)
	cancelBtn:SetPos(btnPanel:GetWide() - 320, 0)
	cancelBtn:SetText("")
	cancelBtn.Hover = 0
	
	cancelBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
		
		local col = ColorAlpha(Color(30, 30, 35), 150 + self.Hover * 50)
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		surface.SetDrawColor(ui.col.TEXT_DIM.r, ui.col.TEXT_DIM.g, ui.col.TEXT_DIM.b, 60 + self.Hover * 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		draw.SimpleText("CANCEL", "DRP.Char.Info", w / 2, h / 2, ui.col.TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	cancelBtn.DoClick = function()
		frame:Remove()
		DarkRP.Characters.UI.OpenMenu()
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Receivers                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Characters.SendList", function()
	local count = net.ReadUInt(8)
	
	if count > 0 then
		DarkRP.Characters.UI.character = {
			id = net.ReadUInt(32),
			name = net.ReadString(),
			model = net.ReadString(),
			money = net.ReadUInt(32),
			bankMoney = net.ReadUInt(32),
			jobID = net.ReadUInt(16),
			playtime = net.ReadUInt(32),
			isActive = net.ReadBool()
		}
	else
		DarkRP.Characters.UI.character = nil
	end
end)

net.Receive("DarkRP.Characters.OpenMenu", function()
	DarkRP.Characters.UI.OpenMenu()
end)

net.Receive("DarkRP.Characters.Notify", function()
	local message = net.ReadString()
	local isError = net.ReadBool()
	
	chat.AddText(
		isError and Color(231, 76, 60) or Color(46, 204, 113),
		"[Characters] ",
		Color(255, 255, 255),
		message
	)
end)

net.Receive("DarkRP.Characters.Updated", function()
	if IsValid(DarkRP.Characters.UI.activeFrame) then
		net.Start("DarkRP.Characters.RequestList")
		net.SendToServer()
	end
end)

print("[DarkRP] Character system (client) loaded")
