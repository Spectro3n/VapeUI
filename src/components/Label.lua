--[[
    VapeUI Label
    Simple text display.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)

local Label = {}
Label.__index = Label

function Label.new(parent, options)
    local self = setmetatable({}, Label)
    
    options = options or {}
    self.Text = options.Text or "Label"
    self.Style = options.Style or "Default" -- Default, Heading, Muted
    
    local textColor, font, size
    if self.Style == "Heading" then
        textColor = Theme:Get("TextPrimary")
        font = Config.Font.Heading
        size = Config.Font.SizeHeading
    elseif self.Style == "Muted" then
        textColor = Theme:Get("TextMuted")
        font = Config.Font.Small
        size = Config.Font.SizeSmall
    else
        textColor = Theme:Get("TextSecondary")
        font = Config.Font.Body
        size = Config.Font.SizeBody
    end
    
    self.Frame = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Font = font,
        Text = self.Text,
        TextColor3 = textColor,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
    })
    
    return self
end

function Label:Set(text)
    self.Text = text
    self.Frame.Text = text
end

function Label:UpdateTheme()
    if self.Style == "Heading" then
        self.Frame.TextColor3 = Theme:Get("TextPrimary")
    elseif self.Style == "Muted" then
        self.Frame.TextColor3 = Theme:Get("TextMuted")
    else
        self.Frame.TextColor3 = Theme:Get("TextSecondary")
    end
end

return Label