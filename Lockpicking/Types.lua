--> Type Definitions
export type LockpickComponents = Model & {
	[number]: Model?,
	Background: MeshPart,
	Lockpick: MeshPart,
	Camera: Part & {
		ProximityPrompt: ProximityPrompt
	}
}

export type LockpickDoor = {
	Door1: Model,
	Door2: Model,
	Lockpick: LockpickComponents
} & Instance

return nil