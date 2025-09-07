local Animations = {}

function Animations.LoadVMAnimations(Viewmodel)
	local LoadedAnimations = {}

	if Viewmodel.Animations:FindFirstChild("ReloadAnims") then
		LoadedAnimations[1] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.Idle)
		LoadedAnimations[2] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.Shoot)
		LoadedAnimations.Reload = {
			[1] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.ReloadAnims.Start),
			[2] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.ReloadAnims.Mid),
			[3] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.ReloadAnims.Final)
		}

		for _, Anim in LoadedAnimations.Reload do
			Anim.Looped = false
		end

		for _, Anim in {LoadedAnimations[1], LoadedAnimations[2]} do
			Anim.Looped = false
		end
	else
		LoadedAnimations[1] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.Idle)
		LoadedAnimations[2] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.Shoot)
		LoadedAnimations[3] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.Reload)

		for _, Anim in LoadedAnimations do
			Anim.Looped = false
		end
	end

	if Viewmodel.Animations:FindFirstChild("ShootProjectile") then
		LoadedAnimations.ShootProjectile = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.ShootProjectile)
		LoadedAnimations.ShootProjectile.Looped = false
	end

	if Viewmodel.Animations:FindFirstChild("ReloadProjectile") then
		LoadedAnimations.ReloadProjectile = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.ReloadProjectile)
		LoadedAnimations.ReloadProjectile.Looped = false
	end

	if Viewmodel.Animations:FindFirstChild("RunAnimations") then
		LoadedAnimations.Run = {
			[1] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.RunAnimations.Start),
			[2] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.RunAnimations.Loop),
			[3] = Viewmodel.Animation:LoadAnimation(Viewmodel.Animations.RunAnimations.End)
		}
	else
		LoadedAnimations.Run = nil
	end

	LoadedAnimations[1].Priority = Enum.AnimationPriority.Action
	LoadedAnimations[2].Priority = Enum.AnimationPriority.Action2

	if LoadedAnimations[3] then
		LoadedAnimations[3].Priority = Enum.AnimationPriority.Action3
	end

	if LoadedAnimations.Reload then
		for _, Anim in LoadedAnimations.Reload do
			Anim.Priority = Enum.AnimationPriority.Action3
		end
	end

	return LoadedAnimations
end

function Animations.LoadThirdPersonAnimations(Character, Tool)
	local LoadedAnimations = {}

	local function LoadAnim(AnimObject)
		return Character.Humanoid:LoadAnimation(AnimObject)
	end

	local ThirdAnimFolder = Tool:FindFirstChild("Animations")
	if not ThirdAnimFolder then return nil end

	if ThirdAnimFolder:FindFirstChild("ReloadAnims") then
		LoadedAnimations[1] = LoadAnim(ThirdAnimFolder:FindFirstChild("Idle"))
		LoadedAnimations[2] = LoadAnim(ThirdAnimFolder:FindFirstChild("Shoot"))
		LoadedAnimations.Reload = {
			[1] = LoadAnim(ThirdAnimFolder.ReloadAnims:FindFirstChild("Start")),
			[2] = LoadAnim(ThirdAnimFolder.ReloadAnims:FindFirstChild("Mid")),
			[3] = LoadAnim(ThirdAnimFolder.ReloadAnims:FindFirstChild("Final"))
		}
	else
		LoadedAnimations[1] = LoadAnim(ThirdAnimFolder:FindFirstChild("Idle"))
		LoadedAnimations[2] = LoadAnim(ThirdAnimFolder:FindFirstChild("Shoot"))
		LoadedAnimations[3] = LoadAnim(ThirdAnimFolder:FindFirstChild("Reload"))
	end

	if ThirdAnimFolder:FindFirstChild("ShootProjectile") then
		LoadedAnimations.ShootProjectile = LoadAnim(ThirdAnimFolder:FindFirstChild("ShootProjectile"))
	end

	if ThirdAnimFolder:FindFirstChild("ReloadProjectile") then
		LoadedAnimations.ReloadProjectile = LoadAnim(ThirdAnimFolder:FindFirstChild("ReloadProjectile"))
	end

	for _, Anim in LoadedAnimations do
		if Anim then
			Anim.Looped = false
		end
	end

	if LoadedAnimations.Reload then
		for _, Anim in LoadedAnimations.Reload do
			Anim.Looped = false
		end
	end

	if LoadedAnimations.ShootProjectile then
		LoadedAnimations.ShootProjectile.Looped = false
	end

	if LoadedAnimations.ReloadProjectile then
		LoadedAnimations.ReloadProjectile.Looped = false
	end

	return LoadedAnimations
end

return Animations
