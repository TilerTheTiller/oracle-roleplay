-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP ATM Entity - Server
--  Bank ATM for withdrawing and depositing money
-- ═══════════════════════════════════════════════════════════════════════════

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:EnableMotion(false)
	end
	
	-- ATM state
	self:SetNWBool("ATM.InUse", false)
	self:SetNWEntity("ATM.User", NULL)
	
	print("[DarkRP] ATM spawned at " .. tostring(self:GetPos()))
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Usage                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:Use(activator, caller)
	if not IsValid(caller) or not caller:IsPlayer() then return end
	
	-- Check if ATM is already in use
	if self:GetNWBool("ATM.InUse", false) then
		local currentUser = self:GetNWEntity("ATM.User", NULL)
		if IsValid(currentUser) and currentUser ~= caller then
			DarkRP.Economy.NotifyPlayer(caller, "ATM is currently in use", true)
			return
		end
	end
	
	-- Check distance
	if self:GetPos():Distance(caller:GetPos()) > 100 then
		DarkRP.Economy.NotifyPlayer(caller, "You are too far from the ATM", true)
		return
	end
	
	-- Mark as in use
	self:SetNWBool("ATM.InUse", true)
	self:SetNWEntity("ATM.User", caller)
	
	-- Open ATM interface
	net.Start("DarkRP.ATM.Open")
		net.WriteEntity(self)
	net.Send(caller)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  ATM Operations                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:Withdraw(ply, amount)
	if not IsValid(ply) then return false, "Invalid player" end
	if not self:CanPlayerUse(ply) then return false, "You cannot use this ATM" end
	
	-- Validate amount
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then return false, err end
	
	if amount <= 0 then
		return false, "Withdrawal amount must be positive"
	end
	
	-- Check bank balance
	local bankBalance = ply:GetBankMoney()
	if bankBalance < amount then
		return false, "Insufficient bank balance"
	end
	
	-- Withdraw from bank and add to wallet
	ply:TakeBankMoney(amount)
	local success = ply:AddMoney(amount, "ATM Withdrawal", true)
	
	if success then
		DarkRP.Economy.NotifyPlayer(ply, "Withdrew " .. DarkRP.Economy.FormatMoney(amount))
		DarkRP.Economy.LogTransaction(ply, amount, "ATM Withdrawal", "atm_withdrawal")
		
		hook.Call("DarkRP.ATM.Withdrawal", nil, ply, self, amount)
		return true, "Withdrawal successful"
	end
	
	return false, "Withdrawal failed"
end

function ENT:Deposit(ply, amount)
	if not IsValid(ply) then return false, "Invalid player" end
	if not self:CanPlayerUse(ply) then return false, "You cannot use this ATM" end
	
	-- Validate amount
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then return false, err end
	
	if amount <= 0 then
		return false, "Deposit amount must be positive"
	end
	
	-- Check if player has the money in wallet
	if not ply:CanAfford(amount) then
		return false, "Insufficient funds in wallet"
	end
	
	-- Get balance before transaction
	local walletBefore = ply:GetMoney()
	local bankBefore = ply:GetBankMoney()
	
	print("[ATM:DEBUG] Deposit started - Wallet: " .. walletBefore .. ", Bank: " .. bankBefore .. ", Amount: " .. amount)
	
	-- Take money from wallet and add to bank
	local success = ply:TakeMoney(amount, "ATM Deposit", true)
	
	print("[ATM:DEBUG] TakeMoney returned: " .. tostring(success))
	print("[ATM:DEBUG] After TakeMoney - Wallet: " .. ply:GetMoney() .. ", Bank: " .. ply:GetBankMoney())
	
	if success then
		ply:AddBankMoney(amount, true)
		
		print("[ATM:DEBUG] After AddBankMoney - Wallet: " .. ply:GetMoney() .. ", Bank: " .. ply:GetBankMoney())
		
		DarkRP.Economy.NotifyPlayer(ply, "Deposited " .. DarkRP.Economy.FormatMoney(amount))
		DarkRP.Economy.LogTransaction(ply, -amount, "ATM Deposit", "atm_deposit")
		
		hook.Call("DarkRP.ATM.Deposit", nil, ply, self, amount)
		return true, "Deposit successful"
	end
	
	return false, "Deposit failed"
end

function ENT:CheckBalance(ply)
	if not IsValid(ply) then return 0 end
	if not self:CanPlayerUse(ply) then return 0 end
	
	return ply:GetMoney()
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Helper Functions                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:CanPlayerUse(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if not ply:Alive() then return false end
	
	local currentUser = self:GetNWEntity("ATM.User", NULL)
	if IsValid(currentUser) and currentUser ~= ply then
		return false
	end
	
	if self:GetPos():Distance(ply:GetPos()) > 100 then
		return false
	end
	
	return true
end

function ENT:ReleaseUser(ply)
	local currentUser = self:GetNWEntity("ATM.User", NULL)
	if IsValid(currentUser) and currentUser == ply then
		self:SetNWBool("ATM.InUse", false)
		self:SetNWEntity("ATM.User", NULL)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Handlers                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

util.AddNetworkString("DarkRP.ATM.Open")
util.AddNetworkString("DarkRP.ATM.Withdraw")
util.AddNetworkString("DarkRP.ATM.Deposit")
util.AddNetworkString("DarkRP.ATM.CheckBalance")
util.AddNetworkString("DarkRP.ATM.Close")
util.AddNetworkString("DarkRP.ATM.ForceClose")

net.Receive("DarkRP.ATM.Withdraw", function(len, ply)
	local atm = net.ReadEntity()
	local amount = net.ReadInt(32)
	
	if not IsValid(atm) or atm:GetClass() ~= "darkrp_atm" then
		DarkRP.Economy.NotifyPlayer(ply, "Invalid ATM", true)
		return
	end
	
	local success, message = atm:Withdraw(ply, amount)
	if not success then
		DarkRP.Economy.NotifyPlayer(ply, message, true)
	end
end)

net.Receive("DarkRP.ATM.Deposit", function(len, ply)
	local atm = net.ReadEntity()
	local amount = net.ReadInt(32)
	
	if not IsValid(atm) or atm:GetClass() ~= "darkrp_atm" then
		DarkRP.Economy.NotifyPlayer(ply, "Invalid ATM", true)
		return
	end
	
	local success, message = atm:Deposit(ply, amount)
	if not success then
		DarkRP.Economy.NotifyPlayer(ply, message, true)
	end
end)

net.Receive("DarkRP.ATM.Close", function(len, ply)
	local atm = net.ReadEntity()
	
	if IsValid(atm) and atm:GetClass() == "darkrp_atm" then
		atm:ReleaseUser(ply)
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:Think()
	-- Check if user is still nearby
	local user = self:GetNWEntity("ATM.User", NULL)
	if IsValid(user) then
		if self:GetPos():Distance(user:GetPos()) > 150 then
			self:ReleaseUser(user)
			net.Start("DarkRP.ATM.ForceClose")
			net.Send(user)
		end
	end
	
	self:NextThink(CurTime() + 0.5)
	return true
end

function ENT:OnRemove()
	-- Release any user
	local user = self:GetNWEntity("ATM.User", NULL)
	if IsValid(user) then
		self:ReleaseUser(user)
	end
end

hook.Add("PlayerDisconnected", "DarkRP.ATM.PlayerDisconnect", function(ply)
	-- Release ATMs being used by disconnecting player
	for _, ent in pairs(ents.FindByClass("darkrp_atm")) do
		if IsValid(ent) then
			local user = ent:GetNWEntity("ATM.User", NULL)
			if user == ply then
				ent:ReleaseUser(ply)
			end
		end
	end
end)
