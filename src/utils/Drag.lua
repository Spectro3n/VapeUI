--[[
    VapeUI Drag Utility
    Smooth dragging with optional bounds.
]]

local UserInputService = game:GetService("UserInputService")
local Config = require(script.Parent.Parent.core.Config)

local Drag = {}

function Drag.Enable(frame, dragArea, options)
    options = options or {}
    dragArea = dragArea or frame
    
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    local smoothing = options.Smoothing or Config.Window.DragSmoothing
    local bounded = options.Bounded or false
    local bounds = options.Bounds or nil -- {MinX, MinY, MaxX, MaxY}
    
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and 
           (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            
            local delta = input.Position - dragStart
            local targetPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            
            -- Apply bounds if specified
            if bounded and bounds then
                local newX = math.clamp(targetPos.X.Offset, bounds.MinX, bounds.MaxX)
                local newY = math.clamp(targetPos.Y.Offset, bounds.MinY, bounds.MaxY)
                targetPos = UDim2.new(targetPos.X.Scale, newX, targetPos.Y.Scale, newY)
            end
            
            -- Smooth dragging
            if smoothing > 0 then
                frame.Position = frame.Position:Lerp(targetPos, 1 - smoothing)
            else
                frame.Position = targetPos
            end
        end
    end)
    
    return {
        SetEnabled = function(enabled)
            dragging = false
            dragArea.Active = enabled
        end
    }
end

return Drag