-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Character System - Client (Fullscreen Minimal UI)
--  Professional character selection using PANTHEON UI system
-- ═══════════════════════════════════════════════════════════════════════════

print("[DarkRP] Loading character system (client)...")

DarkRP = DarkRP or {}
DarkRP.Characters = DarkRP.Characters or {}
DarkRP.Characters.UI = {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Data Storage                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Characters.UI.characters = {}
DarkRP.Characters.UI.activeFrame = nil
DarkRP.Characters.UI.selectedChar = nil

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Fonts                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

surface.CreateFont("DRP.Char.Title", {
	font = "Funnel Sans",
	size = 72,
	weight = 200,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Subtitle", {
	font = "Funnel Sans",
	size = 24,
	weight = 300,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Name", {
	font = "Funnel Sans",
	size = 32,
	weight = 600,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Info", {
	font = "Funnel Sans",
	size = 16,
	weight = 400,
	extended = true,
	antialias = true
})

surface.CreateFont("DRP.Char.Label", {
	font = "Funnel Sans",
	size = 14,
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
	self.CamPos = Vector(-80, 0, 50)
	self.LookAt = Vector(0, 0, 35)
	self.FOV = 35
	self.TargetRotation = 180
	self.CurrentRotation = 180
	self.AutoRotate = true
	self.RotateSpeed = 0.3
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
			render.SetModelLighting(0, 0.6, 0.6, 0.7) -- Front
			render.SetModelLighting(1, 0.2, 0.2, 0.3) -- Back
			render.SetModelLighting(2, 0.4, 0.4, 0.5) -- Left
			render.SetModelLighting(3, 0.4, 0.4, 0.5) -- Right
			render.SetModelLighting(4, 0.5, 0.5, 0.6) -- Top
			render.SetModelLighting(5, 0.1, 0.1, 0.2) -- Bottom
			
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
-- ║  Main Fullscreen Character Selection                         ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Characters.UI.OpenMenu()
	-- Wait for UI system
	if not ui or not ui.col then
		timer.Simple(0.5, function() DarkRP.Characters.UI.OpenMenu() end)
		return
	end
	
	if IsValid(DarkRP.Characters.UI.activeFrame) then
		DarkRP.Characters.UI.activeFrame:Remove()
	end
	
	local scrW, scrH = ScrW(), ScrH()
	
	-- Fullscreen container
	local frame = vgui.Create("DFrame")
	frame:SetSize(scrW, scrH)
	frame:SetPos(0, 0)
	frame:SetTitle("")
	frame:SetDraggable(false)
	frame:ShowCloseButton(false)
	frame:MakePopup()
	
	DarkRP.Characters.UI.activeFrame = frame
	
	-- Get the single character or detect if we need to create one
	local char = nil
	if #DarkRP.Characters.UI.characters > 0 then
		char = DarkRP.Characters.UI.characters[1]
	end
	
	DarkRP.Characters.UI.selectedChar = char
	
	-- Animation values
	frame.FadeIn = 0
	frame.StartTime = SysTime()
	
	frame.Paint = function(self, w, h)
		-- Animated fade in
		self.FadeIn = math.min(1, (SysTime() - self.StartTime) * 2)
		local alpha = 255 * self.FadeIn
		
		-- Dark gradient background
		surface.SetDrawColor(12, 12, 15, alpha)
		surface.DrawRect(0, 0, w, h)
		
		-- Subtle gradient overlay
		draw.RoundedBox(0, 0, 0, w, h * 0.4, ColorAlpha(Color(0, 0, 0), 60 * self.FadeIn))
		
		-- Purple accent glow (top)
		draw.RoundedBox(0, 0, 0, w, 3, ColorAlpha(ui.col.PANTHEON, alpha))
		
		-- Title section (centered top)
		local title = char and "WELCOME BACK" or "CREATE CHARACTER"
		draw.SimpleText(title, "DRP.Char.Title", w / 2, h * 0.15, ColorAlpha(ui.col.White, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Center panel: Character display
	local mainPanel = vgui.Create("DPanel", frame)
	mainPanel:SetSize(scrW * 0.5, scrH * 0.55)
	mainPanel:SetPos((scrW - scrW * 0.5) / 2, scrH * 0.28)
	mainPanel.Paint = function(self, w, h)
		-- Background
		draw.RoundedBox(12, 0, 0, w, h, ColorAlpha(Color(20, 20, 25), 200 * frame.FadeIn))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 30 * frame.FadeIn)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	
	-- Model preview (top section)
	local modelPanel = vgui.Create("DRP_CharModel", mainPanel)
	modelPanel:SetSize(mainPanel:GetWide(), mainPanel:GetTall() * 0.7)
	modelPanel:SetPos(0, 0)
	
	if char then
		modelPanel:SetModel(char.model)
	end
	
	-- Character info panel (bottom section)
	local infoPanel = vgui.Create("DPanel", mainPanel)
	infoPanel:SetSize(mainPanel:GetWide(), mainPanel:GetTall() * 0.3)
	infoPanel:SetPos(0, mainPanel:GetTall() * 0.7)
	infoPanel.Paint = function(self, w, h)
		-- Dark separator
		surface.SetDrawColor(40, 40, 45, 200 * frame.FadeIn)
		surface.DrawRect(0, 0, w, 1)
		
		if not char then
			-- No character - show creation prompt
			draw.SimpleText("Create your character to begin", "DRP.Char.Info", w / 2, h / 2, ColorAlpha(ui.col.TEXT_DIM, 200 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end
		
		local yPos = 20
		
		-- Character name
		draw.SimpleText(char.name, "DRP.Char.Name", w / 2, yPos, ColorAlpha(ui.col.White, 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		yPos = yPos + 40
		
		-- Stats grid
		local statW = w / 3
		local statX1 = statW / 2
		local statX2 = w / 2
		local statX3 = w - statW / 2
		
		-- Wallet
		draw.SimpleText("WALLET", "DRP.Char.Label", statX1, yPos, ColorAlpha(ui.col.TEXT_DIM, 200 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("$" .. string.Comma(char.money), "DRP.Char.Info", statX1, yPos + 18, ColorAlpha(ui.col.PANTHEON_LIGHT, 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		-- Bank
		draw.SimpleText("BANK", "DRP.Char.Label", statX2, yPos, ColorAlpha(ui.col.TEXT_DIM, 200 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("$" .. string.Comma(char.bankMoney), "DRP.Char.Info", statX2, yPos + 18, ColorAlpha(ui.col.PANTHEON_LIGHT, 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		
		-- Playtime
		draw.SimpleText("PLAYTIME", "DRP.Char.Label", statX3, yPos, ColorAlpha(ui.col.TEXT_DIM, 200 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText(DarkRP.Characters.FormatPlaytime(char.playtime), "DRP.Char.Info", statX3, yPos + 18, ColorAlpha(Color(100, 200, 255), 255 * frame.FadeIn), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end
	
	-- Bottom action buttons (centered)
	local btnPanel = vgui.Create("DPanel", frame)
	btnPanel:SetSize(char and 450 or 350, 60)
	btnPanel:SetPos((scrW - (char and 450 or 350)) / 2, scrH * 0.88)
	btnPanel.Paint = function() end
	
	if char then
		-- Play button (character exists)
		local playBtn = vgui.Create("DButton", btnPanel)
		playBtn:SetSize(char.isActive and 450 or 220, 60)
		playBtn:SetPos(0, 0)
		playBtn:SetText("")
		playBtn.Hover = 0
	
	playBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
		
		local col = ColorAlpha(ui.col.PANTHEON, 200 + self.Hover * 55)
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		if self.Hover > 0 then
			draw.RoundedBox(8, 0, 0, w, h, ColorAlpha(ui.col.White, 10 * self.Hover))
		end
		
		local txt = "PLAY"
		if DarkRP.Characters.UI.selectedChar and DarkRP.Characters.UI.selectedChar.isActive then
			txt = "CURRENTLY PLAYING"
		end
		
		draw.SimpleText(txt, "DRP.Char.Info", w / 2, h / 2, ui.col.White, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	playBtn.DoClick = function()
		if not DarkRP.Characters.UI.selectedChar then return end
		if DarkRP.Characters.UI.selectedChar.isActive then return end
		
		net.Start("DarkRP.Characters.Select")
			net.WriteUInt(DarkRP.Characters.UI.selectedChar.id, 32)
		net.SendToServer()
		
		frame:Remove()
	end
	
	-- Create character button
	local canCreate = #DarkRP.Characters.UI.characters < DarkRP.Characters.Config.maxCharacters
	
	local createBtn = vgui.Create("DButton", btnPanel)
	createBtn:SetSize(300, 60)
	createBtn:SetPos(320, 5)
	createBtn:SetText("")
	createBtn.Hover = 0
	createBtn:SetEnabled(canCreate)
	
	createBtn.Paint = function(self, w, h)
		self.Hover = Lerp(FrameTime() * 8, self.Hover, (self:IsHovered() and canCreate) and 1 or 0)
		
		local col = canCreate and ColorAlpha(Color(40, 40, 50), 200 + self.Hover * 55) or ColorAlpha(Color(30, 30, 35), 100)
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, canCreate and (60 + self.Hover * 100) or 20)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		local txtCol = canCreate and ui.col.White or ui.col.TEXT_DIM
		draw.SimpleText("+ NEW CHARACTER", "DRP.Char.Info", w / 2, h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	createBtn.DoClick = function()
		if not canCreate then return end
		frame:Remove()
		DarkRP.Characters.UI.OpenCreationMenu()
	end
	
	-- Delete button (only if character selected and not active)
	local deleteBtn = vgui.Create("DButton", btnPanel)
	deleteBtn:SetSize(250, 60)
	deleteBtn:SetPos(640, 5)
	deleteBtn:SetText("")
	deleteBtn.Hover = 0
	
	deleteBtn.Paint = function(self, w, h)
		local canDelete = DarkRP.Characters.UI.selectedChar and not DarkRP.Characters.UI.selectedChar.isActive and DarkRP.Characters.Config.allowDeletion
		
		self.Hover = Lerp(FrameTime() * 8, self.Hover, (self:IsHovered() and canDelete) and 1 or 0)
		
		local col = canDelete and ColorAlpha(Color(60, 30, 30), 150 + self.Hover * 105) or ColorAlpha(Color(30, 30, 35), 100)
		draw.RoundedBox(8, 0, 0, w, h, col)
		
		local borderCol = canDelete and Color(200, 80, 80) or Color(50, 50, 55)
		surface.SetDrawColor(borderCol.r, borderCol.g, borderCol.b, canDelete and (60 + self.Hover * 100) or 20)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		local txtCol = canDelete and (self.Hover > 0.5 and Color(255, 120, 120) or ui.col.White) or ui.col.TEXT_DIM
		draw.SimpleText("DELETE", "DRP.Char.Info", w / 2, h / 2, txtCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	deleteBtn.DoClick = function()
		if not DarkRP.Characters.UI.selectedChar then return end
		if DarkRP.Characters.UI.selectedChar.isActive then return end
		if not DarkRP.Characters.Config.allowDeletion then return end
		
		local char = DarkRP.Characters.UI.selectedChar
		
		Derma_Query(
			"Delete character '" .. char.name .. "'?\n\nThis action cannot be undone.",
			"Confirm Deletion",
			"Delete",
			function()
				net.Start("DarkRP.Characters.Delete")
					net.WriteUInt(char.id, 32)
				net.SendToServer()
			end,
			"Cancel"
		)
	end
	
	-- Cancel/Close button (only if has active character)
	local hasActiveChar = false
	for _, char in ipairs(DarkRP.Characters.UI.characters) do
		if char.isActive then
			hasActiveChar = true
			break
		end
	end
	
	if hasActiveChar then
		local closeBtn = vgui.Create("DButton", btnPanel)
		closeBtn:SetSize(200, 60)
		closeBtn:SetPos(btnPanel:GetWide() - 200, 5)
		closeBtn:SetText("")
		closeBtn.Hover = 0
		
		closeBtn.Paint = function(self, w, h)
			self.Hover = Lerp(FrameTime() * 8, self.Hover, self:IsHovered() and 1 or 0)
			
			local col = ColorAlpha(Color(30, 30, 35), 150 + self.Hover * 50)
			draw.RoundedBox(8, 0, 0, w, h, col)
			
			surface.SetDrawColor(ui.col.TEXT_DIM.r, ui.col.TEXT_DIM.g, ui.col.TEXT_DIM.b, 60 + self.Hover * 100)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			
			draw.SimpleText("CANCEL", "DRP.Char.Info", w / 2, h / 2, ui.col.TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		
		closeBtn.DoClick = function()
			frame:Remove()
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
		
		-- Background
		surface.SetDrawColor(12, 12, 15, alpha)
		surface.DrawRect(0, 0, w, h)
		
		draw.RoundedBox(0, 0, 0, w, 3, ColorAlpha(ui.col.PANTHEON, alpha))
		
		-- Title
		draw.SimpleText("CREATE CHARACTER", "DRP.Char.Title", w / 2, h * 0.12, ColorAlpha(ui.col.White, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Customize your new character", "DRP.Char.Subtitle", w / 2, h * 0.16, ColorAlpha(ui.col.TEXT_DIM, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	
	-- Center content panel
	local contentW = scrW * 0.7
	local contentH = scrH * 0.6
	local contentX = (scrW - contentW) / 2
	local contentY = scrH * 0.24
	
	local content = vgui.Create("DPanel", frame)
	content:SetSize(contentW, contentH)
	content:SetPos(contentX, contentY)
	content.Paint = function(self, w, h)
		draw.RoundedBox(12, 0, 0, w, h, ColorAlpha(Color(20, 20, 25), 200 * frame.FadeIn))
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 30 * frame.FadeIn)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	
	-- Model preview (left side)
	local modelPanel = vgui.Create("DRP_CharModel", content)
	modelPanel:SetSize(contentW * 0.45, contentH)
	modelPanel:SetPos(0, 0)
	
	local selectedModel = DarkRP.Characters.Config.maleModels[1]
	local selectedGender = "male"
	modelPanel:SetModel(selectedModel)
	
	-- Customization panel (right side)
	local customPanel = vgui.Create("DPanel", content)
	customPanel:SetSize(contentW * 0.52, contentH)
	customPanel:SetPos(contentW * 0.48, 0)
	customPanel.Paint = function() end
	
	-- Scrollable content
	local scroll = vgui.Create("DScrollPanel", customPanel)
	scroll:Dock(FILL)
	scroll:DockMargin(30, 30, 30, 30)
	
	local sbar = scroll:GetVBar()
	sbar:SetWide(6)
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
	nameLabel:SetTall(25)
	nameLabel:SetFont("DRP.Char.Info")
	nameLabel:SetText("CHARACTER NAME")
	nameLabel:SetTextColor(ui.col.White)
	
	local nameEntry = vgui.Create("DTextEntry", scroll)
	nameEntry:Dock(TOP)
	nameEntry:DockMargin(0, 10, 0, 30)
	nameEntry:SetTall(45)
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
	genderLabel:SetTall(25)
	genderLabel:SetFont("DRP.Char.Info")
	genderLabel:SetText("GENDER")
	genderLabel:SetTextColor(ui.col.White)
	
	local genderPanel = vgui.Create("DPanel", scroll)
	genderPanel:Dock(TOP)
	genderPanel:DockMargin(0, 10, 0, 30)
	genderPanel:SetTall(50)
	genderPanel.Paint = function() end
	
	local maleBtn = vgui.Create("DButton", genderPanel)
	maleBtn:SetSize((genderPanel:GetWide() - 10) / 2, 50)
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
	femaleBtn:SetSize((genderPanel:GetWide() - 10) / 2, 50)
	femaleBtn:SetPos((genderPanel:GetWide() + 10) / 2, 0)
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
	modelLabel:SetTall(25)
	modelLabel:SetFont("DRP.Char.Info")
	modelLabel:SetText("MODEL")
	modelLabel:SetTextColor(ui.col.White)
	
	local modelGrid = vgui.Create("DGrid", scroll)
	modelGrid:Dock(TOP)
	modelGrid:DockMargin(0, 10, 0, 0)
	modelGrid:SetCols(3)
	modelGrid:SetColWide(100)
	modelGrid:SetRowHeight(100)
	
	local function PopulateModels()
		modelGrid:Clear()
		
		local models = selectedGender == "male" and DarkRP.Characters.Config.maleModels or DarkRP.Characters.Config.femaleModels
		
		for _, mdl in ipairs(models) do
			local btn = vgui.Create("DButton")
			btn:SetSize(95, 95)
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
			icon:DockMargin(3, 3, 3, 3)
			
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
	btnPanel:SetSize(scrW * 0.7, 70)
	btnPanel:SetPos((scrW - scrW * 0.7) / 2, scrH * 0.88)
	btnPanel.Paint = function() end
	
	-- Create button
	local createBtn = vgui.Create("DButton", btnPanel)
	createBtn:SetSize(350, 60)
	createBtn:SetPos(0, 5)
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
	
	-- Cancel button
	local cancelBtn = vgui.Create("DButton", btnPanel)
	cancelBtn:SetSize(350, 60)
	cancelBtn:SetPos(btnPanel:GetWide() - 350, 5)
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
	local characters = {}
	
	for i = 1, count do
		table.insert(characters, {
			id = net.ReadUInt(32),
			name = net.ReadString(),
			model = net.ReadString(),
			money = net.ReadUInt(32),
			bankMoney = net.ReadUInt(32),
			jobID = net.ReadUInt(16),
			playtime = net.ReadUInt(32),
			isActive = net.ReadBool()
		})
	end
	
	DarkRP.Characters.UI.characters = characters
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
