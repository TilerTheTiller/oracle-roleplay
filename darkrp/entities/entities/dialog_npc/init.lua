AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel(self.NPCModel)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetUseType(SIMPLE_USE)
	
	-- Set collision bounds
	local mins, maxs = self:GetModelBounds()
	self:SetCollisionBounds(mins, maxs)
	
	-- Start the idle sequence
	local seq = self:LookupSequence(self.NPCSequence)
	if seq > 0 then
		self:SetSequence(seq)
		self:SetPlaybackRate(1)
	end
	
	-- Set networked variables
	self:SetDialogID(self.DialogID)
	self:SetNPCName(self.NPCName)
	
	-- Disable physics
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	
	-- Check distance
	local dist = activator:GetPos():Distance(self:GetPos())
	if dist > self.UseDistance then return end
	
	-- Send dialog to player
	net.Start("DialogNPC.OpenDialog")
		net.WriteEntity(self)
		net.WriteString(self:GetDialogID())
		net.WriteString(self:GetNPCName())
	net.Send(activator)
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end

-- Network the dialog system
util.AddNetworkString("DialogNPC.OpenDialog")
util.AddNetworkString("DialogNPC.SelectOption")

-- Handle dialog option selection from client
net.Receive("DialogNPC.SelectOption", function(len, pl)
	local npc = net.ReadEntity()
	local dialogID = net.ReadString()
	local optionID = net.ReadString()
	
	if not IsValid(npc) or not IsValid(pl) then return end
	
	-- Get the dialog configuration
	local dialog = DialogNPC.Dialogs[dialogID]
	if not dialog then return end
	
	-- Find the option and execute its action
	for _, option in pairs(dialog.options or {}) do
		if option.id == optionID and option.action then
			option.action(pl, npc)
			break
		end
	end
end)
