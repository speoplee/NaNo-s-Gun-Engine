--> Type Definitions
export type LockpickComponents = Model & {
	[number]: Model?,
	Background: MeshPart,
	Lockpick: MeshPart,
	Camera: Part & {
		ProximityPrompt: ProximityPrompt
	}
}

export type LockpickDoor = {
	Door1: Model,
	Door2: Model,
	Lockpick: LockpickComponents
}

task.wait(2)

--> Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--> Events
local Events = game.ReplicatedStorage:WaitForChild("Events", 1)
local ChangePivotEvent = Events.OtherSystems.ChangePivotDoor

--> Constants
local TotalPins = 4
local TweenDuration = 0.65

--> Helper Functions
local function TweenPartSize(Part: Part, NewYPos: number, NewYSize: number)
	local CurrentYSize = Part.Size.Y
	local SizeChange = (NewYSize - CurrentYSize) / 2
	local Goal = {
		Position = Vector3.new(Part.Position.X, NewYPos - SizeChange, Part.Position.Z),
		Size = Vector3.new(Part.Size.X, NewYSize, Part.Size.Z)
	}
	TweenService:Create(Part, TweenInfo.new(TweenDuration), Goal):Play()
end

local LockpickingUI = script:WaitForChild("LockpickingUI")

local Gun

--> Doors
local LockpickDoors = CollectionService:GetTagged("LockpickDoor")

for _, DoorData in ipairs(LockpickDoors) do
	local LockpickDoor = DoorData :: LockpickDoor

	local CurrentPinIndex = 1
	local ExpectedPinStep = 1
	local IsLockpicking = false

	local ExpectedOrder = {}
	local OriginalProperties = {}
	local TargetSizes = {}
	local HighlightParts = {}

	local LockpickModel = LockpickDoor.Lockpick
	local LockpickHandle = LockpickModel.Lockpick
	local Camera = LockpickModel.Camera

	for I = 1, TotalPins do
		local PinModel = LockpickModel[tostring(I)]
		local Part1 = PinModel.Part1
		OriginalProperties[I] = {
			Position = Part1.Position,
			Size = Part1.Size
		}
		TargetSizes[I] = math.random(120, 150) / 400
		ExpectedOrder[I] = I
	end

	for I = TotalPins, 2, -1 do
		local J = math.random(1, I)
		ExpectedOrder[I], ExpectedOrder[J] = ExpectedOrder[J], ExpectedOrder[I]
	end

	local function ResetPins()
		for I = 1, TotalPins do
			local PinModel = LockpickModel[tostring(I)]
			local Part1 = PinModel.Part1
			local Original = OriginalProperties[I]
			TweenService:Create(Part1, TweenInfo.new(TweenDuration), {Position = Original.Position, Size = Original.Size}):Play()
		end
		ExpectedPinStep = 1
	end

	local function HighlightPin(Part1: BasePart, Part2: BasePart)
		if HighlightParts[1] then
			HighlightParts[1].Color = Color3.new(1, 1, 1)
			HighlightParts[2].Color = Color3.new(1, 1, 1)
		end
		HighlightParts[1] = Part1
		HighlightParts[2] = Part2
		Part1.Color = Color3.new(1, 0, 0)
		Part2.Color = Color3.new(1, 0, 0)
	end

	local function SetupInitialHighlight()
		local PinModel = LockpickModel[tostring(CurrentPinIndex)]
		HighlightPin(PinModel.Part1, PinModel.Part2)
	end

	for _, Part in ipairs(LockpickModel:GetDescendants()) do
		if Part:IsA("MeshPart") or Part:IsA("BasePart") then
			Part.Transparency = 1
		end
	end

	--> Prompt Setup
	Camera.ProximityPrompt.PromptShown:Connect(function()
		for _, Part in ipairs(LockpickModel:GetDescendants()) do
			if (Part:IsA("MeshPart") or Part:IsA("BasePart")) and Part.Name ~= "Camera" then
				TweenService:Create(Part, TweenInfo.new(1.5), {Transparency = 0}):Play()
			end
		end
	end)

	Camera.ProximityPrompt.PromptHidden:Connect(function()
		for _, Part in ipairs(LockpickModel:GetDescendants()) do
			if Part:IsA("MeshPart") or Part:IsA("BasePart") then
				if IsLockpicking then continue end
				TweenService:Create(Part, TweenInfo.new(0.8), {Transparency = 1}):Play()
			end
		end
	end)

	LockpickDoor.AttributeChanged:Connect(function()
		if LockpickDoor:GetAttribute("Enabled") then
			Camera.ProximityPrompt.Enabled = false
			for _, Part in ipairs(LockpickModel:GetDescendants()) do
				if (Part:IsA("MeshPart") or Part:IsA("BasePart")) and Part.Name ~= "Camera" then
					Part:Destroy()
				end
			end
		end
	end)

	--> Main Logic
	Camera.ProximityPrompt.Triggered:Connect(function()
		if IsLockpicking then return end
		IsLockpicking = true

		LockpickingUI.Parent = game.Players.LocalPlayer.PlayerGui
		local LastCameraCFrame = workspace.CurrentCamera.CFrame
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = Camera.CFrame}):Play()

		SetupInitialHighlight()

		if game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") then
			Gun = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):Clone()
			game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):Destroy()
			print("Test")
		end

		game.Players.LocalPlayer.PlayerScripts.GunFramework.Running.Enabled = false

		local InputConnection
		InputConnection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
			if GameProcessed then return end

			if Input.KeyCode == Enum.KeyCode.F then
				ResetPins()
				TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = LastCameraCFrame}):Play()
				task.delay(1, function()
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
				end)
				LockpickingUI.Parent = script
				IsLockpicking = false
				InputConnection:Disconnect()

			elseif Input.KeyCode == Enum.KeyCode.H then
				if CurrentPinIndex == ExpectedOrder[ExpectedPinStep] then
					local PinModel = LockpickModel[tostring(CurrentPinIndex)]
					local Part1 = PinModel.Part1
					local Part2 = PinModel.Part2
					local TargetSizeY = TargetSizes[CurrentPinIndex]

					TweenService:Create(LockpickHandle, TweenInfo.new(0.15), {Position = LockpickHandle.Position + Vector3.new(0, 0.25/3, 0)}):Play()
					task.wait(0.15)
					TweenPartSize(Part1, Part1.Position.Y, TargetSizeY)
					TweenService:Create(LockpickHandle, TweenInfo.new(0.15), {Position = LockpickHandle.Position - Vector3.new(0, 0.25/3, 0)}):Play()

					ExpectedPinStep += 1
					if ExpectedPinStep > TotalPins then
						for _, Part in ipairs(LockpickModel:GetDescendants()) do
							if Part:IsA("MeshPart") or Part:IsA("BasePart") then
								TweenService:Create(Part, TweenInfo.new(0.8), {Transparency = 1}):Play()
							end
						end
						TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = LastCameraCFrame}):Play()
						task.delay(1, function()
							workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
						end)
						if Gun then
							Gun.Parent = game.Players.LocalPlayer.Character
						end
						game.Players.LocalPlayer.PlayerScripts.GunFramework.Running.Enabled = true
						LockpickingUI.Parent = script
						ChangePivotEvent:FireServer(LockpickDoor.Door1, LockpickDoor.Door2)
						Camera.ProximityPrompt.Enabled = false
						IsLockpicking = false
						InputConnection:Disconnect()
					else
						HighlightPin(Part1, Part2)
					end
				else
					TweenService:Create(LockpickHandle, TweenInfo.new(0.15), {Position = LockpickHandle.Position + Vector3.new(0, 0.25/3, 0)}):Play()
					task.delay(0.15, function()
						TweenService:Create(LockpickHandle, TweenInfo.new(0.15), {Position = LockpickHandle.Position - Vector3.new(0, 0.25/3, 0)}):Play()
					end)
					ResetPins()
				end

			elseif Input.KeyCode == Enum.KeyCode.Right then
				if CurrentPinIndex < TotalPins then
					CurrentPinIndex += 1
					if HighlightParts[1] then
						HighlightParts[1].Color = Color3.new(1, 1, 1)
						HighlightParts[2].Color = Color3.new(1, 1, 1)
					end
					local PinModel = LockpickModel[tostring(CurrentPinIndex)]
					HighlightPin(PinModel.Part1, PinModel.Part2)
					TweenService:Create(LockpickHandle, TweenInfo.new(0.1), {CFrame = LockpickHandle.CFrame * CFrame.new(0, 0, 1.2/4.5)}):Play()
				end
			elseif Input.KeyCode == Enum.KeyCode.Left then
				if CurrentPinIndex > 1 then
					CurrentPinIndex -= 1
					if HighlightParts[1] then
						HighlightParts[1].Color = Color3.new(1, 1, 1)
						HighlightParts[2].Color = Color3.new(1, 1, 1)
					end
					local PinModel = LockpickModel[tostring(CurrentPinIndex)]
					HighlightPin(PinModel.Part1, PinModel.Part2)
					TweenService:Create(LockpickHandle, TweenInfo.new(0.1), {CFrame = LockpickHandle.CFrame * CFrame.new(0, 0, -1.2/4.5)}):Play()
				end
			end
		end)
	end)
end