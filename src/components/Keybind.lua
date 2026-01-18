--[[
    VapeUI Keybind
    Key binding selector.
]]

local UserInputService = game:GetService("UserInputService")
local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)
local Signal = require(script.Parent.Parent.core.Signal)
local Card = require(script.Parent.Card)

local Keybind = {}
Keybind.__index = Keybind

local KEY_NAMES = {
    LeftShift = "LShift",
    RightShift = "RShift",
    LeftControl = "LCtrl",
    RightControl = "RCtrl",
    LeftAlt = "LAlt",
    RightAlt = "RAlt",
    CapsLock = "Caps",
    Backspace = "Back",
    Unknown = "None",
}

function Keybind.new(parent, options)
    local self = setmetatable({}, Keybind)
    
    options = options or {}
    self.Name = options.Name or "Keybind"
    self.Flag = options.Flag or self.Name
    self.Default = options.Default or Enum.KeyCode.Unknown
    self.Callback = options.Callback or function() end
    self.ChangedCallback = options.ChangedCallback or function() end
    
    self.Value = self.Default
    self.Binding = false
    
    -- Signals
    self.OnChanged = Signal.new()
    self.OnActivated = Signal.new()
    
    -- Create card base
    self.Card = Card.new(parent, {
        Name = self.Name,
    })
    
    self.Frame = self.Card.Frame
    
    -- Key button
    self.KeyButton = Create.Button({
        Name = "KeyButton",
        Size = UDim2.fromOffset(70, 24),
        Position = UDim2.new(1, -Config.Card.Padding, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme:Get("CardHover"),
        Font = Config.Font.Heading,
        Text = self:_getKeyName(self.Default),
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = Config.Font.SizeSmall,
        AutoButtonColor = false,
        Parent = self.Card.Content,
    }, {
        Create.Corner(4),
    })
    
    -- Click to bind
    self.KeyButton.MouseButton1Click:Connect(function()
        self:_startBinding()
    end)
    
    -- Listen for key press
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if self.Binding then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self:Set(input.KeyCode)
            end
        elseif input.KeyCode == self.Value and self.Value ~= Enum.KeyCode.Unknown then
            self.Callback(self.Value)
            self.OnActivated:Fire(self.Value)
        end
    end)
    
    return self
end

function Keybind:_getKeyName(keyCode)
    return KEY_NAMES[keyCode.Name] or keyCode.Name
end

function Keybind:_startBinding()
    if self.Binding then return end
    
    self.Binding = true
    self.KeyButton.Text = "..."
    Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("Accent")})
    Tween.Fast(self.KeyButton, {TextColor3 = Color3.fromRGB(10, 10, 10)})
    
    -- Timeout after 5 seconds
    task.delay(5, function()
        if self.Binding then
            self.Binding = false
            self.KeyButton.Text = self:_getKeyName(self.Value)
            Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("CardHover")})
            Tween.Fast(self.KeyButton, {TextColor3 = Theme:Get("TextSecondary")})
        end
    end)
end

function Keybind:Set(keyCode, skipCallback)
    self.Binding = false
    self.Value = keyCode
    self.KeyButton.Text = self:_getKeyName(keyCode)
    
    Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("CardHover")})
    Tween.Fast(self.KeyButton, {TextColor3 = Theme:Get("TextSecondary")})
    
    if not skipCallback then
        self.ChangedCallback(keyCode)
        self.OnChanged:Fire(keyCode)
    end
end

function Keybind:Get()
    return self.Value
end

function Keybind:UpdateTheme()
    self.Card:UpdateTheme()
    self.KeyButton.BackgroundColor3 = Theme:Get("CardHover")
    self.KeyButton.TextColor3 = Theme:Get("TextSecondary")
end

return Keybind