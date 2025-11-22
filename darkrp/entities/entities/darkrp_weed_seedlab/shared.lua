AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Seed Laboratory"
ENT.Category = "DarkRP - Weed System"
ENT.Author = "DarkRP Weed System"
ENT.Spawnable = true
ENT.AdminOnly = false

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "JarsPlaced")
	self:NetworkVar("Bool", 0, "IsSplicing")
	self:NetworkVar("Entity", 0, "Owner")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/zerochain/props_growop2/zgo2_lab.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		-- Initialize seed lab data
		self:SetJarsPlaced(0)
		self:SetIsSplicing(false)
		
		self.placedJars = {}
		self.splicingTime = 20 -- 20 seconds to splice
	end
end

if SERVER then
	function ENT:Use(activator, caller)
		if not IsValid(caller) or not caller:IsPlayer() then return end
		
		-- Set owner if not set
		if not IsValid(self:GetOwner()) then
			self:SetOwner(caller)
		end
		
		-- Open seed lab menu
		net.Start("DarkRP.Weed.OpenSeedLab")
			net.WriteEntity(self)
			net.WriteTable(self.placedJars)
			net.WriteInt(self:GetJarsPlaced(), 8)
			net.WriteBool(self:GetIsSplicing())
		net.Send(caller)
	end
	
	function ENT:AddJar(strainID, strainName, grams, thc, quality, ply)
		if self:GetJarsPlaced() >= 2 then
			DarkRP.Weed.Notify(ply, "Seed lab is full! (2 jars max)", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		if self:GetIsSplicing() then
			DarkRP.Weed.Notify(ply, "Already splicing!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		table.insert(self.placedJars, {
			strainID = strainID,
			strainName = strainName,
			grams = grams,
			thc = thc,
			quality = quality
		})
		
		self:SetJarsPlaced(#self.placedJars)
		
		DarkRP.Weed.Notify(ply, string.format("Added %s jar (%d/2)", strainName, self:GetJarsPlaced()), DarkRP.Weed.NOTIFY_HINT)
		
		return true
	end
	
	function ENT:StartSplicing(ply, seedName)
		if self:GetJarsPlaced() < 2 then
			DarkRP.Weed.Notify(ply, "Need 2 jars to splice!", DarkRP.Weed.NOTIFY_ERROR)
			return false
		end
		
		if not seedName or seedName == "" then
			seedName = "Custom Strain"
		end
		
		self:SetIsSplicing(true)
		self.customSeedName = seedName
		
		DarkRP.Weed.Notify(ply, "Splicing seeds...", DarkRP.Weed.NOTIFY_HINT)
		
		timer.Simple(self.splicingTime, function()
			if not IsValid(self) then return end
			
			self:CompleteSplicing(ply)
		end)
		
		return true
	end
	
	function ENT:CompleteSplicing(ply)
		-- Average the stats from both jars
		local avgTHC = (self.placedJars[1].thc + self.placedJars[2].thc) / 2
		local avgQuality = (self.placedJars[1].quality + self.placedJars[2].quality) / 2
		
		-- Get the parent strains
		local parent1 = DarkRP.Weed.Config.GetStrain(self.placedJars[1].strainID)
		local parent2 = DarkRP.Weed.Config.GetStrain(self.placedJars[2].strainID)
		
		if not parent1 or not parent2 then
			DarkRP.Weed.Notify(ply, "Failed to splice seeds!", DarkRP.Weed.NOTIFY_ERROR)
			self:ClearLab()
			return false
		end
		
		-- Average growth time and yield
		local avgGrowthTime = (parent1.growthTime + parent2.growthTime) / 2
		local avgYieldMin = (parent1.yieldMin + parent2.yieldMin) / 2
		local avgYieldMax = (parent1.yieldMax + parent2.yieldMax) / 2
		
		-- Create custom seed data
		local customSeed = {
			id = "custom_" .. util.CRC(self.customSeedName .. CurTime()),
			name = self.customSeedName,
			description = string.format("Hybrid of %s and %s", parent1.name, parent2.name),
			tier = "custom",
			color = Color(
				(parent1.color.r + parent2.color.r) / 2,
				(parent1.color.g + parent2.color.g) / 2,
				(parent1.color.b + parent2.color.b) / 2
			),
			growthTime = avgGrowthTime,
			stages = parent1.stages, -- Use first parent's stages
			waterRequirement = (parent1.waterRequirement + parent2.waterRequirement) / 2,
			fertilizerRequirement = (parent1.fertilizerRequirement + parent2.fertilizerRequirement) / 2,
			lightRequirement = (parent1.lightRequirement + parent2.lightRequirement) / 2,
			yieldMin = avgYieldMin,
			yieldMax = avgYieldMax,
			qualityMin = avgQuality - 5,
			qualityMax = avgQuality + 5,
			pricePerGram = (parent1.pricePerGram + parent2.pricePerGram) / 2,
			baseTHC = avgTHC
		}
		
		-- Give custom seed to player (create seed entity)
		local seed = ents.Create("darkrp_weed_seed_custom")
		if IsValid(seed) then
			seed:SetPos(self:GetPos() + self:GetUp() * 30)
			seed:SetAngles(self:GetAngles())
			seed.customSeedData = customSeed
			seed:Spawn()
			seed:Activate()
		end
		
		DarkRP.Weed.Notify(ply, string.format("Created custom seed: %s!", self.customSeedName), DarkRP.Weed.NOTIFY_HINT)
		
		-- Clear lab
		self:ClearLab()
		
		return true
	end
	
	function ENT:ClearLab()
		self.placedJars = {}
		self:SetJarsPlaced(0)
		self:SetIsSplicing(false)
		self.customSeedName = nil
	end
	
	function ENT:Think()
		self:NextThink(CurTime() + 1)
		return true
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
		
		-- Draw status
		local pos = self:GetPos() + self:GetUp() * 60
		local ang = LocalPlayer():EyeAngles()
		ang:RotateAroundAxis(ang:Forward(), 90)
		ang:RotateAroundAxis(ang:Right(), 90)
		
		local dist = LocalPlayer():GetPos():Distance(pos)
		if dist > 300 then return end
		
		cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.1)
			draw.SimpleText("Seed Laboratory", "DarkRP.Weed.Medium", 0, -60, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(string.format("Jars: %d/2", self:GetJarsPlaced()), "DarkRP.Weed.Small", 0, -40, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
			if self:GetIsSplicing() then
				draw.SimpleText("SPLICING...", "DarkRP.Weed.Small", 0, -20, Color(100, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			draw.SimpleText("[E] Open", "DarkRP.Weed.Tiny", 0, 0, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end

-- Network strings
if SERVER then
	util.AddNetworkString("DarkRP.Weed.OpenSeedLab")
	util.AddNetworkString("DarkRP.Weed.SeedLab.AddJar")
	util.AddNetworkString("DarkRP.Weed.SeedLab.StartSplicing")
	util.AddNetworkString("DarkRP.Weed.SeedLab.Clear")
	
	net.Receive("DarkRP.Weed.SeedLab.StartSplicing", function(len, ply)
		local lab = net.ReadEntity()
		local seedName = net.ReadString()
		
		if not IsValid(lab) or lab:GetClass() ~= "darkrp_weed_seedlab" then return end
		
		lab:StartSplicing(ply, seedName)
	end)
	
	net.Receive("DarkRP.Weed.SeedLab.Clear", function(len, ply)
		local lab = net.ReadEntity()
		
		if not IsValid(lab) or lab:GetClass() ~= "darkrp_weed_seedlab" then return end
		
		lab:ClearLab()
	end)
end
