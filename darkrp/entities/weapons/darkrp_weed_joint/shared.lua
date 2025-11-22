AddCSLuaFile()

SWEP.PrintName = "Joint"
SWEP.Category = "DarkRP - Weed System"
SWEP.Author = "DarkRP Weed System"
SWEP.Instructions = "Left Click: Light/Smoke | Right Click: Pass"
SWEP.Purpose = "Smoke some weed"

SWEP.Slot = 2
SWEP.SlotPos = 1
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/zerochain/props_growop2/zgo2_joint_vm.mdl"
SWEP.WorldModel = "models/zerochain/props_growop2/zgo2_joint_wm.mdl"
SWEP.ViewModelFOV = 62
SWEP.UseHands = false

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

function SWEP:Initialize()
	self:SetHoldType("normal")
	
	if SERVER then
		self.isLit = false
		self.hitCount = 0
		self.maxHits = 10
		self.quality = 50
		self.strainID = "schwag"
	end
end

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
	self:NetworkVar("Int", 0, "HitCount")
	self:NetworkVar("Int", 1, "MaxHits")
end

if SERVER then
	function SWEP:SetJointData(strainID, quality)
		self.strainID = strainID or "schwag"
		self.quality = quality or 50
		
		-- Max hits based on quality
		self:SetMaxHits(math.floor(8 + (quality / 100 * 7)))
		self:SetHitCount(0)
	end
	
	function SWEP:PrimaryAttack()
		if not IsValid(self:GetOwner()) then return end
		
		local ply = self:GetOwner()
		
		if not self:GetLit() then
			-- Light the joint
			self:SetLit(true)
			self:EmitSound("ambient/fire/ignite.wav", 60, 100)
			
			DarkRP.Weed.Notify(ply, "You light the joint", DarkRP.Weed.NOTIFY_HINT)
		else
			-- Take a hit
			if self:GetHitCount() >= self:GetMaxHits() then
				DarkRP.Weed.Notify(ply, "The joint is finished", DarkRP.Weed.NOTIFY_HINT)
				self:Remove()
				return
			end
			
			self:SetHitCount(self:GetHitCount() + 1)
			self:EmitSound("player/breathe1.wav", 70, math.random(95, 105))
			
			-- Apply effects
			local product = DarkRP.Weed.Config.GetProduct("joint")
			if product and product.effects and DarkRP.Weed.Server then
				DarkRP.Weed.Server.ApplyEffect(ply, product.effects)
			end
			
			-- Smoke particle
			local effectdata = EffectData()
			effectdata:SetOrigin(ply:GetPos() + Vector(0, 0, 60) + ply:GetForward() * 10)
			effectdata:SetScale(3)
			util.Effect("zgo2_bong_vfx", effectdata)
			
			DarkRP.Weed.Notify(ply, string.format("Took a hit (%d/%d)", self:GetHitCount(), self:GetMaxHits()), DarkRP.Weed.NOTIFY_HINT)
		end
		
		self:SetNextPrimaryFire(CurTime() + 2)
	end
	
	function SWEP:SecondaryAttack()
		if not IsValid(self:GetOwner()) then return end
		
		local ply = self:GetOwner()
		local trace = ply:GetEyeTrace()
		
		if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.HitPos:Distance(ply:GetPos()) <= 100 then
			-- Pass to other player
			local target = trace.Entity
			
			if not target:HasWeapon(self:GetClass()) then
				target:Give(self:GetClass())
				local weapon = target:GetWeapon(self:GetClass())
				
				if IsValid(weapon) then
					weapon:SetJointData(self.strainID, self.quality)
					weapon:SetLit(self:GetLit())
					weapon:SetHitCount(self:GetHitCount())
					weapon:SetMaxHits(self:GetMaxHits())
				end
				
				self:Remove()
				
				DarkRP.Weed.Notify(ply, "You passed the joint to " .. target:Nick(), DarkRP.Weed.NOTIFY_HINT)
				DarkRP.Weed.Notify(target, ply:Nick() .. " passed you a joint", DarkRP.Weed.NOTIFY_HINT)
			end
		end
		
		self:SetNextSecondaryFire(CurTime() + 1)
	end
	
	function SWEP:Think()
		-- Smoke effects while lit
		if self:GetLit() and IsValid(self:GetOwner()) then
			local ply = self:GetOwner()
			
			if math.random(1, 3) == 1 then
				local effectdata = EffectData()
				effectdata:SetOrigin(ply:GetPos() + Vector(0, 0, 50) + ply:GetForward() * 15)
				effectdata:SetScale(1)
				util.Effect("zgo2_bong_vfx", effectdata)
			end
		end
	end
end

if CLIENT then
	function SWEP:DrawWorldModel()
		self:DrawModel()
		
		-- Draw smoke effect if lit
		if self:GetLit() then
			local owner = self:GetOwner()
			if IsValid(owner) then
				local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand")
				if bone then
					local pos, ang = owner:GetBonePosition(bone)
					pos = pos + owner:GetForward() * 5 + owner:GetUp() * 2
					
					-- Smoke particle
					if math.random(1, 2) == 1 then
						local emitter = ParticleEmitter(pos)
						if emitter then
							local particle = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), pos)
							if particle then
								particle:SetVelocity(VectorRand() * 5 + Vector(0, 0, 10))
								particle:SetDieTime(math.Rand(1, 2))
								particle:SetStartAlpha(100)
								particle:SetEndAlpha(0)
								particle:SetStartSize(2)
								particle:SetEndSize(10)
								particle:SetRoll(math.Rand(0, 360))
								particle:SetRollDelta(math.Rand(-1, 1))
								particle:SetColor(200, 200, 200)
							end
							emitter:Finish()
						end
					end
				end
			end
		end
	end
	
	function SWEP:DrawHUD()
		local scrW, scrH = ScrW(), ScrH()
		
		if self:GetLit() then
			local text = string.format("Hits: %d / %d", self:GetHitCount(), self:GetMaxHits())
			draw.SimpleText(text, "DarkRP.Weed.Medium", scrW / 2, scrH - 100, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText("Left Click to Light", "DarkRP.Weed.Small", scrW / 2, scrH - 100, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
	
	function SWEP:GetViewModelPosition(pos, ang)
		-- Adjust viewmodel position
		pos = pos + ang:Forward() * 2
		pos = pos + ang:Right() * 3
		pos = pos + ang:Up() * -2
		
		return pos, ang
	end
end
