--[[
    VapeUI Divider
    Visual separator with optional text label.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")

local Divider = {}
Divider.__index = Divider

function Divider.new(parent, options)
    local self = setmetatable({}, Divider)
    
    -- Handle string shorthand
    if type(options) == "string" then
        options = { Text = options }
    end
    
    options = options or {}
    self.Text = options.Text
    self.Style = options.Style or "Default" -- Default, Accent, Subtle
    self.Spacing = options.Spacing or 8
    
    -- Get line color based on style
    local lineColor = Theme:Get("Divider")
    local textColor = Theme:Get("TextMuted")
    
    if self.Style == "Accent" then
        lineColor = Theme:Get("Accent")
        textColor = Theme:Get("Accent")
    elseif self.Style == "Subtle" then
        lineColor = Theme:Get("Border")
        textColor = Theme:Get("TextDark")
    end
    
    if self.Text then
        -- Divider with text (section header style)
        self.Frame = Create.Frame({
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            Parent = parent,
        })
        
        -- Padding frame for spacing
        local paddingFrame = Create.Frame({
            Name = "PaddingFrame",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Parent = self.Frame,
        }, {
            Create.Padding(self.Spacing, 0, 0, 0),
        })
        
        -- Text label
        self.Label = Create.Text({
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 16),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Font = Config.Font.Title,
            Text = self.Text:upper(),
            TextColor3 = textColor,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = paddingFrame,
        })
        
        -- Line under text
        self.Line = Create.Frame({
            Name = "Line",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = lineColor,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = paddingFrame,
        })
    else
        -- Simple line divider
        self.Frame = Create.Frame({
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 1 + (self.Spacing * 2)),
            BackgroundTransparency = 1,
            Parent = parent,
        })
        
        self.Line = Create.Frame({
            Name = "Line",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = lineColor,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            Parent = self.Frame,
        })
    end
    
    -- Store style for theme updates
    self._style = self.Style
    
    return self
end

function Divider:SetText(text)
    if self.Label then
        self.Text = text
        self.Label.Text = text:upper()
    end
end

function Divider:SetVisible(visible)
    self.Frame.Visible = visible
end

function Divider:UpdateTheme()
    local lineColor = Theme:Get("Divider")
    local textColor = Theme:Get("TextMuted")
    
    if self._style == "Accent" then
        lineColor = Theme:Get("Accent")
        textColor = Theme:Get("Accent")
    elseif self._style == "Subtle" then
        lineColor = Theme:Get("Border")
        textColor = Theme:Get("TextDark")
    end
    
    if self.Label then
        self.Label.TextColor3 = textColor
    end
    
    if self.Line then
        self.Line.BackgroundColor3 = lineColor
    end
end

function Divider:Destroy()
    self.Frame:Destroy()
end

return Divider