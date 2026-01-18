--[[
    VapeUI Tab Button
    Sidebar navigation button.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

local TabButton = {}
TabButton.__index = TabButton

function TabButton.new(parent, options)
    local self = setmetatable({}, TabButton)
    
    options = options or {}
    self.Name = options.Name or "Tab"
    self.Icon = options.Icon
    self.Active = false
    self.Collapsed = false
    self.Width = options.Width or Config.Sidebar.Width - 20
    
    self.OnClick = Signal.new()
    
    -- Main Button
    self.Frame = Create.Button({
        Name = "Tab_" .. self.Name,
        Size = UDim2.new(1, 0, 0, Config.Sidebar.TabHeight),
        BackgroundColor3 = Theme:Get("Sidebar"),
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = "",
        AutoButtonColor = false,
        Parent = parent,
    }, {
        Create.Corner(8),
    })
    
    -- Active Indicator
    self.Indicator = Create.Frame({
        Name = "Indicator",
        Size = UDim2.new(0, Config.Sidebar.IndicatorWidth, 0, Config.Sidebar.TabHeight - Config.Sidebar.IndicatorPadding * 2),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme:Get("Accent"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = self.Frame,
    }, {
        Create.Corner(2),
    })
    
    -- Icon
    if self.Icon then
        self.IconLabel = Create.Image({
            Name = "Icon",
            Size = UDim2.fromOffset(Config.Sidebar.IconSize, Config.Sidebar.IconSize),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Image = self.Icon,
            ImageColor3 = Theme:Get("TextSecondary"),
            Parent = self.Frame,
        })
    end
    
    -- Label
    self.Label = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, -(self.Icon and 45 or 25), 1, 0),
        Position = UDim2.new(0, self.Icon and 40 or 14, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Frame,
    })
    
    -- Hover
    self.Frame.MouseEnter:Connect(function()
        if not self.Active then
            Tween.Fast(self.Frame, { BackgroundTransparency = 0.85 })
            Tween.Fast(self.Frame, { BackgroundColor3 = Theme:Get("CardHover") })
        end
    end)
    
    self.Frame.MouseLeave:Connect(function()
        if not self.Active then
            Tween.Fast(self.Frame, { BackgroundTransparency = 1 })
        end
    end)
    
    -- Click
    self.Frame.MouseButton1Click:Connect(function()
        self.OnClick:Fire()
    end)
    
    return self
end

function TabButton:SetActive(active)
    self.Active = active
    
    if active then
        Tween.Fast(self.Frame, { BackgroundTransparency = 0.9, BackgroundColor3 = Theme:Get("Card") })
        Tween.Fast(self.Indicator, { BackgroundTransparency = 0 })
        Tween.Fast(self.Label, { TextColor3 = Theme:Get("TextPrimary") })
        if self.IconLabel then
            Tween.Fast(self.IconLabel, { ImageColor3 = Theme:Get("Accent") })
        end
    else
        Tween.Fast(self.Frame, { BackgroundTransparency = 1 })
        Tween.Fast(self.Indicator, { BackgroundTransparency = 1 })
        Tween.Fast(self.Label, { TextColor3 = Theme:Get("TextSecondary") })
        if self.IconLabel then
            Tween.Fast(self.IconLabel, { ImageColor3 = Theme:Get("TextSecondary") })
        end
    end
end

function TabButton:SetCollapsed(collapsed)
    self.Collapsed = collapsed
    self.Label.Visible = not collapsed
end

function TabButton:UpdateTheme()
    self.Indicator.BackgroundColor3 = Theme:Get("Accent")
    self.Label.TextColor3 = self.Active and Theme:Get("TextPrimary") or Theme:Get("TextSecondary")
    if self.IconLabel then
        self.IconLabel.ImageColor3 = self.Active and Theme:Get("Accent") or Theme:Get("TextSecondary")
    end
end

return TabButton