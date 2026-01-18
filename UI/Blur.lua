--[[
    VapeUI Blur Controller
    Background blur effect management.
]]

local Services = require("Utils/Services.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")

local Blur = {}
Blur.__index = Blur

local instance = nil

function Blur.new()
    if instance then return instance end
    
    local self = setmetatable({}, Blur)
    
    self.Enabled = false
    self.Size = Config.Misc.BlurSize
    
    self.Effect = Instance.new("BlurEffect")
    self.Effect.Name = "VapeUI_Blur"
    self.Effect.Size = 0
    self.Effect.Parent = Services.Lighting
    
    instance = self
    return self
end

function Blur:Enable(size)
    self.Enabled = true
    self.Size = size or Config.Misc.BlurSize
    Tween.Slow(self.Effect, { Size = self.Size })
end

function Blur:Disable()
    self.Enabled = false
    Tween.Slow(self.Effect, { Size = 0 })
end

function Blur:Toggle()
    if self.Enabled then
        self:Disable()
    else
        self:Enable()
    end
end

function Blur:SetSize(size)
    self.Size = size
    if self.Enabled then
        Tween.Normal(self.Effect, { Size = size })
    end
end

function Blur:Destroy()
    if self.Effect then
        self.Effect:Destroy()
    end
    instance = nil
end

return Blur