-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced Weed Growing System - Initialization
--  Load this file in your DarkRP gamemode init.lua or via loader
-- ═══════════════════════════════════════════════════════════════════════════

local WEED_VERSION = "1.0.0"

print("╔════════════════════════════════════════════════════════════╗")
print("║         DarkRP Advanced Weed System v" .. WEED_VERSION .. "           ║")
print("║         Using Zero's GrowOp 2 Content Pack               ║")
print("╚════════════════════════════════════════════════════════════╝")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Verify DarkRP                                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

if not DarkRP then
	ErrorNoHalt("[DarkRP Weed] ERROR: DarkRP not found! This system requires DarkRP.\n")
	return
end

print("[DarkRP Weed] init_weed.lua loaded - Setting up DarkRP integration...")

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  DarkRP Integration                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

if SERVER then
	-- Add custom jobs for weed system
	hook.Add("DarkRPFinishedLoading", "DarkRP.Weed.AddJobs", function()
		-- Weed Farmer Job
		TEAM_WEEDFARMER = DarkRP.createJob("Weed Farmer", {
			color = Color(100, 200, 100),
			model = {
				"models/player/hostage/hostage_01.mdl",
				"models/player/hostage/hostage_02.mdl",
				"models/player/hostage/hostage_03.mdl",
				"models/player/hostage/hostage_04.mdl"
			},
			description = [[You are a weed farmer. Grow and sell cannabis for profit.]],
			weapons = {},
			command = "weedfarmer",
			max = 4,
			salary = 50,
			admin = 0,
			vote = false,
			hasLicense = false,
			category = "Weed System"
		})
		
		-- Weed Dealer Job
		TEAM_WEEDDEALER = DarkRP.createJob("Weed Dealer", {
			color = Color(80, 160, 70),
			model = {
				"models/player/monk.mdl"
			},
			description = [[You are a weed dealer. Buy from farmers and sell to customers.]],
			weapons = {},
			command = "weeddealer",
			max = 2,
			salary = 75,
			admin = 0,
			vote = false,
			hasLicense = false,
			category = "Weed System"
		})
	end)
	
	-- Add entities to F4 menu
	hook.Add("DarkRPFinishedLoading", "DarkRP.Weed.AddEntities", function()
		-- Growing Equipment
		DarkRP.createEntity("Weed Growing Pot", {
			ent = "darkrp_weed_pot",
			model = "models/zerochain/props_growop2/zgo2_pot01.mdl",
			price = 50,
			max = 10,
			cmd = "buyweedpot",
			allowed = {TEAM_WEEDFARMER}
		})
		
		DarkRP.createEntity("LED Grow Lamp", {
			ent = "darkrp_weed_lamp",
			model = "models/zerochain/props_growop2/zgo2_led_lamp01.mdl",
			price = 500,
			max = 5,
			cmd = "buyweedlamp",
			allowed = {TEAM_WEEDFARMER}
		})
		
		DarkRP.createEntity("Drying Rack", {
			ent = "darkrp_weed_dryrack",
			model = "models/zerochain/props_growop2/zgo2_rack01.mdl",
			price = 200,
			max = 3,
			cmd = "buydryingrack",
			allowed = {TEAM_WEEDFARMER}
		})
	end)
	
	-- Add shipments (seeds)
	hook.Add("DarkRPFinishedLoading", "DarkRP.Weed.AddShipments", function()
		-- Add seed shipments for each strain
		DarkRP.createShipment("Schwag Seeds", {
			model = "models/zerochain/props_growop2/zgo2_weedseeds.mdl",
			entity = "darkrp_weed_seed_schwag",
			price = 50,
			amount = 5,
			separate = true,
			pricesep = 10,
			noship = false,
			allowed = {TEAM_WEEDFARMER},
			category = "Weed Seeds"
		})
		
		DarkRP.createShipment("Mid-Grade Seeds", {
			model = "models/zerochain/props_growop2/zgo2_weedseeds.mdl",
			entity = "darkrp_weed_seed_midgrade",
			price = 150,
			amount = 5,
			separate = true,
			pricesep = 30,
			noship = false,
			allowed = {TEAM_WEEDFARMER},
			category = "Weed Seeds"
		})
		
		DarkRP.createShipment("OG Kush Seeds", {
			model = "models/zerochain/props_growop2/zgo2_weedseeds.mdl",
			entity = "darkrp_weed_seed_og_kush",
			price = 300,
			amount = 5,
			separate = true,
			pricesep = 60,
			noship = false,
			allowed = {TEAM_WEEDFARMER},
			category = "Weed Seeds"
		})
		
		DarkRP.createShipment("Purple Haze Seeds", {
			model = "models/zerochain/props_growop2/zgo2_weedseeds.mdl",
			entity = "darkrp_weed_seed_purple_haze",
			price = 500,
			amount = 5,
			separate = true,
			pricesep = 100,
			noship = false,
			allowed = {TEAM_WEEDFARMER},
			category = "Weed Seeds"
		})
		
		DarkRP.createShipment("Northern Lights Seeds", {
			model = "models/zerochain/props_growop2/zgo2_weedseeds.mdl",
			entity = "darkrp_weed_seed_northern_lights",
			price = 1000,
			amount = 5,
			separate = true,
			pricesep = 200,
			noship = false,
			allowed = {TEAM_WEEDFARMER},
			category = "Weed Seeds"
		})
	end)
	
	print("[DarkRP Weed] Server integration complete")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  PANTHEON Commands                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

if SERVER then
	local function RegisterWeedCommands()
		if not pas or not pas.cmd then
			print("[DarkRP Weed] Warning: PANTHEON not loaded, commands will not be registered")
			return
		end
		
		-- Give seed command
		pas.cmd.Create('weedseed', function(pl, args)
			if not IsValid(pl) or not pl:IsPlayer() then return end
			
			local strainID = args[1] or "schwag"
			
			if not DarkRP.Weed.ValidateStrain(strainID) then
				pas.notify(pl, "Invalid strain ID!", 1)
				pas.notify(pl, "Valid strains: schwag, midgrade, og_kush, purple_haze, northern_lights", 2)
				return false
			end
			
			-- Spawn seed entity in front of player
			local trace = pl:GetEyeTrace()
			local spawnPos = trace.HitPos + trace.HitNormal * 10
			
			local seed = ents.Create("darkrp_weed_seed_" .. strainID)
			if IsValid(seed) then
				seed:SetPos(spawnPos)
				seed:Spawn()
				pas.notify(pl, "Spawned " .. strainID .. " seed!", 0)
			else
				pas.notify(pl, "Failed to spawn seed entity!", 1)
			end
		end)
			:SetFlag('a')
			:SetHelp('Spawn a weed seed entity')
			:SetIcon('icon16/bug.png')
			:AddAlias('giveseed')
			:AddArg('string', 'strain (schwag/midgrade/og_kush/purple_haze/northern_lights)')
		
		-- View weed stats command
		pas.cmd.Create('weedstats', function(pl, args)
			if not IsValid(pl) or not pl:IsPlayer() then return end
			
			if not DarkRP.Weed.Server then
				pas.notify(pl, "Weed system not fully loaded yet!", 1)
				return
			end
			
			local data = DarkRP.Weed.Server.GetPlayerData(pl)
			if data then
				pas.notify(pl, "═══ Your Weed Stats ═══", 2)
				pas.notify(pl, "Total Harvests: " .. data.stats.totalHarvests, 2)
				pas.notify(pl, "Total Grams: " .. string.format("%.1f", data.stats.totalGrams), 2)
				pas.notify(pl, "Total Earned: " .. DarkRP.Weed.FormatMoney(data.stats.totalEarned), 2)
				pas.notify(pl, "Plants Grown: " .. data.stats.plantsGrown, 2)
			end
		end)
			:SetFlag('u')
			:SetHelp('View your weed growing statistics')
			:SetIcon('icon16/chart_bar.png')
		
		print("[DarkRP Weed] PANTHEON commands registered")
	end
	
	-- Try to register immediately if PANTHEON is already loaded
	if pas and pas.cmd then
		RegisterWeedCommands()
	else
		-- Wait for PANTHEON to load
		hook.Add("PANTHEON_Loaded", "DarkRP.Weed.RegisterCommands", function()
			RegisterWeedCommands()
		end)
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  System Ready                                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

hook.Add("Initialize", "DarkRP.Weed.Ready", function()
	timer.Simple(1, function()
		print("╔════════════════════════════════════════════════════════════╗")
		print("║       DarkRP Weed System Loaded Successfully!             ║")
		print("║                                                            ║")
		print("║  Features:                                                ║")
		print("║  • " .. #DarkRP.Weed.Config.Strains .. " unique weed strains with growth stages      ║")
		print("║  • Advanced growth system with water/fertilizer          ║")
		print("║  • Light-based growth mechanics                          ║")
		print("║  • Quality and yield calculations                        ║")
		print("║  • Drying and processing system                          ║")
		print("║  • Visual effects when consuming                         ║")
		print("║  • Full F4 menu integration                              ║")
		print("║                                                            ║")
		print("║  Commands:                                                ║")
		print("║  • pas weedseed [strain] - Spawn weed seeds (admin)      ║")
		print("║  • pas weedstats - View your weed statistics             ║")
		print("╚════════════════════════════════════════════════════════════╝")
	end)
end)

return true
