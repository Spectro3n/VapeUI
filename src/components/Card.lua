--[[
    VapeUI Card
    Base container for all interactive components.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Tween = require(script.Parent.Parent.utils.Tween)

local Card = {}
Card.__index = Card

function Card.new(parent, options)
    local self = setmetatable({}, Card)
    
    options = options or {}
    self.Name = options.Name or "Card"
    self.Height = options.Height or Config.Card.Height
    self.Hoverable = options.Hoverable ~= false
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "Card_" .. self.Name,
        Size = UDim2.new(1, 0, 0, self.Height),
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
    
    -- Left label
    self.Label = Create.Text({
        Name = "Label",
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, Config.Card.Padding, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    
    -- Content container (right side)
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(0.4, -Config.Card.Padding, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    })
    
    -- Hover effect
    if self.Hoverable then
        self.Frame.MouseEnter:Connect(function()
            Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("CardHover")})
        end)
        
        self.Frame.MouseLeave:Connect(function()
            Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("Card")})
        end)
    end
    
    return self
end

function Card:SetLabel(text)
    self.Label.Text = text
end

function Card:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.Frame.UIStroke.Color = Theme:Get("Border")
    self.Label.TextColor3 = Theme:Get("TextPrimary")
end

return Card