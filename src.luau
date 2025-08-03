
--[[
	author: notzanocoddz (bobhub)
]]

if not Drawing then return end

local Objects = {
	['BillboardGui'] = Instance.new('BillboardGui'),
	['Frame'] = Instance.new('Frame'),
	['Highlight'] = Instance.new('Highlight'),
	['TextLabel'] = Instance.new('TextLabel'),
}

local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');
local CurrentCamera = Workspace.CurrentCamera;
local Player = game.Players.LocalPlayer;

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
	ESPSettings = {
		EnabledDistance = false,
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
	local Color = options.Color
	local Object = options.Object

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
	BillboardGui.Enabled = true
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
	TextLabel.FontSize = Enum.FontSize.Size18
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextWrapped = true

	local Highlight = Objects.Highlight:Clone()
	Highlight.Parent = Object
	Highlight.Name = 'Highlight: ' .. Object.Name
	Highlight.Enabled = true
	Highlight.Adornee = Object
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.FillTransparency = 0.5
	Highlight.FillColor = Color
	Highlight.OutlineTransparency = 0
	Highlight.OutlineColor = Color

     -- Synapse X API (Drawing)
	local Line = Drawing.new('Line')
	Line.Color = Color
	Line.Thickness = 1
	Line.Transparency = 1
	Line.Visible = false

	local distanceConn = RunService.RenderStepped:Connect(function()
		local pos = GetObjectPosition(Object)
		if pos and TextLabel then
			if self.ESPSettings.EnabledDistance then
				local dist = math.round(Player:DistanceFromCharacter(pos))
				TextLabel.Text = string.format('%s\n[%sms]', Text, dist)
			else
				TextLabel.Text = Text
			end
		end
	end)

	local tracerConn = RunService.RenderStepped:Connect(function()
		local pos = GetObjectPosition(Object)
		if pos then
			local Vector, OnScreen = CurrentCamera:WorldToViewportPoint(pos)
			if OnScreen then
				Line.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
				Line.To = Vector2.new(Vector.X, Vector.Y)
				-- Line.Visible = true
			else
				Line.Visible = false
			end
		end
	end)

	self.ESPObjects[Object] = {
		Line = Line,
		DistanceConnection = distanceConn,
		TracerConnection = tracerConn,
		BillboardGui = BillboardGui,
	}
end

function KBOB_ESPLibrary:SetEnabled(object: Instance, enabled: boolean)
	if not object then return end

	self:SetBillboardEnabled(object, enabled)
	self:SetHighlightEnabled(object, enabled)
end

function KBOB_ESPLibrary:SetTracerEnabled(object: Instance, enabled: boolean)
	local esp = self.ESPObjects[object]
	if esp and esp.Line then
		esp.Line.Visible = enabled
	end
end

function KBOB_ESPLibrary:SetBillboardEnabled(object: Instance, enabled: boolean)
	if not object then return end
	if not Workspace:FindFirstChild('KBOB_ESP') then return end

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. object.Name)
	if classFolder then
		for _, gui in pairs(classFolder:GetChildren()) do
			if gui:IsA('BillboardGui') and gui.Adornee == object then
				gui.Enabled = enabled
			end
		end
	end
end

function KBOB_ESPLibrary:SetHighlightEnabled(object: Instance, enabled: boolean)
	local highlight = object:FindFirstChild('Highlight: ' .. object.Name)
	if highlight and highlight:IsA('Highlight') then
		highlight.Enabled = enabled
	end
end

function KBOB_ESPLibrary:SetColor(object: Instance, color: Color3)
	if not object or not color then return end
	if not Workspace:FindFirstChild('KBOB_ESP') then return end

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. object.Name)
	if classFolder then
		for _, gui in pairs(classFolder:GetChildren()) do
			if gui:IsA('BillboardGui') and gui.Adornee == object then
				local frame = gui:FindFirstChild('Frame')
				if frame then
					for _, label in pairs(frame:GetChildren()) do
						if label:IsA('TextLabel') then
							label.TextColor3 = color
						end
					end
				end
			end
		end
	end

	local highlight = object:FindFirstChild('Highlight: ' .. object.Name)
	if highlight and highlight:IsA('Highlight') then
		highlight.FillColor = color
		highlight.OutlineColor = color
	end

	local esp = self.ESPObjects[object]
	if esp and esp.Line then
		esp.Line.Color = color
	end
end

function KBOB_ESPLibrary:EnabledDistance(enabled: boolean)
	self.ESPSettings.EnabledDistance = enabled
end

function KBOB_ESPLibrary:RemoveESP(object: Instance)
	if not object then return end

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. object.Name)
	if classFolder then
		classFolder:Destroy()
	end

	local highlight = object:FindFirstChild('Highlight: ' .. object.Name)
	if highlight then
		highlight:Destroy()
	end

	local esp = self.ESPObjects[object]
	if esp then
		if esp.Line then esp.Line:Remove() end
		if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
		if esp.TracerConnection then esp.TracerConnection:Disconnect() end
		self.ESPObjects[object] = nil
	end
end

function KBOB_ESPLibrary:Unload()
	for object, esp in pairs(self.ESPObjects) do
		if esp.Line then esp.Line:Remove() end
		if esp.DistanceConnection then esp.DistanceConnection:Disconnect() end
		if esp.TracerConnection then esp.TracerConnection:Disconnect() end
          	if esp.BillboardGui then esp.BillboardGui:Destroy() end

		local highlight = object:FindFirstChild('Highlight: ' .. object.Name)
		if highlight then
			highlight:Destroy()
		end
	end
	self.ESPObjects = {}

	if Workspace:FindFirstChild('KBOB_ESP') then
		Workspace.KBOB_ESP:Destroy()
	end

	print('ESP has unloaded')
end


return KBOB_ESPLibrary

