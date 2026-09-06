local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local OriginalWalkSpeed = Humanoid.WalkSpeed
local SpeedValue = 32
local SpeedEnabled = false

-- Membuat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedOnlyGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local function New(class, properties)
	local object = Instance.new(class)
	for property, value in pairs(properties) do
		object[property] = value
	end
	return object
end

local function Corner(object, radius)
	New("UICorner", {
		Parent = object,
		CornerRadius = UDim.new(0, radius)
	})
end

-- Membuat Frame Utama (Langsung Terlihat)
local SpeedFrame = New("Frame", {
	Parent = ScreenGui,
	Size = UDim2.new(0, 225, 0, 175),
	Position = UDim2.new(0.5, -112, 0.5, -87),
	BackgroundColor3 = Color3.fromRGB(30, 30, 36),
	BorderSizePixel = 0,
	Visible = true -- Langsung muncul saat dieksekusi
})
Corner(SpeedFrame, 10)

local TitleLabel = New("TextLabel", {
	Parent = SpeedFrame,
	Size = UDim2.new(1, -45, 0, 35),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = "SPEED CONTROL",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left
})

-- Tombol Close (Menutup GUI)
local CloseButton = New("TextButton", {
	Parent = SpeedFrame,
	Size = UDim2.new(0, 28, 0, 28),
	Position = UDim2.new(1, -34, 0, 4),
	BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.GothamBold
})
Corner(CloseButton, 7)

local Toggle = New("TextButton", {
	Parent = SpeedFrame,
	Size = UDim2.new(1, -20, 0, 35),
	Position = UDim2.new(0, 10, 0, 42),
	BackgroundColor3 = Color3.fromRGB(50, 50, 58),
	Text = "OFF",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 15,
	Font = Enum.Font.GothamBold
})
Corner(Toggle, 7)

local ValueLabel = New("TextLabel", {
	Parent = SpeedFrame,
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 82),
	BackgroundTransparency = 1,
	Text = "Speed: " .. SpeedValue,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham
})

local Minus = New("TextButton", {
	Parent = SpeedFrame,
	Size = UDim2.new(0, 45, 0, 32),
	Position = UDim2.new(0, 28, 0, 120),
	BackgroundColor3 = Color3.fromRGB(50, 50, 58),
	Text = "-",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold
})
Corner(Minus, 7)

local Plus = New("TextButton", {
	Parent = SpeedFrame,
	Size = UDim2.new(0, 45, 0, 32),
	Position = UDim2.new(1, -73, 0, 120),
	BackgroundColor3 = Color3.fromRGB(50, 50, 58),
	Text = "+",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold
})
Corner(Plus, 7)

-- Logika Dragging UI
local Dragging = false
local DragStart
local StartPosition

SpeedFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = input.Position
		StartPosition = SpeedFrame.Position
	end
end)

SpeedFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local Delta = input.Position - DragStart
		SpeedFrame.Position = UDim2.new(
			StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
		)
	end
end)

-- Fungsi Penerapan Kecepatan
local function ApplySpeed()
	if Character and Character:FindFirstChild("Humanoid") then
		Character.Humanoid.WalkSpeed = SpeedEnabled and SpeedValue or OriginalWalkSpeed
	end
end

-- Refresh karakter kalau mati / respawn
Player.CharacterAdded:Connect(function(newChar)
	Character = newChar
	Humanoid = Character:WaitForChild("Humanoid")
	task.wait(0.5)
	ApplySpeed()
end)

local function UpdateUI()
	Toggle.Text = SpeedEnabled and "ON" or "OFF"
	Toggle.BackgroundColor3 = SpeedEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(50, 50, 58)
	ValueLabel.Text = "Speed: " .. SpeedValue
end

Toggle.MouseButton1Click:Connect(function()
	SpeedEnabled = not SpeedEnabled
	ApplySpeed()
	UpdateUI()
end)

CloseButton.MouseButton1Click:Connect(function()
	if SpeedEnabled and Character and Character:FindFirstChild("Humanoid") then
		Character.Humanoid.WalkSpeed = OriginalWalkSpeed
	end
	ScreenGui:Destroy()
end)

local Adjusting = false

local function AdjustValue(amount)
	SpeedValue = math.max(1, SpeedValue + amount)
	ApplySpeed()
	UpdateUI()
end

local function StartAdjusting(amount)
	if Adjusting then return end
	Adjusting = true
	task.spawn(function()
		while Adjusting do
			AdjustValue(amount)
			task.wait(0.08)
		end
	end)
end

Minus.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		AdjustValue(-5)
		StartAdjusting(-5)
	end
end)

Minus.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Adjusting = false
	end
end)

Plus.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		AdjustValue(5)
		StartAdjusting(5)
	end
end)

Plus.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Adjusting = false
	end
end)

-- Menyiapkan UI Awal
UpdateUI()
