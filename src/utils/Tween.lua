--[[
    VapeUI Tween Utility
    Centralized animation system.
]]

local TweenService = game:GetService("TweenService")
local Config = require(script.Parent.Parent.core.Config)

local Tween = {}

-- ═══════════════════════════════════════════════════════════════════
-- CORE TWEEN FUNCTION
-- ═══════════════════════════════════════════════════════════════════

function Tween.new(instance, properties, duration, easingStyle, easingDirection)
    duration = duration or Config.Animation.Normal
    easingStyle = easingStyle or Config.Animation.EasingStyle
    easingDirection = easingDirection or Config.Animation.EasingDirection
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    
    return tween
end

-- ═══════════════════════════════════════════════════════════════════
-- PRESET TWEENS
-- ═══════════════════════════════════════════════════════════════════

function Tween.Fast(instance, properties)
    return Tween.new(instance, properties, Config.Animation.Fast)
end

function Tween.Normal(instance, properties)
    return Tween.new(instance, properties, Config.Animation.Normal)
end

function Tween.Slow(instance, properties)
    return Tween.new(instance, properties, Config.Animation.Slow)
end

function Tween.Spring(instance, properties)
    return Tween.new(
        instance, 
        properties, 
        Config.Animation.Spring,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )
end

-- ═══════════════════════════════════════════════════════════════════
-- SPECIFIC ANIMATIONS
-- ═══════════════════════════════════════════════════════════════════

function Tween.FadeIn(instance, duration)
    instance.BackgroundTransparency = 1
    return Tween.new(instance, {BackgroundTransparency = 0}, duration or Config.Animation.Normal)
end

function Tween.FadeOut(instance, duration)
    return Tween.new(instance, {BackgroundTransparency = 1}, duration or Config.Animation.Normal)
end

function Tween.SlideIn(instance, fromDirection, duration)
    local directions = {
        Left = UDim2.new(-1, 0, 0, 0),
        Right = UDim2.new(1, 0, 0, 0),
        Top = UDim2.new(0, 0, -1, 0),
        Bottom = UDim2.new(0, 0, 1, 0),
    }
    
    local targetPos = instance.Position
    instance.Position = directions[fromDirection] or directions.Left
    return Tween.new(instance, {Position = targetPos}, duration or Config.Animation.Slow)
end

function Tween.Pop(instance, duration)
    instance.Size = UDim2.new(0, 0, 0, 0)
    return Tween.Spring(instance, {Size = instance:GetAttribute("OriginalSize") or UDim2.new(1, 0, 1, 0)})
end

-- ═══════════════════════════════════════════════════════════════════
-- HOVER EFFECTS
-- ═══════════════════════════════════════════════════════════════════

function Tween.HoverColor(instance, normalColor, hoverColor)
    instance.MouseEnter:Connect(function()
        Tween.Fast(instance, {BackgroundColor3 = hoverColor})
    end)
    
    instance.MouseLeave:Connect(function()
        Tween.Fast(instance, {BackgroundColor3 = normalColor})
    end)
end

function Tween.HoverTransparency(instance, normalTrans, hoverTrans)
    instance.MouseEnter:Connect(function()
        Tween.Fast(instance, {BackgroundTransparency = hoverTrans})
    end)
    
    instance.MouseLeave:Connect(function()
        Tween.Fast(instance, {BackgroundTransparency = normalTrans})
    end)
end

return Tween