--[[
    VapeUI Label
    Simple text display with multiple styles.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")

local Label = {}
Label.__index = Label

-- Style presets
local STYLES = {
    Default = {
        ColorKey = "TextSecondary",
        Font = "Body",
        Size = "SizeBody",
    },
    Heading = {
        ColorKey = "TextPrimary",
        Font = "Heading",
        Size = "SizeHeading",
    },
    Title = {
        ColorKey = "TextPrimary",
        Font = "Title",
        Size = "SizeTitle",
    },
    Muted = {
        ColorKey = "TextMuted",
        Font = "Small",
        Size = "SizeSmall",
    },
    Accent = {
        ColorKey = "Accent",
        Font = "Heading",
        Size = "SizeBody",
    },
    Success = {
        ColorKey = "Success",
        Font = "Body",
        Size = "SizeBody",
    },
    Warning = {
        ColorKey = "Warning",
        Font = "Body",
        Size = "SizeBody",
    },
    Error = {
        ColorKey = "Error",
        Font = "Body",
        Size = "SizeBody",
    },
}

function Label.new(parent, options)
    local self = setmetatable({}, Label)
    
    -- Handle string shorthand
    if type(options) == "string" then
        options = { Text = options }
    end
    
    options = options or {}
    self.Text = options.Text or "Label"
    self.Style = options.Style or "Default"
    self.Align = options.Align or "Left"
    self.Wrap = options.Wrap or false
    self.RichText = options.RichText or false
    
    -- Get style properties
    local styleConfig = STYLES[self.Style] or STYLES.Default
    local textColor = Theme:Get(styleConfig.ColorKey)
    local font = Config.Font[styleConfig.Font]
    local size = Config.Font[styleConfig.Size]
    
    -- Allow custom overrides
    if options.Color then textColor = options.Color end
    if options.Font then font = options.Font end
    if options.TextSize then size = options.TextSize end
    
    -- Alignment
    local alignment = Enum.TextXAlignment.Left
    if self.Align == "Center" then
        alignment = Enum.TextXAlignment.Center
    elseif self.Align == "Right" then
        alignment = Enum.TextXAlignment.Right
    end
    
    -- Create label
    self.Frame = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, self.Wrap and 0 or 24),
        AutomaticSize = self.Wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        Font = font,
        Text = self.Text,
        TextColor3 = textColor,
        TextSize = size,
        TextXAlignment = alignment,
        TextWrapped = self.Wrap,
        RichText = self.RichText,
        Parent = parent,
    })
    
    -- Store style info for theme updates
    self._styleConfig = styleConfig
    
    return self
end

function Label:Set(text)
    self.Text = text
    self.Frame.Text = text
end

function Label:SetStyle(style)
    self.Style = style
    self._styleConfig = STYLES[style] or STYLES.Default
    self:UpdateTheme()
end

function Label:SetColor(color)
    self.Frame.TextColor3 = color
end

function Label:SetVisible(visible)
    self.Frame.Visible = visible
end

function Label:UpdateTheme()
    local styleConfig = self._styleConfig
    self.Frame.TextColor3 = Theme:Get(styleConfig.ColorKey)
    self.Frame.Font = Config.Font[styleConfig.Font]
    self.Frame.TextSize = Config.Font[styleConfig.Size]
end

function Label:Destroy()
    self.Frame:Destroy()
end

return Label