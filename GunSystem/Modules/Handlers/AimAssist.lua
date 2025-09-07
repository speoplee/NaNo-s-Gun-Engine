local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local AutoAim = {}
AutoAim.__index = AutoAim

function AutoAim.New(Params)
	local Self = setmetatable({}, AutoAim)

	Self.DetectionDistance = Params.DetectionDistance or 30
	Self.BoxSize = Params.BoxSize or Vector3.new(6, 6, 25)
	Self.LerpSpeed = Params.LerpSpeed or 0.1
	Self.Timeout = Params.Timeout or 0.5

	Self.FilterDescendantsInstances = Params.FilterDescendantsInstances or {}
	Self.FilterDescendantsInstances[#Self.FilterDescendantsInstances+1] = Players.LocalPlayer.Character

	Self.CurrentTarget = nil
	Self.LostTargetTimer = 0

	Self.Connection = nil

	return Self
end

function AutoAim.GetCamera(Self)
	return workspace.CurrentCamera
end

function AutoAim.DetectTarget(Self, DeltaTime)
	local Camera = Self:GetCamera()
	if not Camera then
		Self.CurrentTarget = nil
		return
	end

	local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (Self.DetectionDistance / 2)
	local Direction = Camera.CFrame.LookVector * Self.DetectionDistance
	local BoxCFrame = CFrame.new(Origin, Origin + Camera.CFrame.LookVector)

	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = Self.FilterDescendantsInstances
	RaycastParams.CollisionGroup = "Default"

	local Result = workspace:Blockcast(BoxCFrame, Self.BoxSize, Direction, RaycastParams)

	if Result and Result.Instance then
		local Model = Result.Instance:FindFirstAncestorOfClass("Model")
		if Model and Model:FindFirstChild("Humanoid") and Model:FindFirstChild("Head") then
			Self.CurrentTarget = Model.Head
			Self.LostTargetTimer = 0
		else
			Self.LostTargetTimer += DeltaTime
			if Self.LostTargetTimer > Self.Timeout then
				Self.CurrentTarget = nil
			end
		end
	else
		Self.LostTargetTimer += DeltaTime
		if Self.LostTargetTimer > Self.Timeout then
			Self.CurrentTarget = nil
		end
	end
end

function AutoAim.Start(Self)
	if Self.Connection then return end

	Self.Connection = RunService.RenderStepped:Connect(function(DeltaTime)
		Self:DetectTarget(DeltaTime)
	end)
end

function AutoAim.Stop(Self)
	if Self.Connection then
		Self.Connection:Disconnect()
		Self.Connection = nil
	end
	Self.CurrentTarget = nil
	Self.LostTargetTimer = 0
end

function AutoAim.GetCurrentTarget(Self)
	return Self.CurrentTarget
end

return AutoAim