-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Economy Commands - PAS Integration
--  Server-side economy commands using PANTHEON command system
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

-- Function to register all economy commands
local function RegisterEconomyCommands()
	if not pas or not pas.cmd then
		ErrorNoHalt("[DarkRP Economy] PAS command system not found!\n")
		return false
	end

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Give Money Command                                           ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('givemoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		local amount = tonumber(args[2])
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		if not amount or amount <= 0 then
			pas.notify(pl, 'Invalid amount', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				target:AddMoney(amount, "Admin give from " .. pl:Nick(), false)
				pas.notify(pl, 'Gave ' .. DarkRP.Economy.FormatMoney(amount) .. ' to ' .. target:Nick(), 0)
				
				if pas.log and pas.log.Add then
					pas.log.Add('Economy', pl:Nick() .. ' gave ' .. DarkRP.Economy.FormatMoney(amount) .. ' to ' .. target:Nick())
				end
			end
		end
	end)
		:SetFlag('a')
		:SetHelp('Give money to a player')
		:SetIcon('icon16/money_add.png')
		:AddAlias('addmoney')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Take Money Command                                           ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('takemoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		local amount = tonumber(args[2])
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		if not amount or amount <= 0 then
			pas.notify(pl, 'Invalid amount', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				if not target:CanAfford(amount) then
					pas.notify(pl, target:Nick() .. ' does not have enough money', 1)
				else
					target:TakeMoney(amount, "Admin take by " .. pl:Nick(), false)
					pas.notify(pl, 'Took ' .. DarkRP.Economy.FormatMoney(amount) .. ' from ' .. target:Nick(), 0)
					
					if pas.log and pas.log.Add then
						pas.log.Add('Economy', pl:Nick() .. ' took ' .. DarkRP.Economy.FormatMoney(amount) .. ' from ' .. target:Nick())
					end
				end
			end
		end
	end)
		:SetFlag('a')
		:SetHelp('Take money from a player')
		:SetIcon('icon16/money_delete.png')
		:AddAlias('removemoney')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Set Money Command                                            ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('setmoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		local amount = tonumber(args[2])
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		if not amount or amount < 0 then
			pas.notify(pl, 'Invalid amount', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				local oldMoney = target:GetMoney()
				target:SetMoney(amount, false)
				pas.notify(pl, 'Set ' .. target:Nick() .. '\'s money to ' .. DarkRP.Economy.FormatMoney(amount), 0)
				
				if pas.log and pas.log.Add then
					pas.log.Add('Economy', pl:Nick() .. ' set ' .. target:Nick() .. '\'s money from ' .. DarkRP.Economy.FormatMoney(oldMoney) .. ' to ' .. DarkRP.Economy.FormatMoney(amount))
				end
			end
		end
	end)
		:SetFlag('a')
		:SetHelp('Set a player\'s money amount')
		:SetIcon('icon16/money.png')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Set Salary Command                                           ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('setsalary', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		local amount = tonumber(args[2])
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		if not amount or amount < 0 then
			pas.notify(pl, 'Invalid amount', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				target:SetSalary(amount)
				pas.notify(pl, 'Set ' .. target:Nick() .. '\'s salary to ' .. DarkRP.Economy.FormatMoney(amount), 0)
				
				if pas.log and pas.log.Add then
					pas.log.Add('Economy', pl:Nick() .. ' set ' .. target:Nick() .. '\'s salary to ' .. DarkRP.Economy.FormatMoney(amount))
				end
			end
		end
	end)
		:SetFlag('a')
		:SetHelp('Set a player\'s salary amount')
		:SetIcon('icon16/coins.png')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Check Money Command                                          ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('checkmoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		
		-- If no target specified, check self
		if not targetStr then
			local money = pl:GetMoney()
			local salary = pl:GetSalary()
			pas.notify(pl, 'Your balance: ' .. DarkRP.Economy.FormatMoney(money), 0)
			pas.notify(pl, 'Your salary: ' .. DarkRP.Economy.FormatMoney(salary), 0)
			return
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				local money = target:GetMoney()
				local salary = target:GetSalary()
				pas.notify(pl, target:Nick() .. '\'s balance: ' .. DarkRP.Economy.FormatMoney(money), 0)
				pas.notify(pl, target:Nick() .. '\'s salary: ' .. DarkRP.Economy.FormatMoney(salary), 0)
			end
		end
	end)
		:SetFlag('u')
		:SetHelp('Check your balance or another player\'s balance')
		:SetIcon('icon16/information.png')
		:AddAlias('balance')
		:AddAlias('money')
		:AddAlias('wallet')
		:AddArg('player', 'target', true)

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Pay/Transfer Money Command                                   ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('pay', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		local amount = tonumber(args[2])
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		if not amount or amount <= 0 then
			pas.notify(pl, 'Invalid amount', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				if target == pl then
					pas.notify(pl, 'You cannot pay yourself', 1)
				else
					local success, err = DarkRP.Economy.TransferMoney(pl, target, amount, "Player transfer")
					
					if not success then
						pas.notify(pl, err, 1)
					end
				end
			end
		end
	end)
		:SetFlag('u')
		:SetHelp('Transfer money to another player')
		:SetIcon('icon16/arrow_right.png')
		:AddAlias('transfer')
		:AddAlias('givecash')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Pay Salary Command (Admin)                                   ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('paysalary', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local targetStr = args[1]
		
		if not targetStr then
			return false
		end
		
		-- Parse player argument
		local targets = pas.parser.ParsePlayer(targetStr, pl)
		
		if not targets or #targets == 0 then
			pas.notify(pl, 'Player not found', 1)
			return false
		end
		
		for _, target in ipairs(targets) do
			if IsValid(target) and target:IsPlayer() then
				DarkRP.Economy.PaySalary(target)
				pas.notify(pl, 'Paid salary to ' .. target:Nick(), 0)
				
				if pas.log and pas.log.Add then
					pas.log.Add('Economy', pl:Nick() .. ' manually paid salary to ' .. target:Nick())
				end
			end
		end
	end)
		:SetFlag('a')
		:SetHelp('Manually pay salary to a player')
		:SetIcon('icon16/coins_add.png')
		:AddArg('player', 'target')

	-- ╔═══════════════════════════════════════════════════════════════╗
	-- ║  Pay All Salaries Command (Admin)                             ║
	-- ╚═══════════════════════════════════════════════════════════════╝

	pas.cmd.Create('paysalaries', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local count = 0
		for _, ply in ipairs(player.GetAll()) do
			if IsValid(ply) and ply:Alive() then
				DarkRP.Economy.PaySalary(ply)
				count = count + 1
			end
		end
		
		pas.notify(pl, 'Paid salaries to ' .. count .. ' player(s)', 0)
		
		if pas.log and pas.log.Add then
			pas.log.Add('Economy', pl:Nick() .. ' manually paid salaries to all players')
		end
	end)
		:SetFlag('a')
		:SetHelp('Pay salary to all players')
		:SetIcon('icon16/group_gear.png')
		:AddAlias('payall')

	print("[DarkRP] Economy commands registered with PAS")
	return true
end

-- Try to register immediately if PAS is already loaded
if pas and pas.cmd then
	RegisterEconomyCommands()
else
	-- Wait a bit and try again
	timer.Simple(0.5, function()
		if not RegisterEconomyCommands() then
			-- Try one more time after a longer delay
			timer.Simple(2, function()
				if not RegisterEconomyCommands() then
					ErrorNoHalt("[DarkRP Economy] Failed to register commands - PAS not available\n")
				end
			end)
		end
	end)
end
