game.Players.LocalPlayer.CharacterAdded:Wait()
--> Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GunEngine = ReplicatedStorage:WaitForChild("GunEngine")

--> Dependencies // Folders

local GunSystem = script.Parent
local Modules = GunSystem.Modules

local Core = Modules.Core
local Handlers = Modules.Handlers
local UI = Modules.UI
local Utils = Modules.Utils

--> Dependencies // Modules

local GunUI = GunEngine.GunUI

local ConnectionManager = require(Core.ConnectionManager).new()
local WeaponConstructor = require(Core.WeaponConstructor)
local StateManager = require(Core.StateManager)

local InputHandler = require(Handlers.InputHandler)
local Attachments = require(Handlers.Attachments)
local RecoilHandler = require(Handlers.RecoilHandler)
local AnimationsHandler = require(Handlers.Animations)
local BulletHandler = require(Handlers.BulletHandler)

local GunUIHandler = require(UI.GunUI)

local Spring = require(Utils.Spring)
local MathUtils = require(Utils.MathUtils)
local GunUI = require(Players.LocalPlayer.PlayerScripts.GunSystem.Modules.UI.GunUI)

--> States

local PlayerState = StateManager.new({
	CanShoot = false,
	CanReload = false,
	IsCrouching = false,
	IsSprinting = false,
	IsLeaning = false,
	IsProne = false,
	NVG_Enabled = false,
	ThermalVision = false,
	IsShooting = false,
	IsReloading = false,
	IsAiming = false,
	IsAlive = true
})

--> Tables

local StoredWeapons = {}

--> Non-Initiated Vars

local NVGLight = nil
local CurrentWeapon = nil
local OldCameraCFrame = nil
local OriginalOffset = nil
local MouseDelta = nil
local ViewmodelLeanCFrame = nil
local CameraLeanCFrame = nil

--> Connections

local Connections = ConnectionManager.new()

--> Code

local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Character = Player.Character

local function OnPlayerDied()
	PlayerState:SetState("IsAlive", false)

	if CurrentWeapon.Viewmodel then
		CurrentWeapon.Viewmodel:Destroy()
		CurrentWeapon.Viewmodel = nil
	end

	if GunUI then
		GunUI.Parent = GunEngine
	end

	Connections:Clear()
end

local function OnGunDesequipped(wasDeath: boolean?)
	if not CurrentWeapon then
		print("No weapon")
		return
	end

	UserInputService.MouseIconEnabled = true

	Connections:Clear()

	if CurrentWeapon.Viewmodel then
		CurrentWeapon.Viewmodel:Destroy()
		CurrentWeapon.Viewmodel = nil
	end

	PlayerState:SetState("CanShoot", false)
	PlayerState:SetState("CanReload", false)

	if not wasDeath then
		StoredWeapons[CurrentWeapon.Name] = nil
		CurrentWeapon = nil
	end
end

local function CameraAnimation()
	local FakeCamera = CurrentWeapon.Viewmodel.CameraBone
	local NewCamCF = FakeCamera.CFrame:ToObjectSpace(CurrentWeapon.Viewmodel.PrimaryPart.CFrame)

	if OldCameraCFrame then
		local _, _, z = NewCamCF:ToOrientation()
		local x, y, _ = NewCamCF:ToObjectSpace(OldCameraCFrame):ToEulerAnglesXYZ()
		Camera.CFrame = Camera.CFrame * CFrame.Angles(x, y, -z)
	end

	OldCameraCFrame = NewCamCF
end

local function SetupCharacter(Child)
	if Child:IsA("Tool") and Child:GetTags()[1] then
		UserInputService.MouseIconEnabled = false

		CurrentWeapon = WeaponConstructor.new(require(Child.Data), Child)

		if not StoredWeapons[CurrentWeapon.Name] then
			StoredWeapons[CurrentWeapon.Name] = CurrentWeapon
		else
			CurrentWeapon = StoredWeapons[CurrentWeapon.Name]
		end

		if CurrentWeapon.Viewmodel then
			CurrentWeapon.Viewmodel:Destroy()
			CurrentWeapon.Viewmodel = nil
		end

		CurrentWeapon.Viewmodel = GunEngine.Viewmodels:FindFirstChild(CurrentWeapon.Name):Clone()
		CurrentWeapon.Viewmodel.Parent = Camera

		GunUIHandler.Update(GunUI, CurrentWeapon)
		GunUI.Parent = Player.PlayerGui
		
		PlayerState:SetState({"CanShoot", "CanReload"}, {true, true})

		CurrentWeapon.State = PlayerState

		Attachments:LoadAttachments(CurrentWeapon)

		CurrentWeapon.Animations = AnimationsHandler.LoadVMAnimations(CurrentWeapon.Viewmodel)
		CurrentWeapon.ThirdPersonAnimations = AnimationsHandler.LoadThirdPersonAnimations(Character, Child)

		if CurrentWeapon.Animations and CurrentWeapon.Animations[1] then
			CurrentWeapon.Animations[1].Looped = true
			CurrentWeapon.Animations[1]:Play()
		end

		if CurrentWeapon.ThirdPersonAnimations and CurrentWeapon.ThirdPersonAnimations[1] then
			CurrentWeapon.ThirdPersonAnimations[1].Looped = true
			CurrentWeapon.ThirdPersonAnimations[1]:Play()
		end

		local TickTime = 0
		local BobbingAmount = Vector3.new(0, 0, 0)
		local SwayCFrame = CFrame.new()
		local LeanCFrame = CFrame.new()
		local CameraOffset = CFrame.new()

		for _, GunPart: any in Child.Model:GetDescendants() do
			if GunPart:IsA("BasePart") then
				GunPart.Transparency = 1
			end
		end

		TickTime = TickTime or 0
		BobbingAmount = BobbingAmount or Vector3.new(0,0,0)
		SwayCFrame = SwayCFrame or CFrame.new()
		ViewmodelLeanCFrame = ViewmodelLeanCFrame or CFrame.new()
		CameraLeanCFrame = CameraLeanCFrame or CFrame.new()
		local CameraAtRest = false

		ConnectionManager:Connect("ViewmodelMovement", RunService.RenderStepped, function(DeltaTime: number)
			if not GunEngine.Bools.ViewmodelMovement.Value then return end

			local Velocity = Character.Humanoid.MoveDirection.Magnitude
			local IsMoving = Velocity > 0.1

			local aimFactor = PlayerState:GetState("IsAiming") and 0.35 or 1

			local TickSpeed, FrequencyX, FrequencyY = 5, 1, 2
			local baseAmpX, baseAmpY = 0.06 / 1.2, 0.08 / 1.2
			local AmplitudeX, AmplitudeY = baseAmpX * aimFactor, baseAmpY * aimFactor

			if IsMoving then
				TickTime = TickTime + DeltaTime * TickSpeed
			else
				TickTime = math.max(TickTime - DeltaTime * 5, 0)
			end

			local TargetBobX = IsMoving and (math.sin(TickTime * FrequencyX) * AmplitudeX) or 0
			local TargetBobY = IsMoving and ((math.sin(TickTime * FrequencyY)) ^ 3 * AmplitudeY) or 0
			BobbingAmount = BobbingAmount:Lerp(Vector3.new(TargetBobX, TargetBobY, 0), DeltaTime * 10)

			local MouseDelta = UserInputService:GetMouseDelta()
			local baseSwayAmount, SwaySmoothing = 0.11, 10
			local SwayAmount = baseSwayAmount * aimFactor
			local TargetSway = CFrame.Angles(-math.rad(MouseDelta.Y * SwayAmount), -math.rad(MouseDelta.X * SwayAmount), 0)
			SwayCFrame = SwayCFrame:Lerp(TargetSway, DeltaTime * SwaySmoothing)

			local RightDot = Camera.CFrame.RightVector:Dot(Character.Humanoid.MoveDirection)
			local MaxLean = math.rad(3)
			local TargetLean = math.clamp(RightDot, -1, 1) * MaxLean

			ViewmodelLeanCFrame = ViewmodelLeanCFrame:Lerp(CFrame.Angles(0, 0, TargetLean), DeltaTime * 5)
			CameraLeanCFrame = CameraLeanCFrame:Lerp(CFrame.Angles(0, 0, TargetLean * 0.33), DeltaTime * 5)

			local OffsetCFrame = CFrame.new(CurrentWeapon.Viewmodel.Offset.Value)
			local BobbingCFrame = CFrame.new(BobbingAmount)
			local ViewmodelCFrame = Camera.CFrame * OffsetCFrame * ViewmodelLeanCFrame * SwayCFrame * BobbingCFrame
			CurrentWeapon.Viewmodel:SetPrimaryPartCFrame(ViewmodelCFrame)

			local CamBobbing = CFrame.new(TargetBobX * 0.03 * aimFactor, TargetBobY * 0.03 * aimFactor, 0) *
				CFrame.Angles(TargetBobY * 0.03 * 0.5 * aimFactor, 0, TargetBobX * 0.03 * 0.5 * aimFactor)
			local CamSway = CFrame.Angles(-math.rad(MouseDelta.Y * 0.05 * aimFactor), -math.rad(MouseDelta.X * 0.05 * aimFactor), 0)

			if IsMoving then
				CameraAtRest = false
				Camera.CFrame = Camera.CFrame * CamBobbing * CamSway * CameraLeanCFrame
			else
				local targetCFrame = Camera.CFrame * CameraLeanCFrame
				Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1)
				if (Camera.CFrame.Position - targetCFrame.Position).Magnitude < 0.001 then
					CameraAtRest = true
				end
			end

			if CurrentWeapon.Viewmodel:FindFirstChild("CameraBone") then
				CameraAnimation()
			end
		end)
	end
end

Player.CharacterAdded:Connect(function(NewCharacter)
	Character = nil
	Character = NewCharacter

	Character.ChildAdded:Connect(function(Child1)
		SetupCharacter(Child1)
	end)
end)

Character.ChildAdded:Connect(SetupCharacter)

Character.ChildRemoved:Connect(function(Child)
	if Child:IsA("Tool") and Child:GetAttribute("GunSystem") then
		OnGunDesequipped()
	end
end)

local function Shoot()
	if not CurrentWeapon or CurrentWeapon.Bullets == 0 or not PlayerState:GetState("CanShoot") then return end
	PlayerState:SetState("CanShoot", false)

	local vmAnims = CurrentWeapon.Animations
	local tpAnims = CurrentWeapon.ThirdPersonAnimations

	if vmAnims then
		if vmAnims[2] then pcall(function() vmAnims[2]:Play() if PlayerState:GetState("IsAiming") == true then vmAnims[2]:AdjustWeight(0.1) end end) end
		if vmAnims.ShootProjectile then pcall(function() vmAnims.ShootProjectile:Play() end) end
	end

	if tpAnims and tpAnims[2] then pcall(function() tpAnims[2]:Play() end) end

	if CurrentWeapon.Viewmodel then
		pcall(function()
			local vm = CurrentWeapon.Viewmodel
			if vm:FindFirstChild("HumanoidRootPart") and vm.HumanoidRootPart:FindFirstChild("Sounds") and vm.HumanoidRootPart.Sounds:FindFirstChild("Shoot") then
				vm.HumanoidRootPart.Sounds.Shoot:Play()
			end
			if vm:FindFirstChild("Joint") and vm.Joint:FindFirstChild("Muzzle") and vm.Joint.Muzzle:FindFirstChild("Fire") then
				vm.Joint.Muzzle.Fire:Emit(100)
			end
		end)
	end

	if CurrentWeapon.Recoil then
		pcall(function() RecoilHandler.recoil(CurrentWeapon.Recoil) end)
	end

	CurrentWeapon:RemoveBullets(CurrentWeapon.BulletsPerShoot or 1)

	pcall(function() GunUIHandler.Update(GunUI, CurrentWeapon) end)

	local origin = Camera.CFrame.Position
	local direction = Camera.CFrame.LookVector
	
	task.spawn(function()
		local Result = BulletHandler.Shoot(CurrentWeapon, origin, direction)
		
		print(Result)
	end)

	task.delay(CurrentWeapon.ShootCooldown or 0.12, function()
		if PlayerState then
			PlayerState:SetState("CanShoot", true)
		end
	end)
end

local function Reload()
	if not CurrentWeapon 
   or not CurrentWeapon.Viewmodel 
   or PlayerState:GetState("CanReload") ~= true 
   or CurrentWeapon.Bullets >= CurrentWeapon.WeaponData.Data.Bullets 
   or CurrentWeapon.ReservedBullets <= 0 then
   return end

	PlayerState:SetState("CanReload", false)
	PlayerState:SetState("CanShoot", false)

	local SoundsFolder: Folder = CurrentWeapon.Viewmodel.HumanoidRootPart:FindFirstChild("Sounds")
	local ThirdPersonAnims = CurrentWeapon.ThirdPersonAnimations
	local ViewmodelAnims = CurrentWeapon.Animations
	local maxBullets = CurrentWeapon.WeaponData.Data.Bullets

	if CurrentWeapon.TypeOfGun == 1 or CurrentWeapon.TypeOfGun == 2 then
		if ViewmodelAnims[3] then ViewmodelAnims[3]:Play() end
		if ThirdPersonAnims[3] then ThirdPersonAnims[3]:Play() end
		
		if SoundsFolder and SoundsFolder:FindFirstChild("Reload") then
			SoundsFolder.Reload:Play()
		end

		if ViewmodelAnims[3] then ViewmodelAnims[3].Stopped:Wait() end

		local missing = maxBullets - CurrentWeapon.Bullets
		local toLoad = math.min(missing, CurrentWeapon.ReservedBullets)

		CurrentWeapon.ReservedBullets -= toLoad
		CurrentWeapon.Bullets += toLoad

	else
		if ThirdPersonAnims.Reload then ThirdPersonAnims.Reload:Play() end

		local ReloadSounds = {}
		if SoundsFolder then
			ReloadSounds[1] = SoundsFolder:FindFirstChild("Start")
			ReloadSounds[2] = SoundsFolder:FindFirstChild("Mid")
			ReloadSounds[3] = SoundsFolder:FindFirstChild("Final")
		end

		if ReloadSounds[1] then ReloadSounds[1]:Play() end
		if CurrentWeapon.Animations.Reload[1] then 
			CurrentWeapon.Animations.Reload[1]:Play()
			CurrentWeapon.Animations.Reload[1].Stopped:Wait()
		end

		for _ = 1, maxBullets - CurrentWeapon.Bullets do
			if CurrentWeapon.ReservedBullets <= 0 then break end
			if CurrentWeapon.Animations.Reload[2] then 
				CurrentWeapon.Animations.Reload[2]:Play()
				if ReloadSounds[2] then ReloadSounds[2]:Play() end
				CurrentWeapon.Animations.Reload[2].Stopped:Wait()
			end
			CurrentWeapon.Bullets += 1
			CurrentWeapon.ReservedBullets -= 1
		end

		if CurrentWeapon.Animations.Reload[3] then 
			CurrentWeapon.Animations.Reload[3]:Play()
			if ReloadSounds[3] then ReloadSounds[3]:Play() end
			CurrentWeapon.Animations.Reload[3].Stopped:Wait()
		end
	end

	PlayerState:SetState("CanReload", true)
	PlayerState:SetState("CanShoot", true)
end

local function Aim()
	if CurrentWeapon and CurrentWeapon.Viewmodel and CurrentWeapon.Viewmodel.AimPoint then
		local Offset = MathUtils.CalculateOffset(CurrentWeapon.Viewmodel, CurrentWeapon)
		if Offset then
			local targetTime = 0.5
			local frames = targetTime / RunService.RenderStepped:Wait()

			local alpha = 1 / frames

			local tweenInfo = TweenInfo.new(0.65, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local goal = {Value = Offset}

			local tween = TweenService:Create(CurrentWeapon.Viewmodel.Offset, tweenInfo, goal)
			tween:Play()
		end
	end
end

local function SwitchMode()
	if CurrentWeapon and CurrentWeapon.Viewmodel then
		local currentIndex = 1
		for i, v in CurrentWeapon.TypesOfGun do
			if v == CurrentWeapon.TypeOfGun then
				currentIndex = i
				break
			end
		end

		local nextIndex = currentIndex + 1
		if nextIndex > #CurrentWeapon.TypesOfGun then
			nextIndex = 1
		end

		CurrentWeapon.TypeOfGun = CurrentWeapon.TypesOfGun[nextIndex]
	end
end

InputHandler.Register({
	[Enum.UserInputType.MouseButton1] = {
		pressed = function()
			if not CurrentWeapon then return end
			
			if CurrentWeapon.TypeOfGun == 1 then
				PlayerState:SetState("IsShooting", true)

				task.spawn(function()
					while PlayerState:GetState("IsShooting") and CurrentWeapon do
						if PlayerState:GetState("CanShoot") then
							Shoot()
						end
						task.wait(CurrentWeapon.ShootCooldown or 0.12)
					end
				end)
			else
				if PlayerState:GetState("CanShoot") then
					Shoot()
				end
			end
		end,
		released = function()
			if not CurrentWeapon then return end
			PlayerState:SetState("IsShooting", false)
		end
	},

	[Enum.UserInputType.MouseButton2] = {
		pressed = function()
			if not CurrentWeapon then return end
			PlayerState:SetState("IsAiming", true)
			Aim()
		end,
		released = function()
			if not CurrentWeapon then return end
			PlayerState:SetState("IsAiming", false)
			local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local goal = {Value = Vector3.new(0, 0, 0)}

			local tween = TweenService:Create(CurrentWeapon.Viewmodel.Offset, tweenInfo, goal)
			tween:Play()
		end
	},

	[Enum.KeyCode.R] = {
		pressed = Reload
	},

	[Enum.KeyCode.H] = {
		pressed = SwitchMode
	}
})

InputHandler.Start()

Character.Humanoid.Died:Connect(function()
	if CurrentWeapon then
		OnGunDesequipped(true)
	end
end)