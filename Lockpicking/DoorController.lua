--> Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--> Events
local Events = game.ReplicatedStorage:WaitForChild("Events", 1)
local ChangePivotEvent = Events.OtherSystems.ChangePivotDoor

--> Modules
local LockpickDoor = require(script.Parent.LockpickDoor)
local DoorSystem = require(script.Parent)
local DoorConnections = {} :: {[string]: RBXScriptConnection}

local DoorController = {}
DoorController.currentDoor = nil :: LockpickDoor.self?

local LockpickingUI = script.Parent.LockpickingUI
local Gun

local TWEEN_DURATION = 0.65

local function tweenPartSize(part: Part, newYPos: number, newYSize: number)
	local currentYSize = part.Size.Y
	local sizeChange = (newYSize - currentYSize) / 2
	local goal = {
		Position = Vector3.new(part.Position.X, newYPos - sizeChange, part.Position.Z),
		Size = Vector3.new(part.Size.X, newYSize, part.Size.Z)
	}
	TweenService:Create(part, TweenInfo.new(TWEEN_DURATION), goal):Play()
end

function DoorController.StartLockpicking(doorID)
	if DoorController.currentDoor then return end

	local door = DoorSystem.GetDoorFromID(doorID)
	if not door then return end

	if not door:startLockpick() then
		return
	end

	DoorController.currentDoor = door

	
	door:setupInitialHighlight()

	LockpickingUI.Parent = Players.LocalPlayer.PlayerGui
	local lastCameraCFrame = workspace.CurrentCamera.CFrame
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = door.camera.CFrame}):Play()

	if Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") then
		Gun = Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):Clone()
		Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):Destroy()
	end

	Players.LocalPlayer.PlayerScripts.GunFramework.Running.Enabled = false

	local inputConnection
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.F then
			DoorController.EndLockpicking(lastCameraCFrame, inputConnection)
		elseif input.KeyCode == Enum.KeyCode.H then
			if door.currentPinIndex == door.expectedOrder[door.expectedPinStep] then
				local pinModel = door.lockpickModel[tostring(door.currentPinIndex)]
				local part1 = pinModel.Part1
				local part2 = pinModel.Part2
				local targetSizeY = door.targetSizes[door.currentPinIndex]

				TweenService:Create(door.lockpickHandle, TweenInfo.new(0.15), {Position = door.lockpickHandle.Position + Vector3.new(0, 0.25/3, 0)}):Play()
				task.wait(0.15)
				tweenPartSize(part1, part1.Position.Y, targetSizeY)
				TweenService:Create(door.lockpickHandle, TweenInfo.new(0.15), {Position = door.lockpickHandle.Position - Vector3.new(0, 0.25/3, 0)}):Play()

				door.expectedPinStep += 1
				if door.expectedPinStep > door.TOTAL_PINS then
					for _, part in ipairs(door.lockpickModel:GetDescendants()) do
						if part:IsA("MeshPart") or part:IsA("BasePart") then
							TweenService:Create(part, TweenInfo.new(0.8), {Transparency = 1}):Play()
						end
					end
					TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = lastCameraCFrame}):Play()
					task.delay(1, function()
						workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					end)
					if Gun then
						Gun.Parent = game.Players.LocalPlayer.Character
					end
					game.Players.LocalPlayer.PlayerScripts.GunFramework.Running.Enabled = true
					LockpickingUI.Parent = script
					ChangePivotEvent:FireServer(door.Instance.Door1, door.Instance.Door2)
					door.camera.ProximityPrompt.Enabled = false
					door:stopLockpick()
					inputConnection:Disconnect()
				else
					door:highlightPin(part1, part2)
				end
			else
				TweenService:Create(door.lockpickHandle, TweenInfo.new(0.15), {Position = door.lockpickHandle.Position + Vector3.new(0, 0.25/3, 0)}):Play()
				task.delay(0.15, function()
					TweenService:Create(door.lockpickHandle, TweenInfo.new(0.15), {Position = door.lockpickHandle.Position - Vector3.new(0, 0.25/3, 0)}):Play()
				end)
				door:resetPins()
			end
		elseif input.KeyCode == Enum.KeyCode.Right then
			door:movePin(1)
		elseif input.KeyCode == Enum.KeyCode.Left then
			door:movePin(-1)
		end
	end)
end

function DoorController.EndLockpicking(lastCameraCFrame, inputConnection, successful)
	local door = DoorController.currentDoor
	if not door then return end

	door:resetPins()
	DoorController.currentDoor = nil
	door:stopLockpick()

	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = lastCameraCFrame}):Play()
	task.delay(1, function()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end)

	LockpickingUI.Parent = script.Parent
	if successful then
		door:unlock()
		if Gun then
			Gun.Parent = Players.LocalPlayer.Character
		end
		Players.LocalPlayer.PlayerScripts.GunFramework.Running.Enabled = true
	end

	if inputConnection then
		inputConnection:Disconnect()
	end
end

local function handleDoor(ID: string, door: LockpickDoor.self)
	print(ID, door)
	DoorConnections[ID] = door.camera.ProximityPrompt.Triggered:Connect(function(playerWhoTriggered: Player)
		DoorController.StartLockpicking(ID)
	end)
end

for id, door in DoorSystem.Doors do
	task.spawn(handleDoor, id, door)
end

DoorSystem.DoorAdded:Connect(handleDoor)

DoorSystem.DoorRemoved:Connect(function(ID: string)
	if DoorConnections[ID] then
		DoorConnections[ID]:Disconnect()
	end
end)

return DoorController
