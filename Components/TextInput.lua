--[[
    VapeUI Text Input
    Text entry field with validation support.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")
local Card = require("Components/Card.lua")

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
    self.Integer = options.Integer or false
    self.Min = options.Min
    self.Max = options.Max
    self.MaxLength = options.MaxLength
    self.ClearOnFocus = options.ClearOnFocus or false
    self.Callback = options.Callback or function() end
    
    self.Value = self.Default
    self.Focused = false
    
    -- Signals
    self.OnChanged = Signal.new()
    self.OnEnter = Signal.new()
    self.OnFocused = Signal.new()
    self.OnFocusLost = Signal.new()
    
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
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = self.ClearOnFocus,
        Parent = self.InputContainer,
    })
    
    -- Focus effects
    self.TextBox.Focused:Connect(function()
        self.Focused = true
        Tween.Fast(self.InputContainer, {BackgroundColor3 = Theme:Get("CardActive")})
        
        -- Add accent border
        local stroke = self.InputContainer:FindFirstChildOfClass("UIStroke")
        if not stroke then
            stroke = Create.Stroke({
                Color = Theme:Get("Accent"),
                Transparency = 0,
                Thickness = 1,
                Parent = self.InputContainer,
            })
        end
        Tween.Fast(stroke, {Transparency = 0})
        
        self.OnFocused:Fire()
    end)
    
    self.TextBox.FocusLost:Connect(function(enterPressed)
        self.Focused = false
        Tween.Fast(self.InputContainer, {BackgroundColor3 = Theme:Get("CardHover")})
        
        -- Remove accent border
        local stroke = self.InputContainer:FindFirstChildOfClass("UIStroke")
        if stroke then
            Tween.Fast(stroke, {Transparency = 1})
        end
        
        local text = self.TextBox.Text
        
        -- Validate input
        text = self:_validate(text)
        self.TextBox.Text = text
        
        self.Value = text
        self.Callback(text, enterPressed)
        self.OnChanged:Fire(text)
        self.OnFocusLost:Fire(text, enterPressed)
        
        if enterPressed then
            self.OnEnter:Fire(text)
        end
    end)
    
    -- Live validation for max length
    if self.MaxLength then
        self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
            local text = self.TextBox.Text
            if #text > self.MaxLength then
                self.TextBox.Text = text:sub(1, self.MaxLength)
            end
        end)
    end
    
    return self
end

function TextInput:_validate(text)
    if self.Numeric or self.Integer then
        local num = tonumber(text)
        
        if not num then
            return tostring(self.Value) -- Revert to previous valid value
        end
        
        if self.Integer then
            num = math.floor(num)
        end
        
        if self.Min and num < self.Min then
            num = self.Min
        end
        
        if self.Max and num > self.Max then
            num = self.Max
        end
        
        return tostring(num)
    end
    
    return text
end

function TextInput:Set(value, skipCallback)
    value = tostring(value)
    
    if self.Numeric or self.Integer then
        value = self:_validate(value)
    end
    
    if self.MaxLength and #value > self.MaxLength then
        value = value:sub(1, self.MaxLength)
    end
    
    self.Value = value
    self.TextBox.Text = value
    
    if not skipCallback then
        self.Callback(value, false)
        self.OnChanged:Fire(value)
    end
end

function TextInput:Get()
    return self.Value
end

function TextInput:GetNumber()
    return tonumber(self.Value) or 0
end

function TextInput:Focus()
    self.TextBox:CaptureFocus()
end

function TextInput:Clear()
    self:Set("", true)
end

function TextInput:UpdateTheme()
    self.Card:UpdateTheme()
    
    if self.Focused then
        self.InputContainer.BackgroundColor3 = Theme:Get("CardActive")
    else
        self.InputContainer.BackgroundColor3 = Theme:Get("CardHover")
    end
    
    self.TextBox.TextColor3 = Theme:Get("TextPrimary")
    self.TextBox.PlaceholderColor3 = Theme:Get("TextMuted")
end

function TextInput:Destroy()
    self.OnChanged:Destroy()
    self.OnEnter:Destroy()
    self.OnFocused:Destroy()
    self.OnFocusLost:Destroy()
    self.Card:Destroy()
end

return TextInput