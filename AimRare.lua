--[[
    AimRare Hub - Advanced Educational Script
    Version: 2.8 (Full ESP Restoration)
    Author: Ben
    
    Changelog v2.8:
    - FIX: Alle ESP Funktionen (Skeleton, Health, Name) wiederhergestellt.
    - FEATURE: Keybind System (v2.7) beibehalten.
    - FEATURE: Toggle/Hold Mode (v2.7) beibehalten.
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Check ob Drawing API existiert
if not Drawing then
    warn("AimRare Hub: Drawing API nicht gefunden! Bitte nutze einen besseren Executor.")
    return
end

-- Safe Color Helper
local function SafeColor(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end

-- Einstellungen & Status
local Settings = {
    -- Visuals
    BoxESP = false,
    SkeletonESP = false,
    NameESP = false,
    HealthESP = false,
    TeamCheck = false,
    ESPColor = SafeColor(255, 65, 65),
    
    -- Aimbot Main
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.2,
    
    -- Aimbot Input Settings
    AimKey = Enum.UserInputType.MouseButton2, -- Standard: Rechtsklick
    AimKeyName = "RMB", -- Für die Anzeige
    AimMode = "Hold", -- "Hold" oder "Toggle"
    IsAimingToggled = false, -- Interner Status für Toggle Mode
    
    -- Aimbot Checks
    WallCheck = false,
    AliveCheck = true,
}

-- Cache & Globals
local ESP_Cache = {}
local FOV_Circle = nil
local changingKey = false -- Status ob wir gerade eine Taste binden

-- Initialisiere FOV Circle
pcall(function()
    FOV_Circle = Drawing.new("Circle")
    FOV_Circle.Color = Color3.new(1, 1, 1)
    FOV_Circle.Thickness = 1
    FOV_Circle.NumSides = 60
    FOV_Circle.Radius = Settings.AimbotFOV
    FOV_Circle.Visible = false
    FOV_Circle.Transparency = 0.7
    FOV_Circle.Filled = false
    FOV_Circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-------------------------------------------------------------------------
-- MODERN UI SYSTEM
-------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimRareHubUI_v3"

if CoreGui:FindFirstChild("AimRareHubUI_v3") then CoreGui.AimRareHubUI_v3:Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("AimRareHubUI_v3") then LocalPlayer.PlayerGui.AimRareHubUI_v3:Destroy() end

if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Farben
local Theme = {
    Background = SafeColor(25, 25, 30),
    Sidebar = SafeColor(35, 35, 40),
    Element = SafeColor(45, 45, 50),
    Text = SafeColor(240, 240, 240),
    Accent = SafeColor(255, 65, 65),
    Success = SafeColor(100, 255, 120)
}

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 380)
MainFrame.Position = UDim2.new(0.5, -250, 0.4, -190)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Shadow (Fake)
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ZIndex = 0
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceScale = 1
Shadow.Parent = MainFrame

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
local SideCorner = Instance.new("UICorner", Sidebar); SideCorner.CornerRadius = UDim.new(0, 10)
local SideFix = Instance.new("Frame", Sidebar); SideFix.Size = UDim2.new(0, 10, 1, 0); SideFix.Position = UDim2.new(1, -10, 0, 0); SideFix.BackgroundColor3 = Theme.Sidebar; SideFix.BorderSizePixel = 0

-- Titel
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "AIM<font color='#ff4141'>RARE</font>"
Title.RichText = true
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.Parent = Sidebar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -140, 1, -20)
ContentArea.Position = UDim2.new(0, 140, 0, 10)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

-- Dragging
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = input.Position; startPos = MainFrame.Position end
end)
MainFrame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

-- Tab System
local TabsFrames = {}
TabsFrames.Visuals = Instance.new("ScrollingFrame", ContentArea); TabsFrames.Visuals.Size = UDim2.new(1, 0, 1, 0); TabsFrames.Visuals.BackgroundTransparency = 1; TabsFrames.Visuals.ScrollBarThickness = 2; TabsFrames.Visuals.Visible = true
TabsFrames.Aimbot = Instance.new("ScrollingFrame", ContentArea); TabsFrames.Aimbot.Size = UDim2.new(1, 0, 1, 0); TabsFrames.Aimbot.BackgroundTransparency = 1; TabsFrames.Aimbot.ScrollBarThickness = 2; TabsFrames.Aimbot.Visible = false
TabsFrames.Credits = Instance.new("Frame", ContentArea); TabsFrames.Credits.Size = UDim2.new(1, 0, 1, 0); TabsFrames.Credits.BackgroundTransparency = 1; TabsFrames.Credits.Visible = false

local activeTabBtn = nil
local function SwitchTab(tabName, btn)
    for name, frame in pairs(TabsFrames) do frame.Visible = (name == tabName) end
    if activeTabBtn then TweenService:Create(activeTabBtn, TweenInfo.new(0.3), {TextColor3 = SafeColor(150,150,150)}):Play() end
    activeTabBtn = btn
    TweenService:Create(activeTabBtn, TweenInfo.new(0.3), {TextColor3 = Theme.Accent}):Play()
end

local TabButtonContainer = Instance.new("Frame", Sidebar)
TabButtonContainer.Size = UDim2.new(1, 0, 1, -60)
TabButtonContainer.Position = UDim2.new(0, 0, 0, 60)
TabButtonContainer.BackgroundTransparency = 1
local TabListLayout = Instance.new("UIListLayout", TabButtonContainer)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabListLayout.Padding = UDim.new(0, 5)

local function CreateTabButton(text, targetTab, isDefault)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.BackgroundTransparency = 1
    btn.Text = text
    btn.TextColor3 = isDefault and Theme.Accent or SafeColor(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = TabButtonContainer
    if isDefault then activeTabBtn = btn end
    btn.MouseButton1Click:Connect(function() SwitchTab(targetTab, btn) end)
end

CreateTabButton("Visuals", "Visuals", true)
CreateTabButton("Aimbot", "Aimbot", false)
CreateTabButton("Credits", "Credits", false)

local listVis = Instance.new("UIListLayout", TabsFrames.Visuals); listVis.Padding = UDim.new(0, 10)
local listAim = Instance.new("UIListLayout", TabsFrames.Aimbot); listAim.Padding = UDim.new(0, 10)

-- CREDITS
local CreditTitle = Instance.new("TextLabel", TabsFrames.Credits)
CreditTitle.Size = UDim2.new(1, 0, 0, 40); CreditTitle.Position = UDim2.new(0, 0, 0.3, 0); CreditTitle.BackgroundTransparency = 1
CreditTitle.Text = "This Script Made By\nBen And His Friend"; CreditTitle.TextColor3 = Theme.Text; CreditTitle.Font = Enum.Font.GothamBlack; CreditTitle.TextSize = 24
local CreditSub = Instance.new("TextLabel", TabsFrames.Credits)
CreditSub.Size = UDim2.new(1, 0, 0, 30); CreditSub.Position = UDim2.new(0, 0, 0.5, 0); CreditSub.BackgroundTransparency = 1
CreditSub.Text = "Thanks For using it ❤️"; CreditSub.TextColor3 = Theme.Accent; CreditSub.Font = Enum.Font.GothamBold; CreditSub.TextSize = 18

-- UI HELPER FUNKTIONEN
local function CreateSection(parent, title)
    local label = Instance.new("TextLabel", parent)
    label.Size = UDim2.new(1, 0, 0, 25)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = SafeColor(120, 120, 120)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Theme.Element; local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0); label.Position = UDim2.new(0, 15, 0, 0); label.BackgroundTransparency = 1
    label.Text = text; label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamSemibold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 40, 0, 20); btn.Position = UDim2.new(1, -55, 0.5, -10)
    btn.BackgroundColor3 = default and Theme.Accent or SafeColor(60, 60, 60); btn.Text = ""; local btnC = Instance.new("UICorner", btn); btnC.CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame", btn)
    circle.Size = UDim2.new(0, 16, 0, 16); circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    circle.BackgroundColor3 = Theme.Text; local circC = Instance.new("UICorner", circle); circC.CornerRadius = UDim.new(1, 0)

    btn.MouseButton1Click:Connect(function()
        local newState = callback()
        local targetPos = newState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local targetColor = newState and Theme.Accent or SafeColor(60, 60, 60)
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
    end)
    return btn
end

-- NEW: Keybind Changer Button
local function CreateKeybind(parent, text)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Theme.Element; local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0, 15, 0, 0); label.BackgroundTransparency = 1
    label.Text = text; label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamSemibold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 25); btn.Position = UDim2.new(1, -95, 0.5, -12.5)
    btn.BackgroundColor3 = SafeColor(60, 60, 60); btn.Text = Settings.AimKeyName; btn.TextColor3 = Theme.Text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    local btnC = Instance.new("UICorner", btn); btnC.CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if changingKey then return end
        changingKey = true
        btn.Text = "Press Key..."
        btn.TextColor3 = Theme.Accent
        
        local inputConnection
        inputConnection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                
                -- Setze neue Taste
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Settings.AimKey = input.KeyCode
                    Settings.AimKeyName = input.KeyCode.Name
                else
                    Settings.AimKey = input.UserInputType
                    Settings.AimKeyName = input.UserInputType.Name
                end
                
                -- UI Reset
                btn.Text = Settings.AimKeyName
                btn.TextColor3 = Theme.Text
                changingKey = false
                inputConnection:Disconnect()
            end
        end)
    end)
end

-- NEW: Mode Toggle (Hold vs Toggle)
local function CreateModeSwitch(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Theme.Element; local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0, 15, 0, 0); label.BackgroundTransparency = 1
    label.Text = "Aim Mode"; label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamSemibold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 25); btn.Position = UDim2.new(1, -95, 0.5, -12.5)
    btn.BackgroundColor3 = SafeColor(60, 60, 60); btn.Text = Settings.AimMode; btn.TextColor3 = Theme.Text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    local btnC = Instance.new("UICorner", btn); btnC.CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if Settings.AimMode == "Hold" then
            Settings.AimMode = "Toggle"
            btn.Text = "Toggle"
            btn.TextColor3 = Theme.Success
        else
            Settings.AimMode = "Hold"
            btn.Text = "Hold"
            btn.TextColor3 = Theme.Text
            Settings.IsAimingToggled = false -- Reset state when switching back
        end
    end)
end

local function CreateSlider(parent, text, valueKey, min, max, displayFormat)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 60); frame.BackgroundColor3 = Theme.Element; local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -20, 0, 30); label.Position = UDim2.new(0, 10, 0, 0); label.BackgroundTransparency = 1
    label.Text = text .. ": " .. string.format(displayFormat, Settings[valueKey]); label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamSemibold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left
    
    local sliderBg = Instance.new("TextButton", frame); sliderBg.Size = UDim2.new(1, -30, 0, 6); sliderBg.Position = UDim2.new(0, 15, 0, 40); sliderBg.BackgroundColor3 = SafeColor(60, 60, 60); sliderBg.Text = ""; sliderBg.AutoButtonColor = false; local sC = Instance.new("UICorner", sliderBg); sC.CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", sliderBg); local percent = (Settings[valueKey] - min) / (max - min); fill.Size = UDim2.new(percent, 0, 1, 0); fill.BackgroundColor3 = Theme.Accent; local fC = Instance.new("UICorner", fill); fC.CornerRadius = UDim.new(1, 0)

    local function Update(input)
        local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local newVal = min + (pos * (max - min))
        Settings[valueKey] = newVal
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. ": " .. string.format(displayFormat, newVal)
        if valueKey == "AimbotFOV" and FOV_Circle then FOV_Circle.Radius = newVal end
    end
    
    local sliding = false
    sliderBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; Update(input) end end)
    UserInputService.InputChanged:Connect(function(input) if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then Update(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
end

-- UI SETUP
CreateSection(TabsFrames.Visuals, "PLAYERS")
CreateToggle(TabsFrames.Visuals, "Box ESP", Settings.BoxESP, function() Settings.BoxESP = not Settings.BoxESP; return Settings.BoxESP end)
CreateToggle(TabsFrames.Visuals, "Skeleton ESP", Settings.SkeletonESP, function() Settings.SkeletonESP = not Settings.SkeletonESP; return Settings.SkeletonESP end)
CreateToggle(TabsFrames.Visuals, "Name ESP", Settings.NameESP, function() Settings.NameESP = not Settings.NameESP; return Settings.NameESP end)
CreateToggle(TabsFrames.Visuals, "Health Bar", Settings.HealthESP, function() Settings.HealthESP = not Settings.HealthESP; return Settings.HealthESP end)
CreateSection(TabsFrames.Visuals, "FILTER")
CreateToggle(TabsFrames.Visuals, "Team Check", Settings.TeamCheck, function() Settings.TeamCheck = not Settings.TeamCheck; return Settings.TeamCheck end)

CreateSection(TabsFrames.Aimbot, "MAIN")
CreateToggle(TabsFrames.Aimbot, "Aimbot Enable", Settings.AimbotEnabled, function() 
    Settings.AimbotEnabled = not Settings.AimbotEnabled
    if FOV_Circle then FOV_Circle.Visible = Settings.AimbotEnabled end
    return Settings.AimbotEnabled 
end)

-- NEUE INPUT SEKTION
CreateSection(TabsFrames.Aimbot, "INPUT SETTINGS")
CreateKeybind(TabsFrames.Aimbot, "Aim Keybind")
CreateModeSwitch(TabsFrames.Aimbot)

CreateSection(TabsFrames.Aimbot, "CONFIG")
CreateSlider(TabsFrames.Aimbot, "FOV Radius", "AimbotFOV", 10, 800, "%.0f")
CreateSlider(TabsFrames.Aimbot, "Smoothness", "AimbotSmooth", 0.01, 1, "%.2f")
CreateSection(TabsFrames.Aimbot, "CHECKS")
CreateToggle(TabsFrames.Aimbot, "Wall Check", Settings.WallCheck, function() Settings.WallCheck = not Settings.WallCheck; return Settings.WallCheck end)
CreateToggle(TabsFrames.Aimbot, "Alive Check", Settings.AliveCheck, function() Settings.AliveCheck = not Settings.AliveCheck; return Settings.AliveCheck end)

-------------------------------------------------------------------------
-- DRAWING & LOGIC
-------------------------------------------------------------------------
-- Helper Functions (verkürzt, da unverändert)
local function createBoxStructure()
    local t = Drawing.new("Text"); t.Center=true; t.Outline=true; t.Size=13; t.Color=Color3.new(1,1,1)
    local t2 = Drawing.new("Text"); t2.Center=true; t2.Outline=true; t2.Size=13; t2.Color=Color3.new(1,1,1)
    return { BoxOutline=Drawing.new("Square"), Box=Drawing.new("Square"), HealthOutline=Drawing.new("Line"), HealthBar=Drawing.new("Line"), Name=t, Distance=t2 }
end
local function createLine() return Drawing.new("Line") end

local function removeESP(player)
    if ESP_Cache[player] then
        if ESP_Cache[player].Objects then for _,o in pairs(ESP_Cache[player].Objects) do if o.Remove then o:Remove() end end end
        if ESP_Cache[player].SkeletonLines then for _,l in pairs(ESP_Cache[player].SkeletonLines) do if l.Remove then l:Remove() end end end
        ESP_Cache[player] = nil
    end
end
Players.PlayerRemoving:Connect(removeESP)

local function IsVisible(target)
    if not target.Character or not target.Character:FindFirstChild("Head") then return false end
    local params = RaycastParams.new(); params.FilterDescendantsInstances={LocalPlayer.Character, target.Character}; params.FilterType=Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(Camera.CFrame.Position, target.Character.Head.Position - Camera.CFrame.Position, params)
    return not result
end

local function GetClosestPlayerToMouse()
    local closest, dist = nil, Settings.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            local hum = p.Character:FindFirstChild("Humanoid")
            if Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            if Settings.AliveCheck and hum and hum.Health <= 0 then continue end
            if Settings.WallCheck and not IsVisible(p) then continue end
            local pos, vis = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if vis then
                local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if d < dist then closest = p; dist = d end
            end
        end
    end
    return closest
end

-- NEW: INPUT LISTENER FÜR TOGGLE MODE
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe or changingKey then return end
    
    local isCorrectKey = false
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.AimKey then isCorrectKey = true end
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) and input.UserInputType == Settings.AimKey then isCorrectKey = true end
    
    if isCorrectKey and Settings.AimMode == "Toggle" then
        Settings.IsAimingToggled = not Settings.IsAimingToggled
    end
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and FOV_Circle then FOV_Circle.Position = UserInputService:GetMouseLocation(); FOV_Circle.Visible = true
    elseif FOV_Circle then FOV_Circle.Visible = false end

    -- NEW: AIM STATUS LOGIC
    local isAiming = false
    if Settings.AimbotEnabled then
        if Settings.AimMode == "Hold" then
            -- Check für Maus oder Keyboard Hold
            if Settings.AimKey.EnumType == Enum.UserInputType then
                isAiming = UserInputService:IsMouseButtonPressed(Settings.AimKey)
            elseif Settings.AimKey.EnumType == Enum.KeyCode then
                isAiming = UserInputService:IsKeyDown(Settings.AimKey)
            end
        else
            -- Toggle Mode
            isAiming = Settings.IsAimingToggled
        end
    end

    if isAiming then
        local target = GetClosestPlayerToMouse()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Character.Head.Position), Settings.AimbotSmooth)
        end
    end

    -- ESP Loop (komprimiert)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            local hrp, hum = p.Character.HumanoidRootPart, p.Character.Humanoid
            if (Settings.TeamCheck and p.Team == LocalPlayer.Team) or hum.Health <= 0 then removeESP(p); continue end
            local v, vis = Camera:WorldToViewportPoint(hrp.Position)
            if not ESP_Cache[p] then ESP_Cache[p] = {Objects=createBoxStructure(), SkeletonLines={}} end
            local objs = ESP_Cache[p].Objects
            
            if vis then
                local h = (Camera.ViewportSize.Y / v.Z) * 4.5; local w = h/1.5; local pos = Vector2.new(v.X-w/2, v.Y-h/2)
                if Settings.BoxESP then
                    objs.BoxOutline.Size=Vector2.new(w,h); objs.BoxOutline.Position=pos; objs.BoxOutline.Visible=true
                    objs.Box.Size=Vector2.new(w,h); objs.Box.Position=pos; objs.Box.Color=Settings.ESPColor; objs.Box.Visible=true
                else objs.Box.Visible=false; objs.BoxOutline.Visible=false end
                
                -- WIEDERHERGESTELLT: Health Bar
                if Settings.HealthESP then
                    local healthPercent = hum.Health / hum.MaxHealth
                    local barHeight = h * healthPercent
                    objs.HealthOutline.From = Vector2.new(pos.X - 5, pos.Y + h)
                    objs.HealthOutline.To = Vector2.new(pos.X - 5, pos.Y)
                    objs.HealthOutline.Visible = true
                    objs.HealthBar.From = Vector2.new(pos.X - 5, pos.Y + h)
                    objs.HealthBar.To = Vector2.new(pos.X - 5, pos.Y + h - barHeight)
                    objs.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    objs.HealthBar.Visible = true
                else
                    objs.HealthOutline.Visible = false; objs.HealthBar.Visible = false
                end

                -- WIEDERHERGESTELLT: Names & Distance
                if Settings.NameESP then
                    objs.Name.Text = p.Name
                    objs.Name.Position = Vector2.new(v.X, pos.Y - 15)
                    objs.Name.Color = Settings.ESPColor
                    objs.Name.Visible = true
                    objs.Distance.Text = math.floor(v.Z) .. " studs"
                    objs.Distance.Position = Vector2.new(v.X, pos.Y + h + 5)
                    objs.Distance.Visible = true
                else
                    objs.Name.Visible = false; objs.Distance.Visible = false
                end

                -- WIEDERHERGESTELLT: Skeleton ESP
                if Settings.SkeletonESP then
                    local connections = {}
                    if hum.RigType == Enum.HumanoidRigType.R15 then
                         connections = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"}}
                    else
                        connections = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
                    end
                    for i, pair in ipairs(connections) do
                        local pA = p.Character:FindFirstChild(pair[1]); local pB = p.Character:FindFirstChild(pair[2])
                        if pA and pB then
                            local vA, visA = Camera:WorldToViewportPoint(pA.Position); local vB, visB = Camera:WorldToViewportPoint(pB.Position)
                            if visA and visB then
                                if not ESP_Cache[p].SkeletonLines[i] then ESP_Cache[p].SkeletonLines[i] = createLine() end
                                local line = ESP_Cache[p].SkeletonLines[i]
                                line.From = Vector2.new(vA.X, vA.Y); line.To = Vector2.new(vB.X, vB.Y); line.Color = Settings.ESPColor; line.Visible = true
                            elseif ESP_Cache[p].SkeletonLines[i] then ESP_Cache[p].SkeletonLines[i].Visible = false end
                        end
                    end
                else
                    for _, l in pairs(ESP_Cache[p].SkeletonLines) do l.Visible = false end
                end

            else
                objs.Box.Visible=false; objs.BoxOutline.Visible=false
                objs.HealthBar.Visible = false; objs.HealthOutline.Visible = false
                objs.Name.Visible = false; objs.Distance.Visible = false
                for _, l in pairs(ESP_Cache[p].SkeletonLines) do l.Visible = false end
            end
        else removeESP(p) end
    end
end)

print("AimRare Hub v2.8 (Restored) Loaded")
