--[[
    VapeUI TopBar
    Title and window controls.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Drag = require("Utils/Drag.lua")
local Signal = require("Core/Signal.lua")

local TopBar = {}
TopBar.__index = TopBar

function TopBar.new(parent, options)
    local self = setmetatable({}, TopBar)
    
    options = options or {}
    self.Title = options.Title or "VapeUI"
    self.ShowClose = options.ShowClose ~= false
    self.ShowMinimize = options.ShowMinimize ~= false
    
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    
    -- Main Frame
    self.Frame = Create.Frame({
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, Config.TopBar.Height),
        BackgroundColor3 = Theme:Get("TopBar"),
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Create.Corner(Config.Window.CornerRadius),
        Create.Frame({
            Name = "BottomCover",
            Size = UDim2.new(1, 0, 0, Config.Window.CornerRadius),
            Position = UDim2.new(0, 0, 1, -Config.Window.CornerRadius),
            BackgroundColor3 = Theme:Get("TopBar"),
            BorderSizePixel = 0,
        }),
    })
    
    -- Title
    self.TitleLabel = Create.Text({
        Name = "Title",
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Title,
        Text = self.Title,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeTitle,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Frame,
    })
    
    -- Buttons Container
    self.ButtonsContainer = Create.Frame({
        Name = "Buttons",
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -90, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.List({
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, Config.TopBar.ButtonPadding),
        }),
    })
    
    -- Minimize Button
    if self.ShowMinimize then
        self.MinimizeButton = self:_createButton("−", function()
            self.OnMinimize:Fire()
        end)
    end
    
    -- Close Button
    if self.ShowClose then
        self.CloseButton = self:_createButton("×", function()
            self.OnClose:Fire()
        end, true)
    end
    
    -- Enable dragging
    if options.DragTarget then
        Drag.Enable(options.DragTarget, self.Frame)
    end
    
    return self
end

function TopBar:_createButton(text, callback, isClose)
    local button = Create.Button({
        Name = "Button_" .. text,
        Size = UDim2.fromOffset(Config.TopBar.ButtonSize, Config.TopBar.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        Font = Config.Font.Title,
        Text = text,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 18,
        AutoButtonColor = false,
        Parent = self.ButtonsContainer,
    }, {
        Create.Corner(6),
    })
    
    local normalColor = Theme:Get("Card")
    local hoverColor = isClose and Theme:Get("Error") or Theme:Get("CardHover")
    local hoverTextColor = isClose and Color3.new(1, 1, 1) or Theme:Get("TextPrimary")
    
    button.MouseEnter:Connect(function()
        Tween.Fast(button, { BackgroundColor3 = hoverColor, TextColor3 = hoverTextColor })
    end)
    
    button.MouseLeave:Connect(function()
        Tween.Fast(button, { BackgroundColor3 = normalColor, TextColor3 = Theme:Get("TextSecondary") })
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

function TopBar:SetTitle(title)
    self.Title = title
    self.TitleLabel.Text = title
end

function TopBar:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("TopBar")
    self.Frame.BottomCover.BackgroundColor3 = Theme:Get("TopBar")
    self.TitleLabel.TextColor3 = Theme:Get("TextPrimary")
    
    for _, child in ipairs(self.ButtonsContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child.BackgroundColor3 = Theme:Get("Card")
            child.TextColor3 = Theme:Get("TextSecondary")
        end
    end
end

return TopBar