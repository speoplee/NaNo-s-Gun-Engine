type Action = {
	pressed: ((input: InputObject) -> ())?,
	released: ((input: InputObject) -> ())?
}

local BindedActions: { [Enum.KeyCode | Enum.UserInputType]: Action } = {}
local InputHandler = {}
local UserInputService = game:GetService("UserInputService")

function InputHandler.Register(bindings: { [Enum.KeyCode | Enum.UserInputType]: Action })
	for key, action in bindings do
		BindedActions[key] = action
	end
end

function InputHandler.Start()
	if InputHandler._started then return end
	InputHandler._started = true

	InputHandler._connBegan = UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		local act = BindedActions[input.KeyCode] or BindedActions[input.UserInputType]
		if act and act.pressed then
			task.spawn(act.pressed, input)
		end
	end)

	InputHandler._connEnded = UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end
		local act = BindedActions[input.KeyCode] or BindedActions[input.UserInputType]
		if act and act.released then
			task.spawn(act.released, input)
		end
	end)
end

function InputHandler.Stop()
	if not InputHandler._started then return end
	InputHandler._started = false
	if InputHandler._connBegan then InputHandler._connBegan:Disconnect() end
	if InputHandler._connEnded then InputHandler._connEnded:Disconnect() end
end

return InputHandler