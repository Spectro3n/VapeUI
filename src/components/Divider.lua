--[[
    VapeUI Divider
    Visual separator line.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)

local Divider = {}
Divider.__index = Divider

function Divider.new(parent, options)
    local self = setmetatable({}, Divider)
    
    options = options or {}
    self.Text = options.Text
    
    if self.Text then
        -- Divider with text
        self.Frame = Create.Frame({
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Parent = parent,
        })
        
        self.Label = Create.Text({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = self.Text,
            TextColor3 = Theme:Get("Accent"),
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.Frame,
        })
        
        self.Line = Create.Frame({
            Name = "Line",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, -4),
            BackgroundColor3 = Theme:Get("Divider"),
            BorderSizePixel = 0,
            Parent = self.Frame,
        })
    else
        -- Simple line divider
        self.Frame = Create.Frame({
            Name = "Divider",
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Theme:Get("Divider"),
            BorderSizePixel = 0,
            Parent = parent,
        })
    end
    
    return self
end

function Divider:UpdateTheme()
    if self.Label then
        self.Label.TextColor3 = Theme:Get("Accent")
        self.Line.BackgroundColor3 = Theme:Get("Divider")
    else
        self.Frame.BackgroundColor3 = Theme:Get("Divider")
    end
end

return Divider