ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Dialog NPC"
ENT.Author = "DarkRP"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.AutomaticFrameAdvance = true

-- Dialog configuration
ENT.DialogID = "default"
ENT.NPCName = "Generic NPC"
ENT.NPCModel = "models/player/group01/male_01.mdl"
ENT.NPCSequence = "idle_angry"
ENT.UseDistance = 100

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "DialogID")
	self:NetworkVar("String", 1, "NPCName")
end
