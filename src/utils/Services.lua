--[[
    VapeUI Services
    Cached game services for performance.
]]

local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Lighting = game:GetService("Lighting"),
    CoreGui = game:GetService("CoreGui"),
    TextService = game:GetService("TextService"),
    HttpService = game:GetService("HttpService"),
}

-- Player reference
Services.LocalPlayer = Services.Players.LocalPlayer
Services.Mouse = Services.LocalPlayer:GetMouse()

-- Camera reference
Services.Camera = workspace.CurrentCamera

return Services