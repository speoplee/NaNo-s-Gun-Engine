local Players = game:GetService("Players")

local StateManager = require(script.Parent.StateManager)
local Signal = require(script.Parent.Parent.Utils.Signal)

local WeaponConstructor = {}
WeaponConstructor.__index = WeaponConstructor

export type Weapon = typeof(setmetatable({}, WeaponConstructor))
export type Viewmodel = Instance

function WeaponConstructor.new(WeaponData: table, tool: Tool): Weapon
	local self = setmetatable({}, WeaponConstructor)

	self.Tool = tool
	self.WeaponData = WeaponData or {}

	self.Name = WeaponData.Constants and WeaponData.Constants.Name or "Unknown"
	self.TypeOfGun = WeaponData.Constants and WeaponData.Constants.TypeOfGun or 0
	self.TypesOfGun = WeaponData.Constants and WeaponData.Constants.TypesOfGun or {}
	self.BulletsPerShoot = WeaponData.Constants and WeaponData.Constants.BulletsPerShoot or 1
	self.Offset = WeaponData.Constants and WeaponData.Constants.Offset or Vector3.new(0,0,0)

	self.Physics = WeaponData.Physics or {}
	self.BulletPhysics = self.Physics.Bullet or {}
	self.SpreadPhysics = self.Physics.Spread or {}
	self.RecoilPhysics = self.Physics.Recoil or {}
	self.MiscPhysics = self.Physics.Misc or {}

	self.Recoil = WeaponData.Recoil
	self.ShootCooldown = WeaponData.Cooldown or 0.12
	self.Dispertion = (WeaponData.Data and WeaponData.Data.Dispertion) or WeaponData.Dispertion
	self.Bullets = (WeaponData.Data and WeaponData.Data.Bullets) or 0
	self.ReservedBullets = (WeaponData.Data and WeaponData.Data.ReservedBullets) or 0

	self.BulletSpeed = self.BulletPhysics.Speed or self.BulletPhysics.Velocity or (WeaponData.Constants and WeaponData.Constants.BulletSpeed) or 3000
	self.Penetration = self.BulletPhysics.Penetration or (WeaponData.Constants and WeaponData.Constants.Penetration) or 1
	self.VisualSpeedMultiplier = self.BulletPhysics.VisualSpeedMultiplier or 0.25

	self.SpreadConfig = {
		BaseSpreadDeg = self.SpreadPhysics.BaseSpreadDeg or self.SpreadPhysics.BaseDeg or self.SpreadPhysics.Base or 0.3,
		SpreadPerShotDeg = self.SpreadPhysics.SpreadPerShotDeg or self.SpreadPhysics.SpreadPerShot or self.SpreadPhysics.PerShot or 0.8,
		MaxBloomDeg = self.SpreadPhysics.MaxBloomDeg or self.SpreadPhysics.MaxDeg or self.SpreadPhysics.Max or 12,
		BloomRecoveryDegPerSec = self.SpreadPhysics.BloomRecoveryDegPerSec or self.SpreadPhysics.BloomRecovery or 10,
		MoveSpreadMultiplier = self.SpreadPhysics.MoveSpreadMultiplier or self.SpreadPhysics.MoveMultiplier or 4,
		ADSMultiplier = self.SpreadPhysics.ADSMultiplier or self.SpreadPhysics.ADS or 0.25,
		CrouchMultiplier = self.SpreadPhysics.CrouchMultiplier or self.SpreadPhysics.Crouch or 0.6,
		FirstShotAccuracyDeg = self.SpreadPhysics.FirstShotAccuracyDeg or self.SpreadPhysics.FirstShotDeg or 0.02,
	}

	self.RecoilPattern = self.RecoilPhysics.Pattern or self.RecoilPattern
	self.RecoilXRandomness = self.RecoilPhysics.XRandomness or 0.1
	self.RecoilYRandomness = self.RecoilPhysics.YRandomness or 0.05
	self.RecoilBiasHorDeg = self.RecoilPhysics.BiasHorDeg or self.RecoilPhysics.HorizontalBiasDeg or 0
	self.RecoilBiasVertDeg = self.RecoilPhysics.BiasVertDeg or self.RecoilPhysics.VerticalBiasDeg or 0

	self.Attachments = WeaponData.Attachments or {}
	self.UseMultipleReloadSounds = WeaponData.MultipleReload or false
	self.GunIconTemplate = WeaponData.UI and WeaponData.UI.GunIcon or nil
	self.IconSize = WeaponData.UI and WeaponData.UI.IconSize or nil
	self.AspectRatio = WeaponData.UI and WeaponData.UI.AspectRatio or nil
	self.IconPosition = WeaponData.UI and WeaponData.UI.IconPosition or nil

	self.BulletsChanged = Signal.new()
	self.MagsChanged = Signal.new()

	self.Viewmodel = nil :: (Viewmodel?)
	
	self.State = nil

	return self
end

local function clamp(value: number, min: number, max: number): number
	if value < min then return min end
	if value > max then return max end
	return value
end

function WeaponConstructor:SetBullets(amount: number)
	local maxBullets = self.WeaponData.Data and self.WeaponData.Data.Bullets or 0
	local clamped = clamp(amount, 0, maxBullets)
	if self.Bullets ~= clamped then
		self.Bullets = clamped
		self.BulletsChanged:Fire(self.Bullets)
	end
end

function WeaponConstructor:AddBullets(amount: number)
	self:SetBullets(self.Bullets + amount)
end

function WeaponConstructor:RemoveBullets(amount: number)
	self:SetBullets(self.Bullets - amount)
end

function WeaponConstructor:SetMags(amount: number)
	local maxMags = self.WeaponData.Data and self.WeaponData.Data.ReservedBullets or 0
	local clamped = clamp(amount, 0, maxMags)
	if self.Mags ~= clamped then
		self.Mags = clamped
		self.MagsChanged:Fire(self.Mags)
	end
end

function WeaponConstructor:AddMags(amount: number)
	self:SetMags(self.Mags + amount)
end

function WeaponConstructor:RemoveMags(amount: number)
	self:SetMags(self.Mags - amount)
end

function WeaponConstructor:SaveGun()
	self.Tool.Parent = Players.LocalPlayer.Backpack
end

function WeaponConstructor:RestoreGun(): boolean
	local playerCharacter = Players.LocalPlayer.Character
	if playerCharacter then
		self.Tool.Parent = playerCharacter
		return true
	end
	return false
end

function WeaponConstructor:SetState(newState: string)
	if self.State then self.State:SetState(newState) end
end

function WeaponConstructor:GetState(): string
	if self.State then return self.State:GetState() end
	return nil
end

function WeaponConstructor:SetViewModel(viewmodel: ViewModel)
	self.ViewModel = viewmodel
end

function WeaponConstructor:GetViewModel(): ViewModel?
	return self.ViewModel
end

return WeaponConstructor