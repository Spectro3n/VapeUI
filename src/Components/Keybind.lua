--[[
    VapeUI Keybind
    Key binding selector.
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")
local Card = require("Components/Card.lua")

-- ✅ CORRIGIDO: Acesso direto ao cache
local UserInputService = Services.UserInputService

local Keybind = {}
Keybind.__index = Keybind

-- Shortened key names for display
local KEY_NAMES = {
    LeftShift = "LShift",
    RightShift = "RShift",
    LeftControl = "LCtrl",
    RightControl = "RCtrl",
    LeftAlt = "LAlt",
    RightAlt = "RAlt",
    CapsLock = "Caps",
    Backspace = "Back",
    Return = "Enter",
    Unknown = "None",
    Escape = "Esc",
    Delete = "Del",
    Insert = "Ins",
    Home = "Home",
    End = "End",
    PageUp = "PgUp",
    PageDown = "PgDn",
    LeftBracket = "[",
    RightBracket = "]",
    Semicolon = ";",
    Quote = "'",
    BackSlash = "\\",
    Comma = ",",
    Period = ".",
    Slash = "/",
    BackQuote = "`",
    Equals = "=",
    Minus = "-",
    Space = "Space",
    Tab = "Tab",
}

function Keybind.new(parent, options)
    local self = setmetatable({}, Keybind)
    
    options = options or {}
    self.Name = options.Name or "Keybind"
    self.Flag = options.Flag or self.Name
    self.Default = options.Default or Enum.KeyCode.Unknown
    self.Callback = options.Callback or function() end
    self.ChangedCallback = options.ChangedCallback or function() end
    self.IgnoreGameProcessed = options.IgnoreGameProcessed or false
    
    self.Value = self.Default
    self.Binding = false
    self._connections = {}
    
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
    
    -- Hover effect
    self.KeyButton.MouseEnter:Connect(function()
        if not self.Binding then
            Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("CardActive")})
        end
    end)
    
    self.KeyButton.MouseLeave:Connect(function()
        if not self.Binding then
            Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("CardHover")})
        end
    end)
    
    -- Click to bind
    self.KeyButton.MouseButton1Click:Connect(function()
        self:_startBinding()
    end)
    
    -- Listen for key press
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed and not self.IgnoreGameProcessed then 
            if self.Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                self:Set(input.KeyCode)
            end
            return 
        end
        
        if self.Binding then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                self:Set(input.KeyCode)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                -- Click outside cancels binding
                task.wait()
                if self.Binding then
                    self:_cancelBinding()
                end
            end
        elseif input.KeyCode == self.Value and self.Value ~= Enum.KeyCode.Unknown then
            self.Callback(self.Value)
            self.OnActivated:Fire(self.Value)
        end
    end))
    
    return self
end

function Keybind:_getKeyName(keyCode)
    if keyCode == nil then return "None" end
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
            self:_cancelBinding()
        end
    end)
end

function Keybind:_cancelBinding()
    self.Binding = false
    self.KeyButton.Text = self:_getKeyName(self.Value)
    Tween.Fast(self.KeyButton, {BackgroundColor3 = Theme:Get("CardHover")})
    Tween.Fast(self.KeyButton, {TextColor3 = Theme:Get("TextSecondary")})
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

function Keybind:Clear()
    self:Set(Enum.KeyCode.Unknown, true)
end

function Keybind:UpdateTheme()
    self.Card:UpdateTheme()
    
    if self.Binding then
        self.KeyButton.BackgroundColor3 = Theme:Get("Accent")
        self.KeyButton.TextColor3 = Color3.fromRGB(10, 10, 10)
    else
        self.KeyButton.BackgroundColor3 = Theme:Get("CardHover")
        self.KeyButton.TextColor3 = Theme:Get("TextSecondary")
    end
end

function Keybind:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    self.OnChanged:Destroy()
    self.OnActivated:Destroy()
    self.Card:Destroy()
end

return Keybind