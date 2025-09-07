local GunEngine = game:GetService("ReplicatedStorage").GunEngine
local RunService = game:GetService("RunService")

local WeaponConstructor = require(script.Parent.Parent.Core.WeaponConstructor)
local Types = require(script.Parent.Parent.Utils.Types)
local ConnectionManager = require(script.Parent.Parent.Core.ConnectionManager)
ConnectionManager = ConnectionManager.new()

local AttachmentsFolder = GunEngine.Attachments

export type Weapon = WeaponConstructor.Weapon
export type Attachment = Types.Attachment

local AttachmentsHandler = {}

function AttachmentsHandler:LoadAttachments(gun: Weapon)
	if not gun.Attachments then return end
	for _, attachment in ipairs(gun.Attachments) do
		self:LoadAttachment(gun, attachment)
	end
end

function AttachmentsHandler:LoadAttachment(gun: Weapon, attachment: Attachment)
	local attachmentInstance = AttachmentsFolder:FindFirstChild(attachment.Name)
	if not attachmentInstance then return end

	local clone = attachmentInstance:Clone()
	clone.Parent = workspace

	local attachmentParent = gun.Viewmodel:FindFirstChild(clone.Name, true)
	if attachmentParent then
		clone.Parent = attachmentParent
	end

	if attachment.Function then
		attachment.Function(gun, clone)
	end

	ConnectionManager:Connect(attachment.Name .. "_Follow", RunService.RenderStepped, function()
		if clone and attachmentParent then
			clone:PivotTo(attachmentParent.WorldCFrame)
		end
	end)
end

return AttachmentsHandler