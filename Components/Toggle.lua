--[[
    VapeUI Toggle
    Boolean switch component.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")
local Card = require("Components/Card.lua")

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, options)
    local self = setmetatable({}, Toggle)
    
    options = options or {}
    self.Name = options.Name or "Toggle"
    self.Flag = options.Flag
    self.Default = options.Default or false
    self.Callback = options.Callback or function() end
    self.Value = self.Default
    
    self.OnChanged = Signal.new()
    
    -- Create card
    self.Card = Card.new(parent, { Name = self.Name })
    self.Frame = self.Card.Frame
    
    -- Switch
    self.Switch = Create.Button({
        Name = "Switch",
        Size = UDim2.fromOffset(Config.Toggle.Width, Config.Toggle.Height),
        Position = UDim2.new(1, -Config.Card.Padding, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme:Get("ToggleOff"),
        Font = Enum.Font.SourceSans,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Card.Content,
    }, {
        Create.Corner(UDim.new(1, 0)),
    })
    
    -- Indicator
    self.Indicator = Create.Frame({
        Name = "Indicator",
        Size = UDim2.fromOffset(Config.Toggle.IndicatorSize, Config.Toggle.IndicatorSize),
        Position = UDim2.new(0, Config.Toggle.IndicatorPadding, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = self.Switch,
    }, {
        Create.Corner(UDim.new(1, 0)),
    })
    
    -- Events
    self.Switch.MouseButton1Click:Connect(function()
        self:Set(not self.Value)
    end)
    
    self.Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Set(not self.Value)
        end
    end)
    
    self:_updateVisual(false)
    
    return self
end

function Toggle:Set(value, skipCallback)
    self.Value = value
    self:_updateVisual(true)
    
    if not skipCallback then
        self.Callback(value)
        self.OnChanged:Fire(value)
    end
end

function Toggle:Get()
    return self.Value
end

function Toggle:_updateVisual(animate)
    local tweenFunc = animate and Tween.Normal or function(inst, props)
        for k, v in pairs(props) do inst[k] = v end
    end
    
    if self.Value then
        tweenFunc(self.Switch, { BackgroundColor3 = Theme:Get("ToggleOn") })
        tweenFunc(self.Indicator, {
            Position = UDim2.new(1, -Config.Toggle.IndicatorPadding - Config.Toggle.IndicatorSize, 0.5, 0),
        })
    else
        tweenFunc(self.Switch, { BackgroundColor3 = Theme:Get("ToggleOff") })
        tweenFunc(self.Indicator, {
            Position = UDim2.new(0, Config.Toggle.IndicatorPadding, 0.5, 0),
        })
    end
end

function Toggle:UpdateTheme()
    self.Card:UpdateTheme()
    self:_updateVisual(false)
end

return Toggle