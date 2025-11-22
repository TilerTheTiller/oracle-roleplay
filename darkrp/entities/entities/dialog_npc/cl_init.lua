include("shared.lua")

-- Receive dialog open request
net.Receive("DialogNPC.OpenDialog", function()
	local npc = net.ReadEntity()
	local dialogID = net.ReadString()
	local npcName = net.ReadString()
	
	if not IsValid(npc) then return end
	
	-- Get the dialog configuration
	local dialog = DialogNPC.Dialogs[dialogID]
	if not dialog then
		chat.AddText(Color(255, 100, 100), "[Dialog NPC] Dialog ID '" .. dialogID .. "' not found!")
		return
	end
	
	-- Create the dialog UI
	DialogNPC.OpenDialogUI(npc, dialog, npcName)
end)

function DialogNPC.OpenDialogUI(npc, dialog, npcName)
	-- Close existing dialog if any
	if IsValid(DialogNPC.ActiveFrame) then
		DialogNPC.ActiveFrame:Remove()
	end
	
	local scrW, scrH = ScrW(), ScrH()
	local width, height = 600, 400
	
	local frame = vgui.Create("DFrame")
	frame:SetSize(width, height)
	frame:Center()
	frame:SetTitle("")
	frame:SetDraggable(true)
	frame:ShowCloseButton(true)
	frame:MakePopup()
	frame.Paint = function(self, w, h)
		-- Background
		draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 35, 250))
		
		-- Header
		draw.RoundedBoxEx(8, 0, 0, w, 40, Color(41, 128, 185, 255), true, true, false, false)
		
		-- Title
		draw.SimpleText(npcName, "DermaLarge", w/2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		-- Border
		surface.SetDrawColor(41, 128, 185, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2)
	end
	
	DialogNPC.ActiveFrame = frame
	
	-- NPC Text panel
	local textPanel = vgui.Create("DPanel", frame)
	textPanel:Dock(TOP)
	textPanel:SetTall(150)
	textPanel:DockMargin(10, 50, 10, 10)
	textPanel.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(20, 20, 25, 200))
		
		-- Draw dialog text
		local text = dialog.text or "..."
		draw.DrawText(text, "DermaDefault", 10, 10, Color(220, 220, 220), TEXT_ALIGN_LEFT)
	end
	
	-- Options scroll panel
	local scrollPanel = vgui.Create("DScrollPanel", frame)
	scrollPanel:Dock(FILL)
	scrollPanel:DockMargin(10, 0, 10, 10)
	
	-- Add options
	if dialog.options then
		for i, option in ipairs(dialog.options) do
			local optBtn = vgui.Create("DButton", scrollPanel)
			optBtn:Dock(TOP)
			optBtn:SetTall(40)
			optBtn:DockMargin(0, 0, 0, 5)
			optBtn:SetText("")
			
			local hovered = false
			optBtn.Paint = function(self, w, h)
				local col = hovered and Color(41, 128, 185, 255) or Color(50, 50, 60, 255)
				draw.RoundedBox(4, 0, 0, w, h, col)
				
				-- Option text
				draw.SimpleText(option.text, "DermaDefault", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
			
			optBtn.OnCursorEntered = function(self)
				hovered = true
			end
			
			optBtn.OnCursorExited = function(self)
				hovered = false
			end
			
			optBtn.DoClick = function(self)
				-- Send selection to server if there's an action
				if option.action then
					net.Start("DialogNPC.SelectOption")
						net.WriteEntity(npc)
						net.WriteString(dialog.id or "")
						net.WriteString(option.id or "")
					net.SendToServer()
				end
				
				-- Handle dialog chaining
				if option.nextDialog then
					local nextDialog = DialogNPC.Dialogs[option.nextDialog]
					if nextDialog then
						timer.Simple(0.1, function()
							if IsValid(frame) then
								DialogNPC.OpenDialogUI(npc, nextDialog, npcName)
							end
						end)
					end
				else
					-- Close dialog if no next dialog
					frame:Close()
				end
			end
		end
	end
	
	-- Close button
	local closeBtn = vgui.Create("DButton", frame)
	closeBtn:SetText("Close")
	closeBtn:Dock(BOTTOM)
	closeBtn:SetTall(35)
	closeBtn:DockMargin(10, 0, 10, 10)
	closeBtn.Paint = function(self, w, h)
		local col = self:IsHovered() and Color(200, 50, 50, 255) or Color(60, 60, 70, 255)
		draw.RoundedBox(4, 0, 0, w, h, col)
		draw.SimpleText("Close", "DermaDefault", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = function()
		frame:Close()
	end
end

function ENT:Draw()
	self:DrawModel()
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Draw name above NPC
	local pos = self:GetPos() + Vector(0, 0, 75)
	local ang = (ply:GetPos() - pos):Angle()
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	
	local dist = ply:GetPos():Distance(self:GetPos())
	if dist > 500 then return end
	
	cam.Start3D2D(pos, ang, 0.1)
		-- Background
		draw.RoundedBox(4, -100, -20, 200, 40, Color(30, 30, 35, 200))
		
		-- Name
		draw.SimpleText(self:GetNPCName(), "DermaLarge", 0, 0, Color(41, 128, 185), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		-- Interaction hint
		if dist <= self.UseDistance then
			draw.SimpleText("Press E to talk", "DermaDefault", 0, 15, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end
