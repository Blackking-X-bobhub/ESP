--[[
	************************************

          ESP Library by KBOB
		Author: notzanocoddz (bobhub)

	************************************
]]

local Globals = getgenv()

if Globals.KBOB_ESPLibrary then
	return Globals.KBOB_ESPLibrary
end

local Objects = {
	ScreenGui = Instance.new('ScreenGui'),
	BillboardGui = Instance.new('BillboardGui'),
	Folder = Instance.new('Folder'),
	Frame = Instance.new('Frame'),
	Highlight = Instance.new('Highlight'),
	TextLabel = Instance.new('TextLabel'),
}

local CoreGui = game:GetService('CoreGui');
local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');
local Player = game:GetService('Players').LocalPlayer
local Camera = Workspace.CurrentCamera

local Character = Player.Character or Player.CharacterAdded:Wait()

if not Workspace:FindFirstChild('KBOB_ESP') then
	local folder = Objects.Folder:Clone()
	folder.Name = 'KBOB_ESP'
	folder.Parent = Workspace
end

local function GetHUI()
	return ((identifyexecutor or getexecutorname) ~= nil and CoreGui) or Player:WaitForChild('PlayerGui')
end

local function GetPartPosition(object: Model | BasePart)
	if object:IsA('Model') then
		return object:GetPivot().Position
	elseif object:IsA('BasePart') then
		return object.Position
	end
	return nil
end

local function DistanceOfCharacter(point: Vector3)
	local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
	if HumanoidRootPart then
		return (point - HumanoidRootPart.Position).Magnitude
	elseif Camera then
		return (point - Camera.CFrame.Position).Magnitude
	end
end

local function RainbowColor()
	return Color3.fromHSV(tick() % 5 / 5, 1, 1)
end

local KBOB_ESPLibrary = {
	ESPObjects = {},
	Settings = {
	    Distance = false,
		Tracer = false,
		Rainbow = false,
		TextSize = 18,
		Text = true,
		Highlight = true,
		TracerThickness = 1.5,
	}
}

KBOB_ESPLibrary.__index = KBOB_ESPLibrary

export type ESP_Params = {
	Text: string?,
	Object: Instance?,
	Color: Color3?
}

function KBOB_ESPLibrary:CreateESP(params: ESP_Params)
	if not params then return end
	assert(typeof(params) == 'table', 'Missing table on CreateESP')

	local Text = params.Text or 'Object'
	local Object = params.Object
	local Color = params.Color or Color3.fromRGB(255, 255, 255)

	if not Object or Object:GetAttribute("KBOBESP_Added") then return end
	Object:SetAttribute("KBOBESP_Added", true)

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. Object.Name)
	if not classFolder then
		classFolder = Objects.Folder:Clone()
		classFolder.Name = 'Class: ' .. Object.Name
		classFolder.Parent = Workspace.KBOB_ESP
	end

	local BillboardFolder = Objects.Folder:Clone()
	BillboardFolder.Name = 'BillboardFolder'
	BillboardFolder.Parent = classFolder

	local TracerLine = Objects.ScreenGui:Clone()
	TracerLine.Parent = GetHUI()
	TracerLine.Name = 'TracerLine'
	TracerLine.IgnoreGuiInset = true
	TracerLine.ResetOnSpawn = false

	local BillboardGui = Objects.BillboardGui:Clone()
	BillboardGui.Parent = BillboardFolder
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
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.FontFace = Font.new('rbxassetid://12187374954', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	TextLabel.RichText = true
	TextLabel.TextSize = self.Settings.TextSize
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextWrapped = true

	local TracerLineFrame = Instance.new("Frame")
	TracerLineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	TracerLineFrame.BackgroundColor3 = Color
	TracerLineFrame.Size = UDim2.new(0, 2, 0, 0)
	TracerLineFrame.Parent = TracerLine

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

	local Connection
	Connection = RunService.RenderStepped:Connect(function()
		if not Object or not Object.Parent then
			Connection:Disconnect()
			return
		end

		local position = GetPartPosition(Object)
		if not position then return end

		local screenPos, onScreen = Camera:WorldToViewportPoint(position)

		BillboardGui.Enabled = onScreen and self.Settings.Text
		TextLabel.Visible = self.Settings.Text

		if self.Settings.Text then
			if self.Settings.Distance then
				TextLabel.Text = string.format("%s [%d Studs]", Text, math.floor(DistanceOfCharacter(position)))
			else
				TextLabel.Text = Text
			end
		end

		if self.Settings.Tracer and onScreen then
			local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			local to = Vector2.new(screenPos.X, screenPos.Y)
			local delta = to - from
			local length = delta.Magnitude
			local pos = (from + to) / 2

			TracerLineFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
			TracerLineFrame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			TracerLineFrame.Size = UDim2.new(0, self.Settings.TracerThickness, 0, length)
			TracerLineFrame.Visible = true
		else
			TracerLineFrame.Visible = false
		end

		Highlight.Enabled = self.Settings.Highlight and onScreen

		if self.Settings.Rainbow then
			local rainbow = RainbowColor()
			TextLabel.TextColor3 = rainbow
			Highlight.FillColor = rainbow
			Highlight.OutlineColor = rainbow
			TracerLineFrame.BackgroundColor3 = rainbow
		else
			TextLabel.TextColor3 = Color
			Highlight.FillColor = Color
			Highlight.OutlineColor = Color
			TracerLineFrame.BackgroundColor3 = Color
		end
	end)

	self.ESPObjects[Object] = {{
		BillboardGui = BillboardGui,
		Connection = Connection,
		Highlight = Highlight,
		Tracer = TracerLineFrame,
		TextLabel = TextLabel,
		OriginalColor = Color
	}}
end

function KBOB_ESPLibrary:EnabledDistance(enabled: boolean) self.Settings.Distance = enabled end
function KBOB_ESPLibrary:EnabledTracer(enabled: boolean) self.Settings.Tracer = enabled end
function KBOB_ESPLibrary:EnabledRainbow(enabled: boolean) self.Settings.Rainbow = enabled end
function KBOB_ESPLibrary:EnabledText(enabled: boolean) self.Settings.Text = enabled end
function KBOB_ESPLibrary:EnabledHighlight(enabled: boolean) self.Settings.Highlight = enabled end
function KBOB_ESPLibrary:SetTextSize(size: number) self.Settings.TextSize = size end
function KBOB_ESPLibrary:SetTracerThickness(thickness: number) self.Settings.TracerThickness = thickness end

function KBOB_ESPLibrary:SetColor(object: Instance, newColor: Color3)
	if not object or not self.ESPObjects[object] then return end
	for _, esp in ipairs(self.ESPObjects[object]) do
		esp.OriginalColor = newColor
		esp.TextLabel.TextColor3 = newColor
		esp.Highlight.FillColor = newColor
		esp.Highlight.OutlineColor = newColor
		esp.Tracer.BackgroundColor3 = newColor
	end
end

function KBOB_ESPLibrary:RemoveESP(object: Instance)
	if not object then return end
	for _, esp in pairs(self.ESPObjects[object] or {}) do
		if esp.BillboardGui then esp.BillboardGui:Destroy() end
		if esp.Connection then esp.Connection:Disconnect() end
		if esp.Highlight then esp.Highlight:Destroy() end
		if esp.Tracer then esp.Tracer:Destroy() end
	end
	self.ESPObjects[object] = nil
	object:SetAttribute("KBOBESP_Added", nil)
end

function KBOB_ESPLibrary:ClearAll()
	for object in pairs(self.ESPObjects) do
		self:RemoveESP(object)
	end
end

function KBOB_ESPLibrary:Unload()
	self:ClearAll()
	self.ESPObjects = {}
	local espFolder = Workspace:FindFirstChild("KBOB_ESP")
	if espFolder then espFolder:Destroy() end
	local hui = GetHUI()
	for _, gui in ipairs(hui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name == "TracerLine" then
			gui:Destroy()
		end
	end
end

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

Globals.KBOB_ESPLibrary = KBOB_ESPLibrary
return KBOB_ESPLibrary
--[[
	************************************

          ESP Library by KBOB
		Author: notzanocoddz (bobhub)

	************************************
]]

local Globals = getgenv()

if Globals.KBOB_ESPLibrary then
	return Globals.KBOB_ESPLibrary
end

local Objects = {
	ScreenGui = Instance.new('ScreenGui'),
	BillboardGui = Instance.new('BillboardGui'),
	Folder = Instance.new('Folder'),
	Frame = Instance.new('Frame'),
	Highlight = Instance.new('Highlight'),
	TextLabel = Instance.new('TextLabel'),
}

local CoreGui = game:GetService('CoreGui');
local Workspace = game:GetService('Workspace');
local RunService = game:GetService('RunService');
local Player = game:GetService('Players').LocalPlayer
local Camera = Workspace.CurrentCamera

local Character = Player.Character or Player.CharacterAdded:Wait()

if not Workspace:FindFirstChild('KBOB_ESP') then
	local folder = Objects.Folder:Clone()
	folder.Name = 'KBOB_ESP'
	folder.Parent = Workspace
end

local function GetHUI()
	return ((identifyexecutor or getexecutorname) ~= nil and CoreGui) or Player:WaitForChild('PlayerGui')
end

local function GetPartPosition(object: Model | BasePart)
	if object:IsA('Model') then
		return object:GetPivot().Position
	elseif object:IsA('BasePart') then
		return object.Position
	end
	return nil
end

local function DistanceOfCharacter(point: Vector3)
	local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
	if HumanoidRootPart then
		return (point - HumanoidRootPart.Position).Magnitude
	elseif Camera then
		return (point - Camera.CFrame.Position).Magnitude
	end
end

local function RainbowColor()
	return Color3.fromHSV(tick() % 5 / 5, 1, 1)
end

local KBOB_ESPLibrary = {
	ESPObjects = {},
	Settings = {
	     Distance = false,
		Tracer = false,
		Rainbow = false,
		TextSize = 18,
		Text = true,
		Highlight = true,
		TracerThickness = 1.5,
	}
}

KBOB_ESPLibrary.__index = KBOB_ESPLibrary

export type ESP_Params = {
	Text: string?,
	Object: Instance?,
	Color: Color3?
}

function KBOB_ESPLibrary:CreateESP(params: ESP_Params)
	if not params then return end
	assert(typeof(params) == 'table', 'Missing table on CreateESP')

	local Text = params.Text or 'Object'
	local Object = params.Object
	local Color = params.Color or Color3.fromRGB(255, 255, 255)

	if not Object or Object:GetAttribute("KBOBESP_Added") then return end
	Object:SetAttribute("KBOBESP_Added", true)

	local classFolder = Workspace.KBOB_ESP:FindFirstChild('Class: ' .. Object.Name)
	if not classFolder then
		classFolder = Objects.Folder:Clone()
		classFolder.Name = 'Class: ' .. Object.Name
		classFolder.Parent = Workspace.KBOB_ESP
	end

	local BillboardFolder = Objects.Folder:Clone()
	BillboardFolder.Name = 'BillboardFolder'
	BillboardFolder.Parent = classFolder

	local TracerLine = Objects.ScreenGui:Clone()
	TracerLine.Parent = GetHUI()
	TracerLine.Name = 'TracerLine'
	TracerLine.IgnoreGuiInset = true
	TracerLine.ResetOnSpawn = false

	local BillboardGui = Objects.BillboardGui:Clone()
	BillboardGui.Parent = BillboardFolder
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
	TextLabel.BackgroundTransparency = 1
	TextLabel.Size = UDim2.new(1, 0, 1, 0)
	TextLabel.FontFace = Font.new('rbxassetid://12187374954', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	TextLabel.RichText = true
	TextLabel.TextSize = self.Settings.TextSize
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextWrapped = true

	local TracerLineFrame = Instance.new("Frame")
	TracerLineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	TracerLineFrame.BackgroundColor3 = Color
	TracerLineFrame.Size = UDim2.new(0, 2, 0, 0)
	TracerLineFrame.Parent = TracerLine

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

	local Connection
	Connection = RunService.RenderStepped:Connect(function()
		if not Object or not Object.Parent then
			Connection:Disconnect()
			return
		end

		local position = GetPartPosition(Object)
		if not position then return end

		local screenPos, onScreen = Camera:WorldToViewportPoint(position)

		BillboardGui.Enabled = onScreen and self.Settings.Text
		TextLabel.Visible = self.Settings.Text

		if self.Settings.Text then
			if self.Settings.Distance then
				TextLabel.Text = string.format("%s [%d Studs]", Text, math.floor(DistanceOfCharacter(position)))
			else
				TextLabel.Text = Text
			end
		end

		if self.Settings.Tracer and onScreen then
			local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			local to = Vector2.new(screenPos.X, screenPos.Y)
			local delta = to - from
			local length = delta.Magnitude
			local pos = (from + to) / 2

			TracerLineFrame.Position = UDim2.new(0, pos.X, 0, pos.Y)
			TracerLineFrame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			TracerLineFrame.Size = UDim2.new(0, self.Settings.TracerThickness, 0, length)
			TracerLineFrame.Visible = true
		else
			TracerLineFrame.Visible = false
		end

		Highlight.Enabled = self.Settings.Highlight and onScreen

		if self.Settings.Rainbow then
			local rainbow = RainbowColor()
			TextLabel.TextColor3 = rainbow
			Highlight.FillColor = rainbow
			Highlight.OutlineColor = rainbow
			TracerLineFrame.BackgroundColor3 = rainbow
		else
			TextLabel.TextColor3 = Color
			Highlight.FillColor = Color
			Highlight.OutlineColor = Color
			TracerLineFrame.BackgroundColor3 = Color
		end
	end)

	self.ESPObjects[Object] = {{
		BillboardGui = BillboardGui,
		Connection = Connection,
		Highlight = Highlight,
		Tracer = TracerLineFrame,
		TextLabel = TextLabel,
		OriginalColor = Color
	}}
end

function KBOB_ESPLibrary:EnabledDistance(enabled: boolean) self.Settings.Distance = enabled end
function KBOB_ESPLibrary:EnabledTracer(enabled: boolean) self.Settings.Tracer = enabled end
function KBOB_ESPLibrary:EnabledRainbow(enabled: boolean) self.Settings.Rainbow = enabled end
function KBOB_ESPLibrary:EnabledText(enabled: boolean) self.Settings.Text = enabled end
function KBOB_ESPLibrary:EnabledHighlight(enabled: boolean) self.Settings.Highlight = enabled end
function KBOB_ESPLibrary:SetTextSize(size: number) self.Settings.TextSize = size end
function KBOB_ESPLibrary:SetTracerThickness(thickness: number) self.Settings.TracerThickness = thickness end

function KBOB_ESPLibrary:SetColor(object: Instance, newColor: Color3)
	if not object or not self.ESPObjects[object] then return end
	for _, esp in ipairs(self.ESPObjects[object]) do
		esp.OriginalColor = newColor
		esp.TextLabel.TextColor3 = newColor
		esp.Highlight.FillColor = newColor
		esp.Highlight.OutlineColor = newColor
		esp.Tracer.BackgroundColor3 = newColor
	end
end

function KBOB_ESPLibrary:RemoveESP(object: Instance)
	if not object then return end
	for _, esp in pairs(self.ESPObjects[object] or {}) do
		if esp.BillboardGui then esp.BillboardGui:Destroy() end
		if esp.Connection then esp.Connection:Disconnect() end
		if esp.Highlight then esp.Highlight:Destroy() end
		if esp.Tracer then esp.Tracer:Destroy() end
	end
	self.ESPObjects[object] = nil
	object:SetAttribute("KBOBESP_Added", nil)
end

function KBOB_ESPLibrary:ClearAll()
	for object in pairs(self.ESPObjects) do
		self:RemoveESP(object)
	end
end

function KBOB_ESPLibrary:Unload()
	self:ClearAll()
	self.ESPObjects = {}
	local espFolder = Workspace:FindFirstChild("KBOB_ESP")
	if espFolder then espFolder:Destroy() end
	local hui = GetHUI()
	for _, gui in ipairs(hui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name == "TracerLine" then
			gui:Destroy()
		end
	end
end

Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

Globals.KBOB_ESPLibrary = KBOB_ESPLibrary
return KBOB_ESPLibrary

