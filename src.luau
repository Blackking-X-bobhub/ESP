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
	if not point then return math.huge end

	local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		return (point - hrp.Position).Magnitude
	elseif Camera then
		return (point - Camera.CFrame.Position).Magnitude
	end
	
	return math.huge
end

local function RainbowColor()
	return Color3.fromHSV(tick() % 5 / 5, 1, 1)
end

local GIVE_TASKS = {}
local KBOB_ESPLibrary = {}
KBOB_ESPLibrary.__index = KBOB_ESPLibrary

function KBOB_ESPLibrary.new()
	local self = setmetatable({}, KBOB_ESPLibrary)
	self.ESPObjects = {}
	self.Settings = {
	    Distance = false,
		Rainbow = false,
		TextSize = 18,
		Text = true,
		Billboard = true,
		Highlight = true,
		Tracer = false,
		TracerThickness = 1.5,
	}
	return self
end

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
	BillboardGui.Enabled = self.Settings.Billboard
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
	TextLabel.Visible = self.Settings.Text
	TextLabel.Text = Text
	TextLabel.TextColor3 = Color
	TextLabel.TextStrokeTransparency = 0
	TextLabel.TextWrapped = true

    local TracerLineFrame = Instance.new("Frame")
    TracerLineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    TracerLineFrame.BackgroundColor3 = Color
    TracerLineFrame.BorderSizePixel = 0
   	TracerLineFrame.Size = UDim2.new(0, 2, 0, 100)
    TracerLineFrame.Visible = self.Settings.Tracer
    TracerLineFrame.ZIndex = 5
    TracerLineFrame.Parent = TracerLine

	local Highlight = Objects.Highlight:Clone()
	Highlight.Parent = Object
	Highlight.Enabled = self.Settings.Highlight
	Highlight.Name = 'Highlight: ' .. Object.Name
	Highlight.Adornee = Object
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.FillTransparency = 0.5
	Highlight.FillColor = Color
	Highlight.OutlineTransparency = 0
	Highlight.OutlineColor = Color

	self.ESPObjects[Object] = {{
		BillboardGui = BillboardGui,
		Connection = nil,
		Highlight = Highlight,
		Tracer = TracerLineFrame,
		TextLabel = TextLabel,
		OriginalColor = Color,
		Enabled = true
	}}

	local Connection
	Connection = RunService.RenderStepped:Connect(function()
		if not Object or not Object.Parent then
			Connection:Disconnect()
			return
		end

        local espData = self.ESPObjects[Object]
        if not espData then return end
        local esp = espData[1]

        if not esp.Enabled then
            esp.TextLabel.Visible = false
            esp.Highlight.Enabled = false
            esp.Tracer.Visible = false
            return
        end

		local position = GetPartPosition(Object)
		if not position then return end

		local screenPos, onScreen = Camera:WorldToViewportPoint(position)

		esp.BillboardGui.Enabled = onScreen and self.Settings.Text
		esp.TextLabel.Visible = self.Settings.Text

		if self.Settings.Text then
			if self.Settings.Distance then
				esp.TextLabel.Text = string.format("%s\n[%d Studs]", Text, math.floor(DistanceOfCharacter(position)))
			else
				esp.TextLabel.Text = Text
			end
		end

        if self.Settings.Tracer and onScreen then
            local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            local to = Vector2.new(screenPos.X, screenPos.Y)
            local dir = to - from
            local length = dir.Magnitude
            local midPos = (from + to) / 2

            esp.Tracer.Position = UDim2.new(0, midPos.X, 0, midPos.Y)
            esp.Tracer.Rotation = math.deg(math.atan2(dir.Y, dir.X))
            esp.Tracer.Size = UDim2.new(0, length, 0, self.Settings.TracerThickness)
            esp.Tracer.Visible = true
        else
          	esp.Tracer.Visible = false
        end

		esp.Highlight.Enabled = self.Settings.Highlight and onScreen

		if self.Settings.Rainbow then
			local rainbow = RainbowColor()
			esp.TextLabel.TextColor3 = rainbow
			esp.Highlight.FillColor = rainbow
			esp.Highlight.OutlineColor = rainbow
			esp.Tracer.BackgroundColor3 = rainbow
		else
            local currentColor = esp.OriginalColor
            esp.TextLabel.TextColor3 = currentColor
            esp.Highlight.FillColor = currentColor
            esp.Highlight.OutlineColor = currentColor
            esp.Tracer.BackgroundColor3 = currentColor
		end
	end)

	self.ESPObjects[Object][1].Connection = Connection
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
	end
end

function KBOB_ESPLibrary:SetEnabled(object: Instance, enabled: boolean)
    if not object or not self.ESPObjects[object] then return end
    for _, esp in ipairs(self.ESPObjects[object]) do
        esp.Enabled = enabled
        if not enabled then
            esp.TextLabel.Visible = false
            esp.Highlight.Enabled = false
            esp.Tracer.Visible = false
        end
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
	for _, gui in pairs(hui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name == "TracerLine" then
			gui:Destroy()
		end
	end

	for _, task in pairs(GIVE_TASKS) do
		task:Disconnect()
	end
end

table.insert(GIVE_TASKS, Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end))

Globals.KBOB_ESPLibrary = KBOB_ESPLibrary
return KBOB_ESPLibrary

