local ConnectionManager = {}
ConnectionManager.__index = ConnectionManager

function ConnectionManager.new()
	local self = setmetatable({}, ConnectionManager)
	self.connections = {}
	return self
end

function ConnectionManager:Add(connection)
	table.insert(self.connections, connection)
end

function ConnectionManager:Connect(name, event, callback)
	local conn = event:Connect(callback)
	self:Add(conn)
	return conn
end

function ConnectionManager:Clear()
	for _, conn in ipairs(self.connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	self.connections = {}
end

return ConnectionManager
