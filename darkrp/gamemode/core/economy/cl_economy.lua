-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Economy System - Client
--  Client-side economy interface and notifications
-- ═══════════════════════════════════════════════════════════════════════════

if SERVER then return end

-- Initialize namespace (in case shared file hasn't loaded yet)
DarkRP = DarkRP or {}
DarkRP.Economy = DarkRP.Economy or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Handlers                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Economy.Notify", function()
	local message = net.ReadString()
	local isError = net.ReadBool()
	
	chat.AddText(
		isError and Color(231, 76, 60) or Color(46, 204, 113),
		"[Economy] ",
		Color(255, 255, 255),
		message
	)
	
	if isError then
		surface.PlaySound("buttons/button10.wav")
	else
		surface.PlaySound("buttons/button14.wav")
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Money Transfer Menu                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.OpenTransferMenu()
	local frame = vgui.Create("DFrame")
	frame:SetSize(400, 200)
	frame:Center()
	frame:SetTitle("Transfer Money")
	frame:SetVisible(true)
	frame:SetDraggable(true)
	frame:ShowCloseButton(true)
	frame:MakePopup()
	
	local ply = LocalPlayer()
	
	-- Info label
	local infoLabel = vgui.Create("DLabel", frame)
	infoLabel:SetPos(20, 35)
	infoLabel:SetSize(360, 20)
	infoLabel:SetText("Your Balance: " .. DarkRP.Economy.FormatMoney(ply:GetMoney()))
	infoLabel:SetTextColor(Color(255, 255, 255))
	
	-- Target player label
	local targetLabel = vgui.Create("DLabel", frame)
	targetLabel:SetPos(20, 65)
	targetLabel:SetSize(100, 20)
	targetLabel:SetText("Player Name:")
	
	-- Target player entry
	local targetEntry = vgui.Create("DTextEntry", frame)
	targetEntry:SetPos(130, 60)
	targetEntry:SetSize(250, 30)
	targetEntry:SetPlaceholderText("Enter player name...")
	
	-- Amount label
	local amountLabel = vgui.Create("DLabel", frame)
	amountLabel:SetPos(20, 105)
	amountLabel:SetSize(100, 20)
	amountLabel:SetText("Amount:")
	
	-- Amount entry
	local amountEntry = vgui.Create("DTextEntry", frame)
	amountEntry:SetPos(130, 100)
	amountEntry:SetSize(250, 30)
	amountEntry:SetPlaceholderText("Enter amount...")
	amountEntry:SetNumeric(true)
	
	-- Transfer button
	local transferBtn = vgui.Create("DButton", frame)
	transferBtn:SetPos(20, 150)
	transferBtn:SetSize(360, 35)
	transferBtn:SetText("Transfer Money")
	transferBtn.DoClick = function()
		local targetName = targetEntry:GetValue()
		local amount = tonumber(amountEntry:GetValue())
		
		if not targetName or targetName == "" then
			chat.AddText(Color(231, 76, 60), "[Economy] ", Color(255, 255, 255), "Please enter a player name")
			return
		end
		
		if not amount or amount <= 0 then
			chat.AddText(Color(231, 76, 60), "[Economy] ", Color(255, 255, 255), "Please enter a valid amount")
			return
		end
		
		net.Start("DarkRP.Economy.Transfer")
			net.WriteString(targetName)
			net.WriteInt(amount, 32)
		net.SendToServer()
		
		frame:Close()
	end
	
	-- Style the frame
	frame.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, Color(25, 25, 35, 250))
		draw.RoundedBox(4, 0, 0, w, 25, Color(52, 152, 219, 255))
	end
	
	transferBtn.Paint = function(self, w, h)
		local col = self:IsHovered() and Color(41, 128, 185, 255) or Color(52, 152, 219, 255)
		draw.RoundedBox(4, 0, 0, w, h, col)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Client Menu Bind                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

concommand.Add("darkrp_transfermoney", function()
	DarkRP.Economy.OpenTransferMenu()
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Meta Functions (Client)                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMoney()
	-- Use character system if available
	if DarkRP.Characters and DarkRP.Characters.UI and DarkRP.Characters.UI.characters then
		-- Find active character for this player
		for _, char in ipairs(DarkRP.Characters.UI.characters) do
			if char.isActive then
				return char.money or 0
			end
		end
	end
	
	return self:GetNWInt("DarkRP.Money", 0)
end

function PLAYER:CanAfford(amount)
	return self:GetMoney() >= amount
end

-- Commands are handled by PAS chat command system
-- Use: !balance, !money, !pay <player> <amount>, etc.

print("[DarkRP] Economy system (client) loaded")
