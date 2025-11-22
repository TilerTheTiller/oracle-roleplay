-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Advanced Weed Growing System - Configuration
--  Using Zero's GrowOp 2 Content Pack
-- ═══════════════════════════════════════════════════════════════════════════

DarkRP.Weed = DarkRP.Weed or {}
DarkRP.Weed.Config = {}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  General Settings                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Config.Enabled = true
DarkRP.Weed.Config.Debug = GetConVar("developer"):GetBool() or false

-- Growth timing (in seconds)
DarkRP.Weed.Config.GrowthTickRate = 5 -- How often to update growth
DarkRP.Weed.Config.WaterConsumptionRate = 2 -- How much water consumed per tick (%)
DarkRP.Weed.Config.FertilizerConsumptionRate = 1 -- How much fertilizer consumed per tick (%)

-- Plant health
DarkRP.Weed.Config.HealthDecayRate = 0.5 -- Health decay per tick without proper care
DarkRP.Weed.Config.HealthRegenRate = 1.0 -- Health regen per tick with proper care
DarkRP.Weed.Config.DeathThreshold = 10 -- Plant dies below this health %

-- Lighting
DarkRP.Weed.Config.RequireLight = true
DarkRP.Weed.Config.LightRadius = 200 -- Radius for lamp effect
DarkRP.Weed.Config.LightGrowthBoost = 1.5 -- Growth speed multiplier with lamp

-- Economy
DarkRP.Weed.Config.SeedPrices = {
	lowgrade = 100,
	midgrade = 250,
	highgrade = 500,
	premium = 1000,
	exotic = 2500
}

DarkRP.Weed.Config.EquipmentPrices = {
	pot = 50,
	lamp = 500,
	dryrack = 200,
	processingtable = 750,
	generator = 1500,
	watertank = 300
}

-- Maximum limits
DarkRP.Weed.Config.MaxPotsPerPlayer = 10
DarkRP.Weed.Config.MaxLampsPerPlayer = 5

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Plant Strain Definitions                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Config.Strains = {
	-- Low Grade Strains
	{
		id = "schwag",
		name = "Schwag",
		description = "Low quality street weed. Fast growing but low yield.",
		tier = "lowgrade",
		color = Color(100, 140, 60),
		
		-- Growth parameters
		growthTime = 300, -- 5 minutes total
		stages = {
			{name = "Seedling", duration = 60, model = "models/zerochain/props_growop2/zgo2_plant01.mdl", size = 0.3},
			{name = "Vegetative", duration = 120, model = "models/zerochain/props_growop2/zgo2_plant02.mdl", size = 0.6},
			{name = "Flowering", duration = 120, model = "models/zerochain/props_growop2/zgo2_plant03.mdl", size = 0.9},
			{name = "Harvest Ready", duration = 0, model = "models/zerochain/props_growop2/zgo2_plant04.mdl", size = 1.0}
		},
		
		-- Requirements
		waterRequirement = 50, -- % per stage
		fertilizerRequirement = 25,
		lightRequirement = 40,
		
		-- Yield
		yieldMin = 5,
		yieldMax = 15,
		qualityMin = 20,
		qualityMax = 40,
		
		-- Value
		pricePerGram = 5
	},
	
	{
		id = "midgrade",
		name = "Mid-Grade",
		description = "Decent quality cannabis. Balanced growth and yield.",
		tier = "midgrade",
		color = Color(80, 160, 70),
		
		growthTime = 420, -- 7 minutes
		stages = {
			{name = "Seedling", duration = 90, model = "models/zerochain/props_growop2/zgo2_plant01.mdl", size = 0.3},
			{name = "Vegetative", duration = 150, model = "models/zerochain/props_growop2/zgo2_plant02.mdl", size = 0.6},
			{name = "Flowering", duration = 180, model = "models/zerochain/props_growop2/zgo2_plant03.mdl", size = 0.9},
			{name = "Harvest Ready", duration = 0, model = "models/zerochain/props_growop2/zgo2_plant04.mdl", size = 1.0}
		},
		
		waterRequirement = 60,
		fertilizerRequirement = 35,
		lightRequirement = 50,
		
		yieldMin = 15,
		yieldMax = 30,
		qualityMin = 40,
		qualityMax = 60,
		
		pricePerGram = 10
	},
	
	{
		id = "og_kush",
		name = "OG Kush",
		description = "High quality strain. Strong effects and good yield.",
		tier = "highgrade",
		color = Color(60, 180, 80),
		
		growthTime = 600, -- 10 minutes
		stages = {
			{name = "Seedling", duration = 120, model = "models/zerochain/props_growop2/zgo2_plant01.mdl", size = 0.3},
			{name = "Vegetative", duration = 180, model = "models/zerochain/props_growop2/zgo2_plant02.mdl", size = 0.6},
			{name = "Flowering", duration = 300, model = "models/zerochain/props_growop2/zgo2_plant03.mdl", size = 0.9},
			{name = "Harvest Ready", duration = 0, model = "models/zerochain/props_growop2/zgo2_plant04.mdl", size = 1.0}
		},
		
		waterRequirement = 70,
		fertilizerRequirement = 50,
		lightRequirement = 70,
		
		yieldMin = 25,
		yieldMax = 45,
		qualityMin = 60,
		qualityMax = 80,
		
		pricePerGram = 20
	},
	
	{
		id = "purple_haze",
		name = "Purple Haze",
		description = "Premium strain with purple hues. Requires expert care.",
		tier = "premium",
		color = Color(120, 80, 180),
		
		growthTime = 780, -- 13 minutes
		stages = {
			{name = "Seedling", duration = 150, model = "models/zerochain/props_growop2/zgo2_plant01.mdl", size = 0.3},
			{name = "Vegetative", duration = 240, model = "models/zerochain/props_growop2/zgo2_plant02.mdl", size = 0.6},
			{name = "Flowering", duration = 390, model = "models/zerochain/props_growop2/zgo2_plant03.mdl", size = 0.9},
			{name = "Harvest Ready", duration = 0, model = "models/zerochain/props_growop2/zgo2_plant04.mdl", size = 1.0}
		},
		
		waterRequirement = 80,
		fertilizerRequirement = 70,
		lightRequirement = 85,
		
		yieldMin = 35,
		yieldMax = 60,
		qualityMin = 75,
		qualityMax = 95,
		
		pricePerGram = 35
	},
	
	{
		id = "northern_lights",
		name = "Northern Lights",
		description = "Exotic strain with glowing trichomes. Extremely rare.",
		tier = "exotic",
		color = Color(100, 200, 255),
		
		growthTime = 960, -- 16 minutes
		stages = {
			{name = "Seedling", duration = 180, model = "models/zerochain/props_growop2/zgo2_plant01.mdl", size = 0.3},
			{name = "Vegetative", duration = 300, model = "models/zerochain/props_growop2/zgo2_plant02.mdl", size = 0.6},
			{name = "Flowering", duration = 480, model = "models/zerochain/props_growop2/zgo2_plant03.mdl", size = 0.9},
			{name = "Harvest Ready", duration = 0, model = "models/zerochain/props_growop2/zgo2_plant04.mdl", size = 1.0}
		},
		
		waterRequirement = 90,
		fertilizerRequirement = 85,
		lightRequirement = 95,
		
		yieldMin = 50,
		yieldMax = 80,
		qualityMin = 90,
		qualityMax = 100,
		
		pricePerGram = 50
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Product Definitions                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Config.Products = {
	-- Raw Products
	{
		id = "weed_raw",
		name = "Raw Weed",
		description = "Freshly harvested cannabis. Needs to be dried.",
		category = "raw",
		model = "models/zerochain/props_growop2/zgo2_weedblock.mdl",
		sellable = false,
		consumable = false,
		processingTime = 0
	},
	
	{
		id = "weed_dried",
		name = "Dried Weed",
		description = "Properly dried cannabis. Ready for processing.",
		category = "dried",
		model = "models/zerochain/props_growop2/zgo2_weedblock.mdl",
		sellable = true,
		consumable = false,
		processingTime = 60, -- 1 minute to dry
		valueMultiplier = 1.5
	},
	
	-- Processed Products
	{
		id = "weed_baggy",
		name = "Weed Baggy",
		description = "Small bag of weed. Perfect for street deals.",
		category = "processed",
		model = "models/zerochain/props_growop2/zgo2_baggy.mdl",
		sellable = true,
		consumable = true,
		processingTime = 10,
		gramsRequired = 3.5,
		valueMultiplier = 1.2,
		effects = {
			duration = 120,
			healthBoost = 10,
			armorBoost = 0,
			speedMultiplier = 1.0,
			damageReduction = 0,
			hungerSatisfy = 20,
			highlevel = 1
		}
	},
	
	{
		id = "weed_jar",
		name = "Weed Jar",
		description = "Premium storage jar. Preserves quality.",
		category = "processed",
		model = "models/zerochain/props_growop2/zgo2_jar.mdl",
		sellable = true,
		consumable = false,
		processingTime = 30,
		gramsRequired = 28,
		valueMultiplier = 1.8
	},
	
	-- Consumables
	{
		id = "joint",
		name = "Joint",
		description = "Hand-rolled joint. Classic way to consume.",
		category = "consumable",
		model = "models/zerochain/props_growop2/zgo2_joint.mdl",
		worldModel = "models/zerochain/props_growop2/zgo2_joint_wm.mdl",
		viewModel = "models/zerochain/props_growop2/zgo2_joint_vm.mdl",
		sellable = true,
		consumable = true,
		processingTime = 5,
		gramsRequired = 0.5,
		valueMultiplier = 2.0,
		effects = {
			duration = 90,
			healthBoost = 5,
			armorBoost = 0,
			speedMultiplier = 0.95,
			damageReduction = 5,
			hungerSatisfy = 10,
			highlevel = 1
		}
	},
	
	{
		id = "bong_hit",
		name = "Bong",
		description = "Water pipe for smooth hits.",
		category = "consumable",
		model = "models/zerochain/props_growop2/zgo2_bong01_wm.mdl",
		worldModel = "models/zerochain/props_growop2/zgo2_bong01_wm.mdl",
		viewModel = "models/zerochain/props_growop2/zgo2_bong01_vm.mdl",
		sellable = true,
		consumable = true,
		reusable = true,
		processingTime = 0,
		gramsRequired = 0.3,
		valueMultiplier = 3.0,
		effects = {
			duration = 180,
			healthBoost = 20,
			armorBoost = 5,
			speedMultiplier = 0.9,
			damageReduction = 10,
			hungerSatisfy = 5,
			highlevel = 2
		}
	},
	
	-- Edibles
	{
		id = "weed_brownie",
		name = "Weed Brownie",
		description = "Delicious and potent edible. Long-lasting effects.",
		category = "edible",
		model = "models/zerochain/props_growop2/zgo2_food_brownie.mdl",
		sellable = true,
		consumable = true,
		processingTime = 120,
		gramsRequired = 2,
		valueMultiplier = 2.5,
		requiresOven = true,
		effects = {
			duration = 300,
			healthBoost = 30,
			armorBoost = 10,
			speedMultiplier = 0.85,
			damageReduction = 15,
			hungerSatisfy = 50,
			highlevel = 3
		}
	},
	
	{
		id = "weed_cookie",
		name = "Weed Cookie",
		description = "Sweet and potent cookie.",
		category = "edible",
		model = "models/zerochain/props_growop2/zgo2_food_cookie.mdl",
		sellable = true,
		consumable = true,
		processingTime = 90,
		gramsRequired = 1.5,
		valueMultiplier = 2.2,
		requiresOven = true,
		effects = {
			duration = 240,
			healthBoost = 25,
			armorBoost = 5,
			speedMultiplier = 0.9,
			damageReduction = 10,
			hungerSatisfy = 40,
			highlevel = 2
		}
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Equipment Definitions                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Config.Equipment = {
	pots = {
		{
			id = "pot_small",
			name = "Small Pot",
			description = "Basic growing pot. Good for beginners.",
			model = "models/zerochain/props_growop2/zgo2_pot01.mdl",
			price = 50,
			capacity = 1, -- number of plants
			qualityBonus = 0
		},
		{
			id = "pot_medium",
			name = "Medium Pot",
			description = "Standard size pot. Slightly better yields.",
			model = "models/zerochain/props_growop2/zgo2_pot03.mdl",
			price = 100,
			capacity = 1,
			qualityBonus = 5
		},
		{
			id = "pot_large",
			name = "Large Pot",
			description = "Professional growing container. Best yields.",
			model = "models/zerochain/props_growop2/zgo2_pot06.mdl",
			price = 200,
			capacity = 1,
			qualityBonus = 10
		}
	},
	
	lamps = {
		{
			id = "lamp_led",
			name = "LED Grow Lamp",
			description = "Energy efficient LED grow light.",
			model = "models/zerochain/props_growop2/zgo2_led_lamp01.mdl",
			price = 500,
			radius = 150,
			growthBoost = 1.3,
			powerConsumption = 5 -- per minute
		},
		{
			id = "lamp_sodium",
			name = "Sodium Lamp",
			description = "High-intensity sodium lamp. Best for flowering.",
			model = "models/zerochain/props_growop2/zgo2_sodium_lamp01.mdl",
			price = 750,
			radius = 200,
			growthBoost = 1.5,
			powerConsumption = 10
		},
		{
			id = "lamp_tent",
			name = "Tent Lamp",
			description = "All-in-one tent with integrated lighting.",
			model = "models/zerochain/props_growop2/zgo2_tent_led_lamp.mdl",
			price = 1200,
			radius = 250,
			growthBoost = 1.7,
			powerConsumption = 8,
			hidesPlantsInside = true
		}
	},
	
	processing = {
		{
			id = "dryrack",
			name = "Drying Rack",
			description = "Hang and dry your harvest properly.",
			model = "models/zerochain/props_growop2/zgo2_rack01.mdl",
			price = 200,
			slots = 4,
			dryTime = 60
		},
		{
			id = "dryline",
			name = "Drying Line",
			description = "Simple clothesline for drying.",
			model = "models/zerochain/props_growop2/zgo2_dryline.mdl",
			price = 100,
			slots = 6,
			dryTime = 90
		},
		{
			id = "processing_table",
			name = "Processing Table",
			description = "Roll joints, pack bags, and more.",
			model = "models/zerochain/props_growop2/zgo2_doobytable.mdl",
			price = 750,
			speedMultiplier = 1.5
		},
		{
			id = "oven",
			name = "Baking Oven",
			description = "Make delicious edibles.",
			model = "models/zerochain/props_growop2/zgo2_oven.mdl",
			price = 600,
			requiredForEdibles = true
		}
	},
	
	utility = {
		{
			id = "generator",
			name = "Generator",
			description = "Provides power for your lamps.",
			model = "models/zerochain/props_growop2/zgo2_generator01.mdl",
			price = 1500,
			fuelCapacity = 100,
			fuelConsumption = 1, -- per minute
			powerOutput = 50
		},
		{
			id = "watertank",
			name = "Water Tank",
			description = "Store water for your plants.",
			model = "models/zerochain/props_growop2/zgo2_watertank.mdl",
			price = 300,
			capacity = 1000 -- liters
		},
		{
			id = "watertank_small",
			name = "Small Water Tank",
			description = "Compact water storage.",
			model = "models/zerochain/props_growop2/zgo2_watertank_small.mdl",
			price = 150,
			capacity = 500
		}
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Effects Configuration                                        ║
-- ╚═══════════════════════════════════════════════════════════════╝

DarkRP.Weed.Config.HighEffects = {
	-- Level 1: Mild high
	{
		level = 1,
		screenEffects = {
			colormod = {
				["$pp_colour_addr"] = 0.02,
				["$pp_colour_addg"] = 0.05,
				["$pp_colour_addb"] = 0,
				["$pp_colour_brightness"] = 0.02,
				["$pp_colour_contrast"] = 1.05,
				["$pp_colour_colour"] = 1.1,
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 0
			},
			motionblur = 0.1,
			blur = 0
		},
		sounds = {
			ambient = "ambient/levels/canals/windmill_wind_loop1.wav",
			volume = 0.3
		}
	},
	
	-- Level 2: Moderate high
	{
		level = 2,
		screenEffects = {
			colormod = {
				["$pp_colour_addr"] = 0.03,
				["$pp_colour_addg"] = 0.08,
				["$pp_colour_addb"] = 0.02,
				["$pp_colour_brightness"] = 0.05,
				["$pp_colour_contrast"] = 1.1,
				["$pp_colour_colour"] = 1.2,
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 0
			},
			motionblur = 0.2,
			blur = 0.5
		},
		sounds = {
			ambient = "ambient/levels/canals/windmill_wind_loop1.wav",
			volume = 0.5
		}
	},
	
	-- Level 3: Strong high
	{
		level = 3,
		screenEffects = {
			colormod = {
				["$pp_colour_addr"] = 0.05,
				["$pp_colour_addg"] = 0.12,
				["$pp_colour_addb"] = 0.05,
				["$pp_colour_brightness"] = 0.08,
				["$pp_colour_contrast"] = 1.15,
				["$pp_colour_colour"] = 1.3,
				["$pp_colour_mulr"] = 0,
				["$pp_colour_mulg"] = 0,
				["$pp_colour_mulb"] = 0
			},
			motionblur = 0.4,
			blur = 1.5
		},
		sounds = {
			ambient = "ambient/levels/canals/windmill_wind_loop1.wav",
			volume = 0.7
		}
	}
}

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Helper Functions                                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

function DarkRP.Weed.Config.GetStrain(id)
	for _, strain in ipairs(DarkRP.Weed.Config.Strains) do
		if strain.id == id then
			return strain
		end
	end
	return nil
end

function DarkRP.Weed.Config.GetProduct(id)
	for _, product in ipairs(DarkRP.Weed.Config.Products) do
		if product.id == id then
			return product
		end
	end
	return nil
end

function DarkRP.Weed.Config.GetEquipment(category, id)
	if not DarkRP.Weed.Config.Equipment[category] then return nil end
	
	for _, item in ipairs(DarkRP.Weed.Config.Equipment[category]) do
		if item.id == id then
			return item
		end
	end
	return nil
end

function DarkRP.Weed.Config.GetHighEffect(level)
	for _, effect in ipairs(DarkRP.Weed.Config.HighEffects) do
		if effect.level == level then
			return effect
		end
	end
	return DarkRP.Weed.Config.HighEffects[1]
end

if SERVER then
	print("[DarkRP Weed] Configuration loaded - " .. #DarkRP.Weed.Config.Strains .. " strains, " .. #DarkRP.Weed.Config.Products .. " products")
end

return DarkRP.Weed.Config
