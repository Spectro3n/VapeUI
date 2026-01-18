--[[
    VapeUI Notification
    Toast-style notification system.
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")

local Notification = {}
Notification.__index = Notification

-- Notification container (singleton)
local _container = nil
local _queue = {}
local _active = {}
local MAX_VISIBLE = 5

-- Notification types with icons and colors
local TYPES = {
    Info = {
        ColorKey = "Info",
        Icon = "ℹ️",
    },
    Success = {
        ColorKey = "Success",
        Icon = "✓",
    },
    Warning = {
        ColorKey = "Warning",
        Icon = "⚠",
    },
    Error = {
        ColorKey = "Error",
        Icon = "✕",
    },
}

function Notification:_getContainer(screenGui)
    if _container and _container.Parent then
        return _container
    end
    
    _container = Create.Frame({
        Name = "NotificationContainer",
        Size = UDim2.new(0, 320, 1, 0),
        Position = UDim2.new(1, -340, 0, 0),
        BackgroundTransparency = 1,
        Parent = screenGui,
    }, {
        Create.List({
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
        }),
        Create.Padding(0, 0, 20, 0),
    })
    
    return _container
end

function Notification.new(screenGui, options)
    local self = setmetatable({}, Notification)
    
    options = options or {}
    self.Title = options.Title or "Notification"
    self.Message = options.Message or ""
    self.Type = options.Type or "Info"
    self.Duration = options.Duration or Config.Misc.NotificationDuration
    self.Callback = options.Callback
    
    local container = Notification:_getContainer(screenGui)
    local typeConfig = TYPES[self.Type] or TYPES.Info
    local accentColor = Theme:Get(typeConfig.ColorKey)
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "Notification",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme:Get("Card"),
        ClipsDescendants = true,
        Parent = container,
    }, {
        Create.Corner(8),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.5,
        }),
    })
    
    -- Accent line
    self.AccentLine = Create.Frame({
        Name = "AccentLine",
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = self.Frame,
    })
    
    -- Content container
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, -15, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.Padding(12, 12, 12, 0),
    })
    
    -- Icon
    self.Icon = Create.Text({
        Name = "Icon",
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = typeConfig.Icon,
        TextColor3 = accentColor,
        TextSize = 16,
        Parent = self.Content,
    })
    
    -- Title
    self.TitleLabel = Create.Text({
        Name = "Title",
        Size = UDim2.new(1, -30, 0, 18),
        Position = UDim2.new(0, 28, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Title,
        Text = self.Title,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Content,
    })
    
    -- Message
    self.MessageLabel = Create.Text({
        Name = "Message",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = self.Message,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = self.Content,
    })
    
    -- Progress bar
    self.ProgressBar = Create.Frame({
        Name = "ProgressBar",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = accentColor,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = self.Frame,
    })
    
    -- Click to dismiss
    local clickDetector = Create.Button({
        Name = "ClickDetector",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Frame,
    })
    
    clickDetector.MouseButton1Click:Connect(function()
        self:Dismiss()
        if self.Callback then
            self.Callback()
        end
    end)
    
    -- Show animation
    self:_show()
    
    return self
end

function Notification:_show()
    -- Calculate height based on content
    local messageHeight = self.MessageLabel.TextBounds.Y
    local totalHeight = 24 + messageHeight + 24 + 2 -- padding + message + padding + progress
    totalHeight = math.max(totalHeight, 60)
    
    -- Animate in
    self.Frame.Size = UDim2.new(1, 0, 0, 0)
    Tween.Normal(self.Frame, {Size = UDim2.new(1, 0, 0, totalHeight)})
    
    -- Progress bar animation
    task.delay(0.2, function()
        Tween.new(self.ProgressBar, {Size = UDim2.new(0, 0, 0, 2)}, self.Duration - 0.2, Enum.EasingStyle.Linear)
    end)
    
    -- Auto dismiss
    task.delay(self.Duration, function()
        if self.Frame and self.Frame.Parent then
            self:Dismiss()
        end
    end)
    
    table.insert(_active, self)
end

function Notification:Dismiss()
    -- Remove from active list
    for i, notif in ipairs(_active) do
        if notif == self then
            table.remove(_active, i)
            break
        end
    end
    
    -- Animate out
    Tween.Fast(self.Frame, {Size = UDim2.new(1, 0, 0, 0)})
    
    task.delay(Config.Animation.Fast, function()
        if self.Frame then
            self.Frame:Destroy()
        end
    end)
end

function Notification:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.TitleLabel.TextColor3 = Theme:Get("TextPrimary")
    self.MessageLabel.TextColor3 = Theme:Get("TextSecondary")
    
    local typeConfig = TYPES[self.Type] or TYPES.Info
    local accentColor = Theme:Get(typeConfig.ColorKey)
    
    self.AccentLine.BackgroundColor3 = accentColor
    self.Icon.TextColor3 = accentColor
    self.ProgressBar.BackgroundColor3 = accentColor
end

-- Static method to create notifications easily
function Notification.Show(screenGui, options)
    return Notification.new(screenGui, options)
end

return Notification