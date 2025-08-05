--[[
	author: notzanocoddz (bobhub)
]]

if not Drawing then return end

local env = getgenv();

if env.KBOBESPLibrary_Loaded then
	return
end

local Objects = {
	['BillboardGui'] = Instance.new('BillboardGui'),
	['Frame'] = Instance.new('Frame'),
	['Highlight'] = Instance.new('Highlight'),
	['TextLabel'] = Instance.new('TextLabel'),
}

local Workspace = game:GetService('Workspace');
local Players = game:GetService('Players');
local RunService = game:GetService('RunService');
local CurrentCamera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if not Workspace:FindFirstChild('KBOB_ESP') then
	local folder = Instance.new('Folder', Workspace)
	folder.Name = 'KBOB_ESP'
end

local function GetObjectPosition(obj)
	if not obj then return end
	if obj:IsA('Model') and obj:IsDescendantOf(Workspace) then
		return obj:GetPivot().Position
	elseif obj:IsA('BasePart') then
		return obj.Position
	end
end

local KBOB_ESPLibrary = {
	ESPObjects = {},
	TextSize = 18,
	Settings = {
		Distance = false,
		Rainbow = false,
		Tracer = false,
	}
}
KBOB_ESPLibrary.__index = KBOB_ESPLibrary

export type ESP_Params = {
	Text: string?,
	Object: Instance?,
	Color: Color3?
}

function KBOB_ESPLibrary:CreateESP(options: ESP_Params)
	if not options then return end

	local Text = options.Text or 'Object'
	local Color = options.Color or Color3.fromRGB(255, 255, 255)
	local Object = options.Object

	if Object:GetAttribute("KBOBESP_Added") then return end
	Object:SetAttribute("KBOBESP_Added", true)

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. Object.Name)
	if not classFolder then
		classFolder = Instance.new('Folder', Workspace.KBOB_ESP)
		classFolder.Name = 'Class: ' .. Object.Name
	end

	local BillboardGui = Objects.BillboardGui:Clone()
	BillboardGui.Parent = classFolder
	BillboardGui.Name = Text
	BillboardGui.Adornee = Object
	BillboardGui.AlwaysOnTop = true
	BillboardGui.Enabled = false
	BillboardGui.Size = UDim2.new(0, 200, 0, 50)
	BillboardGui.MaxDistance = math.huge
	BillboardGui.ResetOnSpawn = false

	local Frame = Objects.Frame:Clone()
	Frame.Parent = BillboardGui
	Frame.BackgroundTransparency = 1
	Frame.Size = UDim2.new(1, 0, 1, 0)

	local TextLabel = Objects.TextLabel:Clone()
	TextLabel.Parent = Frame
	TextLabel.Name = 'Text: ' .. Text
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.FontFace = Font.new('rbxassetid://12187374954', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	TextLabel.RichText = true
	TextLabel.TextSize = self.TextSize
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextWrapped = true

	local Highlight = Objects.Highlight:Clone()
	Highlight.Parent = Object
	Highlight.Enabled = false
	Highlight.Name = 'Highlight: ' .. Object.Name
	Highlight.Adornee = Object
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.FillTransparency = 0.5
	Highlight.FillColor = Color
	Highlight.OutlineTransparency = 0
	Highlight.OutlineColor = Color

	-- Synapse X API (Drawing)
	local Line = Drawing.new('Line')
	Line.Visible = false
	Line.Color = Color
	Line.Transparency = 1
	Line.Thickness = 1.5

	local connection = RunService.RenderStepped:Connect(function()
		if TextLabel and Object and Object:IsDescendantOf(Workspace) then
			local pos = GetObjectPosition(Object)
			if not pos then return end

			local distance = LocalPlayer:DistanceFromCharacter(pos)

			local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(pos)
			if OnScreen then
				Line.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
				Line.To = Vector2.new(Vector.X, Vector.Y)
				Line.Visible = self.Settings.Tracer
			else
				Line.Visible = false
			end

			if self.Settings.Distance then
				TextLabel.Text = Text .. '\n' .. math.floor(distance) .. ' Studs'
			else
				TextLabel.Text = Text
			end
		end
	end)

	self.ESPObjects[Object] = {
		Folder = classFolder,
		BillboardGui = BillboardGui,
		Highlight = Highlight,
		TextLabel = TextLabel,
		Line = Line,
		Connection = connection,
	}
end

function KBOB_ESPLibrary:EnabledDistance(enabled: boolean)
	self.Settings.Distance = enabled
end

function KBOB_ESPLibrary:EnabledTracer(enabled: boolean)
	self.Settings.Tracer = enabled
end

function KBOB_ESPLibrary:ShowRainbow(enabled: boolean)
	self.Settings.Rainbow = enabled
end

function KBOB_ESPLibrary:SetEnabled(object: Instance, enabled: boolean)
	if not object then return end

	local record = self.ESPObjects and self.ESPObjects[object]
	if not record then return end

	if record.BillboardGui and record.TextLabel then
		record.BillboardGui.Enabled = enabled
		record.TextLabel.Visible = enabled
	end

	if record.Highlight then
		record.Highlight.Enabled = enabled
	end

	if record.Line then
		record.Line.Visible = enabled and self.Settings.Tracer
	end
end

function KBOB_ESPLibrary:SetColor(object: Instance, newColor: Color3)
	if not object then return end
	local esp = self.ESPObjects[object]
	if not esp then return end
	
	if esp.TextLabel then
		esp.TextLabel.TextColor3 = newColor
	end

	if esp.Highlight then
		esp.Highlight.FillColor = newColor
		esp.Highlight.OutlineColor = newColor
	end

	if esp.Line then
		esp.Line.Color = newColor
	end
end

function KBOB_ESPLibrary:SetText(object: Instance, newText: string)
	if not object then return end
	local esp = self.ESPObjects[object]
	if not esp then return end
	
	if esp.TextLabel then
		esp.TextLabel.Text = newText
	end
end

function KBOB_ESPLibrary:SetTextSize(size: number)
	for _, esp in pairs(self.ESPObjects) do
		if esp.TextLabel then
			if typeof(size) == "number" then
				esp.TextLabel.TextSize = size
			end
		end
	end
end

function KBOB_ESPLibrary:RemoveESP(object: Instance)
	if not object then return end

	local espFolder = Workspace:FindFirstChild("KBOB_ESP")
	if not espFolder then return end

	local classFolder = espFolder:FindFirstChild("Class: " .. object.Name)
	if classFolder then
		classFolder:Destroy()
	end

	local highlight = object:FindFirstChild("Highlight: " .. object.Name)
	if highlight then
		highlight:Destroy()
	end

	if object:GetAttribute("KBOBESP_Added") then
		object:SetAttribute("KBOBESP_Added", nil)
	end

	local record = self.ESPObjects[object]
	if record then
		if record.Connection then
			record.Connection:Disconnect()
		end
		if record.Line then
			record.Line:Remove()
		end
		self.ESPObjects[object] = nil
	end
end

function KBOB_ESPLibrary:Unload()
	env.KBOBESPLibrary_Loaded = false

	local espFolder = Workspace:FindFirstChild("KBOB_ESP")
	if espFolder then
		espFolder:Destroy()
	end	

	for object, data in pairs(self.ESPObjects) do
		if data.Connection then
			data.Connection:Disconnect()
		end

		if data.Line then
			data.Line:Remove()	
		end

		local highlight = object:FindFirstChild("Highlight: " .. object.Name)
		if highlight then
			highlight:Destroy()
		end

		if object:GetAttribute("KBOBESP_Added") then
			object:SetAttribute("KBOBESP_Added", nil)
		end
	end

	self.ESPObjects = {}
	warn('KBOB ESPLibrary has unloaded!!!')
end

env.KBOBESPLibrary_Loaded = true
return KBOB_ESPLibrary
