--> Type Definition
task.wait(3)
type Cell = {
	F: number,
	G: number,
	H: number,
	ParentI: number,
	ParentJ: number,
	ParentK: number
}

--> Grid Information
local XMin, XMax = 1, 170
local YMin, YMax = 0, 1
local ZMin, ZMax = -50, 33
local XDim = XMax - XMin + 1
local YDim = YMax - YMin + 1
local ZDim = ZMax - ZMin + 1

local Floor = math.floor
local Sqrt = math.sqrt
local function Idx(I, J, K)
	return ((I - 1) * YDim + (J - 1)) * ZDim + K
end

--> Helper Functions
local function ToGrid(Position: Vector3): {I: number, J: number, K: number}
	return {
		I = Floor(Position.X + 0.5) - XMin + 1,
		J = Floor(Position.Y + 0.5) - YMin + 1,
		K = Floor(Position.Z + 0.5) - ZMin + 1
	}
end

local function ToWorld(I: number, J: number, K: number): Vector3
	return Vector3.new(XMin + I - 1, YMin + J - 1, ZMin + K - 1)
end

local function IsValid(Position: Vector3): boolean
	local GridPos = ToGrid(Position)
	return GridPos.I >= 1 and GridPos.I <= XDim
		and GridPos.J >= 1 and GridPos.J <= YDim
		and GridPos.K >= 1 and GridPos.K <= ZDim
end

local function IsUnblocked(Position: Vector3): boolean
	local Size = Vector3.new(1, 1, 1)
	local Region = Region3.new(Position - Size/2, Position + Size/2)
	local PartsInRegion = workspace:FindPartsInRegion3(Region, nil, math.huge)
	return #PartsInRegion == 0
end

local function IsDestination(Position: Vector3, Destination: Vector3): boolean
	local PosGrid = ToGrid(Position)
	local DestGrid = ToGrid(Destination)
	return PosGrid.I == DestGrid.I and PosGrid.J == DestGrid.J and PosGrid.K == DestGrid.K
end

local function CalculateHeuristic(Position: Vector3, Destination: Vector3): number
	return Sqrt((Position.X - Destination.X)^2 + (Position.Y - Destination.Y)^2 + (Position.Z - Destination.Z)^2)
end

local function Reverse(Table: {Vector3}): {Vector3}
	local NewTable = {}
	for I = #Table, 1, -1 do
		NewTable[#NewTable + 1] = Table[I]
	end
	return NewTable
end

--> Heap Logic
local function HeapInsert(Heap: {any}, Element: any, Comparator: (any, any) -> boolean)
	Heap[#Heap + 1] = Element
	local I = #Heap
	while I > 1 do
		local Parent = math.floor(I / 2)
		if not Comparator(Heap[I], Heap[Parent]) then break end
		Heap[I], Heap[Parent] = Heap[Parent], Heap[I]
		I = Parent
	end
end

local function HeapRemove(Heap: {any}, Comparator: (any, any) -> boolean): any
	if #Heap == 0 then return nil end
	local Root = Heap[1]
	Heap[1] = Heap[#Heap]
	Heap[#Heap] = nil
	local I = 1
	while true do
		local Left = 2 * I
		local Right = Left + 1
		local Smallest = I
		if Left <= #Heap and Comparator(Heap[Left], Heap[Smallest]) then Smallest = Left end
		if Right <= #Heap and Comparator(Heap[Right], Heap[Smallest]) then Smallest = Right end
		if Smallest == I then break end
		Heap[I], Heap[Smallest] = Heap[Smallest], Heap[I]
		I = Smallest
	end
	return Root
end

local Directions = {}
for Dx = -1, 1 do
	for Dy = -1, 1 do
		for Dz = -1, 1 do
			if Dx ~= 0 or Dy ~= 0 or Dz ~= 0 then
				Directions[#Directions + 1] = {Dx = Dx, Dy = Dy, Dz = Dz}
			end
		end
	end
end

--> Main Logic
local Time1 = tick()
local function TracePath(CellDetails: {Cell}, DestI: number, DestJ: number, DestK: number): {Vector3}
	local Path = {}
	local I, J, K = DestI, DestJ, DestK
	while not (CellDetails[Idx(I, J, K)].ParentI == I
		and CellDetails[Idx(I, J, K)].ParentJ == J
		and CellDetails[Idx(I, J, K)].ParentK == K) do
		Path[#Path + 1] = ToWorld(I, J, K)
		local TempI = CellDetails[Idx(I, J, K)].ParentI
		local TempJ = CellDetails[Idx(I, J, K)].ParentJ
		local TempK = CellDetails[Idx(I, J, K)].ParentK
		I, J, K = TempI, TempJ, TempK
	end
	Path[#Path + 1] = ToWorld(I, J, K)
	return Reverse(Path)
end

local function ASearch3D(Origin: Vector3, Destination: Vector3): {Vector3}? 
	if not IsValid(Origin) or not IsValid(Destination) then return nil end
	if not IsUnblocked(Origin) or not IsUnblocked(Destination) then return nil end
	if IsDestination(Origin, Destination) then return {Origin} end

	local OriginGrid = ToGrid(Origin)
	local DestGrid = ToGrid(Destination)
	local Total = XDim * YDim * ZDim
	local ClosedList = {}
	local CellDetails = {}

	for I = 1, Total do
		ClosedList[I] = false
		CellDetails[I] = {F = math.huge, G = math.huge, H = math.huge, ParentI = -1, ParentJ = -1, ParentK = -1}
	end

	CellDetails[Idx(OriginGrid.I, OriginGrid.J, OriginGrid.K)] = {
		F = 0, G = 0, H = 0,
		ParentI = OriginGrid.I, ParentJ = OriginGrid.J, ParentK = OriginGrid.K
	}

	local OpenList = {}
	HeapInsert(OpenList, {I = OriginGrid.I, J = OriginGrid.J, K = OriginGrid.K, F = 0}, function(A, B) return A.F < B.F end)

	while #OpenList > 0 do
		local Current = HeapRemove(OpenList, function(A, B) return A.F < B.F end)
		local I, J, K = Current.I, Current.J, Current.K

		if I == DestGrid.I and J == DestGrid.J and K == DestGrid.K then
			return TracePath(CellDetails, I, J, K)
		end

		ClosedList[Idx(I, J, K)] = true

		for _, Dir in ipairs(Directions) do
			local Ni, Nj, Nk = I + Dir.Dx, J + Dir.Dy, K + Dir.Dz
			if Ni >= 1 and Ni <= XDim and Nj >= 1 and Nj <= YDim and Nk >= 1 and Nk <= ZDim and not ClosedList[Idx(Ni, Nj, Nk)] then
				local NeighborWorld = ToWorld(Ni, Nj, Nk)
				if IsUnblocked(NeighborWorld) then
					local GNew = CellDetails[Idx(I, J, K)].G + 1.0
					local HNew = CalculateHeuristic(NeighborWorld, Destination)
					local FNew = GNew + HNew
					if FNew < CellDetails[Idx(Ni, Nj, Nk)].F then
						HeapInsert(OpenList, {I = Ni, J = Nj, K = Nk, F = FNew}, function(A, B) return A.F < B.F end)
						CellDetails[Idx(Ni, Nj, Nk)] = {F = FNew, G = GNew, H = HNew, ParentI = I, ParentJ = J, ParentK = K}
					end
				end
			end
		end
	end
	return nil
end

local function GraphPath(Path: {Vector3})
	for _, Pos in ipairs(Path) do
		local Part = Instance.new("Part")
		Part.Size = Vector3.new(1, 1, 1)
		Part.Position = Pos
		Part.Anchored = true
		Part.BrickColor = BrickColor.new("Bright red")
		Part.Parent = workspace
		task.wait(0.03)
	end
end

local Origin = Vector3.new(38, 0, -0.4)
local Destination = Vector3.new(169.7, 0, 32.5)
local Path = ASearch3D(Origin, Destination)

print("NaNo spid " .. tick() - Time1)

if Path then
	GraphPath(Path)
end