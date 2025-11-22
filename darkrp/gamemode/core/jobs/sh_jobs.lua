AddCSLuaFile()

--[[
	DarkRP Job System - Core Functionality
	Handles job changing, validation, and hooks
]]--

DarkRP = DarkRP or {}
DarkRP.jobs = DarkRP.jobs or {}

-- Initialize JOBS table
JOBS = JOBS or {}

-- Configuration
DarkRP.config = DarkRP.config or {}
DarkRP.config.changejobcooldown = 10 -- Seconds between job changes
DarkRP.config.allowjobvoting = true -- Allow voting for jobs that require it

-- Job change cooldowns
local jobChangeCooldowns = {}

--[[
	Get job table by team ID
]]--
function DarkRP.getJobByTeam(teamID)
	return JOBS[teamID]
end

--[[
	Get job table by command
]]--
function DarkRP.getJobByCommand(command)
	for k, v in pairs(JOBS) do
		if v.command == command then
			return v, k
		end
	end
	return nil
end

--[[
	Get all jobs
]]--
function DarkRP.getJobs()
	return JOBS
end

--[[
	Get jobs by category
]]--
function DarkRP.getJobsByCategory(category)
	local jobs = {}
	for k, v in pairs(JOBS) do
		if v.category == category then
			table.insert(jobs, v)
		end
	end
	return jobs
end

--[[
	Get all job categories
]]--
function DarkRP.getJobCategories()
	local categories = {}
	for k, v in pairs(JOBS) do
		if not table.HasValue(categories, v.category) then
			table.insert(categories, v.category)
		end
	end
	return categories
end

--[[
	Check if player can become job
]]--
function DarkRP.canBecomeJob(ply, jobID)
	if not IsValid(ply) then return false, "Invalid player" end
	if not JOBS[jobID] then return false, "Invalid job" end
	
	local job = JOBS[jobID]
	
	-- Check if already this job
	if ply:Team() == jobID then
		return false, "You are already this job"
	end
	
	-- Check cooldown
	if jobChangeCooldowns[ply:SteamID()] and jobChangeCooldowns[ply:SteamID()] > CurTime() then
		local timeLeft = math.ceil(jobChangeCooldowns[ply:SteamID()] - CurTime())
		return false, "You must wait " .. timeLeft .. " seconds before changing jobs"
	end
	
	-- Check admin requirement
	if job.admin > 0 then
		if job.admin == 1 and not ply:IsAdmin() then
			return false, "This job requires admin"
		elseif job.admin == 2 and not ply:IsSuperAdmin() then
			return false, "This job requires superadmin"
		end
	end
	
	-- Check max players
	if job.max > 0 and team.NumPlayers(jobID) >= job.max then
		return false, "This job is full"
	end
	
	-- Check vote requirement
	if job.vote and DarkRP.config.allowjobvoting then
		-- Vote will be handled separately
		return true, "vote_required"
	end
	
	-- Check custom condition
	if job.customCheck then
		local canJoin = job.customCheck(ply)
		if not canJoin then
			return false, job.CustomCheckFailMsg or "You cannot become this job"
		end
	end
	
	return true
end

if SERVER then
	util.AddNetworkString("DarkRP_ChangeJob")
	util.AddNetworkString("DarkRP_JobChanged")
	util.AddNetworkString("DarkRP_RequestJobMenu")
	util.AddNetworkString("DarkRP_SendJobs")
	
	--[[
		Change player's job
	]]--
	function DarkRP.changeJob(ply, jobID, skipChecks)
		if not IsValid(ply) then return false end
		if not JOBS[jobID] then return false end
		
		if not skipChecks then
			local canJoin, reason = DarkRP.canBecomeJob(ply, jobID)
			if not canJoin then
				if reason == "vote_required" then
					-- TODO: Start vote
					DarkRP.notify(ply, "Job voting not yet implemented", 1)
					return false
				end
				DarkRP.notify(ply, reason, 1)
				return false
			end
		end
		
		local job = JOBS[jobID]
		local oldTeam = ply:Team()
		
		-- Set team
		ply:SetTeam(jobID)
		
		-- Strip weapons
		ply:StripWeapons()
		
		-- Give weapons
		for _, wep in pairs(job.weapons) do
			ply:Give(wep)
		end
		
		-- Set model
		if type(job.model) == "table" then
			ply:SetModel(job.model[math.random(1, #job.model)])
		else
			ply:SetModel(job.model)
		end
		
		-- Give ammo
		if job.ammo then
			for ammoType, amount in pairs(job.ammo) do
				ply:GiveAmmo(amount, ammoType)
			end
		end
		
		-- Set health/armor if specified
		if job.health then
			ply:SetHealth(job.health)
		else
			ply:SetHealth(100)
		end
		
		if job.armor then
			ply:SetArmor(job.armor)
		else
			ply:SetArmor(0)
		end
		
		-- Respawn player
		ply:Spawn()
		
		-- Set cooldown
		jobChangeCooldowns[ply:SteamID()] = CurTime() + DarkRP.config.changejobcooldown
		
		-- Call hook
		hook.Run("DarkRP_PlayerChangedJob", ply, jobID, oldTeam)
		
		-- Custom spawn function
		if job.PlayerSpawn then
			job.PlayerSpawn(ply)
		end
		
		-- Notify
		DarkRP.notify(ply, "You are now a " .. job.name, 0)
		
		-- Network to client
		net.Start("DarkRP_JobChanged")
			net.WriteUInt(jobID, 8)
		net.Send(ply)
		
		return true
	end
	
	-- Receive job change request
	net.Receive("DarkRP_ChangeJob", function(len, ply)
		local jobID = net.ReadUInt(8)
		DarkRP.changeJob(ply, jobID)
	end)
	
	-- Send jobs to client
	net.Receive("DarkRP_RequestJobMenu", function(len, ply)
		net.Start("DarkRP_SendJobs")
			net.WriteTable(JOBS)
		net.Send(ply)
	end)
	
	-- Set player's job on spawn
	hook.Add("PlayerInitialSpawn", "DarkRP_SetDefaultJob", function(ply)
		timer.Simple(1, function()
			if not IsValid(ply) then return end
			if ply:Team() == 0 or ply:Team() == 1001 then
				DarkRP.changeJob(ply, TEAM_CITIZEN, true)
			end
		end)
	end)
	
	-- Handle player loadout
	hook.Add("PlayerLoadout", "DarkRP_JobLoadout", function(ply)
		local job = JOBS[ply:Team()]
		if not job then return end
		
		-- Strip weapons
		ply:StripWeapons()
		
		-- Give job weapons
		for _, wep in pairs(job.weapons) do
			ply:Give(wep)
		end
		
		-- Give ammo
		if job.ammo then
			for ammoType, amount in pairs(job.ammo) do
				ply:GiveAmmo(amount, ammoType)
			end
		end
		
		-- Custom loadout
		if job.PlayerLoadout then
			job.PlayerLoadout(ply)
		end
		
		return true
	end)
	
	-- Handle suicide
	hook.Add("CanPlayerSuicide", "DarkRP_JobSuicide", function(ply)
		local job = JOBS[ply:Team()]
		if not job then return true end
		
		if job.CanPlayerSuicide then
			return job.CanPlayerSuicide(ply)
		end
		
		return true
	end)
	
	-- Salary system
	timer.Create("DarkRP_Salary", 300, 0, function() -- Every 5 minutes
		for _, ply in pairs(player.GetAll()) do
			if IsValid(ply) then
				local job = JOBS[ply:Team()]
				if job and job.salary > 0 then
					ply:addMoney(job.salary)
					DarkRP.notify(ply, "You received $" .. job.salary .. " salary", 0)
				end
			end
		end
	end)
	
	-- Chat command handler
	hook.Add("PlayerSay", "DarkRP_JobCommands", function(ply, text)
		text = string.lower(text)
		
		-- Check for job commands
		if string.sub(text, 1, 1) == "/" then
			local command = string.sub(text, 2)
			
			local job, jobID = DarkRP.getJobByCommand(command)
			if job then
				DarkRP.changeJob(ply, jobID)
				return ""
			end
		end
	end)
	
	-- Clean up cooldowns on disconnect
	hook.Add("PlayerDisconnected", "DarkRP_CleanupCooldown", function(ply)
		jobChangeCooldowns[ply:SteamID()] = nil
	end)
	
	-- Notification system (if not already defined)
	function DarkRP.notify(ply, message, type)
		if not IsValid(ply) then return end
		
		-- Type: 0 = success, 1 = error, 2 = warning
		ply:ChatPrint("[DarkRP] " .. message)
		
		-- You can replace this with a custom notification system
	end
	
	-- Money system (basic implementation)
	local plyMeta = FindMetaTable("Player")
	
	function plyMeta:addMoney(amount)
		local current = self:getDarkRPVar("money") or 0
		self:setDarkRPVar("money", current + amount)
	end
	
	function plyMeta:setMoney(amount)
		self:setDarkRPVar("money", amount)
	end
	
	function plyMeta:getMoney()
		return self:getDarkRPVar("money") or 0
	end
	
	-- DarkRP vars (simple networked vars)
	function plyMeta:setDarkRPVar(key, value)
		self:SetNWString("DRP_" .. key, tostring(value))
	end
	
	function plyMeta:getDarkRPVar(key)
		return tonumber(self:GetNWString("DRP_" .. key)) or 0
	end
	
	-- Initialize money on spawn
	hook.Add("PlayerInitialSpawn", "DarkRP_InitMoney", function(ply)
		ply:setMoney(500) -- Starting money
	end)
else
	-- CLIENT
	
	-- Receive job change notification
	net.Receive("DarkRP_JobChanged", function()
		local jobID = net.ReadUInt(8)
		local job = JOBS[jobID]
		if job then
			chat.AddText(Color(0, 255, 0), "[DarkRP] ", Color(255, 255, 255), "You are now a ", job.color, job.name)
		end
	end)
	
	-- Request to change job
	function DarkRP.requestJob(jobID)
		net.Start("DarkRP_ChangeJob")
			net.WriteUInt(jobID, 8)
		net.SendToServer()
	end
end

-- Print loaded message
print("[DarkRP] Job system loaded")
