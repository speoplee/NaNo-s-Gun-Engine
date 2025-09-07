local Types = require(script.Parent.Types)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LockpickDoor = {}
LockpickDoor.__index = LockpickDoor 

local TOTAL_PINS = 4
local TWEEN_DURATION = 0.65

function LockpickDoor.new(instance: Types.LockpickDoor)
	local self = setmetatable({}, LockpickDoor)

	self.Instance = instance
	
	self.currentPinIndex = 1
	self.expectedPinStep = 1
	self.isLockpicking = false
	self.expectedOrder = {}
	self.originalProperties = {}
	self.targetSizes = {}
	self.highlightParts = {}
	
	self.TOTAL_PINS = TOTAL_PINS

	self.lockpickModel = instance.Lockpick
	self.lockpickHandle = self.lockpickModel:WaitForChild("Lockpick")
	self.camera = self.lockpickModel:WaitForChild("Camera")

	self:initializePins()
	self:shufflePinOrder()
	self:setupTransparency()
	self:setupProximityPrompts()
	self:setupDoorAttributeListener(instance)

	return self
end

export type self = typeof(LockpickDoor.new())

function LockpickDoor.startLockpick(self: self)
	if self.isLockpicking then
		return false
	end
	
	--TODO: AÑADIR CONDICIONES
	
	self.isLockpicking = true
	self:setupInitialHighlight()
	
	return true
end

function LockpickDoor.stopLockpick(self: self)
	if not self.isLockpicking then
		return
	end
	
	self.isLockpicking = false
end

function LockpickDoor.initializePins(self: self)
	for i = 1, TOTAL_PINS do
		local pinModel = self.lockpickModel[tostring(i)]
		local part1 = pinModel.Part1
		self.originalProperties[i] = {
			Position = part1.Position,
			Size = part1.Size
		}
		self.targetSizes[i] = math.random(120, 150) / 400
		self.expectedOrder[i] = i
	end
end

function LockpickDoor.shufflePinOrder(self: self)
	for i = TOTAL_PINS, 2, -1 do
		local j = math.random(1, i)
		self.expectedOrder[i], self.expectedOrder[j] = self.expectedOrder[j], self.expectedOrder[i]
	end
end

function LockpickDoor.setupTransparency(self: self)
	for _, part in ipairs(self.lockpickModel:GetDescendants()) do
		if part:IsA("MeshPart") or part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

function LockpickDoor.setupProximityPrompts(self: self)
	self.camera.ProximityPrompt.PromptShown:Connect(function()
		self:setTransparency(0, 1.5)
	end)

	self.camera.ProximityPrompt.PromptHidden:Connect(function()
		if not self.isLockpicking then
			self:setTransparency(1, 0.8)
		end
	end)
end

function LockpickDoor.setTransparency(self: self, value, duration)
	for _, part in ipairs(self.lockpickModel:GetDescendants()) do
		if (part:IsA("MeshPart") or part:IsA("BasePart")) and part.Name ~= "Camera" then
			TweenService:Create(part, TweenInfo.new(duration), {Transparency = value}):Play()
		end
	end
end

function LockpickDoor.setupDoorAttributeListener(self: self, instance)
	instance.AttributeChanged:Connect(function()
		if instance:GetAttribute("Enabled") then
			self.camera.ProximityPrompt.Enabled = false
			for _, part in ipairs(self.lockpickModel:GetDescendants()) do
				if (part:IsA("MeshPart") or part:IsA("BasePart")) and part.Name ~= "Camera" then
					part:Destroy()
				end
			end
		end
	end)
end

function LockpickDoor.highlightPin(self: self, part1, part2)
	if self.highlightParts[1] then
		self.highlightParts[1].Color = Color3.new(1, 1, 1)
		self.highlightParts[2].Color = Color3.new(1, 1, 1)
	end
	self.highlightParts[1] = part1
	self.highlightParts[2] = part2
	part1.Color = Color3.new(1, 0, 0)
	part2.Color = Color3.new(1, 0, 0)
end

function LockpickDoor.resetPins(self: self)
	for i = 1, TOTAL_PINS do
		local pinModel = self.lockpickModel[tostring(i)]
		local part1 = pinModel.Part1
		local original = self.originalProperties[i]
		TweenService:Create(part1, TweenInfo.new(TWEEN_DURATION), {Position = original.Position, Size = original.Size}):Play()
	end
	self.expectedPinStep = 1
end

function LockpickDoor.movePin(self: self, amount: number)
	local newPinIndex = self.currentPinIndex + amount

	if newPinIndex >= 1 and newPinIndex <= TOTAL_PINS then
		self.currentPinIndex = newPinIndex
	else
		return
	end

	if self.highlightParts[1] then
		self.highlightParts[1].Color = Color3.new(1, 1, 1)
		self.highlightParts[2].Color = Color3.new(1, 1, 1)
	end

	local pinModel = self.lockpickModel[tostring(self.currentPinIndex)]

	self:highlightPin(pinModel.Part1, pinModel.Part2)

	local moveAmount = (amount > 0) and 1.2/4.5 or -1.2/4.5 
	TweenService:Create(self.lockpickHandle, TweenInfo.new(0.1), {CFrame = self.lockpickHandle.CFrame * CFrame.new(0, 0, moveAmount)}):Play()
end

function LockpickDoor.setupInitialHighlight(self: self)
	local pinModel = self.lockpickModel[tostring(self.currentPinIndex)]
	self:highlightPin(pinModel.Part1, pinModel.Part2)
end

-- TODO: Determinar que hacer
function LockpickDoor.AddCondition(self: self, name: string)
	
end

function LockpickDoor.Destroy(self: self)
end


return LockpickDoor