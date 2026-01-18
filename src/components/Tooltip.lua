--[[
    VapeUI Tooltip
    Hover tooltip display.
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")

local UserInputService = Services:Get("UserInputService")
local RunService = Services:Get("RunService")

local Tooltip = {}
Tooltip.__index = Tooltip

-- Singleton tooltip instance
local _tooltip = nil
local _currentTarget = nil
local _showDelay = nil
local _updateConnection = nil

function Tooltip:_create(screenGui)
    if _tooltip then return _tooltip end
    
    _tooltip = Create.Frame({
        Name = "Tooltip",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Theme:Get("Card"),
        Visible = false,
        ZIndex = 1000,
        Parent = screenGui,
    }, {
        Create.Corner(6),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.5,
        }),
        Create.Padding(8, 12, 8, 12),
    })
    
    local label = Create.Text({
        Name = "Label",
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = "",
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = 12,
        Parent = _tooltip,
    })
    
    _tooltip._label = label
    
    return _tooltip
end

function Tooltip.Bind(screenGui, element, text, options)
    options = options or {}
    local delay = options.Delay or Config.Misc.TooltipDelay
    local followMouse = options.FollowMouse ~= false
    
    local tooltip = Tooltip:_create(screenGui)
    
    element.MouseEnter:Connect(function()
        _currentTarget = element
        
        -- Cancel previous delay
        if _showDelay then
            task.cancel(_showDelay)
        end
        
        -- Delay before showing
        _showDelay = task.delay(delay, function()
            if _currentTarget == element then
                tooltip._label.Text = text
                tooltip.Visible = true
                Tween.Fast(tooltip, {BackgroundTransparency = 0})
                
                -- Update position
                if _updateConnection then
                    _updateConnection:Disconnect()
                end
                
                _updateConnection = RunService.RenderStepped:Connect(function()
                    if not tooltip.Visible then
                        _updateConnection:Disconnect()
                        return
                    end
                    
                    local mousePos = UserInputService:GetMouseLocation()
                    local viewportSize = workspace.CurrentCamera.ViewportSize
                    
                    local x = mousePos.X + 15
                    local y = mousePos.Y + 15
                    
                    -- Keep within viewport
                    if x + tooltip.AbsoluteSize.X > viewportSize.X - 10 then
                        x = mousePos.X - tooltip.AbsoluteSize.X - 15
                    end
                    
                    if y + tooltip.AbsoluteSize.Y > viewportSize.Y - 10 then
                        y = mousePos.Y - tooltip.AbsoluteSize.Y - 15
                    end
                    
                    tooltip.Position = UDim2.fromOffset(x, y - 36) -- Account for topbar inset
                end)
            end
        end)
    end)
    
    element.MouseLeave:Connect(function()
        if _currentTarget == element then
            _currentTarget = nil
            
            if _showDelay then
                task.cancel(_showDelay)
                _showDelay = nil
            end
            
            if _updateConnection then
                _updateConnection:Disconnect()
                _updateConnection = nil
            end
            
            Tween.Fast(tooltip, {BackgroundTransparency = 1})
            task.delay(Config.Animation.Fast, function()
                if _currentTarget == nil then
                    tooltip.Visible = false
                end
            end)
        end
    end)
end

function Tooltip.UpdateTheme()
    if _tooltip then
        _tooltip.BackgroundColor3 = Theme:Get("Card")
        _tooltip._label.TextColor3 = Theme:Get("TextPrimary")
        
        local stroke = _tooltip:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = Theme:Get("Border")
        end
    end
end

function Tooltip.Hide()
    if _tooltip then
        _tooltip.Visible = false
    end
    _currentTarget = nil
end

return Tooltip