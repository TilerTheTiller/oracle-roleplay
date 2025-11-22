-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP ATM Entity - Client
--  ATM interface using PANTHEON UI framework
-- ═══════════════════════════════════════════════════════════════════════════

include("shared.lua")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Drawing                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:Draw()
	self:DrawModel()
	
	-- Draw 3D2D text above ATM
	local pos = self:GetPos() + self:GetUp() * 50
	local ang = self:GetAngles()
	
	ang:RotateAroundAxis(ang:Up(), 90)
	ang:RotateAroundAxis(ang:Forward(), 90)
	
	cam.Start3D2D(pos, ang, 0.1)
		draw.SimpleText("ATM", "DermaLarge", 0, 0, Color(138, 43, 226), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
		local inUse = self:GetNWBool("ATM.InUse", false)
		if inUse then
			draw.SimpleText("IN USE", "DermaDefault", 0, 40, Color(244, 67, 54), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Press E to use", "DermaDefault", 0, 40, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	cam.End3D2D()
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  ATM Interface (PANTHEON UI)                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

local ATMFrame = nil
local CurrentATM = nil

function OpenATMInterface(atm)
	if IsValid(ATMFrame) then
		ATMFrame:Remove()
	end
	
	if not IsValid(atm) then return end
	
	CurrentATM = atm
	
	-- Create main frame using PANTHEON UI
	ATMFrame = ui.components.CreateFrame("Bank ATM", 550, 500, "money")
	
	ATMFrame.OnClose = function()
		if IsValid(CurrentATM) then
			net.Start("DarkRP.ATM.Close")
				net.WriteEntity(CurrentATM)
			net.SendToServer()
		end
		CurrentATM = nil
		timer.Remove("ATM.UpdateBalance")
	end
	
	-- Override close button action
	ATMFrame.CloseButton.DoClick = function(self)
		self.ClickAnimation = 1
		ui.Animate(ATMFrame, "OpenAnimation", 0, 0.2, ui.easings.easeInCubic, function()
			ATMFrame:Close()
		end)
	end
	
	-- ═══════════════════════════════════════════════════════════
	-- Balance Display Panel
	-- ═══════════════════════════════════════════════════════════
	
	local balancePanel = ui.components.CreatePanel(ATMFrame, 10, 44, 530, 120, nil, nil)
	balancePanel.Paint = function(self, w, h)
		-- Blurred background
		draw.BlurredPanel(self, 6, Color(24, 24, 28), 245)
		
		-- Gradient overlay
		surface.SetDrawColor(ui.col.PANTHEON.r, ui.col.PANTHEON.g, ui.col.PANTHEON.b, 20)
		surface.DrawRect(0, 0, w, h)
		
		-- Border
		surface.SetDrawColor(ui.col.Outline.r, ui.col.Outline.g, ui.col.Outline.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		-- Title
		draw.SimpleText("Account Overview", 'PANTHEON.18', 20, 15, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	-- Bank Balance
	local bankLabel = vgui.Create("DLabel", balancePanel)
	bankLabel:SetPos(20, 45)
	bankLabel:SetSize(250, 25)
	bankLabel:SetFont("PANTHEON.16")
	bankLabel:SetText("Bank Balance:")
	bankLabel:SetTextColor(ui.col.TEXT_DIM)
	
	local bankAmount = vgui.Create("DLabel", balancePanel)
	bankAmount:SetPos(20, 70)
	bankAmount:SetSize(250, 30)
	bankAmount:SetFont("PANTHEON.24")
	bankAmount:SetText(DarkRP.Economy.FormatMoney(LocalPlayer():GetBankMoney()))
	bankAmount:SetTextColor(ui.col.Green)
	
	-- Wallet Balance
	local walletLabel = vgui.Create("DLabel", balancePanel)
	walletLabel:SetPos(280, 45)
	walletLabel:SetSize(230, 25)
	walletLabel:SetFont("PANTHEON.16")
	walletLabel:SetText("Wallet:")
	walletLabel:SetTextColor(ui.col.TEXT_DIM)
	
	local walletAmount = vgui.Create("DLabel", balancePanel)
	walletAmount:SetPos(280, 70)
	walletAmount:SetSize(230, 30)
	walletAmount:SetFont("PANTHEON.24")
	walletAmount:SetText(DarkRP.Economy.FormatMoney(LocalPlayer():GetMoney()))
	walletAmount:SetTextColor(ui.col.Blue)
	
	-- Update balances periodically
	timer.Create("ATM.UpdateBalance", 0.5, 0, function()
		if IsValid(bankAmount) and IsValid(walletAmount) and IsValid(LocalPlayer()) then
			bankAmount:SetText(DarkRP.Economy.FormatMoney(LocalPlayer():GetBankMoney()))
			walletAmount:SetText(DarkRP.Economy.FormatMoney(LocalPlayer():GetMoney()))
		else
			timer.Remove("ATM.UpdateBalance")
		end
	end)
	
	-- ═══════════════════════════════════════════════════════════
	-- Withdraw Section
	-- ═══════════════════════════════════════════════════════════
	
	local withdrawPanel = ui.components.CreatePanel(ATMFrame, 10, 174, 530, 140, nil, nil)
	withdrawPanel.Paint = function(self, w, h)
		draw.BlurredPanel(self, 6, Color(24, 24, 28), 245)
		surface.SetDrawColor(ui.col.Outline.r, ui.col.Outline.g, ui.col.Outline.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		-- Title with icon
		draw.SimpleText("Withdraw from Bank", 'PANTHEON.18', 20, 15, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	local withdrawEntry = ui.components.CreateTextEntry(withdrawPanel, 20, 50, 390, 40, "Enter amount to withdraw...")
	withdrawEntry:SetNumeric(true)
	
	local withdrawBtn = ui.components.CreateButton(withdrawPanel, "Withdraw", 420, 50, 90, 40, function()
		local amount = tonumber(withdrawEntry:GetValue())
		if not amount or amount <= 0 then
			chat.AddText(ui.col.Red, "[ATM] ", ui.col.White, "Invalid amount")
			surface.PlaySound("buttons/button10.wav")
			return
		end
		
		net.Start("DarkRP.ATM.Withdraw")
			net.WriteEntity(atm)
			net.WriteInt(amount, 32)
		net.SendToServer()
		
		withdrawEntry:SetText("")
		surface.PlaySound("ui/buttonclick.wav")
	end, nil, "success")
	
	-- Quick withdraw buttons
	local quickAmounts = {50, 100, 500, 1000}
	for i, amount in ipairs(quickAmounts) do
		local btn = ui.components.CreateButton(
			withdrawPanel, 
			DarkRP.Economy.FormatMoney(amount), 
			20 + (i - 1) * 127, 
			100, 
			120, 
			30,
			function()
				net.Start("DarkRP.ATM.Withdraw")
					net.WriteEntity(atm)
					net.WriteInt(amount, 32)
				net.SendToServer()
				surface.PlaySound("ui/buttonclick.wav")
			end,
			nil,
			"primary"
		)
	end
	
	-- ═══════════════════════════════════════════════════════════
	-- Deposit Section
	-- ═══════════════════════════════════════════════════════════
	
	local depositPanel = ui.components.CreatePanel(ATMFrame, 10, 324, 530, 100, nil, nil)
	depositPanel.Paint = function(self, w, h)
		draw.BlurredPanel(self, 6, Color(24, 24, 28), 245)
		surface.SetDrawColor(ui.col.Outline.r, ui.col.Outline.g, ui.col.Outline.b, 100)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		
		draw.SimpleText("Deposit to Bank", 'PANTHEON.18', 20, 15, ui.col.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	
	local depositEntry = ui.components.CreateTextEntry(depositPanel, 20, 50, 390, 40, "Enter amount to deposit...")
	depositEntry:SetNumeric(true)
	
	local depositBtn = ui.components.CreateButton(depositPanel, "Deposit", 420, 50, 90, 40, function()
		local amount = tonumber(depositEntry:GetValue())
		if not amount or amount <= 0 then
			chat.AddText(ui.col.Red, "[ATM] ", ui.col.White, "Invalid amount")
			surface.PlaySound("buttons/button10.wav")
			return
		end
		
		net.Start("DarkRP.ATM.Deposit")
			net.WriteEntity(atm)
			net.WriteInt(amount, 32)
		net.SendToServer()
		
		depositEntry:SetText("")
		surface.PlaySound("ui/buttonclick.wav")
	end, nil, "primary")
	
	-- ═══════════════════════════════════════════════════════════
	-- Close Button
	-- ═══════════════════════════════════════════════════════════
	
	local closeBtn = ui.components.CreateButton(ATMFrame, "Close", 10, 434, 530, 40, function()
		ATMFrame:Close()
	end, nil, "danger")
end

function CloseATMInterface()
	if IsValid(ATMFrame) then
		ATMFrame:Close()
	end
	
	timer.Remove("ATM.UpdateBalance")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Handlers                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.ATM.Open", function()
	local atm = net.ReadEntity()
	
	timer.Simple(0.1, function()
		if IsValid(atm) then
			OpenATMInterface(atm)
		end
	end)
end)

net.Receive("DarkRP.ATM.ForceClose", function()
	CloseATMInterface()
	chat.AddText(ui.col.Yellow, "[ATM] ", ui.col.White, "You moved too far away from the ATM")
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("OnPlayerChat", "DarkRP.ATM.CloseOnChat", function(ply, text)
	if ply == LocalPlayer() and string.lower(text) == "!closeatm" then
		CloseATMInterface()
		return true
	end
end)
