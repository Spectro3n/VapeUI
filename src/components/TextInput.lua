--[[
    VapeUI Text Input
    Text entry field.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)
local Signal = require(script.Parent.Parent.core.Signal)
local Card = require(script.Parent.Card)

local TextInput = {}
TextInput.__index = TextInput

function TextInput.new(parent, options)
    local self = setmetatable({}, TextInput)
    
    options = options or {}
    self.Name = options.Name or "Input"
    self.Flag = options.Flag or self.Name
    self.Placeholder = options.Placeholder or "Enter text..."
    self.Default = options.Default or ""
    self.Numeric = options.Numeric or false
    self.ClearOnFocus = options.ClearOnFocus or false
    self.Callback = options.Callback or function() end
    
    self.Value = self.Default
    
    -- Signals
    self.OnChanged = Signal.new()
    self.OnEnter = Signal.new()
    
    -- Create card base
    self.Card = Card.new(parent, {
        Name = self.Name,
        Hoverable = false,
    })
    
    self.Frame = self.Card.Frame
    
    -- Input box container
    self.InputContainer = Create.Frame({
        Name = "InputContainer",
        Size = UDim2.new(0.55, -Config.Card.Padding, 0, 26),
        Position = UDim2.new(0.45, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme:Get("CardHover"),
        BorderSizePixel = 0,
        Parent = self.Card.Content,
    }, {
        Create.Corner(4),
    })
    
    -- Text box
    self.TextBox = Create.Input({
        Name = "TextBox",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = self.Default,
        PlaceholderText = self.Placeholder,
        PlaceholderColor3 = Theme:Get("TextMuted"),
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeSmall,
        ClearTextOnFocus = self.ClearOnFocus,
        Parent = self.InputContainer,
    })
    
    -- Focus effects
    self.TextBox.Focused:Connect(function()
        Tween.Fast(self.InputContainer, {BackgroundColor3 = Theme:Get("CardActive")})
    end)
    
    self.TextBox.FocusLost:Connect(function(enterPressed)
        Tween.Fast(self.InputContainer, {BackgroundColor3 = Theme:Get("CardHover")})
        
        local text = self.TextBox.Text
        
        if self.Numeric then
            text = tonumber(text) and text or self.Value
            self.TextBox.Text = text
        end
        
        self.Value = text
        self.Callback(text, enterPressed)
        self.OnChanged:Fire(text)
        
        if enterPressed then
            self.OnEnter:Fire(text)
        end
    end)
    
    return self
end

function TextInput:Set(value, skipCallback)
    self.Value = tostring(value)
    self.TextBox.Text = self.Value
    
    if not skipCallback then
        self.Callback(self.Value, false)
        self.OnChanged:Fire(self.Value)
    end
end

function TextInput:Get()
    return self.Value
end

function TextInput:UpdateTheme()
    self.Card:UpdateTheme()
    self.InputContainer.BackgroundColor3 = Theme:Get("CardHover")
    self.TextBox.TextColor3 = Theme:Get("TextPrimary")
    self.TextBox.PlaceholderColor3 = Theme:Get("TextMuted")
end

return TextInput