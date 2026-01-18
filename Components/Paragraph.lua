--[[
    VapeUI Paragraph
    Multi-line text display with title.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")

local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(parent, options)
    local self = setmetatable({}, Paragraph)
    
    options = options or {}
    self.Title = options.Title or "Title"
    self.Content = options.Content or "Content goes here..."
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "Paragraph",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Create.Corner(Config.Card.CornerRadius),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.6,
        }),
        Create.Padding(Config.Card.Padding, Config.Card.Padding, Config.Card.Padding, Config.Card.Padding),
    })
    
    -- Content layout
    local layout = Create.List({
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = self.Frame,
    })
    
    -- Title
    self.TitleLabel = Create.Text({
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Config.Font.Title,
        Text = self.Title,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeHeading,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = self.Frame,
    })
    
    -- Content
    self.ContentLabel = Create.Text({
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = self.Content,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        RichText = true,
        LayoutOrder = 2,
        Parent = self.Frame,
    })
    
    return self
end

function Paragraph:SetTitle(title)
    self.Title = title
    self.TitleLabel.Text = title
end

function Paragraph:SetContent(content)
    self.Content = content
    self.ContentLabel.Text = content
end

function Paragraph:Set(title, content)
    if title then self:SetTitle(title) end
    if content then self:SetContent(content) end
end

function Paragraph:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.TitleLabel.TextColor3 = Theme:Get("TextPrimary")
    self.ContentLabel.TextColor3 = Theme:Get("TextSecondary")
    
    local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = Theme:Get("Border")
    end
end

function Paragraph:Destroy()
    self.Frame:Destroy()
end

return Paragraph