--[[
    VapeUI Slider
    Numeric value selector with drag interaction.
]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)
local Signal = require(script.Parent.Parent.core.Signal)

local Slider = {}
Slider.__index = Slider

function Slider.new(parent, options)
    local self = setmetatable({}, Slider)
    
    options = options or {}
    self.Name = options.Name or "Slider"
    self.Flag = options.Flag or self.Name
    self.Min = options.Min or 0
    self.Max = options.Max or 100
    self.Default = options.Default or self.Min
    self.Increment = options.Increment or 1
    self.Suffix = options.Suffix or ""
    self.Callback = options.Callback or function() end
    self.Value = self.Default
    
    -- Signals
    self.OnChanged = Signal.new()
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "Slider_" .. self.Name,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Create.Corner(Config.Card.CornerRadius),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.6,
        }),
    })
    
    -- Label
    self.Label = Create.Text({
        Name = "Label",
        Size = UDim2.new(0.5, 0, 0, 25),
        Position = UDim2.new(0, Config.Card.Padding, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    
    -- Value display
    self.ValueLabel = Create.Text({
        Name = "Value",
        Size = UDim2.new(0.5, -Config.Card.Padding, 0, 25),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = tostring(self.Value) .. self.Suffix,
        TextColor3 = Theme:Get("Accent"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Frame,
    })
    
    -- Slider bar container
    self.SliderContainer = Create.Frame({
        Name = "SliderContainer",
        Size = UDim2.new(1, -Config.Card.Padding * 2, 0, Config.Slider.Height),
        Position = UDim2.new(0, Config.Card.Padding, 0, 34),
        BackgroundColor3 = Theme:Get("SliderBackground"),
        BorderSizePixel = 0,
        Parent = self.Frame,
    }, {
        Create.Corner(Config.Slider.CornerRadius),
    })
    
    -- Fill bar
    self.Fill = Create.Frame({
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme:Get("SliderFill"),
        BorderSizePixel = 0,
        Parent = self.SliderContainer,
    }, {
        Create.Corner(Config.Slider.CornerRadius),
    })
    
    -- Knob
    self.Knob = Create.Frame({
        Name = "Knob",
        Size = UDim2.fromOffset(Config.Slider.KnobSize, Config.Slider.KnobSize),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.SliderContainer,
    }, {
        Create.Corner(UDim.new(1, 0)),
    })
    
    -- Drag logic
    self:_setupDrag()
    
    -- Set initial value
    self:Set(self.Default, true)
    
    return self
end

function Slider:_setupDrag()
    local dragging = false
    
    local function update(input)
        local container = self.SliderContainer
        local percent = math.clamp(
            (input.Position.X - container.AbsolutePosition.X) / container.AbsoluteSize.X,
            0, 1
        )
        
        local rawValue = self.Min + (self.Max - self.Min) * percent
        local snappedValue = math.floor(rawValue / self.Increment + 0.5) * self.Increment
        snappedValue = math.clamp(snappedValue, self.Min, self.Max)
        
        self:Set(snappedValue)
    end
    
    self.SliderContainer.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Slider:Set(value, skipCallback)
    value = math.clamp(value, self.Min, self.Max)
    value = math.floor(value / self.Increment + 0.5) * self.Increment
    
    self.Value = value
    self.ValueLabel.Text = tostring(value) .. self.Suffix
    
    local percent = (value - self.Min) / (self.Max - self.Min)
    
    Tween.Fast(self.Fill, {Size = UDim2.new(percent, 0, 1, 0)})
    Tween.Fast(self.Knob, {Position = UDim2.new(percent, 0, 0.5, 0)})
    
    if not skipCallback then
        self.Callback(value)
        self.OnChanged:Fire(value)
    end
end

function Slider:Get()
    return self.Value
end

function Slider:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.Frame.UIStroke.Color = Theme:Get("Border")
    self.Label.TextColor3 = Theme:Get("TextPrimary")
    self.ValueLabel.TextColor3 = Theme:Get("Accent")
    self.SliderContainer.BackgroundColor3 = Theme:Get("SliderBackground")
    self.Fill.BackgroundColor3 = Theme:Get("SliderFill")
end

return Slider