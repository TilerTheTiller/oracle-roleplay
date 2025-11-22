-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Character System - PAS Commands
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

print("[DarkRP] Loading character commands...")

-- Wait for PANTHEON to load before registering commands
local function RegisterCommands()
	if not pas or not pas.cmd then
		ErrorNoHalt("[DarkRP:Characters] PANTHEON command system not found!\n")
		return
	end
	
	print("[DarkRP:Characters] Registering character commands with PAS...")

	-- Command: characters - Opens character selection menu
	pas.cmd.Create('characters', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		DarkRP.Characters.OpenCharacterMenu(pl)
		pas.log.Add('Command', pl:Nick() .. ' opened character menu')
	end)
		:SetFlag('u')
		:SetHelp('Open the character selection menu')
		:SetIcon('icon16/user.png')
		:AddAlias('chars')
		:AddAlias('char')

	-- Command: charinfo [player] - Show character information
	pas.cmd.Create('charinfo', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pl
		
		if args[1] then
			target = pas.util.FindPlayer(args[1])
			if not IsValid(target) then
				pas.notify(pl, 'Player not found!', 1)
				return false
			end
		end
		
		local char = target:GetActiveCharacter()
		if not char then
			pas.notify(pl, (target == pl and 'You have' or target:Nick() .. ' has') .. ' no active character!', 1)
			return
		end
		
		pas.notify(pl, '═══ Character Info ═══', 0)
		pas.notify(pl, 'Name: ' .. char.name, 0)
		pas.notify(pl, 'Money: $' .. string.Comma(char.money), 0)
		pas.notify(pl, 'Bank: $' .. string.Comma(char.bankMoney), 0)
		pas.notify(pl, 'Playtime: ' .. DarkRP.Characters.FormatPlaytime(char.playtime), 0)
		
		pas.log.Add('Command', pl:Nick() .. ' viewed character info for ' .. target:Nick())
	end)
		:SetFlag('u')
		:SetHelp('View character information. Usage: !charinfo [player]')
		:SetIcon('icon16/information.png')
		:AddArg('player', 'target (optional)')

	-- Command: givemoney <player> <amount> - Give money to player's character
	pas.cmd.Create('givemoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pas.util.FindPlayer(args[1])
		if not IsValid(target) then
			pas.notify(pl, 'Player not found!', 1)
			return false
		end
		
		local amount = tonumber(args[2])
		if not amount or amount <= 0 then
			pas.notify(pl, 'Invalid amount!', 1)
			return false
		end
		
		if not target:HasActiveCharacter() then
			pas.notify(pl, target:Nick() .. ' has no active character!', 1)
			return
		end
		
		target:AddCharacterMoney(amount, "Admin gift from " .. pl:Nick())
		pas.notify(pl, 'Gave $' .. string.Comma(amount) .. ' to ' .. target:Nick(), 0)
		pas.notify(target, 'Received $' .. string.Comma(amount) .. ' from ' .. pl:Nick(), 0)
		
		pas.log.Add('Command', pl:Nick() .. ' gave $' .. string.Comma(amount) .. ' to ' .. target:Nick())
	end)
		:SetFlag('a')
		:SetHelp('Give money to a player. Usage: !givemoney <player> <amount>')
		:SetIcon('icon16/money_add.png')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- Command: takemoney <player> <amount> - Take money from player's character
	pas.cmd.Create('takemoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pas.util.FindPlayer(args[1])
		if not IsValid(target) then
			pas.notify(pl, 'Player not found!', 1)
			return false
		end
		
		local amount = tonumber(args[2])
		if not amount or amount <= 0 then
			pas.notify(pl, 'Invalid amount!', 1)
			return false
		end
		
		if not target:HasActiveCharacter() then
			pas.notify(pl, target:Nick() .. ' has no active character!', 1)
			return
		end
		
		if not target:CanAffordCharacter(amount) then
			pas.notify(pl, target:Nick() .. ' does not have enough money!', 1)
			return
		end
		
		target:TakeCharacterMoney(amount, "Admin penalty from " .. pl:Nick())
		pas.notify(pl, 'Took $' .. string.Comma(amount) .. ' from ' .. target:Nick(), 0)
		pas.notify(target, 'Lost $' .. string.Comma(amount) .. ' by ' .. pl:Nick(), 2)
		
		pas.log.Add('Command', pl:Nick() .. ' took $' .. string.Comma(amount) .. ' from ' .. target:Nick())
	end)
		:SetFlag('a')
		:SetHelp('Take money from a player. Usage: !takemoney <player> <amount>')
		:SetIcon('icon16/money_delete.png')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- Command: setmoney <player> <amount> - Set player's character money
	pas.cmd.Create('setmoney', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pas.util.FindPlayer(args[1])
		if not IsValid(target) then
			pas.notify(pl, 'Player not found!', 1)
			return false
		end
		
		local amount = tonumber(args[2])
		if not amount or amount < 0 then
			pas.notify(pl, 'Invalid amount!', 1)
			return false
		end
		
		if not target:HasActiveCharacter() then
			pas.notify(pl, target:Nick() .. ' has no active character!', 1)
			return
		end
		
		target:SetCharacterMoney(amount)
		pas.notify(pl, 'Set ' .. target:Nick() .. "'s money to $" .. string.Comma(amount), 0)
		pas.notify(target, 'Your money was set to $' .. string.Comma(amount) .. ' by ' .. pl:Nick(), 0)
		
		pas.log.Add('Command', pl:Nick() .. ' set ' .. target:Nick() .. "'s money to $" .. string.Comma(amount))
	end)
		:SetFlag('a')
		:SetHelp('Set player money. Usage: !setmoney <player> <amount>')
		:SetIcon('icon16/money.png')
		:AddArg('player', 'target')
		:AddArg('number', 'amount')

	-- Command: deletechar <player> <character_id> - Delete a player's character (admin only)
	pas.cmd.Create('deletechar', function(pl, args)
		if not IsValid(pl) or not pl:IsPlayer() then return end
		
		local target = pas.util.FindPlayer(args[1])
		if not IsValid(target) then
			pas.notify(pl, 'Player not found!', 1)
			return false
		end
		
		local charID = tonumber(args[2])
		if not charID then
			pas.notify(pl, 'Invalid character ID!', 1)
			return false
		end
		
		DarkRP.Characters.DeleteCharacter(target, charID)
		pas.notify(pl, 'Deleted character #' .. charID .. ' from ' .. target:Nick(), 0)
		
		pas.log.Add('Command', pl:Nick() .. ' deleted character #' .. charID .. ' from ' .. target:Nick())
	end)
		:SetFlag('a')
		:SetHelp('Delete a player character. Usage: !deletechar <player> <id>')
		:SetIcon('icon16/user_delete.png')
		:AddArg('player', 'target')
		:AddArg('number', 'character ID')

	print("[DarkRP:Characters] PANTHEON commands loaded")
end

-- Register commands when PANTHEON is ready
if pas and pas.cmd then
	RegisterCommands()
else
	hook.Add("PANTHEON_Loaded", "DarkRP.Characters.RegisterCommands", function()
		RegisterCommands()
	end)
end
