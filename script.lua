-- LocalScript inside StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Base Dark Palette
local COLOR_BG = Color3.fromRGB(15, 17, 22)
local COLOR_HEADER = Color3.fromRGB(22, 25, 32)
local COLOR_DARK = Color3.fromRGB(25, 28, 36)
local COLOR_LIGHT_DARK = Color3.fromRGB(34, 38, 48)
local COLOR_TEXT = Color3.fromRGB(235, 235, 235)
local COLOR_MUTED = Color3.fromRGB(110, 115, 130)

--------------------------------------------------------------------------------
-- 1. STATE & SETTINGS DEFAULTS
--------------------------------------------------------------------------------

local settings = {
	Enabled = true,
	DrawFov = true,
	TargetPart = "Head",   -- "Head" or "Torso"
	TeamCheck = true,
	Smoothness = 0.25,     -- 0.05 (soft) to 1.0 (instant snap)
	FovRadius = 140,       -- 40px to 300px
}

local savedConfigs = {
	["Default.cfg"] = {
		Enabled = true,
		DrawFov = true,
		TargetPart = "Head",
		TeamCheck = true,
		Smoothness = 0.25,
		FovRadius = 140,
	}
}
local selectedConfigKey = "Default.cfg"

--------------------------------------------------------------------------------
-- 2. DYNAMIC RGB / CHROMA ENGINE
--------------------------------------------------------------------------------

local currentRgb = Color3.fromRGB(0, 245, 215)
local rgbObjects = {}

local function registerRgb(inst, prop)
	table.insert(rgbObjects, { Instance = inst, Property = prop })
end

RunService.RenderStepped:Connect(function()
	currentRgb = Color3.fromHSV((os.clock() * 0.3) % 1, 0.85, 1)
	for i = #rgbObjects, 1, -1 do
		local item = rgbObjects[i]
		if item.Instance and item.Instance.Parent then
			item.Instance[item.Property] = currentRgb
		else
			table.remove(rgbObjects, i)
		end
	end
end)

--------------------------------------------------------------------------------
-- 3. SCREEN GUI & FLOATING BUBBLE
--------------------------------------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomAimAssistGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- Floating Draggable Bubble (Appears when [X] is clicked)
local flowerBubble = Instance.new("Frame")
flowerBubble.Name = "FlowerBubble"
flowerBubble.Size = UDim2.new(0, 48, 0, 48)
flowerBubble.Position = UDim2.new(0.05, 0, 0.3, 0)
flowerBubble.BackgroundColor3 = COLOR_BG
flowerBubble.BorderSizePixel = 0
flowerBubble.Active = true
flowerBubble.Visible = false
flowerBubble.ZIndex = 20
flowerBubble.Parent = screenGui

local flowerCorner = Instance.new("UICorner")
flowerCorner.CornerRadius = UDim.new(1, 0)
flowerCorner.Parent = flowerBubble

local flowerStroke = Instance.new("UIStroke")
flowerStroke.Thickness = 1.8
flowerStroke.Parent = flowerBubble
registerRgb(flowerStroke, "Color")

local flowerLabel = Instance.new("TextLabel")
flowerLabel.Size = UDim2.new(1, 0, 1, 0)
flowerLabel.BackgroundTransparency = 1
flowerLabel.Text = "🌸"
flowerLabel.TextSize = 22
flowerLabel.ZIndex = 21
flowerLabel.Parent = flowerBubble

-- Transparent Screen-Space FOV Circle Overlay
local fovCircle = Instance.new("Frame")
fovCircle.Name = "FovIndicator"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.fromOffset(settings.FovRadius * 2, settings.FovRadius * 2)
fovCircle.BackgroundTransparency = 1
fovCircle.Active = false
fovCircle.ZIndex = 1
fovCircle.Parent = screenGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovCircle

local fovStroke = Instance.new("UIStroke")
fovStroke.Thickness = 1.2
fovStroke.Transparency = 0.75
fovStroke.Parent = fovCircle
registerRgb(fovStroke, "Color")

--------------------------------------------------------------------------------
-- 4. MAIN WINDOW & HEADER
--------------------------------------------------------------------------------

local mainWindow = Instance.new("Frame")
mainWindow.Name = "MainWindow"
mainWindow.Size = UDim2.new(0, 240, 0, 280)
mainWindow.Position = UDim2.new(0.5, -120, 0.3, 0)
mainWindow.BackgroundColor3 = COLOR_BG
mainWindow.BorderSizePixel = 0
mainWindow.ClipsDescendants = true
mainWindow.Active = true
mainWindow.ZIndex = 10
mainWindow.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainWindow

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 1.6
mainStroke.Parent = mainWindow
registerRgb(mainStroke, "Color")

-- Header Bar
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = COLOR_HEADER
header.BorderSizePixel = 0
header.Active = true
header.ZIndex = 11
header.Parent = mainWindow

local headerTitle = Instance.new("TextLabel")
headerTitle.Size = UDim2.new(1, -75, 1, 0)
headerTitle.Position = UDim2.new(0, 10, 0, 0)
headerTitle.BackgroundTransparency = 1
headerTitle.Text = "AIM ASSIST"
headerTitle.Font = Enum.Font.GothamBold
headerTitle.TextSize = 11
headerTitle.TextXAlignment = Enum.TextXAlignment.Left
headerTitle.ZIndex = 12
headerTitle.Parent = header
registerRgb(headerTitle, "TextColor3")

-- Header Buttons: [-] Minimize and [X] Hide
local minBtn = Instance.new("Frame")
minBtn.Size = UDim2.new(0, 22, 0, 20)
minBtn.Position = UDim2.new(1, -48, 0.5, -10)
minBtn.BackgroundColor3 = COLOR_DARK
minBtn.BorderSizePixel = 0
minBtn.Active = true
minBtn.ZIndex = 12
minBtn.Parent = header
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minBtn
local minText = Instance.new("TextLabel")
minText.Size = UDim2.new(1, 0, 1, 0)
minText.BackgroundTransparency = 1
minText.Text = "-"
minText.Font = Enum.Font.GothamBold
minText.TextSize = 13
minText.TextColor3 = COLOR_TEXT
minText.ZIndex = 13
minText.Parent = minBtn

local closeBtn = Instance.new("Frame")
closeBtn.Size = UDim2.new(0, 22, 0, 20)
closeBtn.Position = UDim2.new(1, -24, 0.5, -10)
closeBtn.BackgroundColor3 = COLOR_DARK
closeBtn.BorderSizePixel = 0
closeBtn.Active = true
closeBtn.ZIndex = 12
closeBtn.Parent = header
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn
local closeText = Instance.new("TextLabel")
closeText.Size = UDim2.new(1, 0, 1, 0)
closeText.BackgroundTransparency = 1
closeText.Text = "X"
closeText.Font = Enum.Font.GothamBold
closeText.TextSize = 11
closeText.TextColor3 = Color3.fromRGB(240, 90, 90)
closeText.ZIndex = 13
closeText.Parent = closeBtn

-- Window Body & Tab Selector
local windowBody = Instance.new("Frame")
windowBody.Name = "Body"
windowBody.Size = UDim2.new(1, 0, 1, -28)
windowBody.Position = UDim2.new(0, 0, 0, 28)
windowBody.BackgroundTransparency = 1
windowBody.ZIndex = 11
windowBody.Parent = mainWindow

local tabNav = Instance.new("Frame")
tabNav.Size = UDim2.new(1, -16, 0, 26)
tabNav.Position = UDim2.new(0, 8, 0, 6)
tabNav.BackgroundColor3 = COLOR_DARK
tabNav.BorderSizePixel = 0
tabNav.ZIndex = 12
tabNav.Parent = windowBody
local tabCorner = Instance.new("UICorner")
tabCorner.CornerRadius = UDim.new(0, 6)
tabCorner.Parent = tabNav

local tabAimBtn = Instance.new("Frame")
tabAimBtn.Size = UDim2.new(0.5, -2, 1, -4)
tabAimBtn.Position = UDim2.new(0, 2, 0, 2)
tabAimBtn.BackgroundColor3 = COLOR_LIGHT_DARK
tabAimBtn.BorderSizePixel = 0
tabAimBtn.Active = true
tabAimBtn.ZIndex = 13
tabAimBtn.Parent = tabNav
local tabAimCorner = Instance.new("UICorner")
tabAimCorner.CornerRadius = UDim.new(0, 4)
tabAimCorner.Parent = tabAimBtn
local tabAimLabel = Instance.new("TextLabel")
tabAimLabel.Size = UDim2.new(1, 0, 1, 0)
tabAimLabel.BackgroundTransparency = 1
tabAimLabel.Text = "🎯 AIM"
tabAimLabel.Font = Enum.Font.GothamBold
tabAimLabel.TextSize = 10
tabAimLabel.TextColor3 = COLOR_TEXT
tabAimLabel.ZIndex = 14
tabAimLabel.Parent = tabAimBtn

local tabCfgBtn = Instance.new("Frame")
tabCfgBtn.Size = UDim2.new(0.5, -2, 1, -4)
tabCfgBtn.Position = UDim2.new(0.5, 0, 0, 2)
tabCfgBtn.BackgroundColor3 = COLOR_DARK
tabCfgBtn.BorderSizePixel = 0
tabCfgBtn.Active = true
tabCfgBtn.ZIndex = 13
tabCfgBtn.Parent = tabNav
local tabCfgCorner = Instance.new("UICorner")
tabCfgCorner.CornerRadius = UDim.new(0, 4)
tabCfgCorner.Parent = tabCfgBtn
local tabCfgLabel = Instance.new("TextLabel")
tabCfgLabel.Size = UDim2.new(1, 0, 1, 0)
tabCfgLabel.BackgroundTransparency = 1
tabCfgLabel.Text = "📁 CONFIGS"
tabCfgLabel.Font = Enum.Font.GothamBold
tabCfgLabel.TextSize = 10
tabCfgLabel.TextColor3 = COLOR_MUTED
tabCfgLabel.ZIndex = 14
tabCfgLabel.Parent = tabCfgBtn

--------------------------------------------------------------------------------
-- 5. DRAG LOGIC & INTERFACE TOGGLES
--------------------------------------------------------------------------------

local function makeDraggable(triggerFrame, targetFrame)
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	triggerFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(header, mainWindow)
makeDraggable(flowerBubble, flowerBubble)

local isMinimized = false
minBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isMinimized = not isMinimized
		if isMinimized then
			windowBody.Visible = false
			mainWindow.Size = UDim2.new(0, 240, 0, 28)
			minText.Text = "+"
		else
			mainWindow.Size = UDim2.new(0, 240, 0, 280)
			windowBody.Visible = true
			minText.Text = "-"
		end
	end
end)

closeBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		mainWindow.Visible = false
		flowerBubble.Visible = true
	end
end)

flowerBubble.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		flowerBubble.Visible = false
		mainWindow.Visible = true
	end
end)

--------------------------------------------------------------------------------
-- 6. TAB 1: AIM SETTINGS PAGE
--------------------------------------------------------------------------------

local aimPage = Instance.new("Frame")
aimPage.Name = "AimPage"
aimPage.Size = UDim2.new(1, -16, 1, -42)
aimPage.Position = UDim2.new(0, 8, 0, 38)
aimPage.BackgroundTransparency = 1
aimPage.ZIndex = 12
aimPage.Parent = windowBody

local function createCheckbox(parent, posY, text, defaultVal, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 22)
	row.Position = UDim2.new(0, 0, 0, posY)
	row.BackgroundTransparency = 1
	row.Active = true
	row.ZIndex = 13
	row.Parent = parent

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 18, 0, 18)
	box.Position = UDim2.new(0, 0, 0.5, -9)
	box.BackgroundColor3 = COLOR_DARK
	box.BorderSizePixel = 0
	box.ZIndex = 14
	box.Parent = row
	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 4)
	bCorner.Parent = box
	local bStroke = Instance.new("UIStroke")
	bStroke.Color = COLOR_LIGHT_DARK
	bStroke.Thickness = 1
	bStroke.Parent = box

	local checkIcon = Instance.new("TextLabel")
	checkIcon.Size = UDim2.new(1, 0, 1, 0)
	checkIcon.BackgroundTransparency = 1
	checkIcon.Text = defaultVal and "✓" or ""
	checkIcon.Font = Enum.Font.GothamBold
	checkIcon.TextSize = 13
	checkIcon.ZIndex = 15
	checkIcon.Parent = box
	registerRgb(checkIcon, "TextColor3")

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -26, 1, 0)
	lbl.Position = UDim2.new(0, 26, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextColor3 = COLOR_TEXT
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 14
	lbl.Parent = row

	local currentVal = defaultVal
	row.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			currentVal = not currentVal
			checkIcon.Text = currentVal and "✓" or ""
			callback(currentVal)
		end
	end)

	return {
		Set = function(v)
			currentVal = v
			checkIcon.Text = currentVal and "✓" or ""
		end
	}
end

local masterCb = createCheckbox(aimPage, 0, "MASTER ASSIST ENABLED", settings.Enabled, function(v)
	settings.Enabled = v
end)

local fovCb = createCheckbox(aimPage, 26, "DRAW FOV CIRCLE", settings.DrawFov, function(v)
	settings.DrawFov = v
	fovCircle.Visible = v
end)

local teamCb = createCheckbox(aimPage, 52, "TEAM CHECK (IGNORE ALLIES)", settings.TeamCheck, function(v)
	settings.TeamCheck = v
end)

-- Target Part Selector: [ HEAD ] vs [ TORSO ]
local partRow = Instance.new("Frame")
partRow.Size = UDim2.new(1, 0, 0, 22)
partRow.Position = UDim2.new(0, 0, 0, 80)
partRow.BackgroundTransparency = 1
partRow.ZIndex = 13
partRow.Parent = aimPage

local headBtn = Instance.new("Frame")
headBtn.Size = UDim2.new(0.5, -4, 1, 0)
headBtn.BackgroundColor3 = settings.TargetPart == "Head" and COLOR_LIGHT_DARK or COLOR_DARK
headBtn.BorderSizePixel = 0
headBtn.Active = true
headBtn.ZIndex = 14
headBtn.Parent = partRow
local hCorner = Instance.new("UICorner")
hCorner.CornerRadius = UDim.new(0, 4)
hCorner.Parent = headBtn
local hLabel = Instance.new("TextLabel")
hLabel.Size = UDim2.new(1, 0, 1, 0)
hLabel.BackgroundTransparency = 1
hLabel.Text = "HEAD"
hLabel.Font = Enum.Font.GothamBold
hLabel.TextSize = 10
hLabel.TextColor3 = settings.TargetPart == "Head" and COLOR_TEXT or COLOR_MUTED
hLabel.ZIndex = 15
hLabel.Parent = headBtn

local torsoBtn = Instance.new("Frame")
torsoBtn.Size = UDim2.new(0.5, -4, 1, 0)
torsoBtn.Position = UDim2.new(0.5, 4, 0, 0)
torsoBtn.BackgroundColor3 = settings.TargetPart == "Torso" and COLOR_LIGHT_DARK or COLOR_DARK
torsoBtn.BorderSizePixel = 0
torsoBtn.Active = true
torsoBtn.ZIndex = 14
torsoBtn.Parent = partRow
local tCorner = Instance.new("UICorner")
tCorner.CornerRadius = UDim.new(0, 4)
tCorner.Parent = torsoBtn
local tLabel = Instance.new("TextLabel")
tLabel.Size = UDim2.new(1, 0, 1, 0)
tLabel.BackgroundTransparency = 1
tLabel.Text = "TORSO"
tLabel.Font = Enum.Font.GothamBold
tLabel.TextSize = 10
tLabel.TextColor3 = settings.TargetPart == "Torso" and COLOR_TEXT or COLOR_MUTED
tLabel.ZIndex = 15
tLabel.Parent = torsoBtn

local function updatePartUI(partName)
	settings.TargetPart = partName
	if partName == "Head" then
		headBtn.BackgroundColor3 = COLOR_LIGHT_DARK
		hLabel.TextColor3 = COLOR_TEXT
		torsoBtn.BackgroundColor3 = COLOR_DARK
		tLabel.TextColor3 = COLOR_MUTED
	else
		torsoBtn.BackgroundColor3 = COLOR_LIGHT_DARK
		tLabel.TextColor3 = COLOR_TEXT
		headBtn.BackgroundColor3 = COLOR_DARK
		hLabel.TextColor3 = COLOR_MUTED
	end
end

headBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		updatePartUI("Head")
	end
end)
torsoBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		updatePartUI("Torso")
	end
end)

-- Volume-Style Sliders
local function createSlider(parent, posY, title, minVal, maxVal, currentVal, isPercent, callback)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 14)
	label.Position = UDim2.new(0, 0, 0, posY)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 9
	label.TextColor3 = COLOR_TEXT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 13
	label.Parent = parent

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 12)
	track.Position = UDim2.new(0, 0, 0, posY + 16)
	track.BackgroundColor3 = COLOR_DARK
	track.BorderSizePixel = 0
	track.Active = true
	track.ZIndex = 13
	track.Parent = parent
	local trCorner = Instance.new("UICorner")
	trCorner.CornerRadius = UDim.new(0, 4)
	trCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BorderSizePixel = 0
	fill.ZIndex = 14
	fill.Parent = track
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill
	registerRgb(fill, "BackgroundColor3")

	local function updateDisplay(val)
		if isPercent then
			label.Text = string.format("%s: %d%%", title, math.floor(val * 100))
		else
			label.Text = string.format("%s: %d px", title, math.floor(val))
		end
	end
	updateDisplay(currentVal)

	local dragging = false
	local function setValFromX(xPos)
		local ratio = math.clamp((xPos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		local val = minVal + (maxVal - minVal) * ratio
		updateDisplay(val)
		callback(val)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setValFromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			setValFromX(input.Position.X)
		end
	end)

	return {
		Set = function(newVal)
			local ratio = math.clamp((newVal - minVal) / (maxVal - minVal), 0, 1)
			fill.Size = UDim2.new(ratio, 0, 1, 0)
			updateDisplay(newVal)
		end
	}
end

local smoothSlider = createSlider(aimPage, 110, "SMOOTHNESS", 0.05, 1.0, settings.Smoothness, true, function(val)
	settings.Smoothness = val
end)

local fovSlider = createSlider(aimPage, 150, "FOV RANGE", 40, 300, settings.FovRadius, false, function(val)
	settings.FovRadius = val
	fovCircle.Size = UDim2.fromOffset(val * 2, val * 2)
end)

--------------------------------------------------------------------------------
-- 7. TAB 2: CONFIG MANAGER PAGE
--------------------------------------------------------------------------------

local cfgPage = Instance.new("Frame")
cfgPage.Name = "CfgPage"
cfgPage.Size = UDim2.new(1, -16, 1, -42)
cfgPage.Position = UDim2.new(0, 8, 0, 38)
cfgPage.BackgroundTransparency = 1
cfgPage.Visible = false
cfgPage.ZIndex = 12
cfgPage.Parent = windowBody

tabAimBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		aimPage.Visible = true
		cfgPage.Visible = false
		tabAimBtn.BackgroundColor3 = COLOR_LIGHT_DARK
		tabAimLabel.TextColor3 = COLOR_TEXT
		tabCfgBtn.BackgroundColor3 = COLOR_DARK
		tabCfgLabel.TextColor3 = COLOR_MUTED
	end
end)

tabCfgBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		aimPage.Visible = false
		cfgPage.Visible = true
		tabCfgBtn.BackgroundColor3 = COLOR_LIGHT_DARK
		tabCfgLabel.TextColor3 = COLOR_TEXT
		tabAimBtn.BackgroundColor3 = COLOR_DARK
		tabAimLabel.TextColor3 = COLOR_MUTED
	end
end)

local cfgInputRow = Instance.new("Frame")
cfgInputRow.Size = UDim2.new(1, 0, 0, 26)
cfgInputRow.Position = UDim2.new(0, 0, 0, 0)
cfgInputRow.BackgroundColor3 = COLOR_DARK
cfgInputRow.BorderSizePixel = 0
cfgInputRow.ZIndex = 13
cfgInputRow.Parent = cfgPage
local cInCorner = Instance.new("UICorner")
cInCorner.CornerRadius = UDim.new(0, 6)
cInCorner.Parent = cfgInputRow

local cfgTextBox = Instance.new("TextBox")
cfgTextBox.Size = UDim2.new(1, -30, 1, 0)
cfgTextBox.Position = UDim2.new(0, 8, 0, 0)
cfgTextBox.BackgroundTransparency = 1
cfgTextBox.Text = selectedConfigKey
cfgTextBox.Font = Enum.Font.GothamBold
cfgTextBox.TextSize = 10
cfgTextBox.TextColor3 = COLOR_TEXT
cfgTextBox.TextXAlignment = Enum.TextXAlignment.Left
cfgTextBox.ClearTextOnFocus = false
cfgTextBox.ZIndex = 14
cfgTextBox.Parent = cfgInputRow

local dropdownArrow = Instance.new("Frame")
dropdownArrow.Size = UDim2.new(0, 24, 1, 0)
dropdownArrow.Position = UDim2.new(1, -24, 0, 0)
dropdownArrow.BackgroundTransparency = 1
dropdownArrow.Active = true
dropdownArrow.ZIndex = 14
dropdownArrow.Parent = cfgInputRow
local arrowLabel = Instance.new("TextLabel")
arrowLabel.Size = UDim2.new(1, 0, 1, 0)
arrowLabel.BackgroundTransparency = 1
arrowLabel.Text = "▼"
arrowLabel.Font = Enum.Font.GothamBold
arrowLabel.TextSize = 9
arrowLabel.TextColor3 = COLOR_TEXT
arrowLabel.ZIndex = 15
arrowLabel.Parent = dropdownArrow

local dropdownScroll = Instance.new("ScrollingFrame")
dropdownScroll.Size = UDim2.new(1, 0, 0, 65)
dropdownScroll.Position = UDim2.new(0, 0, 0, 30)
dropdownScroll.BackgroundColor3 = COLOR_DARK
dropdownScroll.BorderSizePixel = 0
dropdownScroll.Visible = false
dropdownScroll.ZIndex = 25
dropdownScroll.ScrollBarThickness = 3
dropdownScroll.Parent = cfgPage
local dCorner = Instance.new("UICorner")
dCorner.CornerRadius = UDim.new(0, 4)
dCorner.Parent = dropdownScroll
local dLayout = Instance.new("UIListLayout")
dLayout.Padding = UDim.new(0, 2)
dLayout.Parent = dropdownScroll

local function refreshDropdown()
	for _, child in ipairs(dropdownScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for cfgName, _ in pairs(savedConfigs) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, -6, 0, 20)
		item.BackgroundColor3 = COLOR_LIGHT_DARK
		item.BorderSizePixel = 0
		item.Active = true
		item.ZIndex = 26
		item.Parent = dropdownScroll
		local ic = Instance.new("UICorner")
		ic.CornerRadius = UDim.new(0, 4)
		ic.Parent = item

		local txt = Instance.new("TextLabel")
		txt.Size = UDim2.new(1, -8, 1, 0)
		txt.Position = UDim2.new(0, 6, 0, 0)
		txt.BackgroundTransparency = 1
		txt.Text = cfgName
		txt.Font = Enum.Font.GothamBold
		txt.TextSize = 9
		txt.TextColor3 = COLOR_TEXT
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.ZIndex = 27
		txt.Parent = item

		item.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				selectedConfigKey = cfgName
				cfgTextBox.Text = cfgName
				dropdownScroll.Visible = false
			end
		end)
	end
	dropdownScroll.CanvasSize = UDim2.new(0, 0, 0, dLayout.AbsoluteContentSize.Y + 4)
end

dropdownArrow.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dropdownScroll.Visible = not dropdownScroll.Visible
		if dropdownScroll.Visible then refreshDropdown() end
	end
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 14)
statusLabel.Position = UDim2.new(0, 0, 1, -16)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "STATUS: READY"
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 8
statusLabel.TextColor3 = COLOR_MUTED
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.ZIndex = 13
statusLabel.Parent = cfgPage

local function createButton(parent, pos, size, text, color)
	local btn = Instance.new("Frame")
	btn.Size = size
	btn.Position = pos
	btn.BackgroundColor3 = color or COLOR_DARK
	btn.BorderSizePixel = 0
	btn.Active = true
	btn.ZIndex = 14
	btn.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 4)
	bc.Parent = btn
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 9
	lbl.TextColor3 = COLOR_TEXT
	lbl.ZIndex = 15
	lbl.Parent = btn
	return btn
end

local createBtn = createButton(cfgPage, UDim2.new(0, 0, 0, 100), UDim2.new(1, 0, 0, 24), "+ CREATE CONFIG", COLOR_LIGHT_DARK)
createBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local name = cfgTextBox.Text
		if name and #name > 0 then
			savedConfigs[name] = {
				Enabled = settings.Enabled,
				DrawFov = settings.DrawFov,
				TargetPart = settings.TargetPart,
				TeamCheck = settings.TeamCheck,
				Smoothness = settings.Smoothness,
				FovRadius = settings.FovRadius,
			}
			selectedConfigKey = name
			statusLabel.Text = string.format("STATUS: CREATED '%s'", name)
			statusLabel.TextColor3 = Color3.fromRGB(80, 255, 160)
			refreshDropdown()
		end
	end
end)

local loadBtn = createButton(cfgPage, UDim2.new(0, 0, 0, 130), UDim2.new(0.31, 0, 0, 24), "LOAD")
loadBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local cfg = savedConfigs[cfgTextBox.Text]
		if cfg then
			settings.Enabled = cfg.Enabled
			settings.DrawFov = cfg.DrawFov
			settings.TargetPart = cfg.TargetPart
			settings.TeamCheck = cfg.TeamCheck
			settings.Smoothness = cfg.Smoothness
			settings.FovRadius = cfg.FovRadius

			masterCb.Set(cfg.Enabled)
			fovCb.Set(cfg.DrawFov)
			teamCb.Set(cfg.TeamCheck)
			updatePartUI(cfg.TargetPart)
			smoothSlider.Set(cfg.Smoothness)
			fovSlider.Set(cfg.FovRadius)
			fovCircle.Visible = cfg.DrawFov
			fovCircle.Size = UDim2.fromOffset(cfg.FovRadius * 2, cfg.FovRadius * 2)

			statusLabel.Text = string.format("STATUS: LOADED '%s'", cfgTextBox.Text)
			statusLabel.TextColor3 = Color3.fromRGB(80, 255, 160)
		else
			statusLabel.Text = "STATUS: CONFIG NOT FOUND"
			statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		end
	end
end)

local rewriteBtn = createButton(cfgPage, UDim2.new(0.345, 0, 0, 130), UDim2.new(0.31, 0, 0, 24), "REWRITE")
rewriteBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local name = cfgTextBox.Text
		if savedConfigs[name] then
			savedConfigs[name] = {
				Enabled = settings.Enabled,
				DrawFov = settings.DrawFov,
				TargetPart = settings.TargetPart,
				TeamCheck = settings.TeamCheck,
				Smoothness = settings.Smoothness,
				FovRadius = settings.FovRadius,
			}
			statusLabel.Text = string.format("STATUS: REWROTE '%s'", name)
			statusLabel.TextColor3 = Color3.fromRGB(80, 255, 160)
		else
			statusLabel.Text = "STATUS: SAVE FIRST TO REWRITE"
			statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
		end
	end
end)

local deleteBtn = createButton(cfgPage, UDim2.new(0.69, 0, 0, 130), UDim2.new(0.31, 0, 0, 24), "DELETE", Color3.fromRGB(50, 24, 28))
deleteBtn.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		local name = cfgTextBox.Text
		if savedConfigs[name] then
			savedConfigs[name] = nil
			cfgTextBox.Text = ""
			statusLabel.Text = string.format("STATUS: DELETED '%s'", name)
			statusLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
			refreshDropdown()
		end
	end
end)

--------------------------------------------------------------------------------
-- 8. TARGET SCANNING & CAMERA ENGINE
--------------------------------------------------------------------------------

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Validates whether another player is considered an enemy
local function isEnemy(otherPlayer)
	if not settings.TeamCheck then
		return true
	end

	-- Neutral players or FFA modes are targetable
	if player.Neutral or otherPlayer.Neutral then
		return true
	end

	-- Check explicit Team objects
	if player.Team ~= nil and otherPlayer.Team ~= nil then
		return player.Team ~= otherPlayer.Team
	end

	-- Fallback to TeamColor BrickColor equality
	if player.TeamColor ~= nil and otherPlayer.TeamColor ~= nil then
		return player.TeamColor ~= otherPlayer.TeamColor
	end

	-- Safe fallback when teams cannot be resolved
	return false
end

-- Finds closest enemy inside FOV who passes line of sight
local function getBestTarget()
	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local closestTargetPart = nil
	local shortestScreenDist = math.huge

	local char = player.Character
	if not char then return nil end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			-- Fixed Team Check Verification
			if isEnemy(otherPlayer) then
				local oChar = otherPlayer.Character
				local oHum = oChar:FindFirstChildOfClass("Humanoid")

				if oHum and oHum.Health > 0 then
					local targetPart = nil
					if settings.TargetPart == "Head" then
						targetPart = oChar:FindFirstChild("Head")
					else
						targetPart = oChar:FindFirstChild("UpperTorso") or oChar:FindFirstChild("Torso") or oChar:FindFirstChild("HumanoidRootPart")
					end

					if targetPart then
						local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
						if onScreen and screenPos.Z > 0 then
							local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
							if distFromCenter <= settings.FovRadius and distFromCenter < shortestScreenDist then
								-- Line of Sight Wall Check
								rayParams.FilterDescendantsInstances = { char, camera }
								local hit = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, rayParams)

								if hit and hit.Instance:IsDescendantOf(oChar) then
									shortestScreenDist = distFromCenter
									closestTargetPart = targetPart
								end
							end
						end
					end
				end
			end
		end
	end

	return closestTargetPart
end

-- Camera Interpolation Loop
RunService.RenderStepped:Connect(function()
	if not settings.Enabled then return end

	local targetPart = getBestTarget()
	if targetPart then
		local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
		camera.CFrame = camera.CFrame:Lerp(targetCFrame, settings.Smoothness)
	end
end)
