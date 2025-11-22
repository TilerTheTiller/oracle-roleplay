-- ═══════════════════════════════════════════════════════════════════════════
--  DarkRP Weed System - Bong SWEP
-- ═══════════════════════════════════════════════════════════════════════════

if SERVER then
	AddCSLuaFile()
	
	util.AddNetworkString("DarkRP.Weed.Bong.Fill")
	util.AddNetworkString("DarkRP.Weed.Bong.Smoke")
	util.AddNetworkString("DarkRP.Weed.Bong.Share")
end

SWEP.PrintName = "Bong"
SWEP.Category = "DarkRP Weed"
SWEP.Author = "DarkRP"
SWEP.Instructions = "Left Click: Smoke | Reload: Empty | Right Click: Share/Drop"
SWEP.Purpose = "Smoke weed from a bong"

SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.AdminSpawnable = true

SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/zerochain/props_growop2/zgo2_bong01.mdl"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

-- Bong data
SWEP.IsFilled = false
SWEP.WeedStrain = nil
SWEP.WeedGrams = 0
SWEP.WeedQuality = 0
SWEP.WeedTHC = 0
SWEP.UsesRemaining = 0

-- Smoking state
SWEP.IsSmoking = false
SWEP.SmokeStartTime = 0
SWEP.SmokeDuration = 3 -- seconds to hold smoke

function SWEP:Initialize()
	self:SetHoldType("slam")
	
	if SERVER then
		self:SetNWBool("Bong.IsFilled", false)
		self:SetNWString("Bong.Strain", "")
		self:SetNWInt("Bong.UsesRemaining", 0)
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "IsFilled")
	self:NetworkVar("String", 0, "StrainName")
	self:NetworkVar("Int", 0, "UsesLeft")
	self:NetworkVar("Float", 0, "THCLevel")
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Primary Attack - Smoke                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

function SWEP:PrimaryAttack()
	if not IsValid(self:GetOwner()) then return end
	
	if not self:GetIsFilled() then
		if CLIENT then
			chat.AddText(Color(255, 100, 100), "[Bong] ", Color(255, 255, 255), "Bong is empty! Fill it with weed first.")
		end
		return
	end
	
	if self.IsSmoking then return end
	
	-- Start smoking
	self.IsSmoking = true
	self.SmokeStartTime = CurTime()
	
	if SERVER then
		self:GetOwner():SetAnimation(PLAYER_ATTACK1)
		
		-- Play bubbling sound
		self:EmitSound("ambient/water/water_flow_loop1.wav", 60, 100, 0.5)
	end
	
	self:SetNextPrimaryFire(CurTime() + self.SmokeDuration + 1)
end

function SWEP:Think()
	if not IsValid(self:GetOwner()) then return end
	
	-- Smoking timer
	if self.IsSmoking and CurTime() - self.SmokeStartTime >= self.SmokeDuration then
		self:CompleteSmoking()
	end
end

function SWEP:CompleteSmoking()
	if not self.IsSmoking then return end
	
	self.IsSmoking = false
	
	if SERVER then
		local owner = self:GetOwner()
		if not IsValid(owner) then return end
		
		-- Stop bubbling sound
		self:StopSound("ambient/water/water_flow_loop1.wav")
		
		-- Play exhale sound
		self:EmitSound("player/breathe1.wav", 60, 80)
		
		-- Apply weed effects
		local thc = self:GetTHCLevel()
		local quality = self.WeedQuality
		
		-- Determine high level based on THC
		local highLevel = 1
		if thc >= 25 then
			highLevel = 3
		elseif thc >= 18 then
			highLevel = 2
		end
		
		-- Apply screen effects to player
		net.Start("DarkRP.Weed.Bong.Smoke")
			net.WriteInt(highLevel, 8)
			net.WriteFloat(thc)
			net.WriteFloat(quality)
		net.Send(owner)
		
		-- Health/armor bonus
		if quality >= 70 then
			owner:SetHealth(math.min(owner:GetMaxHealth(), owner:Health() + 10))
		end
		
		-- Reduce uses
		local uses = self:GetUsesLeft() - 1
		self:SetUsesLeft(uses)
		
		if uses <= 0 then
			self:EmptyBong()
			
			if IsValid(owner) then
				DarkRP.notify(owner, 1, 3, "Bong is now empty!")
			end
		else
			if IsValid(owner) then
				DarkRP.notify(owner, 0, 3, "Uses remaining: " .. uses)
			end
		end
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Secondary Attack - Share/Drop                                ║
-- ╚═══════════════════════════════════════════════════════════════╝

function SWEP:SecondaryAttack()
	if not IsValid(self:GetOwner()) then return end
	
	if not self:GetIsFilled() then return end
	
	if SERVER then
		local owner = self:GetOwner()
		
		-- Find player in front
		local trace = owner:GetEyeTrace()
		
		if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.HitPos:Distance(owner:GetPos()) <= 100 then
			-- Share with player
			local target = trace.Entity
			
			-- Give target a copy of this bong
			local newBong = ents.Create("weapon_darkrp_weed_bong")
			if IsValid(newBong) then
				newBong:SetPos(target:GetPos() + Vector(0, 0, 50))
				newBong:Spawn()
				
				-- Copy bong data
				newBong:SetIsFilled(true)
				newBong:SetStrainName(self:GetStrainName())
				newBong:SetUsesLeft(1) -- Share 1 use
				newBong:SetTHCLevel(self:GetTHCLevel())
				newBong.WeedStrain = self.WeedStrain
				newBong.WeedQuality = self.WeedQuality
				
				target:PickupObject(newBong)
				
				DarkRP.notify(owner, 0, 3, "Shared bong with " .. target:Nick())
				DarkRP.notify(target, 0, 3, owner:Nick() .. " shared a bong with you!")
				
				-- Reduce our uses
				local uses = self:GetUsesLeft() - 1
				self:SetUsesLeft(uses)
				
				if uses <= 0 then
					self:EmptyBong()
				end
			end
		else
			-- Drop bong
			owner:DropWeapon(self)
			DarkRP.notify(owner, 1, 3, "Dropped bong")
		end
	end
	
	self:SetNextSecondaryFire(CurTime() + 1)
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Reload - Empty Bong                                          ║
-- ╚═══════════════════════════════════════════════════════════════╝

function SWEP:Reload()
	if not self:GetIsFilled() then return end
	
	if SERVER then
		self:EmptyBong()
		
		if IsValid(self:GetOwner()) then
			DarkRP.notify(self:GetOwner(), 1, 3, "Emptied bong")
		end
	end
	
	self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:EmptyBong()
	self:SetIsFilled(false)
	self:SetStrainName("")
	self:SetUsesLeft(0)
	self:SetTHCLevel(0)
	
	self.WeedStrain = nil
	self.WeedGrams = 0
	self.WeedQuality = 0
	self.WeedTHC = 0
	self.UsesRemaining = 0
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Fill Bong (Server)                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

if SERVER then
	function SWEP:FillBong(strainID, grams, quality, thc)
		local strain = DarkRP.Weed.Config.GetStrain(strainID)
		if not strain then return false end
		
		self:SetIsFilled(true)
		self:SetStrainName(strain.name)
		self:SetTHCLevel(thc or 15)
		
		-- Calculate uses based on grams (1 gram = 2-3 uses)
		local uses = math.Clamp(math.ceil(grams * 2.5), 1, 10)
		self:SetUsesLeft(uses)
		
		self.WeedStrain = strainID
		self.WeedGrams = grams
		self.WeedQuality = quality
		self.WeedTHC = thc
		
		return true
	end
end

-- ╔═══════════════════════════════════════════════════════════════╗
-- ║  Drawing                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

function SWEP:DrawWorldModel()
	local owner = self:GetOwner()
	
	if IsValid(owner) then
		local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
		if bone then
			local pos, ang = owner:GetBonePosition(bone)
			
			if pos then
				pos = pos + ang:Forward() * 4 + ang:Right() * 2 + ang:Up() * -3
				ang:RotateAroundAxis(ang:Right(), 90)
				ang:RotateAroundAxis(ang:Up(), 0)
				
				self:SetModelScale(0.6, 0)
				self:SetRenderOrigin(pos)
				self:SetRenderAngles(ang)
			end
		end
	end
	
	self:DrawModel()
end

if CLIENT then
	function SWEP:DrawHUD()
		local owner = LocalPlayer()
		if not IsValid(owner) then return end
		
		local scrW, scrH = ScrW(), ScrH()
		
		-- Bong status HUD
		local x, y = scrW - 200, scrH - 150
		
		-- Background
		draw.RoundedBox(8, x, y, 180, 100, Color(30, 30, 30, 200))
		
		-- Title
		draw.SimpleText("BONG", "DarkRP.Weed.Medium", x + 90, y + 10, Color(150, 255, 150), TEXT_ALIGN_CENTER)
		
		if self:GetIsFilled() then
			-- Strain name
			draw.SimpleText(self:GetStrainName(), "DarkRP.Weed.Small", x + 90, y + 35, Color(200, 200, 255), TEXT_ALIGN_CENTER)
			
			-- THC level
			local thc = self:GetTHCLevel()
			local thcCol = Color(150 + thc * 2, 255 - thc, 100)
			draw.SimpleText("THC: " .. string.format("%.1f%%", thc), "DarkRP.Weed.Small", x + 90, y + 55, thcCol, TEXT_ALIGN_CENTER)
			
			-- Uses remaining
			local uses = self:GetUsesLeft()
			draw.SimpleText("Uses: " .. uses, "DarkRP.Weed.Small", x + 90, y + 75, Color(100, 200, 255), TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Empty", "DarkRP.Weed.Small", x + 90, y + 50, Color(150, 150, 150), TEXT_ALIGN_CENTER)
		end
		
		-- Smoking indicator
		if self.IsSmoking then
			local progress = (CurTime() - self.SmokeStartTime) / self.SmokeDuration
			local barW = 160
			local barH = 20
			local barX = x + 10
			local barY = y + 110
			
			-- Background
			draw.RoundedBox(4, barX, barY, barW, barH, Color(50, 50, 50, 200))
			
			-- Progress
			draw.RoundedBox(4, barX, barY, barW * progress, barH, Color(100, 255, 100, 220))
			
			-- Text
			draw.SimpleText("SMOKING...", "DarkRP.Weed.Tiny", barX + barW / 2, barY + barH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	-- Receive smoke effects from server
	net.Receive("DarkRP.Weed.Bong.Smoke", function()
		local highLevel = net.ReadInt(8)
		local thc = net.ReadFloat()
		local quality = net.ReadFloat()
		
		-- Apply visual effects
		local effectConfig = DarkRP.Weed.Config.GetHighEffect(highLevel)
		if effectConfig then
			-- Calculate duration based on THC
			local duration = effectConfig.duration * (thc / 15)
			
			-- Store effect for rendering
			table.insert(DarkRP.Weed.Client.ActiveEffects or {}, {
				level = highLevel,
				startTime = CurTime(),
				endTime = CurTime() + duration,
				duration = duration,
				thc = thc,
				quality = quality
			})
			
			-- Play cough sound
			LocalPlayer():EmitSound("player/cough" .. math.random(1, 6) .. ".wav", 75, 100)
		end
	end)
end

function SWEP:Holster()
	if self.IsSmoking then
		self:CompleteSmoking()
	end
	
	return true
end

function SWEP:OnRemove()
	if self.IsSmoking and SERVER then
		self:StopSound("ambient/water/water_flow_loop1.wav")
	end
end
