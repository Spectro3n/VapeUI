--[[
    VapeUI Demo
    Example implementation showing all components.
]]

-- Load the library
local VapeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/username/VapeUI/main/src/init.lua"))()

-- Create window
local Window = VapeUI:CreateWindow({
    Title = "VapeUI Demo",
    Size = Vector2.new(680, 500),
    Theme = "Dark", -- Dark, Midnight, Crimson
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ═══════════════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════════════

local CombatTab = Window:CreateTab({
    Name = "Combat",
    Icon = "rbxassetid://7733960981", -- Optional
})

CombatTab:CreateDivider("Aimbot")

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    Flag = "AimbotEnabled",
    Default = false,
    Callback = function(value)
        print("Aimbot:", value)
    end,
})

CombatTab:CreateSlider({
    Name = "FOV",
    Flag = "AimbotFOV",
    Min = 0,
    Max = 180,
    Default = 90,
    Increment = 5,
    Suffix = "°",
    Callback = function(value)
        print("FOV:", value)
    end,
})

CombatTab:CreateDropdown({
    Name = "Target Part",
    Flag = "TargetPart",
    Options = {"Head", "Torso", "Closest"},
    Default = "Head",
    Callback = function(value)
        print("Target:", value)
    end,
})

CombatTab:CreateKeybind({
    Name = "Aimbot Key",
    Flag = "AimbotKey",
    Default = Enum.KeyCode.E,
    Callback = function(key)
        print("Aimbot activated!")
    end,
})

CombatTab:CreateDivider("Triggerbot")

CombatTab:CreateToggle({
    Name = "Enable Triggerbot",
    Flag = "TriggerbotEnabled",
    Default = false,
    Callback = function(value)
        print("Triggerbot:", value)
    end,
})

CombatTab:CreateSlider({
    Name = "Delay",
    Flag = "TriggerbotDelay",
    Min = 0,
    Max = 500,
    Default = 100,
    Increment = 10,
    Suffix = "ms",
    Callback = function(value)
        print("Delay:", value)
    end,
})

-- ═══════════════════════════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════════════════════════

local VisualsTab = Window:CreateTab({
    Name = "Visuals",
})

VisualsTab:CreateDivider("ESP")

VisualsTab:CreateToggle({
    Name = "Player ESP",
    Flag = "PlayerESP",
    Default = false,
    Callback = function(value)
        print("ESP:", value)
    end,
})

VisualsTab:CreateToggle({
    Name = "Box ESP",
    Flag = "BoxESP",
    Default = false,
})

VisualsTab:CreateToggle({
    Name = "Name ESP",
    Flag = "NameESP",
    Default = true,
})

VisualsTab:CreateToggle({
    Name = "Health Bar",
    Flag = "HealthBar",
    Default = false,
})

VisualsTab:CreateDivider("World")

VisualsTab:CreateToggle({
    Name = "Fullbright",
    Flag = "Fullbright",
    Default = false,
    Callback = function(value)
        if value then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
        else
            game:GetService("Lighting").Brightness = 1
        end
    end,
})

VisualsTab:CreateSlider({
    Name = "Field of View",
    Flag = "FOVValue",
    Min = 70,
    Max = 120,
    Default = 70,
    Callback = function(value)
        workspace.CurrentCamera.FieldOfView = value
    end,
})

-- ═══════════════════════════════════════════════════════════════════
-- PLAYER TAB
-- ═══════════════════════════════════════════════════════════════════

local PlayerTab = Window:CreateTab({
    Name = "Player",
})

PlayerTab:CreateDivider("Movement")

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(value)
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.WalkSpeed = value
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Flag = "JumpPower",
    Min = 50,
    Max = 200,
    Default = 50,
    Callback = function(value)
        local player = game:GetService("Players").LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.JumpPower = value
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    Flag = "InfiniteJump",
    Default = false,
})

PlayerTab:CreateToggle({
    Name = "No Clip",
    Flag = "NoClip",
    Default = false,
})

PlayerTab:CreateDivider("Teleport")

PlayerTab:CreateInput({
    Name = "Player Name",
    Flag = "TeleportTarget",
    Placeholder = "Enter username...",
    Callback = function(value)
        print("Target:", value)
    end,
})

PlayerTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        local targetName = VapeUI.Flags.TeleportTarget
        print("Teleporting to:", targetName)
    end,
})

-- ═══════════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════════

local SettingsTab = Window:CreateTab({
    Name = "Settings",
})

SettingsTab:CreateDivider("UI Settings")

SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Midnight", "Crimson"},
    Default = "Dark",
    Callback = function(value)
        Window:SetTheme(value)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Toggle UI",
    Default = Enum.KeyCode.RightShift,
    ChangedCallback = function(key)
        Window.ToggleKey = key
    end,
})

SettingsTab:CreateToggle({
    Name = "Blur Background",
    Default = true,
    Callback = function(value)
        if value then
            Window.BlurController:Enable()
        else
            Window.BlurController:Disable()
        end
    end,
})

SettingsTab:CreateDivider("Actions")

SettingsTab:CreateButton({
    Name = "Copy Config",
    Style = "Default",
    Callback = function()
        print("Config copied!")
    end,
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Style = "Default",
    Callback = function()
        print("Config loaded!")
    end,
})

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Style = "Accent",
    Callback = function()
        Window:Destroy()
    end,
})

SettingsTab:CreateLabel({
    Text = "VapeUI v2.0.0",
    Style = "Muted",
})

-- ═══════════════════════════════════════════════════════════════════
-- ACCESS FLAGS
-- ═══════════════════════════════════════════════════════════════════

-- You can access any flag value globally:
print("Current Flags:")
for flag, value in pairs(VapeUI.Flags) do
    print("  " .. flag .. ":", value)
end