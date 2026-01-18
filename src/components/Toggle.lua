--[[
    VapeUI Toggle
    Boolean switch component.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)
local Signal = require(script.Parent.Parent.core.Signal)
local Card = require(script.Parent.Card)

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(parent, options)
    local self = setmetatable({}, Toggle)
    
    options = options or {}
    self.Name = options.Name or "Toggle"
    self.Flag = options.Flag or self.Name
    self.Default = options.Default or false
    self.Callback = options.Callback or function() end
    self.Value = self.Default
    
    -- Signals
    self.OnChanged = Signal.new()
    
    -- Create card base
    self.Card = Card.new(parent, {
        Name = self.Name,
    })
    
    self.Frame = self.Card.Frame
    
    -- Toggle switch
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
    
    -- Toggle indicator (circle)
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
    
    -- Click handler
    self.Switch.MouseButton1Click:Connect(function()
        self:Set(not self.Value)
    end)
    
    -- Make entire card clickable
    self.Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Set(not self.Value)
        end
    end)
    
    -- Set initial state
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
        for k, v in pairs(props) do
            inst[k] = v
        end
    end
    
    if self.Value then
        tweenFunc(self.Switch, {BackgroundColor3 = Theme:Get("ToggleOn")})
        tweenFunc(self.Indicator, {
            Position = UDim2.new(1, -Config.Toggle.IndicatorPadding - Config.Toggle.IndicatorSize, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
        })
    else
        tweenFunc(self.Switch, {BackgroundColor3 = Theme:Get("ToggleOff")})
        tweenFunc(self.Indicator, {
            Position = UDim2.new(0, Config.Toggle.IndicatorPadding, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
        })
    end
end

function Toggle:UpdateTheme()
    self.Card:UpdateTheme()
    self:_updateVisual(false)
end

return Toggle