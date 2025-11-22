-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Economy System - Server
--  Server-side money management and transactions
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

util.AddNetworkString("DarkRP.Economy.Notify")
util.AddNetworkString("DarkRP.Economy.Transfer")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Internal State                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Economy._transactions = {}
DarkRP.Economy._playerData = {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Money Management                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

local PLAYER = FindMetaTable("Player")

-- Server-side getter functions (must be defined before use)
function PLAYER:GetBankMoney()
	return self:GetNWInt("DarkRP.BankMoney", 0)
end

function PLAYER:GetSalary()
	return self:GetNWInt("DarkRP.Salary", DarkRP.Economy.config.defaultSalary)
end

function PLAYER:SetMoney(amount, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:SetCharacterMoney(amount, silent)
	end
	
	amount = math.Clamp(amount, DarkRP.Economy.config.minMoney, DarkRP.Economy.config.maxMoney)
	amount = math.floor(amount)
	
	local oldAmount = self:GetMoney()
	
	self:SetNWInt("DarkRP.Money", amount)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Money updated: " .. DarkRP.Economy.FormatMoney(amount))
	end
	
	hook.Call("DarkRP.Economy.MoneyChanged", nil, self, oldAmount, amount)
	
	return true
end

function PLAYER:AddMoney(amount, reason, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:AddCharacterMoney(amount, reason, silent)
	end
	
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then
		DarkRP.Economy.NotifyPlayer(self, err, true)
		return false
	end
	
	local currentMoney = self:GetMoney()
	
	local newAmount = currentMoney + amount
	if newAmount > DarkRP.Economy.config.maxMoney then
		newAmount = DarkRP.Economy.config.maxMoney
	end
	
	self:SetMoney(newAmount, true)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Received " .. DarkRP.Economy.FormatMoney(amount) .. (reason and (" (" .. reason .. ")") or ""))
	end
	
	-- Log transaction
	DarkRP.Economy.LogTransaction(self, amount, reason or "Unknown", DarkRP.Economy.TransactionType.OTHER)
	
	return true
end

function PLAYER:TakeMoney(amount, reason, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:TakeCharacterMoney(amount, reason, silent)
	end
	
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then
		DarkRP.Economy.NotifyPlayer(self, err, true)
		return false
	end
	
	if not self:CanAfford(amount) then
		DarkRP.Economy.NotifyPlayer(self, "You cannot afford this!", true)
		return false
	end
	
	local newAmount = math.max(self:GetMoney() - amount, DarkRP.Economy.config.minMoney)
	self:SetMoney(newAmount, true)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Paid " .. DarkRP.Economy.FormatMoney(amount) .. (reason and (" (" .. reason .. ")") or ""))
	end
	
	-- Log transaction
	DarkRP.Economy.LogTransaction(self, -amount, reason or "Unknown", DarkRP.Economy.TransactionType.OTHER)
	
	return true
end

function PLAYER:SetSalary(amount)
	amount = math.max(0, math.floor(amount))
	self:SetNWInt("DarkRP.Salary", amount)
	return true
end

function PLAYER:GetMoney()
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:GetCharacterMoney()
	end
	
	return self:GetNWInt("DarkRP.Money", 0)
end

function PLAYER:CanAfford(amount)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:CanAffordCharacter(amount)
	end
	
	return self:GetMoney() >= amount
end

function PLAYER:SetBankMoney(amount, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:SetCharacterBankMoney(amount, silent)
	end
	
	amount = math.Clamp(amount, 0, DarkRP.Economy.config.maxMoney)
	amount = math.floor(amount)
	
	local oldAmount = self:GetBankMoney()
	
	self:SetNWInt("DarkRP.BankMoney", amount)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Bank balance updated: " .. DarkRP.Economy.FormatMoney(amount))
	end
	
	hook.Call("DarkRP.Economy.BankMoneyChanged", nil, self, oldAmount, amount)
	
	return true
end

function PLAYER:AddBankMoney(amount, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:AddCharacterBankMoney(amount, silent)
	end
	
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then
		if not silent then
			DarkRP.Economy.NotifyPlayer(self, err, true)
		end
		return false
	end
	
	local currentBank = self:GetBankMoney()
	local newAmount = currentBank + amount
	
	if newAmount > DarkRP.Economy.config.maxMoney then
		newAmount = DarkRP.Economy.config.maxMoney
	end
	
	self:SetBankMoney(newAmount, true)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Added " .. DarkRP.Economy.FormatMoney(amount) .. " to bank")
	end
	
	return true
end

function PLAYER:TakeBankMoney(amount, silent)
	-- Use character system if available
	if DarkRP.Characters and self:HasActiveCharacter() then
		return self:TakeCharacterBankMoney(amount, silent)
	end
	
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then
		if not silent then
			DarkRP.Economy.NotifyPlayer(self, err, true)
		end
		return false
	end
	
	local currentBank = self:GetBankMoney()
	
	if currentBank < amount then
		if not silent then
			DarkRP.Economy.NotifyPlayer(self, "Insufficient bank balance", true)
		end
		return false
	end
	
	local newAmount = math.max(currentBank - amount, 0)
	self:SetBankMoney(newAmount, true)
	
	if not silent then
		DarkRP.Economy.NotifyPlayer(self, "Removed " .. DarkRP.Economy.FormatMoney(amount) .. " from bank")
	end
	
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Transaction System                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.LogTransaction(ply, amount, reason, transactionType)
	if not IsValid(ply) then return end
	
	local transaction = {
		steamID = ply:SteamID(),
		playerName = ply:Nick(),
		amount = amount,
		reason = reason,
		type = transactionType or DarkRP.Economy.TransactionType.OTHER,
		timestamp = os.time(),
		balance = ply:GetMoney()
	}
	
	-- Store in database
	if DarkRP.database and DarkRP.database.IsConnected() then
		local escapedReason = reason and DarkRP.database.GetConnection():escape(reason) or "Unknown"
		local transType = transactionType or "OTHER"
		
		DarkRP.database.Query([[
			INSERT INTO darkrp_transactions (steamid, amount, reason, transaction_type, balance_after)
			VALUES (?, ?, ?, ?, ?)
		]], {ply:SteamID(), amount, escapedReason, transType, ply:GetMoney()})
	end
	
	-- Also keep in memory for quick access
	table.insert(DarkRP.Economy._transactions, transaction)
	
	-- Keep only last 1000 transactions in memory
	if #DarkRP.Economy._transactions > 1000 then
		table.remove(DarkRP.Economy._transactions, 1)
	end
	
	hook.Call("DarkRP.Economy.Transaction", nil, ply, transaction)
end

function DarkRP.Economy.GetPlayerTransactions(ply, limit)
	limit = limit or 10
	local transactions = {}
	
	for i = #DarkRP.Economy._transactions, 1, -1 do
		local trans = DarkRP.Economy._transactions[i]
		if trans.steamID == ply:SteamID() then
			table.insert(transactions, trans)
			if #transactions >= limit then break end
		end
	end
	
	return transactions
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Money Transfer System                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.TransferMoney(sender, receiver, amount, reason)
	if not IsValid(sender) or not IsValid(receiver) then
		return false, "Invalid players"
	end
	
	if sender == receiver then
		return false, "You cannot transfer money to yourself"
	end
	
	local valid, err = DarkRP.Economy.ValidateAmount(amount)
	if not valid then
		return false, err
	end
	
	if amount < DarkRP.Economy.config.minTransferAmount then
		return false, "Transfer amount too small"
	end
	
	if amount > DarkRP.Economy.config.maxTransferAmount then
		return false, "Transfer amount too large"
	end
	
	if not sender:CanAfford(amount) then
		return false, "Insufficient funds"
	end
	
	-- Calculate fee
	local fee = math.max(
		math.floor(amount * (DarkRP.Economy.config.transferFee / 100)),
		DarkRP.Economy.config.transferMinFee
	)
	
	local totalCost = amount + fee
	
	if not sender:CanAfford(totalCost) then
		return false, "Insufficient funds (including fee)"
	end
	
	-- Execute transfer
	sender:TakeMoney(totalCost, "Transfer to " .. receiver:Nick(), true)
	receiver:AddMoney(amount, "Transfer from " .. sender:Nick(), true)
	
	-- Notifications
	DarkRP.Economy.NotifyPlayer(sender, "Sent " .. DarkRP.Economy.FormatMoney(amount) .. " to " .. receiver:Nick() .. (fee > 0 and (" (Fee: " .. DarkRP.Economy.FormatMoney(fee) .. ")") or ""))
	DarkRP.Economy.NotifyPlayer(receiver, "Received " .. DarkRP.Economy.FormatMoney(amount) .. " from " .. sender:Nick())
	
	-- Log transactions
	DarkRP.Economy.LogTransaction(sender, -totalCost, "Transfer to " .. receiver:Nick(), DarkRP.Economy.TransactionType.TRANSFER)
	DarkRP.Economy.LogTransaction(receiver, amount, "Transfer from " .. sender:Nick(), DarkRP.Economy.TransactionType.TRANSFER)
	
	hook.Call("DarkRP.Economy.MoneyTransferred", nil, sender, receiver, amount, fee, reason)
	
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Salary System                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.PaySalary(ply)
	if not IsValid(ply) or not ply:Alive() then return end
	
	local salary = ply:GetSalary()
	if salary <= 0 then return end
	
	ply:AddMoney(salary, "Salary", true)
	DarkRP.Economy.NotifyPlayer(ply, "Received salary: " .. DarkRP.Economy.FormatMoney(salary))
	DarkRP.Economy.LogTransaction(ply, salary, "Salary payment", DarkRP.Economy.TransactionType.SALARY)
	
	hook.Call("DarkRP.Economy.SalaryPaid", nil, ply, salary)
end

function DarkRP.Economy.StartSalaryTimer()
	timer.Create("DarkRP.Economy.Salary", DarkRP.Economy.config.salaryInterval, 0, function()
		for _, ply in ipairs(player.GetAll()) do
			DarkRP.Economy.PaySalary(ply)
		end
	end)
	
	print("[DarkRP] Salary timer started (interval: " .. DarkRP.Economy.config.salaryInterval .. "s)")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Notification System                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.NotifyPlayer(ply, message, isError)
	if not IsValid(ply) then return end
	
	net.Start("DarkRP.Economy.Notify")
		net.WriteString(message)
		net.WriteBool(isError or false)
	net.Send(ply)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Data Management                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.SavePlayerData(ply)
	if not IsValid(ply) then return end
	
	if not DarkRP.database or not DarkRP.database.IsConnected() then
		print("[DarkRP:Economy] Cannot save player data - database not connected")
		return
	end
	
	local steamID = ply:SteamID()
	local money = ply:GetMoney()
	local bankMoney = ply:GetBankMoney()
	local salary = ply:GetSalary()
	local playerName = DarkRP.database.GetConnection():escape(ply:Nick())
	
	local query = [[
		INSERT INTO darkrp_players (steamid, name, money, bank_money, salary, last_seen)
		VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
		ON DUPLICATE KEY UPDATE
			name = ?,
			money = ?,
			bank_money = ?,
			salary = ?,
			last_seen = CURRENT_TIMESTAMP
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {
			steamID, playerName, money, bankMoney, salary,
			playerName, money, bankMoney, salary
		}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success then
				hook.Call("DarkRP.Economy.PlayerDataSaved", nil, ply, {
					steamID = steamID,
					money = money,
					bankMoney = bankMoney,
					salary = salary
				})
			else
				ErrorNoHalt("[DarkRP:Economy] Failed to save player data: " .. tostring(err) .. "\n")
			end
		end)
	end
end

function DarkRP.Economy.LoadPlayerData(ply)
	if not IsValid(ply) then return end
	
	local steamID = ply:SteamID()
	
	local query = [[
		SELECT money, bank_money, salary FROM darkrp_players WHERE steamid = ?
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {steamID}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success and data and #data > 0 then
				-- Load existing player data
				ply:SetMoney(tonumber(data[1].money) or DarkRP.Economy.config.startingMoney, true)
				ply:SetSalary(tonumber(data[1].salary) or DarkRP.Economy.config.defaultSalary)
				ply:SetBankMoney(tonumber(data[1].bank_money) or DarkRP.Economy.config.startingBankMoney or 0, true)
				print("[DarkRP:Economy] Loaded data for " .. ply:Nick())
				
				hook.Call("DarkRP.Economy.PlayerDataLoaded", nil, ply, data[1])
			else
				-- New player - initialize with defaults
				ply:SetMoney(DarkRP.Economy.config.startingMoney, true)
				ply:SetSalary(DarkRP.Economy.config.defaultSalary)
				ply:SetBankMoney(DarkRP.Economy.config.startingBankMoney or 0, true)
				print("[DarkRP:Economy] Initialized new player: " .. ply:Nick())
				
				-- Insert new player record
				local playerName = DarkRP.database.GetConnection():escape(ply:Nick())
				DarkRP.database.Query([[
					INSERT INTO darkrp_players (steamid, name, money, bank_money, salary)
					VALUES (?, ?, ?, ?, ?)
				]], {steamID, playerName, DarkRP.Economy.config.startingMoney, 
					DarkRP.Economy.config.startingBankMoney or 0, DarkRP.Economy.config.defaultSalary})
				
				hook.Call("DarkRP.Economy.PlayerDataLoaded", nil, ply, nil)
			end
		end)
	else
		-- Fallback: use in-memory data or defaults
		local data = DarkRP.Economy._playerData[steamID]
		if data then
			ply:SetMoney(data.money, true)
			ply:SetSalary(data.salary)
			ply:SetBankMoney(data.bankMoney or 0, true)
			print("[DarkRP:Economy] Loaded cached data for " .. ply:Nick())
		else
			ply:SetMoney(DarkRP.Economy.config.startingMoney, true)
			ply:SetSalary(DarkRP.Economy.config.defaultSalary)
			ply:SetBankMoney(DarkRP.Economy.config.startingBankMoney or 0, true)
			print("[DarkRP:Economy] Initialized with defaults: " .. ply:Nick())
		end
		hook.Call("DarkRP.Economy.PlayerDataLoaded", nil, ply, data)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Network Handlers                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

net.Receive("DarkRP.Economy.Transfer", function(len, ply)
	local targetName = net.ReadString()
	local amount = net.ReadInt(32)
	
	-- Find player by name
	local target = nil
	for _, p in ipairs(player.GetAll()) do
		if p:Nick() == targetName or string.find(string.lower(p:Nick()), string.lower(targetName), 1, true) then
			target = p
			break
		end
	end
	
	if not IsValid(target) then
		DarkRP.Economy.NotifyPlayer(ply, "Player not found", true)
		return
	end
	
	local success, err = DarkRP.Economy.TransferMoney(ply, target, amount, "Player transfer")
	
	if not success then
		DarkRP.Economy.NotifyPlayer(ply, err, true)
	end
end)

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("PlayerInitialSpawn", "DarkRP.Economy.PlayerSpawn", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			DarkRP.Economy.LoadPlayerData(ply)
		end
	end)
end)

hook.Add("PlayerDisconnected", "DarkRP.Economy.PlayerDisconnect", function(ply)
	DarkRP.Economy.SavePlayerData(ply)
end)

hook.Add("ShutDown", "DarkRP.Economy.Shutdown", function()
	for _, ply in ipairs(player.GetAll()) do
		DarkRP.Economy.SavePlayerData(ply)
	end
	print("[DarkRP] Saved all economy data")
end)

-- Commands are now handled by sv_economy_commands.lua using PAS

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Initialization                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Economy.StartSalaryTimer()

print("[DarkRP] Economy system (server) loaded")
