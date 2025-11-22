-- ═══════════════════════════════════════════════════════════════════════════
--  Dialog NPC Configuration System
--  Create custom dialogs for NPCs throughout the gamemode
-- ═══════════════════════════════════════════════════════════════════════════

if SERVER then
	AddCSLuaFile()
end

DialogNPC = DialogNPC or {}
DialogNPC.Dialogs = DialogNPC.Dialogs or {}

--[[
	Dialog Structure:
	{
		id = "unique_id",           -- Unique identifier
		text = "Dialog text here",  -- What the NPC says
		options = {                 -- Player response options
			{
				id = "option1",
				text = "Option text",
				nextDialog = "next_dialog_id",  -- Chain to another dialog (optional)
				action = function(ply, npc)    -- Server-side action (optional)
					-- Do something
				end
			}
		}
	}
]]

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Helper Function to Register Dialogs                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DialogNPC.RegisterDialog(dialogData)
	if not dialogData.id then
		ErrorNoHalt("[Dialog NPC] Dialog must have an ID!\n")
		return
	end
	
	DialogNPC.Dialogs[dialogData.id] = dialogData
	
	if SERVER then
		print("[Dialog NPC] Registered dialog: " .. dialogData.id)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Default Dialogs                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Example: Default greeting dialog
DialogNPC.RegisterDialog({
	id = "default",
	text = "Hello there! I'm just a generic NPC. An administrator should configure my dialog!",
	options = {
		{
			id = "goodbye",
			text = "Goodbye.",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "The NPC waves goodbye.")
				end
			end
		}
	}
})

-- Example: Shop keeper dialog
DialogNPC.RegisterDialog({
	id = "shopkeeper",
	text = "Welcome to my shop! What can I do for you today?",
	options = {
		{
			id = "buy",
			text = "I'd like to buy something.",
			nextDialog = "shop_menu"
		},
		{
			id = "quest",
			text = "Do you have any work for me?",
			nextDialog = "quest_intro"
		},
		{
			id = "leave",
			text = "Just browsing, thanks.",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "The shopkeeper nods politely.")
				end
			end
		}
	}
})

-- Example: Shop menu
DialogNPC.RegisterDialog({
	id = "shop_menu",
	text = "Here's what I have in stock today:",
	options = {
		{
			id = "buy_health",
			text = "Health Kit - $500",
			action = function(ply, npc)
				if SERVER then
					local money = ply:getDarkRPVar("money") or 0
					if money >= 500 then
						ply:setDarkRPVar("money", money - 500)
						ply:SetHealth(math.min(ply:Health() + 50, ply:GetMaxHealth()))
						DarkRP.notify(ply, 0, 4, "You purchased a health kit!")
					else
						DarkRP.notify(ply, 1, 4, "You can't afford that!")
					end
				end
			end,
			nextDialog = "shop_menu"
		},
		{
			id = "buy_armor",
			text = "Armor - $1000",
			action = function(ply, npc)
				if SERVER then
					local money = ply:getDarkRPVar("money") or 0
					if money >= 1000 then
						ply:setDarkRPVar("money", money - 1000)
						ply:SetArmor(math.min(ply:Armor() + 50, 100))
						DarkRP.notify(ply, 0, 4, "You purchased armor!")
					else
						DarkRP.notify(ply, 1, 4, "You can't afford that!")
					end
				end
			end,
			nextDialog = "shop_menu"
		},
		{
			id = "back",
			text = "Never mind, go back.",
			nextDialog = "shopkeeper"
		}
	}
})

-- Example: Quest introduction
DialogNPC.RegisterDialog({
	id = "quest_intro",
	text = "I need someone to collect 10 items for me. Can you help?",
	options = {
		{
			id = "accept",
			text = "Sure, I'll help!",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "Quest accepted! (This is just an example)")
					-- You would set quest data here
				end
			end,
			nextDialog = "quest_accepted"
		},
		{
			id = "decline",
			text = "Not right now.",
			nextDialog = "shopkeeper"
		}
	}
})

DialogNPC.RegisterDialog({
	id = "quest_accepted",
	text = "Excellent! Come back when you've collected the items.",
	options = {
		{
			id = "ok",
			text = "Will do!",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "Good luck!")
				end
			end
		}
	}
})

-- Example: Guard NPC
DialogNPC.RegisterDialog({
	id = "guard",
	text = "Halt! State your business.",
	options = {
		{
			id = "pass",
			text = "I need to pass through.",
			action = function(ply, npc)
				if SERVER then
					-- Check if player has permission
					local money = ply:getDarkRPVar("money") or 0
					if money >= 1000 then
						ply:setDarkRPVar("money", money - 1000)
						DarkRP.notify(ply, 0, 4, "The guard lets you pass for $1000.")
						-- Open door or grant access
					else
						DarkRP.notify(ply, 1, 4, "The guard shakes his head. You need $1000.")
					end
				end
			end
		},
		{
			id = "info",
			text = "What are you guarding?",
			nextDialog = "guard_info"
		},
		{
			id = "leave",
			text = "Sorry, wrong person.",
		}
	}
})

DialogNPC.RegisterDialog({
	id = "guard_info",
	text = "This is a restricted area. Only authorized personnel may enter.",
	options = {
		{
			id = "back",
			text = "I see. Let me reconsider.",
			nextDialog = "guard"
		}
	}
})

-- Example: Information NPC
DialogNPC.RegisterDialog({
	id = "info_npc",
	text = "Welcome to the server! Need any help getting started?",
	options = {
		{
			id = "rules",
			text = "Tell me about the rules.",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "1. Be respectful to others")
					timer.Simple(0.5, function()
						if IsValid(ply) then
							DarkRP.notify(ply, 0, 4, "2. No RDM (Random Deathmatch)")
						end
					end)
					timer.Simple(1.0, function()
						if IsValid(ply) then
							DarkRP.notify(ply, 0, 4, "3. Follow staff instructions")
						end
					end)
				end
			end,
			nextDialog = "info_npc"
		},
		{
			id = "commands",
			text = "What commands are available?",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "Type !help to see all commands")
				end
			end,
			nextDialog = "info_npc"
		},
		{
			id = "thanks",
			text = "Thanks for the help!",
		}
	}
})

-- Example: Mysterious NPC with branching dialog
DialogNPC.RegisterDialog({
	id = "mysterious",
	text = "I sense great power within you... or perhaps great foolishness.",
	options = {
		{
			id = "power",
			text = "Tell me about this power.",
			nextDialog = "mysterious_power"
		},
		{
			id = "insult",
			text = "Are you calling me a fool?",
			nextDialog = "mysterious_insult"
		},
		{
			id = "leave",
			text = "I should go.",
		}
	}
})

DialogNPC.RegisterDialog({
	id = "mysterious_power",
	text = "The power I speak of lies dormant within all beings. You must unlock it yourself.",
	options = {
		{
			id = "how",
			text = "How do I unlock it?",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "The stranger smiles mysteriously...")
				end
			end,
			nextDialog = "mysterious_riddle"
		},
		{
			id = "back",
			text = "Tell me something else.",
			nextDialog = "mysterious"
		}
	}
})

DialogNPC.RegisterDialog({
	id = "mysterious_insult",
	text = "No insult was intended. Foolishness and wisdom are two sides of the same coin.",
	options = {
		{
			id = "wise",
			text = "That's... actually quite wise.",
			nextDialog = "mysterious"
		},
		{
			id = "nonsense",
			text = "That makes no sense.",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "The stranger shrugs.")
				end
			end
		}
	}
})

DialogNPC.RegisterDialog({
	id = "mysterious_riddle",
	text = "Seek the truth where shadows dance and light fears to tread.",
	options = {
		{
			id = "understand",
			text = "I... think I understand.",
		},
		{
			id = "confused",
			text = "That's completely cryptic.",
			action = function(ply, npc)
				if SERVER then
					DarkRP.notify(ply, 0, 4, "The stranger laughs softly.")
				end
			end
		}
	}
})

-- Example: Trainer NPC that gives items
DialogNPC.RegisterDialog({
	id = "trainer",
	text = "Ah, a new recruit! I can provide you with basic equipment to get started.",
	options = {
		{
			id = "starter_kit",
			text = "I'll take the starter kit.",
			action = function(ply, npc)
				if SERVER then
					-- Give starter weapons/items
					ply:Give("weapon_pistol")
					ply:GiveAmmo(50, "Pistol", true)
					DarkRP.notify(ply, 0, 4, "You received a pistol and 50 bullets!")
				end
			end,
			nextDialog = "trainer_complete"
		},
		{
			id = "no_thanks",
			text = "I'm good, thanks.",
		}
	}
})

DialogNPC.RegisterDialog({
	id = "trainer_complete",
	text = "There you go! Good luck out there, recruit!",
	options = {
		{
			id = "thanks",
			text = "Thank you!",
		}
	}
})

print("[Dialog NPC] Loaded " .. table.Count(DialogNPC.Dialogs) .. " dialogs")
