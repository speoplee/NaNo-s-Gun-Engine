local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RecoilHandler = {}

local Camera = Workspace.CurrentCamera
local Recoil = Vector2.new()
local Zoom = 0
local Time = 0

local RecoilPattern = {
	{2, 8, -1, 0.8, -0.2},
	{5, 8, -1, 0.8, 0.2},
	{8, 10, -2, 0.8, -0.15},
}
local Intensity = 2
local RecoilReset = 0.4

local Sustained = 0
local SustainIncreasePerShot = 0.25 
local SustainMax = 1.6
local SustainDecayRate = 0.6

local ShakeFreqX = 30
local ShakeFreqY = 22
local ShakeAmpMultiplier = 2.8 * 2

local RecoilDecayX = 12 * 5 
local RecoilDecayY = 5 * 2 

local CurShots = 0
local LastShot = 0

local function Lerp(A: number, B: number, T: number): number
	return A * (1 - T) + B * T
end

local function Clamp(Val, A, B)
	return math.max(A, math.min(B, Val))
end

local MaxPatternShots = RecoilPattern[#RecoilPattern][1]

local function OnRenderStepped(DeltaTime: number)
	if not Camera then return end
	Time += DeltaTime

	Sustained = Lerp(Sustained, 0, math.min(DeltaTime * SustainDecayRate, 1))

	local ShakeAmp = Sustained * ShakeAmpMultiplier
	local JitterX = (math.random(-100,100) / 100) * (0.25 * Sustained)
	local OscX = math.sin(Time * ShakeFreqX) * (0.6 * ShakeAmp) + JitterX
	local OscY = math.cos(Time * ShakeFreqY) * (0.9 * ShakeAmp)

	local TotalX = Recoil.X + OscX
	local TotalY = Recoil.Y + OscY

	Camera.CFrame *= CFrame.Angles(math.rad(TotalY) * DeltaTime, math.rad(TotalX) * DeltaTime, 0)
	Camera.FieldOfView = 70 + Zoom

	local DecayX = math.min(DeltaTime * RecoilDecayX, 1)
	local DecayY = math.min(DeltaTime * RecoilDecayY, 1)
	Recoil = Vector2.new(Lerp(Recoil.X, 0, DecayX), Lerp(Recoil.Y, 0, DecayY))

	Zoom = Lerp(Zoom, 0, math.min(DeltaTime * 20, 1))
end

RunService:BindToRenderStep("Recoiler", Enum.RenderPriority.Camera.Value + 1, OnRenderStepped)

function RecoilHandler.Recoil()
	CurShots = (tick() - LastShot > RecoilReset) and 1 or CurShots + 1
	LastShot = tick()

	local ShotIndex = CurShots

	local Matched = false
	for _, V in ipairs(RecoilPattern) do
		if ShotIndex <= V[1] then
			Matched = true
			task.spawn(function()
				local Num = 0
				local Ratio = Clamp(ShotIndex / MaxPatternShots, 0, 1)
				local VertScale = Lerp(0.5, 1.0, Ratio)

				while math.abs(Num - V[2]) > 0.01 do
					Num = Lerp(Num, V[2], V[4])
					Recoil += Vector2.new(Num * V[5], (Num / 10) * Intensity * VertScale)
					RunService.RenderStepped:Wait()
				end

				while math.abs(Num - V[3]) > 0.01 do
					Num = Lerp(Num, V[3], V[4])
					Recoil += Vector2.new(Num * V[5], (Num / 10) * Intensity * VertScale)
					RunService.RenderStepped:Wait()
				end
			end)
			break
		end
	end

	if not Matched then
		Sustained = Clamp(Sustained + SustainIncreasePerShot, 0, SustainMax)
		local Lateral = (math.random(-100,100) / 100) * 0.6 * SustainIncreasePerShot
		Recoil += Vector2.new(Lateral, 0)
	end

	Zoom = 1
end

return RecoilHandler