local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")

local NoClipEnabled = false

-- Membuat ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoClipOnlyGUI"
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

-- Membuat Frame Utama No-Clip (Langsung Terlihat)
local NoClipFrame = New("Frame", {
	Parent = ScreenGui,
	Size = UDim2.new(0, 225, 0, 140),
	Position = UDim2.new(0.5, -112, 0.5, -70),
	BackgroundColor3 = Color3.fromRGB(30, 30, 36),
	BorderSizePixel = 0,
	Visible = true
})
Corner(NoClipFrame, 10)

local TitleLabel = New("TextLabel", {
	Parent = NoClipFrame,
	Size = UDim2.new(1, -45, 0, 35),
	Position = UDim2.new(0, 10, 0, 0),
	BackgroundTransparency = 1,
	Text = "NO-CLIP CONTROL",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	TextXAlignment = Enum.TextXAlignment.Left
})

-- Tombol Close (Menutup GUI dan mematikan noclip)
local CloseButton = New("TextButton", {
	Parent = NoClipFrame,
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
	Parent = NoClipFrame,
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
	Parent = NoClipFrame,
	Size = UDim2.new(1, -20, 0, 25),
	Position = UDim2.new(0, 10, 0, 85),
	BackgroundTransparency = 1,
	Text = "Pass through walls",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	Font = Enum.Font.Gotham,
	TextXAlignment = Enum.TextXAlignment.Center
})

-- Logika Dragging UI Utama
local Dragging = false
local DragStart
local StartPosition

NoClipFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = input.Position
		StartPosition = NoClipFrame.Position
	end
end)

NoClipFrame.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local Delta = input.Position - DragStart
		NoClipFrame.Position = UDim2.new(
			StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
		)
	end
end)

-- Variabel & Fungsi No-Clip
local NoClipConnection
local NoClipTransparency = {}

local function SetNoClip(state)
	NoClipEnabled = state

	if NoClipConnection then
		NoClipConnection:Disconnect()
		NoClipConnection = nil
	end

	if not state then
		for part, transparency in pairs(NoClipTransparency) do
			if part and part.Parent then
				part.LocalTransparencyModifier = transparency
			end
		end

		NoClipTransparency = {}

		if Character then
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		return
	end

	NoClipConnection = RunService.Stepped:Connect(function()
		if not Character or not Root then
			return
		end

		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end

		local OverlapParams = OverlapParams.new()
		OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
		OverlapParams.FilterDescendantsInstances = {Character}

		local NearbyParts = workspace:GetPartBoundsInBox(
			Root.CFrame,
			Vector3.new(5, 6, 5),
			OverlapParams
		)

		for _, part in ipairs(NearbyParts) do
			if part:IsA("BasePart") and part.CanCollide and not part:IsDescendantOf(Character) then
				if NoClipTransparency[part] == nil then
					NoClipTransparency[part] = part.LocalTransparencyModifier
				end
				part.LocalTransparencyModifier = 0.65
			end
		end
	end)
end

local function UpdateUI()
	Toggle.Text = NoClipEnabled and "ON" or "OFF"
	Toggle.BackgroundColor3 = NoClipEnabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(50, 50, 58)
end

Toggle.MouseButton1Click:Connect(function()
	SetNoClip(not NoClipEnabled)
	UpdateUI()
end)

CloseButton.MouseButton1Click:Connect(function()
	SetNoClip(false)
	ScreenGui:Destroy()
end)

-- Update Referensi saat Respawn
Player.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Character:WaitForChild("HumanoidRootPart")
	if NoClipEnabled then
		SetNoClip(true)
	end
end)

UpdateUI()