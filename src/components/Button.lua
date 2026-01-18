--[[
    VapeUI Button
    Clickable action button.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

local Button = {}
Button.__index = Button

function Button.new(parent, options)
    local self = setmetatable({}, Button)
    
    options = options or {}
    self.Name = options.Name or "Button"
    self.Callback = options.Callback or function() end
    self.Style = options.Style or "Default"
    
    self.OnClick = Signal.new()
    
    local bgColor, textColor, hoverColor
    if self.Style == "Accent" then
        bgColor = Theme:Get("Accent")
        textColor = Color3.fromRGB(10, 10, 10)
        hoverColor = Theme:Get("AccentHover")
    else
        bgColor = Theme:Get("Card")
        textColor = Theme:Get("TextPrimary")
        hoverColor = Theme:Get("CardHover")
    end
    
    self.Frame = Create.Button({
        Name = "Button_" .. self.Name,
        Size = UDim2.new(1, 0, 0, Config.Button.Height),
        BackgroundColor3 = bgColor,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = textColor,
        TextSize = Config.Font.SizeBody,
        AutoButtonColor = false,
        Parent = parent,
    }, {
        Create.Corner(Config.Button.CornerRadius),
        Create.Stroke({ Color = Theme:Get("Border"), Transparency = 0.6 }),
    })
    
    self._bgColor = bgColor
    self._hoverColor = hoverColor
    
    self.Frame.MouseEnter:Connect(function()
        Tween.Fast(self.Frame, { BackgroundColor3 = hoverColor })
    end)
    
    self.Frame.MouseLeave:Connect(function()
        Tween.Fast(self.Frame, { BackgroundColor3 = bgColor })
    end)
    
    self.Frame.MouseButton1Click:Connect(function()
        self:_ripple()
        self.Callback()
        self.OnClick:Fire()
    end)
    
    return self
end

function Button:_ripple()
    Tween.Fast(self.Frame, { Size = UDim2.new(1, -4, 0, Config.Button.Height - 2) })
    task.delay(0.1, function()
        Tween.Fast(self.Frame, { Size = UDim2.new(1, 0, 0, Config.Button.Height) })
    end)
end

function Button:SetText(text)
    self.Frame.Text = text
end

function Button:SetEnabled(enabled)
    self.Frame.Active = enabled
    Tween.Fast(self.Frame, {
        BackgroundTransparency = enabled and 0 or 0.5,
        TextTransparency = enabled and 0 or 0.5,
    })
end

function Button:UpdateTheme()
    if self.Style == "Accent" then
        self._bgColor = Theme:Get("Accent")
        self._hoverColor = Theme:Get("AccentHover")
        self.Frame.TextColor3 = Color3.fromRGB(10, 10, 10)
    else
        self._bgColor = Theme:Get("Card")
        self._hoverColor = Theme:Get("CardHover")
        self.Frame.TextColor3 = Theme:Get("TextPrimary")
    end
    self.Frame.BackgroundColor3 = self._bgColor
    self.Frame.UIStroke.Color = Theme:Get("Border")
end

return Button