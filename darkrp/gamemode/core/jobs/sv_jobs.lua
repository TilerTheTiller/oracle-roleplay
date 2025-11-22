-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Jobs System - Server-Side Data Persistence
--  Handles job data saving/loading via MySQL
-- ═══════════════════════════════════════════════════════════════════════════

if CLIENT then return end

DarkRP = DarkRP or {}
DarkRP.jobs = DarkRP.jobs or {}
DarkRP.jobs._playerJobData = {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Player Job Data Management                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.jobs.SavePlayerJobData(ply, jobID)
	if not IsValid(ply) then return end
	if not jobID then jobID = ply:Team() end
	
	local steamID = ply:SteamID()
	
	-- Update player's current job in players table
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query([[
			UPDATE darkrp_players SET job_id = ? WHERE steamid = ?
		]], {jobID, steamID})
		
		-- Track job statistics
		DarkRP.database.Query([[
			INSERT INTO darkrp_jobs_data (steamid, job_id, total_time, times_played)
			VALUES (?, ?, 0, 1)
			ON DUPLICATE KEY UPDATE
				times_played = times_played + 1,
				last_played = CURRENT_TIMESTAMP
		]], {steamID, jobID})
	end
	
	print("[DarkRP:Jobs] Saved job data for " .. ply:Nick() .. " (Job: " .. jobID .. ")")
end

function DarkRP.jobs.LoadPlayerJobData(ply)
	if not IsValid(ply) then return end
	
	local steamID = ply:SteamID()
	
	local query = [[
		SELECT job_id FROM darkrp_players WHERE steamid = ?
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {steamID}, function(data, success, err)
			if not IsValid(ply) then return end
			
			if success and data and #data > 0 then
				local lastJobID = tonumber(data[1].job_id) or TEAM_CITIZEN
				
				-- Validate job still exists
				if JOBS[lastJobID] then
					-- Change to last job after spawn
					timer.Simple(0.5, function()
						if IsValid(ply) then
							DarkRP.changeJob(ply, lastJobID, true)
							print("[DarkRP:Jobs] Restored " .. ply:Nick() .. "'s last job: " .. JOBS[lastJobID].name)
						end
					end)
				else
					print("[DarkRP:Jobs] Job " .. lastJobID .. " no longer exists, defaulting to TEAM_CITIZEN")
				end
			else
				print("[DarkRP:Jobs] No previous job data for " .. ply:Nick())
			end
		end)
	end
end

function DarkRP.jobs.GetPlayerJobStats(ply, jobID)
	if not IsValid(ply) then return nil end
	
	local steamID = ply:SteamID()
	
	local query = [[
		SELECT total_time, times_played, last_played 
		FROM darkrp_jobs_data 
		WHERE steamid = ? AND job_id = ?
	]]
	
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query(query, {steamID, jobID}, function(data, success, err)
			if success and data and #data > 0 then
				return data[1]
			end
		end)
	end
	
	return nil
end

function DarkRP.jobs.UpdateJobPlaytime(ply)
	if not IsValid(ply) then return end
	
	local steamID = ply:SteamID()
	local jobID = ply:Team()
	
	-- This should be called periodically to track time played in each job
	if DarkRP.database and DarkRP.database.IsConnected() then
		DarkRP.database.Query([[
			UPDATE darkrp_jobs_data 
			SET total_time = total_time + 60 
			WHERE steamid = ? AND job_id = ?
		]], {steamID, jobID})
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Hooks                                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- Save job when player changes jobs
hook.Add("DarkRP_PlayerChangedJob", "DarkRP.Jobs.SaveOnChange", function(ply, newJob, oldJob)
	DarkRP.jobs.SavePlayerJobData(ply, newJob)
end)

-- Load job data on player spawn
-- DISABLED: Character system handles job restoration
--[[
hook.Add("PlayerInitialSpawn", "DarkRP.Jobs.LoadData", function(ply)
	timer.Simple(1.5, function()
		if IsValid(ply) then
			DarkRP.jobs.LoadPlayerJobData(ply)
		end
	end)
end)
]]

-- Save job data on disconnect
hook.Add("PlayerDisconnected", "DarkRP.Jobs.SaveOnDisconnect", function(ply)
	DarkRP.jobs.SavePlayerJobData(ply)
end)

-- Track playtime every minute
timer.Create("DarkRP.Jobs.PlaytimeTracker", 60, 0, function()
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			DarkRP.jobs.UpdateJobPlaytime(ply)
		end
	end
end)

-- Save all job data on server shutdown
hook.Add("ShutDown", "DarkRP.Jobs.SaveAll", function()
	for _, ply in pairs(player.GetAll()) do
		DarkRP.jobs.SavePlayerJobData(ply)
	end
	print("[DarkRP:Jobs] Saved all player job data on shutdown")
end)

print("[DarkRP:Jobs] Server-side persistence module loaded")
