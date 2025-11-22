-- ═══════════════════════════════════════════════════════════════════════════
--  Dialog NPC Commands
--  Admin commands to spawn and manage dialog NPCs using PANTHEON
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

-- Initialize DialogNPC table if it doesn't exist
DialogNPC = DialogNPC or {}
DialogNPC.Dialogs = DialogNPC.Dialogs or {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  NPC Spawner Function                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DialogNPC.SpawnNPC(pos, ang, dialogID, name, model)
	local npc = ents.Create("dialog_npc")
	if not IsValid(npc) then return nil end
	
	npc.DialogID = dialogID or "default"
	npc.NPCName = name or "Dialog NPC"
	npc.NPCModel = model or "models/player/group01/male_02.mdl"
	npc.NPCSequence = "idle_angry"
	
	npc:SetPos(pos)
	npc:SetAngles(ang or Angle(0, 0, 0))
	npc:Spawn()
	
	return npc
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  PANTHEON Commands                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Wait for PANTHEON to load before registering commands
local function RegisterCommands()
	if not pas or not pas.cmd then
		ErrorNoHalt("[Dialog NPC] PANTHEON command system not found!\n")
		return
	end

	-- Command: spawndialognpc <dialogID> [name] [model]
	pas.cmd.Create('spawndialognpc', function(pl, args)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	
	local dialogID = args[1]
	local npcName = args[2] or "Dialog NPC"
	local model = args[3] or "models/player/group01/male_02.mdl"
	
	if not dialogID then
		return false
	end
	
	-- Check if dialog exists
	if not DialogNPC.Dialogs[dialogID] then
		pas.notify(pl, 'Dialog ID "' .. dialogID .. '" not found!', 1)
		return
	end
	
	-- Spawn in front of player
	local pos = pl:GetPos() + pl:GetForward() * 100
	local ang = (pl:GetPos() - pos):Angle()
	
	local npc = DialogNPC.SpawnNPC(pos, ang, dialogID, npcName, model)
	
	if IsValid(npc) then
		pas.notify(pl, 'Spawned dialog NPC: ' .. npcName, 0)
		pas.log.Add('Command', pl:Nick() .. ' spawned dialog NPC: ' .. npcName .. ' (' .. dialogID .. ')')
	else
		pas.notify(pl, 'Failed to spawn NPC!', 1)
	end
end)
	:SetFlag('a')
	:SetHelp('Spawn a dialog NPC. Usage: !spawndialognpc <dialogID> [name] [model]')
	:SetIcon('icon16/user.png')
	:AddArg('string', 'dialogID')
	:AddArg('string', 'name (optional)')
	:AddArg('string', 'model (optional)')

-- Command: listdialogs
pas.cmd.Create('listdialogs', function(pl, args)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	
	pas.notify(pl, 'Available Dialog IDs:', 2)
	
	local dialogList = {}
	for id, _ in pairs(DialogNPC.Dialogs) do
		table.insert(dialogList, id)
	end
	table.sort(dialogList)
	
	for _, id in ipairs(dialogList) do
		pl:ChatPrint("  - " .. id)
	end
end)
	:SetFlag('a')
	:SetHelp('List all available dialog IDs')
	:SetIcon('icon16/information.png')

-- Command: removenearbynpcs [radius]
pas.cmd.Create('removenearbynpcs', function(pl, args)
	if not IsValid(pl) or not pl:IsPlayer() then return end
	
	local radius = tonumber(args[1]) or 200
	local removed = 0
	
	for _, ent in pairs(ents.FindInSphere(pl:GetPos(), radius)) do
		if IsValid(ent) and ent:GetClass() == "dialog_npc" then
			ent:Remove()
			removed = removed + 1
		end
	end
	
	pas.notify(pl, 'Removed ' .. removed .. ' dialog NPC(s)', 0)
	pas.log.Add('Command', pl:Nick() .. ' removed ' .. removed .. ' dialog NPC(s) in radius ' .. radius)
end)
	:SetFlag('a')
	:SetHelp('Remove nearby dialog NPCs. Usage: !removenearbynpcs [radius]')
	:SetIcon('icon16/delete.png')
	:AddArg('number', 'radius (optional, default 200)')

	print("[Dialog NPC] PANTHEON commands loaded")
end

-- Register commands when PANTHEON is ready
if pas and pas.cmd then
	RegisterCommands()
else
	hook.Add("PANTHEON_Loaded", "DialogNPC.RegisterCommands", function()
		RegisterCommands()
	end)
end
