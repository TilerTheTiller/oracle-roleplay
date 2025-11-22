AddCSLuaFile()

--[[
	DarkRP Job System Configuration
	Define all jobs/classes for your gamemode here
]]--

-- Job table
JOBS = JOBS or {}

-- Team/Job IDs
TEAM_CITIZEN = 1
TEAM_POLICE = 2
TEAM_MEDIC = 3
TEAM_GANGSTER = 4
TEAM_MAYOR = 5
TEAM_GUN_DEALER = 6
TEAM_HOBO = 7

--[[
	Job Creation Function
	Creates a new job/team with the specified properties
	
	Parameters:
	- name: Display name of the job
	- color: Team color (Color object)
	- model: Player model(s) - string or table of strings
	- description: Job description
	- weapons: Table of weapon class names
	- command: Chat command to become this job
	- max: Maximum number of players with this job (0 = unlimited)
	- salary: Money earned per paycheck
	- admin: Admin level required (0 = none, 1 = admin, 2 = superadmin)
	- vote: Does this job require a vote?
	- hasLicense: Does this job have a license?
	- category: Job category for organization
]]--
function DarkRP.createJob(name, data)
	local jobID = table.Count(JOBS) + 1
	
	JOBS[jobID] = {
		team = jobID,
		name = name,
		color = data.color or Color(255, 255, 255),
		model = data.model or "models/player/group01/male_01.mdl",
		description = data.description or "No description",
		weapons = data.weapons or {},
		command = data.command or string.lower(string.gsub(name, " ", "")),
		max = data.max or 0,
		salary = data.salary or 50,
		admin = data.admin or 0,
		vote = data.vote or false,
		hasLicense = data.hasLicense or false,
		category = data.category or "Citizens",
		sortOrder = data.sortOrder or jobID,
		-- Optional fields
		chief = data.chief or false,
		mayor = data.mayor or false,
		medic = data.medic or false,
		cook = data.cook or false,
		hobo = data.hobo or false,
		PlayerSpawn = data.PlayerSpawn,
		PlayerDeath = data.PlayerDeath,
		PlayerLoadout = data.PlayerLoadout,
		CanPlayerSuicide = data.CanPlayerSuicide,
		-- Custom fields
		customCheck = data.customCheck,
		CustomCheckFailMsg = data.CustomCheckFailMsg,
		ammo = data.ammo or {}
	}
	
	-- Register team
	team.SetUp(jobID, name, data.color or Color(255, 255, 255))
	
	-- Set spawnpoint for this team if specified
	if data.spawn then
		team.SetSpawnPoint(jobID, data.spawn)
	end
	
	-- Set class for this team if specified
	if data.class then
		team.SetClass(jobID, data.class)
	end
	
	return jobID
end

--[[
	DEFINE JOBS BELOW
]]--

-- Citizen
DarkRP.createJob("Citizen", {
	color = Color(20, 150, 20),
	model = {
		"models/player/group01/male_01.mdl",
		"models/player/group01/male_02.mdl",
		"models/player/group01/male_03.mdl",
		"models/player/group01/male_04.mdl",
		"models/player/group01/male_05.mdl",
		"models/player/group01/male_06.mdl",
		"models/player/group01/male_07.mdl",
		"models/player/group01/male_08.mdl",
		"models/player/group01/male_09.mdl",
		"models/player/group01/female_01.mdl",
		"models/player/group01/female_02.mdl",
		"models/player/group01/female_03.mdl",
		"models/player/group01/female_04.mdl",
		"models/player/group01/female_05.mdl",
		"models/player/group01/female_06.mdl",
	},
	description = [[The Citizen is the most basic class. 
	You can do anything legal as a citizen.]],
	weapons = {},
	command = "citizen",
	max = 0,
	salary = 45,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Citizens",
})

-- Police Officer
DarkRP.createJob("Police Officer", {
	color = Color(25, 25, 170),
	model = {
		"models/player/police.mdl",
		"models/player/police_fem.mdl"
	},
	description = [[Protect and serve the city.
	Arrest criminals and maintain law and order.
	Follow the law and the Mayor's orders.]],
	weapons = {"arrest_stick", "unarrest_stick", "weapon_pistol", "stunstick", "door_ram"},
	command = "police",
	max = 4,
	salary = 75,
	admin = 0,
	vote = false,
	hasLicense = true,
	category = "Civil Protection",
	ammo = {
		["pistol"] = 120,
	}
})

-- Medic
DarkRP.createJob("Medic", {
	color = Color(47, 79, 79),
	model = {
		"models/player/kleiner.mdl"
	},
	description = [[Heal players with your Medical Kit.
	You cannot own weapons as a Medic.]],
	weapons = {"med_kit"},
	command = "medic",
	max = 3,
	salary = 60,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Citizens",
	medic = true
})

-- Gangster
DarkRP.createJob("Gangster", {
	color = Color(75, 75, 75),
	model = {
		"models/player/group03/male_01.mdl",
		"models/player/group03/male_02.mdl",
		"models/player/group03/male_03.mdl",
		"models/player/group03/male_04.mdl",
		"models/player/group03/male_05.mdl",
		"models/player/group03/male_06.mdl",
		"models/player/group03/male_07.mdl",
		"models/player/group03/male_08.mdl",
		"models/player/group03/male_09.mdl",
	},
	description = [[The Gangster is a criminal.
	You can mug, raid, and commit crimes.
	Work with other gangsters to control the city.]],
	weapons = {"lockpick"},
	command = "gangster",
	max = 4,
	salary = 35,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Gangsters",
})

-- Mayor
DarkRP.createJob("Mayor", {
	color = Color(150, 20, 20),
	model = {
		"models/player/breen.mdl"
	},
	description = [[The Mayor leads the city.
	Create laws and manage the police force.
	Set taxes and control city operations.]],
	weapons = {},
	command = "mayor",
	max = 1,
	salary = 100,
	admin = 0,
	vote = true,
	hasLicense = false,
	category = "Civil Protection",
	mayor = true
})

-- Gun Dealer
DarkRP.createJob("Gun Dealer", {
	color = Color(255, 140, 0),
	model = {
		"models/player/monk.mdl"
	},
	description = [[Sell guns to citizens.
	You can own and sell weapons legally.
	Set up shop and make money from sales.]],
	weapons = {},
	command = "gundealer",
	max = 2,
	salary = 50,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Citizens",
})

-- Hobo
DarkRP.createJob("Hobo", {
	color = Color(80, 45, 0),
	model = {
		"models/player/corpse1.mdl"
	},
	description = [[You are homeless.
	Beg for money and survive on the streets.
	You cannot own doors or items.]],
	weapons = {"weapon_bugbait"},
	command = "hobo",
	max = 5,
	salary = 0,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Citizens",
	hobo = true
})

--[[
	Additional Jobs - Uncomment and customize as needed
]]--

--[[
DarkRP.createJob("Police Chief", {
	color = Color(20, 20, 255),
	model = "models/player/combine_soldier_prisonguard.mdl",
	description = "Lead the police force. You are the highest ranking police officer.",
	weapons = {"arrest_stick", "unarrest_stick", "weapon_pistol", "weapon_smg1", "stunstick", "door_ram"},
	command = "chief",
	max = 1,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = true,
	category = "Civil Protection",
	chief = true,
	customCheck = function(ply)
		return team.NumPlayers(TEAM_POLICE) >= 2
	end,
	CustomCheckFailMsg = "Need at least 2 police officers online."
})

DarkRP.createJob("Thief", {
	color = Color(50, 50, 50),
	model = "models/player/phoenix.mdl",
	description = "Steal from others. You are a professional thief.",
	weapons = {"lockpick", "keypad_cracker"},
	command = "thief",
	max = 2,
	salary = 40,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Gangsters",
})

DarkRP.createJob("Black Market Dealer", {
	color = Color(30, 30, 30),
	model = "models/player/guerilla.mdl",
	description = "Sell illegal weapons and items. You operate in the shadows.",
	weapons = {},
	command = "blackmarket",
	max = 1,
	salary = 60,
	admin = 0,
	vote = false,
	hasLicense = false,
	category = "Gangsters",
})
]]--

-- Print job count
if SERVER then
	print("[DarkRP] Loaded " .. table.Count(JOBS) .. " jobs")
end
