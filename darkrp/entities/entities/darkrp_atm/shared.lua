-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP ATM Entity - Shared
--  Shared definitions for the ATM entity
-- ═══════════════════════════════════════════════════════════════════════════

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Bank ATM"
ENT.Author = "DarkRP"
ENT.Category = "DarkRP"
ENT.Spawnable = true
ENT.AdminOnly = false

ENT.Model = "models/perp2/bank_atm/bank_atm.mdl"

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Shared Functions                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function ENT:SetupDataTables()
	-- NetworkVars could be added here if needed
end
