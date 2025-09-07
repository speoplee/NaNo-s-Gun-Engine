local WeaponConstructor = require(script.Parent.Parent.Core.WeaponConstructor)

local Util = {}

Util.GetBobbing = function(addition, speed, modifier)
	return math.sin(time() * addition * speed) * modifier
end

Util.CalculateOffset = function(Viewmodel: WeaponConstructor.Viewmodel, CurrentWeapon: WeaponConstructor.Weapon)
	if Viewmodel and CurrentWeapon then
		local offsetCFrame = Viewmodel.AimPoint.CFrame:ToObjectSpace(Viewmodel.PrimaryPart.CFrame)
		return offsetCFrame.Position
	end
	return nil
end

return Util