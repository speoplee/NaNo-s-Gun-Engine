local InventoryModule = {}

local UserInputService = game:GetService("UserInputService")

local Config = {
	Columns = 8,
	Rows = 4,
	Spacing = 4,
	StartOffsetX = 0,
	StartOffsetY = 0
}

local ExampleCass = script.Parent.Parent.Background.Holder.Sections.Items:WaitForChild("ExampleCass")
local OriginalItemContainer = ExampleCass:FindFirstChild("ItemContainer")
if OriginalItemContainer then
	OriginalItemContainer.Parent = nil
end

local CellLocation = Instance.new("Folder")
CellLocation.Name = "CellLocation"
CellLocation.Parent = ExampleCass.Parent

local CellSize = ExampleCass.Size
local Cells = {}
local CellsXY = {}
local CellOriginalTransparency = {}

ExampleCass.Visible = false

for Row = 0, Config.Rows - 1 do
	CellsXY[Row + 1] = {}
	for Col = 0, Config.Columns - 1 do
		local Cell = ExampleCass:Clone()
		Cell.Name = "Cell_" .. tostring((Row * Config.Columns) + Col + 1)
		Cell.Visible = true
		local PosX = Config.StartOffsetX + (CellSize.X.Offset + Config.Spacing) * Col
		local PosY = Config.StartOffsetY + (CellSize.Y.Offset + Config.Spacing) * Row
		Cell.Position = UDim2.new(0, PosX, 0, PosY)
		Cell.Size = UDim2.new(0, CellSize.X.Offset, 0, CellSize.Y.Offset)
		Cell.Parent = CellLocation
		table.insert(Cells, Cell)
		CellsXY[Row + 1][Col + 1] = Cell
		CellOriginalTransparency[Cell] = Cell.ImageTransparency
	end
end

local OccupiedPositions = {}

local function PositionKey(Row, Col)
	return tostring(Row) .. "-" .. tostring(Col)
end

local Items = {}

local function CanPlaceAt(Row, Col, SizeRows, SizeCols, IgnoreItem)
	if Row < 1 or Col < 1 or (Row + SizeRows - 1) > Config.Rows or (Col + SizeCols - 1) > Config.Columns then
		return false
	end
	for R = Row, Row + SizeRows - 1 do
		for C = Col, Col + SizeCols - 1 do
			local Occ = OccupiedPositions[PositionKey(R, C)]
			if Occ and Occ ~= IgnoreItem then
				return false
			end
		end
	end
	return true
end

local function OccupyPositions(Item, Row, Col)
	local SizeRows = Item:GetAttribute("SizeRows")
	local SizeCols = Item:GetAttribute("SizeCols")
	for R = Row, Row + SizeRows - 1 do
		for C = Col, Col + SizeCols - 1 do
			OccupiedPositions[PositionKey(R, C)] = Item
		end
	end
end

local function FreePositions(Item)
	for K, V in pairs(OccupiedPositions) do
		if V == Item then
			OccupiedPositions[K] = nil
		end
	end
end

local function UpdateItemPosition(Item, Row, Col)
	local SizeRows = Item:GetAttribute("SizeRows")
	local SizeCols = Item:GetAttribute("SizeCols")
	local PosX = Config.StartOffsetX + (CellSize.X.Offset + Config.Spacing) * (Col - 1)
	local PosY = Config.StartOffsetY + (CellSize.Y.Offset + Config.Spacing) * (Row - 1)
	local Width = CellSize.X.Offset * SizeCols + Config.Spacing * (SizeCols - 1)
	local Height = CellSize.Y.Offset * SizeRows + Config.Spacing * (SizeRows - 1)
	Item.Position = UDim2.new(0, PosX, 0, PosY)
	Item.Size = UDim2.new(0, Width, 0, Height)
end

function InventoryModule.Add(Position, Size, Object)
	local Row, Col = Position.Y, Position.X
	local SizeRows, SizeCols = Size.Y, Size.X
	if not CanPlaceAt(Row, Col, SizeRows, SizeCols, nil) then
		error("No se puede agregar el item en esa posición porque está ocupada.")
	end

	local ItemContainer = OriginalItemContainer:Clone()
	ItemContainer.Name = "ItemContainer"

	local guiRoot = script.Parent.Parent
	local GuiBackground = guiRoot and guiRoot:FindFirstChild("Background")
	local menuHidden = false
	if GuiBackground and GuiBackground:IsA("Frame") then
		menuHidden = GuiBackground.BackgroundTransparency >= 0.99
	end

	if menuHidden then
		ItemContainer.Visible = false
		for _, d in ipairs(ItemContainer:GetDescendants()) do
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then
				d.ImageTransparency = 1
			elseif d:IsA("TextLabel") or d:IsA("TextButton") then
				d.TextTransparency = 1
			elseif d:IsA("Frame") then
				if d.BackgroundTransparency ~= nil then
					d.BackgroundTransparency = 1
				end
			elseif d:IsA("ViewportFrame") then
				d.Visible = false
			end
		end
	end

	ItemContainer.Parent = CellLocation
	ItemContainer:SetAttribute("SizeRows", SizeRows)
	ItemContainer:SetAttribute("SizeCols", SizeCols)
	ItemContainer:SetAttribute("Row", Row)
	ItemContainer:SetAttribute("Col", Col)

	OccupyPositions(ItemContainer, Row, Col)
	UpdateItemPosition(ItemContainer, Row, Col)

	Object.Parent = ItemContainer

	if menuHidden then
		for _, d in ipairs(ItemContainer:GetDescendants()) do
			if d:IsA("ViewportFrame") then
				d.Visible = false
			end
		end
	end

	table.insert(Items, ItemContainer)
	return ItemContainer
end

function InventoryModule.SetContainersVisible(visible)
	for _, child in ipairs(CellLocation:GetChildren()) do
		if child.Name == "ItemContainer" then
			child.Visible = visible
			for _, d in ipairs(child:GetDescendants()) do
				if d:IsA("ViewportFrame") then
					d.Visible = visible
				elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
					if visible then d.ImageTransparency = 0 else d.ImageTransparency = 1 end
				elseif d:IsA("TextLabel") or d:IsA("TextButton") then
					if visible then d.TextTransparency = 0 else d.TextTransparency = 1 end
				elseif d:IsA("Frame") then
					if visible then d.BackgroundTransparency = 0 else d.BackgroundTransparency = 1 end
				end
			end
		end
	end
end

local CurrentRow, CurrentCol = 1, 1
local MaxRow, MaxCol = Config.Rows, Config.Columns
local SelectedItem = nil

local function UpdateHighlight()
	for R = 1, MaxRow do
		for C = 1, MaxCol do
			local Cell = CellsXY[R][C]
			Cell.ImageTransparency = CellOriginalTransparency[Cell] or 1
		end
	end
	for _, Child in ipairs(CellLocation:GetChildren()) do
		local SizeRows = Child:GetAttribute("SizeRows")
		local SizeCols = Child:GetAttribute("SizeCols")
		if SizeRows and SizeCols then
			Child.ImageTransparency = 1
		end
	end

	local HoveredItem = nil
	for _, Child in CellLocation:GetChildren() do
		local SizeRows = Child:GetAttribute("SizeRows")
		local SizeCols = Child:GetAttribute("SizeCols")
		if SizeRows and SizeCols then
			local ItemRow = Child:GetAttribute("Row")
			local ItemCol = Child:GetAttribute("Col")
			if CurrentRow >= ItemRow and CurrentRow < ItemRow + SizeRows and CurrentCol >= ItemCol and CurrentCol < ItemCol + SizeCols then
				HoveredItem = Child
				break
			end
		end
	end

	if SelectedItem then
		SelectedItem.ImageTransparency = 0.2
	end

	if HoveredItem then
		HoveredItem.ImageTransparency = 0.2
	else
		CellsXY[CurrentRow][CurrentCol].ImageTransparency = 0.5
	end
end

UpdateHighlight()

local function MoveItem(DeltaRow, DeltaCol)
	if SelectedItem then
		local ItemRow = SelectedItem:GetAttribute("Row")
		local ItemCol = SelectedItem:GetAttribute("Col")
		local NewRow = ItemRow + DeltaRow
		local NewCol = ItemCol + DeltaCol
		local SizeRows = SelectedItem:GetAttribute("SizeRows")
		local SizeCols = SelectedItem:GetAttribute("SizeCols")
		if CanPlaceAt(NewRow, NewCol, SizeRows, SizeCols, SelectedItem) then
			FreePositions(SelectedItem)
			SelectedItem:SetAttribute("Row", NewRow)
			SelectedItem:SetAttribute("Col", NewCol)
			OccupyPositions(SelectedItem, NewRow, NewCol)
			UpdateItemPosition(SelectedItem, NewRow, NewCol)
			CurrentRow = NewRow
			CurrentCol = NewCol
		end
	else
		CurrentRow = math.clamp(CurrentRow + DeltaRow, 1, MaxRow)
		CurrentCol = math.clamp(CurrentCol + DeltaCol, 1, MaxCol)
	end
end

local Connection

function InventoryModule.Start()
	if Connection then return end
	Connection = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then return end
		if Input.UserInputType == Enum.UserInputType.Keyboard then
			if Input.KeyCode == Enum.KeyCode.Return then
				local CellItem = nil
				for _, Child in CellLocation:GetChildren() do
					local SizeRows = Child:GetAttribute("SizeRows")
					local SizeCols = Child:GetAttribute("SizeCols")
					if SizeRows and SizeCols then
						local ItemRow = Child:GetAttribute("Row")
						local ItemCol = Child:GetAttribute("Col")
						if CurrentRow >= ItemRow and CurrentRow < ItemRow + SizeRows and CurrentCol >= ItemCol and CurrentCol < ItemCol + SizeCols then
							CellItem = Child
							break
						end
					end
				end
				if CellItem then
					if SelectedItem == CellItem then
						SelectedItem = nil
					else
						SelectedItem = CellItem
					end
					UpdateHighlight()
				end
			end
			if Input.KeyCode == Enum.KeyCode.W then
				MoveItem(-1, 0)
			elseif Input.KeyCode == Enum.KeyCode.S then
				MoveItem(1, 0)
			elseif Input.KeyCode == Enum.KeyCode.A then
				MoveItem(0, -1)
			elseif Input.KeyCode == Enum.KeyCode.D then
				MoveItem(0, 1)
			end
			UpdateHighlight()
		end
	end)
end

function InventoryModule.Stop()
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end

return InventoryModule