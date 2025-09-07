local CollectionService = game:GetService("CollectionService")

local Signal = require(script.Util.Signal)
local Types = require(script.Types)
local LockpickDoor = require(script.LockpickDoor)

local TAG_DOOR = "LockpickDoor"

local DoorSystem = {}
DoorSystem.Doors = {} :: {[string]: LockpickDoor.self}
DoorSystem.DoorAdded = Signal.new() :: Signal.Signal<string, LockpickDoor.self>
DoorSystem.DoorRemoved = Signal.new() :: Signal.Signal<string>

-- TODO: Determinar que hacer
function DoorSystem.AddCondition(name: string, ...)
	
end

function DoorSystem.CreateDoor(ID: string, door: Types.LockpickDoor)
	local newLockpickDoor = LockpickDoor.new(door)
	DoorSystem.Doors[ID] = newLockpickDoor
	
	DoorSystem.DoorAdded:Fire(ID, newLockpickDoor)
end

function DoorSystem.RemoveDoor(ID: string)
	local lockpickDoor = DoorSystem.Doors[ID]
	if not lockpickDoor then return end

	lockpickDoor:Destroy()
	DoorSystem.Doors[ID] = nil
	
	DoorSystem.DoorRemoved:Fire(ID)
end

function DoorSystem.GetDoorFromID(ID: string): LockpickDoor.self
	return DoorSystem.Doors[ID]
end

local function autoCreateDoor(door: Types.LockpickDoor)
	local ID = door:GetAttribute("ID")
	if not ID then
		warn(`{door:GetFullName()} missing ID attribute.`)
		return
	end
	DoorSystem.CreateDoor(ID, door)
end

for _, door in CollectionService:GetTagged(TAG_DOOR) do
	task.spawn(autoCreateDoor, door)
end

CollectionService:GetInstanceAddedSignal(TAG_DOOR):Connect(autoCreateDoor)
CollectionService:GetInstanceRemovedSignal(TAG_DOOR):Connect(function(door) 
	local ID = door:GetAttribute("ID")
	if ID then
		DoorSystem.RemoveDoor(ID)
	end
end)

return DoorSystem
