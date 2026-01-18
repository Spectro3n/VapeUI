--[[
    VapeUI Blur Controller
    Manages background blur effect.
]]

local Lighting = game:GetService("Lighting")
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)

local Blur = {}
Blur.__index = Blur

local instance = nil

function Blur.new()
    if instance then return instance end
    
    local self = setmetatable({}, Blur)
    
    self.Enabled = false
    self.Size = Config.Misc.BlurSize
    
    -- Create blur effect
    self.Effect = Instance.new("BlurEffect")
    self.Effect.Name = "VapeUI_Blur"
    self.Effect.Size = 0
    self.Effect.Parent = Lighting
    
    instance = self
    return self
end

function Blur:Enable(size)
    self.Enabled = true
    self.Size = size or Config.Misc.BlurSize
    Tween.Slow(self.Effect, {Size = self.Size})
end

function Blur:Disable()
    self.Enabled = false
    Tween.Slow(self.Effect, {Size = 0})
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
        Tween.Normal(self.Effect, {Size = size})
    end
end

function Blur:Destroy()
    self.Effect:Destroy()
    instance = nil
end

return Blur