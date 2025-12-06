
--[[
    AimRare Hub - Advanced Educational Script
    Version: 3.2 (Universal Hit Chance + Humanized Aim)
    Author: Ben
    
    Changelog v3.2:
    - UPDATE: Hit Chance Randomizer now works for Camera Aimbot too!
    - ADJUST: Camera Aimbot feels more human/legit with lower Hit Chance.
    - INFO: Lower Hit Chance = Less perfect tracking (Humanized).
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Check if Drawing API exists
if not Drawing then
    warn("AimRare Hub: Drawing API not found! Please use a better executor.")
    return
end

-- Safe Color Helper
local function SafeColor(r, g, b)
    return Color3.new(r / 255, g / 255, b / 255)
end

-- Settings & Status
local Settings = {
    -- Visuals
    BoxESP = false,
    SkeletonESP = false,
    NameESP = false,
    HealthESP = false,
    TeamCheck = false,
    ESPColor = SafeColor(255, 65, 65),
    
    -- Aimbot Main (Legit/Camera)
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.2,
    AimPart = "Head", -- Target Part
    
    -- Silent Aim (Universal)
    SilentAim = false,
    HitChance = 100, -- Randomizer % (Now affects both!)
    
    -- Aimbot Input
    AimKey = Enum.UserInputType.MouseButton2,
    AimKeyName = "RMB",
    AimMode = "Hold",
    IsAimingToggled = false,
    
    -- UI Control
    MenuKey = Enum.KeyCode.RightShift, -- Key to hide menu
    IsMenuVisible = true,
    
    -- Aimbot Checks
    WallCheck = false,
    AliveCheck = true,
}

-- Cache & Globals
local ESP_Cache = {}
local FOV_Circle = nil
local changingKey = false 
local SilentTarget = nil -- Target for Silent Aim

-- Initialize FOV Circle
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
-- SILENT AIM HOOK (Universal Method)
-------------------------------------------------------------------------
-- Uses hookmetamethod to spoof Mouse.Hit and Mouse.Target
-- This makes bullets go to the target without moving the camera
task.spawn(function()
    if not getgenv or not getgenv().hookmetamethod then return end
    
    local oldIndex = nil
    
    local function ShouldHit()
        return math.random(1, 100) <= Settings.HitChance
    end

    oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if Settings.SilentAim and SilentTarget and SilentTarget.Character and SilentTarget.Character:FindFirstChild(Settings.AimPart) then
            if self == LocalPlayer:GetMouse() then
                if key == "Hit" and ShouldHit() then
                    return SilentTarget.Character[Settings.AimPart].CFrame
                elseif key == "Target" and ShouldHit() then
                    return SilentTarget.Character[Settings.AimPart]
                end
            end
        end
        return oldIndex(self, key)
    end))
end)

-------------------------------------------------------------------------
-- UI SYSTEM
-------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AimRareHubUI_v3.2"
ScreenGui.ResetOnSpawn = false

if CoreGui:FindFirstChild("AimRareHubUI_v3.2") then CoreGui["AimRareHubUI_v3.2"]:Destroy() end
if LocalPlayer.PlayerGui:FindFirstChild("AimRareHubUI_v3.2") then LocalPlayer.PlayerGui["AimRareHubUI_v3.2"]:Destroy() end

if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Colors
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
MainFrame.Size = UDim2.new(0, 500, 0, 460)
MainFrame.Position = UDim2.new(0.5, -250, 0.4, -190)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
MainFrame.Visible = true

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

-- Title
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

-- Dragging Logic
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
CreditSub.Text = "Version 3.2"; CreditSub.TextColor3 = Theme.Accent; CreditSub.Font = Enum.Font.GothamBold; CreditSub.TextSize = 18

-- UPDATE LOG WINDOW
local function ShowUpdateLog()
    local LogFrame = Instance.new("Frame")
    LogFrame.Name = "LogFrame"
    LogFrame.Size = UDim2.new(0, 320, 0, 220)
    LogFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
    LogFrame.BackgroundColor3 = Theme.Element
    LogFrame.BorderSizePixel = 0
    LogFrame.ZIndex = 10
    LogFrame.Parent = ScreenGui
    
    local LogCorner = Instance.new("UICorner", LogFrame); LogCorner.CornerRadius = UDim.new(0, 8)
    
    local LogTitle = Instance.new("TextLabel", LogFrame)
    LogTitle.Size = UDim2.new(1, 0, 0, 30); LogTitle.BackgroundTransparency = 1; LogTitle.Text = "UPDATE LOG v3.2"; LogTitle.TextColor3 = Theme.Accent; LogTitle.Font = Enum.Font.GothamBlack; LogTitle.TextSize = 16; LogTitle.ZIndex = 11
    
    local LogText = Instance.new("TextLabel", LogFrame)
    LogText.Size = UDim2.new(0.9, 0, 0.6, 0); LogText.Position = UDim2.new(0.05, 0, 0.2, 0); LogText.BackgroundTransparency = 1
    LogText.Text = "- UPDATE: Hit Chance now affects Camera Aimbot!\n- INFO: Lower Hit Chance makes aimbot look more legit/human.\n- FIX: General logic improvements."
    LogText.TextColor3 = Theme.Text; LogText.Font = Enum.Font.GothamMedium; LogText.TextSize = 14; LogText.TextWrapped = true; LogText.ZIndex = 11
    
    local CloseBtn = Instance.new("TextButton", LogFrame)
    CloseBtn.Size = UDim2.new(0.4, 0, 0, 25); CloseBtn.Position = UDim2.new(0.3, 0, 0.85, 0); CloseBtn.BackgroundColor3 = Theme.Accent; CloseBtn.Text = "Okay"; CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.ZIndex = 11
    local CloseC = Instance.new("UICorner", CloseBtn); CloseC.CornerRadius = UDim.new(0, 4)
    
    -- Animation
    LogFrame.BackgroundTransparency = 1; LogText.TextTransparency = 1; LogTitle.TextTransparency = 1; CloseBtn.BackgroundTransparency = 1; CloseBtn.TextTransparency = 1
    TweenService:Create(LogFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
    TweenService:Create(LogText, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(LogTitle, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    TweenService:Create(CloseBtn, TweenInfo.new(0.5), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
    
    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(LogFrame, TweenInfo.new(0.3), {Position = UDim2.new(0.5, -160, 0.5, -160), BackgroundTransparency = 1}):Play()
        task.wait(0.3)
        LogFrame:Destroy()
    end)
end
task.delay(1, ShowUpdateLog)

-- UI HELPER FUNCTIONS
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

-- Keybind Changer Button
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
        btn.Text = "..."
        btn.TextColor3 = Theme.Accent
        
        local inputConnection
        inputConnection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                
                -- Set Key
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

-- Mode Toggle (Hold vs Toggle)
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
            Settings.IsAimingToggled = false
        end
    end)
end

-- Hitbox Cycler (Head -> Body -> etc)
local function CreateHitboxCycler(parent)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 40); frame.BackgroundColor3 = Theme.Element; local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 6)
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.6, 0, 1, 0); label.Position = UDim2.new(0, 15, 0, 0); label.BackgroundTransparency = 1
    label.Text = "Target Part"; label.TextColor3 = Theme.Text; label.Font = Enum.Font.GothamSemibold; label.TextSize = 14; label.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 110, 0, 25); btn.Position = UDim2.new(1, -125, 0.5, -12.5)
    btn.BackgroundColor3 = SafeColor(60, 60, 60); btn.Text = Settings.AimPart; btn.TextColor3 = Theme.Text; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    local btnC = Instance.new("UICorner", btn); btnC.CornerRadius = UDim.new(0, 4)

    btn.MouseButton1Click:Connect(function()
        if Settings.AimPart == "Head" then
            Settings.AimPart = "UpperTorso" -- Body
        elseif Settings.AimPart == "UpperTorso" then
            Settings.AimPart = "HumanoidRootPart" -- Center
        else
            Settings.AimPart = "Head" -- Reset
        end
        btn.Text = Settings.AimPart
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

CreateSection(TabsFrames.Aimbot, "MAIN (LEGIT AIM)")
CreateToggle(TabsFrames.Aimbot, "Camera Aimbot", Settings.AimbotEnabled, function() 
    Settings.AimbotEnabled = not Settings.AimbotEnabled
    if FOV_Circle then FOV_Circle.Visible = Settings.AimbotEnabled end
    return Settings.AimbotEnabled 
end)
CreateToggle(TabsFrames.Aimbot, "Silent Aim (Universal)", Settings.SilentAim, function() Settings.SilentAim = not Settings.SilentAim; return Settings.SilentAim end)

CreateSection(TabsFrames.Aimbot, "INPUT & TARGET")
CreateKeybind(TabsFrames.Aimbot, "Aim Keybind")
CreateModeSwitch(TabsFrames.Aimbot)
CreateHitboxCycler(TabsFrames.Aimbot)

CreateSection(TabsFrames.Aimbot, "CONFIG")
CreateSlider(TabsFrames.Aimbot, "FOV Radius", "AimbotFOV", 10, 800, "%.0f")
CreateSlider(TabsFrames.Aimbot, "Smoothness", "AimbotSmooth", 0.01, 1, "%.2f")
CreateSlider(TabsFrames.Aimbot, "Hit Chance %", "HitChance", 0, 100, "%.0f") -- New Randomizer

CreateSection(TabsFrames.Aimbot, "CHECKS")
CreateToggle(TabsFrames.Aimbot, "Wall Check", Settings.WallCheck, function() Settings.WallCheck = not Settings.WallCheck; return Settings.WallCheck end)
CreateToggle(TabsFrames.Aimbot, "Alive Check", Settings.AliveCheck, function() Settings.AliveCheck = not Settings.AliveCheck; return Settings.AliveCheck end)

-------------------------------------------------------------------------
-- DRAWING & LOGIC
-------------------------------------------------------------------------
local function createText()
    local text = Drawing.new("Text")
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.new(0,0,0)
    text.Color = Color3.new(1,1,1)
    text.Size = 13
    text.Visible = false
    return text
end

local function createLine()
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Color = Settings.ESPColor
    line.Transparency = 1
    line.Visible = false
    return line
end

local function createBoxStructure()
    local objects = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        HealthOutline = Drawing.new("Line"),
        HealthBar = Drawing.new("Line"),
        Name = createText(),
        Distance = createText()
    }
    
    objects.BoxOutline.Color = Color3.new(0,0,0)
    objects.BoxOutline.Thickness = 3
    objects.BoxOutline.Filled = false
    objects.BoxOutline.Transparency = 1
    
    objects.Box.Thickness = 1
    objects.Box.Filled = false
    
    objects.HealthOutline.Color = Color3.new(0,0,0)
    objects.HealthOutline.Thickness = 4
    
    objects.HealthBar.Color = Color3.new(0, 1, 0)
    objects.HealthBar.Thickness = 2
    
    return objects
end

local function removeESP(player)
    if ESP_Cache[player] then
        if ESP_Cache[player].Objects then
            for _, obj in pairs(ESP_Cache[player].Objects) do
                if obj and obj.Remove then obj:Remove() end
            end
        end
        if ESP_Cache[player].SkeletonLines then
            for _, line in pairs(ESP_Cache[player].SkeletonLines) do
                if line and line.Remove then line:Remove() end
            end
        end
        ESP_Cache[player] = nil
    end
end
Players.PlayerRemoving:Connect(removeESP)

-- HELPER: Wall Check Raycast
local function IsVisible(target)
    if not target or not target.Character or not target.Character:FindFirstChild(Settings.AimPart) then return false end
    
    local origin = Camera.CFrame.Position
    local targetPos = target.Character[Settings.AimPart].Position
    local direction = targetPos - origin
    
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, params)
    
    if result then return false end
    return true 
end

local function GetClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = Settings.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Settings.AimPart) then
            local hum = player.Character:FindFirstChild("Humanoid")
            
            -- Checks
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            if Settings.AliveCheck and hum and hum.Health <= 0 then continue end
            if Settings.WallCheck and not IsVisible(player) then continue end

            local pos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.AimPart].Position)

            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    closestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end
    return closestPlayer
end

-- INPUT LISTENER
UserInputService.InputBegan:Connect(function(input, gpe)
    if changingKey then return end
    
    -- GUI Toggle
    if input.KeyCode == Settings.MenuKey then
        Settings.IsMenuVisible = not Settings.IsMenuVisible
        MainFrame.Visible = Settings.IsMenuVisible
    end
    
    if gpe then return end
    
    -- Aimbot Input
    local isCorrectKey = false
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Settings.AimKey then isCorrectKey = true end
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) and input.UserInputType == Settings.AimKey then isCorrectKey = true end
    
    if isCorrectKey and Settings.AimMode == "Toggle" then
        Settings.IsAimingToggled = not Settings.IsAimingToggled
    end
end)

-------------------------------------------------------------------------
-- RENDER LOOP
-------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and FOV_Circle then
        FOV_Circle.Position = UserInputService:GetMouseLocation()
        FOV_Circle.Visible = true
    elseif FOV_Circle then
        FOV_Circle.Visible = false
    end

    -- TARGET ACQUISITION (Used for both Camera Aim & Silent Aim)
    local target = GetClosestPlayerToMouse()
    SilentTarget = target -- Update global for Silent Aim Hook

    -- CAMERA AIMBOT LOGIC
    local isAiming = false
    if Settings.AimbotEnabled then
        if Settings.AimMode == "Hold" then
            if Settings.AimKey.EnumType == Enum.UserInputType then
                isAiming = UserInputService:IsMouseButtonPressed(Settings.AimKey)
            elseif Settings.AimKey.EnumType == Enum.KeyCode then
                isAiming = UserInputService:IsKeyDown(Settings.AimKey)
            end
        else
            isAiming = Settings.IsAimingToggled
        end
    end

    if isAiming and target and target.Character and target.Character:FindFirstChild(Settings.AimPart) then
        -- Hit Chance Check for Camera Aimbot
        if math.random(1, 100) <= Settings.HitChance then
            local aimPos = target.Character[Settings.AimPart].Position
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.new(currentCFrame.Position, aimPos)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.AimbotSmooth)
        end
    end

    -- ESP LOOP
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local hum = player.Character.Humanoid
            
            if Settings.TeamCheck and player.Team == LocalPlayer.Team then removeESP(player); continue end
            if hum.Health <= 0 then removeESP(player); continue end

            local vector, onScreen = Camera:WorldToViewportPoint(hrp.Position)

            if not ESP_Cache[player] then
                ESP_Cache[player] = { Objects = createBoxStructure(), SkeletonLines = {} }
            end
            local cache = ESP_Cache[player]
            local objs = cache.Objects

            if onScreen then
                local boxHeight = (Camera.ViewportSize.Y / vector.Z) * 4.5
                local boxWidth = boxHeight / 1.5
                local boxPos = Vector2.new(vector.X - boxWidth / 2, vector.Y - boxHeight / 2)

                if Settings.BoxESP and objs.Box and objs.BoxOutline then
                    objs.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    objs.BoxOutline.Position = boxPos
                    objs.BoxOutline.Visible = true
                    
                    objs.Box.Size = Vector2.new(boxWidth, boxHeight)
                    objs.Box.Position = boxPos
                    objs.Box.Color = Settings.ESPColor
                    objs.Box.Visible = true
                else
                    if objs.Box then objs.Box.Visible = false end
                    if objs.BoxOutline then objs.BoxOutline.Visible = false end
                end

                if Settings.HealthESP and objs.HealthBar then
                    local healthPercent = hum.Health / hum.MaxHealth
                    local barHeight = boxHeight * healthPercent
                    
                    objs.HealthOutline.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight)
                    objs.HealthOutline.To = Vector2.new(boxPos.X - 5, boxPos.Y)
                    objs.HealthOutline.Visible = true
                    
                    objs.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight)
                    objs.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight - barHeight)
                    objs.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                    objs.HealthBar.Visible = true
                else
                    if objs.HealthBar then objs.HealthBar.Visible = false end
                    if objs.HealthOutline then objs.HealthOutline.Visible = false end
                end

                if Settings.NameESP and objs.Name then
                    objs.Name.Text = player.Name
                    objs.Name.Position = Vector2.new(vector.X, boxPos.Y - 15)
                    objs.Name.Color = Settings.ESPColor
                    objs.Name.Visible = true
                    
                    objs.Distance.Text = math.floor(vector.Z) .. " studs"
                    objs.Distance.Position = Vector2.new(vector.X, boxPos.Y + boxHeight + 5)
                    objs.Distance.Visible = true
                else
                    if objs.Name then objs.Name.Visible = false end
                    if objs.Distance then objs.Distance.Visible = false end
                end

                if Settings.SkeletonESP then
                    local connections = {}
                    if hum.RigType == Enum.HumanoidRigType.R15 then
                          connections = {{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"}}
                    else
                        connections = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
                    end
                    
                    for i, pair in ipairs(connections) do
                        local pA = player.Character:FindFirstChild(pair[1])
                        local pB = player.Character:FindFirstChild(pair[2])
                        if pA and pB then
                            local vA, visA = Camera:WorldToViewportPoint(pA.Position)
                            local vB, visB = Camera:WorldToViewportPoint(pB.Position)
                            
                            if visA and visB then
                                if not cache.SkeletonLines[i] then cache.SkeletonLines[i] = createLine() end
                                local line = cache.SkeletonLines[i]
                                line.From = Vector2.new(vA.X, vA.Y)
                                line.To = Vector2.new(vB.X, vB.Y)
                                line.Color = Settings.ESPColor
                                line.Visible = true
                            elseif cache.SkeletonLines[i] then
                                cache.SkeletonLines[i].Visible = false
                            end
                        end
                    end
                else
                    for _, l in pairs(cache.SkeletonLines) do l.Visible = false end
                end

            else
                if objs.Box then objs.Box.Visible = false end
                if objs.BoxOutline then objs.BoxOutline.Visible = false end
                if objs.HealthBar then objs.HealthBar.Visible = false end
                if objs.HealthOutline then objs.HealthOutline.Visible = false end
                if objs.Name then objs.Name.Visible = false end
                if objs.Distance then objs.Distance.Visible = false end
                for _, l in pairs(cache.SkeletonLines) do l.Visible = false end
            end
        else
            removeESP(player)
        end
    end
end)
