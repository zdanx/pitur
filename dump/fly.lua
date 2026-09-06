local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local FlightSpeed = 60
local FlightEnabled = false

-- Ambil ControlModule bawaan Roblox untuk analog standar
local PlayerModule = require(Player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ControlModule = PlayerModule:GetControls()

-- Membuat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlightOnlyGUI"
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

-- Membuat Frame Utama Flight (Pengaturan Speed & Toggle)
local FlightFrame = New("Frame", {
	Parent = ScreenGui,
	Size = UDim2.new(0, 225, 0, 175),
	Position = UDim2.new(0.5, -112, 0.3, -87),
	BackgroundColor3 = Color3.fromRGB(30, 30, 36),
	BorderSizePixel = 0,
	Visible = true
})
Corner(FlightFrame, 10)

local TitleLabel = New("TextLabel", {
	Parent = FlightFrame,
	Size = UDim2.new(1, -45, 0, 35),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = "FLIGHT CONTROL",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left
})

-- Tombol Close (Menutup GUI dan mematikan flight)
local CloseButton = New("TextButton", {
	Parent = FlightFrame,
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
	Parent = FlightFrame,
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
	Parent = FlightFrame,
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 82),
	BackgroundTransparency = 1,
	Text = "Flight Speed: " .. FlightSpeed,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham
})

local Minus = New("TextButton", {
	Parent = FlightFrame,
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
	Parent = FlightFrame,
	Size = UDim2.new(0, 45, 0, 32),
	Position = UDim2.new(1, -73, 0, 120),
	BackgroundColor3 = Color3.fromRGB(50, 50, 58),
	Text = "+",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 19,
	Font = Enum.Font.GothamBold
})
Corner(Plus, 7)

-- Logika Dragging UI Utama
local Dragging = false
local DragStart
local StartPosition

FlightFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = input.Position
		StartPosition = FlightFrame.Position
	end
end)

FlightFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local Delta = input.Position - DragStart
		FlightFrame.Position = UDim2.new(
			StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
		)
	end
end)

-- Variabel & Fungsi Flight
local FlightConnection
local FlightVelocity
local FlightControls

-- Status Tombol Naik/Turun khusus HP
local upPressed = false
local downPressed = false

local function StopFlight()
	if FlightConnection then
		FlightConnection:Disconnect()
		FlightConnection = nil
	end

	if FlightVelocity then
		FlightVelocity:Destroy()
		FlightVelocity = nil
	end

	if Humanoid and Humanoid.Parent then
		Humanoid.PlatformStand = false
		Humanoid.AutoRotate = true
	end

	upPressed = false
	downPressed = false

	if FlightControls then
		FlightControls:Destroy()
		FlightControls = nil
	end
end

local function CreateFlightControls()
	-- Wadah Tombol Up & Down di Kanan Bawah
	FlightControls = New("Frame", {
		Parent = ScreenGui,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Active = false
	})

	local function MakeVerticalButton(text, position, callback)
		local btn = New("TextButton", {
			Parent = FlightControls,
			Size = UDim2.new(0, 65, 0, 55),
			Position = position,
			BackgroundColor3 = Color3.fromRGB(40, 40, 48),
			BackgroundTransparency = 0.4,
			Text = text,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 15,
			Font = Enum.Font.GothamBold
		})
		Corner(btn, 12)

		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				callback(true)
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				callback(false)
			end
		end)
	end

	-- Tombol UP
	MakeVerticalButton("UP", UDim2.new(1, -85, 1, -165), function(state)
		upPressed = state
	end)

	-- Tombol DOWN
	MakeVerticalButton("DOWN", UDim2.new(1, -85, 1, -95), function(state)
		downPressed = state
	end)
end

local function StartFlight()
	StopFlight()

	if Humanoid then
		Humanoid.PlatformStand = true
		Humanoid.AutoRotate = false
	end

	FlightVelocity = Instance.new("BodyVelocity")
	FlightVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	FlightVelocity.Velocity = Vector3.zero
	FlightVelocity.Parent = Root

	CreateFlightControls()

	FlightConnection = RunService.RenderStepped:Connect(function()
		if not FlightEnabled or not Root or not Root.Parent then
			StopFlight()
			return
		end

		local Camera = workspace.CurrentCamera
		local direction = Vector3.zero

		-- Kontrol Vertikal (Tombol Up/Down di Layar)
		if upPressed then
			direction += Vector3.new(0, 1, 0)
		end
		if downPressed then
			direction -= Vector3.new(0, 1, 0)
		end

		-- Mengambil input dari Analog Bawaan Roblox / Keyboard (WASD)
		local moveVector = ControlModule:GetMoveVector()
		if moveVector.Magnitude > 0 then
			direction += Camera.CFrame.RightVector * moveVector.X
			direction += Camera.CFrame.LookVector * (-moveVector.Z)
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit * FlightSpeed
		end

		FlightVelocity.Velocity = direction
	end)
end

local function UpdateUI()
	Toggle.Text = FlightEnabled and "ON" or "OFF"
	Toggle.BackgroundColor3 = FlightEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(50, 50, 58)
	ValueLabel.Text = "Flight Speed: " .. FlightSpeed
end

Toggle.MouseButton1Click:Connect(function()
	FlightEnabled = not FlightEnabled
	if FlightEnabled then
		StartFlight()
	else
		StopFlight()
	end
	UpdateUI()
end)

CloseButton.MouseButton1Click:Connect(function()
	FlightEnabled = false
	StopFlight()
	ScreenGui:Destroy()
end)

-- Pengaturan Kecepatan Flight (+ / -)
local Adjusting = false

local function AdjustValue(amount)
	FlightSpeed = math.max(5, FlightSpeed + amount)
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

-- Update Referensi saat Respawn
Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Character:WaitForChild("HumanoidRootPart")
	if FlightEnabled then
		StartFlight()
	end
end)

UpdateUI()
