local StateManager = {}
StateManager.__index = StateManager

function StateManager.new(initialStates, validStates)
	local self = setmetatable({}, StateManager)
	self.states = {}
	self.validStates = validStates or {}
	self.StateChanged = Instance.new("BindableEvent")

	for key, value in pairs(initialStates) do
		self.states[key] = value
	end

	return self
end

function StateManager:GetState(key)
	return self.states[key]
end

function StateManager:SetState(key, value)
	if typeof(key) == "table" and typeof(value) == "table" then
		assert(#key == #value, "Las tablas key y value deben tener la misma longitud")
		for i = 1, #key do
			self:SetState(key[i], value[i])
		end
		return
	end

	local oldValue = self.states[key]
	if oldValue == value then
		return
	end

	local validForKey = self.validStates[key]
	if validForKey and validForKey[value] ~= true then
		error(("Valor inválido para el estado '%s': %s"):format(tostring(key), tostring(value)))
	end

	self.states[key] = value
	self.StateChanged:Fire(key, oldValue, value)
end

function StateManager:Reset(newStates)
	for key, _ in self.states do
		self.states[key] = nil
	end
	for key, value in newStates do
		self.states[key] = value
	end
end

function StateManager:GetAllStates()
	local copy = {}
	for k,v in self.states do
		copy[k] = v
	end
	return copy
end

return StateManager