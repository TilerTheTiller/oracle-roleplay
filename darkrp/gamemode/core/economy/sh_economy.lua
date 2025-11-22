-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Economy System
--  Shared economy definitions and configuration
-- ═══════════════════════════════════════════════════════════════════════════

DarkRP = DarkRP or {}
DarkRP.Economy = DarkRP.Economy or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Configuration                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Economy.config = {
	startingMoney = 500,
	startingBankMoney = 1000,
	minMoney = 0,
	maxMoney = 999999999,
	currency = "$",
	currencyName = "Dollar",
	currencyNamePlural = "Dollars",
	
	-- Salary settings
	salaryInterval = 300,  -- Pay salary every 5 minutes (300 seconds)
	defaultSalary = 100,
	
	-- Transaction fees
	transferFee = 0,  -- Percentage fee for transfers (0 = no fee)
	transferMinFee = 0,  -- Minimum fee amount
	
	-- Limits
	maxTransferAmount = 100000,
	minTransferAmount = 1
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Transaction Types                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Economy.TransactionType = {
	SALARY = "salary",
	PURCHASE = "purchase",
	SALE = "sale",
	TRANSFER = "transfer",
	ADMIN = "admin",
	REWARD = "reward",
	PENALTY = "penalty",
	JOB_CHANGE = "job_change",
	DEATH = "death",
	ARREST = "arrest",
	OTHER = "other"
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Utility Functions                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Economy.FormatMoney(amount)
	local formatted = tostring(math.floor(amount))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then break end
	end
	return DarkRP.Economy.config.currency .. formatted
end

function DarkRP.Economy.ValidateAmount(amount)
	if not isnumber(amount) then return false, "Amount must be a number" end
	if amount < 0 then return false, "Amount cannot be negative" end
	if amount > DarkRP.Economy.config.maxMoney then return false, "Amount exceeds maximum" end
	return true
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Money Accessor Functions                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

local PLAYER = FindMetaTable("Player")

function PLAYER:GetMoney()
	return self:GetNWInt("DarkRP.Money", DarkRP.Economy.config.startingMoney)
end

function PLAYER:GetBankMoney()
	return self:GetNWInt("DarkRP.BankMoney", 0)
end

function PLAYER:CanAfford(amount)
	if not isnumber(amount) then return false end
	return self:GetMoney() >= amount
end

function PLAYER:GetSalary()
	return self:GetNWInt("DarkRP.Salary", DarkRP.Economy.config.defaultSalary)
end

print("[DarkRP] Economy system (shared) loaded")
