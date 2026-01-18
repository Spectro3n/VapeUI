--[[
    VapeUI Scale Utility
    Resolution-independent scaling.
]]

local Scale = {}

local baseResolution = Vector2.new(1920, 1080)
local camera = workspace.CurrentCamera

function Scale.GetRatio()
    local viewportSize = camera.ViewportSize
    local ratioX = viewportSize.X / baseResolution.X
    local ratioY = viewportSize.Y / baseResolution.Y
    return math.min(ratioX, ratioY)
end

function Scale.Pixels(pixels)
    return math.floor(pixels * Scale.GetRatio())
end

function Scale.UDim2(xScale, xOffset, yScale, yOffset)
    local ratio = Scale.GetRatio()
    return UDim2.new(
        xScale,
        math.floor(xOffset * ratio),
        yScale,
        math.floor(yOffset * ratio)
    )
end

function Scale.Vector2(x, y)
    local ratio = Scale.GetRatio()
    return Vector2.new(
        math.floor(x * ratio),
        math.floor(y * ratio)
    )
end

return Scale