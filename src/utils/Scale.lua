--[[
    VapeUI Scale Utility
    Resolution-independent scaling for adaptive UI.
]]

local Services = require("Utils/Services.lua")

local Scale = {}

-- Base resolution for scaling calculations
local BASE_RESOLUTION = Vector2.new(1920, 1080)
local MIN_SCALE = 0.7
local MAX_SCALE = 1.3

-- Cache
local _cachedRatio = nil
local _camera = nil

function Scale:_getCamera()
    if not _camera then
        _camera = Services:Get("Workspace").CurrentCamera
    end
    return _camera
end

function Scale:GetViewportSize()
    local camera = self:_getCamera()
    if camera then
        return camera.ViewportSize
    end
    return BASE_RESOLUTION
end

function Scale:GetRatio()
    if _cachedRatio then
        return _cachedRatio
    end
    
    local viewportSize = self:GetViewportSize()
    local ratioX = viewportSize.X / BASE_RESOLUTION.X
    local ratioY = viewportSize.Y / BASE_RESOLUTION.Y
    
    _cachedRatio = math.clamp(math.min(ratioX, ratioY), MIN_SCALE, MAX_SCALE)
    
    return _cachedRatio
end

function Scale:ClearCache()
    _cachedRatio = nil
end

function Scale:Pixels(pixels)
    return math.floor(pixels * self:GetRatio())
end

function Scale:PixelsX(pixels)
    local viewportSize = self:GetViewportSize()
    local ratio = viewportSize.X / BASE_RESOLUTION.X
    return math.floor(pixels * math.clamp(ratio, MIN_SCALE, MAX_SCALE))
end

function Scale:PixelsY(pixels)
    local viewportSize = self:GetViewportSize()
    local ratio = viewportSize.Y / BASE_RESOLUTION.Y
    return math.floor(pixels * math.clamp(ratio, MIN_SCALE, MAX_SCALE))
end

function Scale:UDim2(xScale, xOffset, yScale, yOffset)
    local ratio = self:GetRatio()
    return UDim2.new(
        xScale,
        math.floor(xOffset * ratio),
        yScale,
        math.floor(yOffset * ratio)
    )
end

function Scale:UDim(scale, offset)
    return UDim.new(scale, math.floor(offset * self:GetRatio()))
end

function Scale:Vector2(x, y)
    local ratio = self:GetRatio()
    return Vector2.new(
        math.floor(x * ratio),
        math.floor(y * ratio)
    )
end

function Scale:Font(baseSize)
    local ratio = self:GetRatio()
    return math.floor(baseSize * ratio)
end

-- Auto-update cache on viewport changes
task.spawn(function()
    local camera = Scale:_getCamera()
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Scale:ClearCache()
        end)
    end
end)

return Scale