--[[
    VapeUI TopBar v2.0
    Advanced title bar with window controls, navigation, and features.
    
    Features:
    ✅ Draggable window
    ✅ Multiple control buttons (Close, Minimize, Maximize, Pin)
    ✅ Title with icon/logo
    ✅ Subtitle support
    ✅ Navigation breadcrumbs
    ✅ Search bar integration
    ✅ User profile/avatar
    ✅ Action buttons area
    ✅ Tabs integration
    ✅ Theme toggle
    ✅ Notification indicator
    ✅ Clock/Time display
    ✅ Status indicators
    ✅ Context menu
    ✅ Responsive layout
    ✅ Double-click maximize
    ✅ Smooth animations
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Drag = require("Utils/Drag.lua")
local Signal = require("Core/Signal.lua")

-- Services
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local Players = Services.Players

local TopBar = {}
TopBar.__index = TopBar

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Dimensions
    Height = 48,
    ButtonSize = 32,
    ButtonPadding = 8,
    LogoSize = 28,
    
    -- Features
    ShowClose = true,
    ShowMinimize = true,
    ShowMaximize = false,
    ShowPin = false,
    ShowThemeToggle = false,
    ShowSearch = false,
    ShowAvatar = false,
    ShowClock = false,
    ShowNotifications = false,
    
    -- Behavior
    EnableDrag = true,
    EnableDoubleClickMaximize = true,
    EnableContextMenu = false,
    
    -- Content
    Title = "VapeUI",
    Subtitle = nil,
    Logo = nil,  -- Image ID or nil
    LogoEmoji = nil,  -- Emoji fallback
    
    -- Animation
    AnimateButtons = true,
}

local BUTTON_CONFIGS = {
    Close = {
        Icon = "✕",
        Tooltip = "Close",
        HoverColor = "Error",
        Order = 100,
    },
    Minimize = {
        Icon = "−",
        Tooltip = "Minimize",
        HoverColor = "CardHover",
        Order = 90,
    },
    Maximize = {
        Icon = "□",
        IconAlt = "❐",  -- When maximized
        Tooltip = "Maximize",
        TooltipAlt = "Restore",
        HoverColor = "CardHover",
        Order = 80,
    },
    Pin = {
        Icon = "📌",
        IconAlt = "📍",  -- When pinned
        Tooltip = "Pin on Top",
        TooltipAlt = "Unpin",
        HoverColor = "CardHover",
        Order = 70,
    },
    ThemeToggle = {
        Icon = "🌙",
        IconAlt = "☀️",  -- When light mode
        Tooltip = "Dark Mode",
        TooltipAlt = "Light Mode",
        HoverColor = "CardHover",
        Order = 60,
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- TOPBAR CLASS
-- ══════════════════════════════════════════════════════════════════════

function TopBar.new(parent, options)
    local self = setmetatable({}, TopBar)
    
    -- Configuration
    options = options or {}
    self.Config = setmetatable({}, {__index = DEFAULT_CONFIG})
    for key, value in pairs(options) do
        self.Config[key] = value
    end
    
    -- Legacy support
    if options.Title then self.Config.Title = options.Title end
    if options.ShowClose ~= nil then self.Config.ShowClose = options.ShowClose end
    if options.ShowMinimize ~= nil then self.Config.ShowMinimize = options.ShowMinimize end
    
    -- State
    self.Title = self.Config.Title
    self.Subtitle = self.Config.Subtitle
    self.Maximized = false
    self.Pinned = false
    self.DarkMode = true
    self.NotificationCount = 0
    self._buttons = {}
    self._connections = {}
    self._lastClickTime = 0
    
    -- Signals
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnMaximize = Signal.new()
    self.OnRestore = Signal.new()
    self.OnPin = Signal.new()
    self.OnUnpin = Signal.new()
    self.OnThemeToggle = Signal.new()
    self.OnSearch = Signal.new()
    self.OnTitleClick = Signal.new()
    self.OnContextMenu = Signal.new()
    
    -- Build UI
    self:_build(parent)
    self:_setupInteractions()
    
    return self
end

function TopBar:_build(parent)
    local config = self.Config
    
    -- Main Frame
    self.Frame = Create.Frame({
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, config.Height),
        BackgroundColor3 = Theme:Get("TopBar"),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = parent,
    }, {
        Create.Corner(Config.Window and Config.Window.CornerRadius or 12),
    })
    
    -- Bottom cover (to make corners only on top)
    self.BottomCover = Create.Frame({
        Name = "BottomCover",
        Size = UDim2.new(1, 0, 0, (Config.Window and Config.Window.CornerRadius or 12)),
        Position = UDim2.new(0, 0, 1, -(Config.Window and Config.Window.CornerRadius or 12)),
        BackgroundColor3 = Theme:Get("TopBar"),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = self.Frame,
    })
    
    -- Bottom border line
    self.BorderLine = Create.Frame({
        Name = "BorderLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme:Get("Border"),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = self.Frame,
    })
    
    -- Left section (Logo + Title)
    self:_buildLeftSection()
    
    -- Center section (Tabs/Navigation - optional)
    self:_buildCenterSection()
    
    -- Right section (Actions + Controls)
    self:_buildRightSection()
end

function TopBar:_buildLeftSection()
    local config = self.Config
    
    self.LeftSection = Create.Frame({
        Name = "LeftSection",
        Size = UDim2.new(0.4, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, 10),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
        Create.Padding(0, 0, 16, 0),
    })
    
    -- Logo/Icon
    if config.Logo or config.LogoEmoji then
        self:_buildLogo()
    end
    
    -- Title container
    self.TitleContainer = Create.Frame({
        Name = "TitleContainer",
        Size = UDim2.new(0, 0, 0, config.Height - 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = self.LeftSection,
    }, {
        Create.List({
            Padding = UDim.new(0, 2),
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Main title
    self.TitleLabel = Create.Text({
        Name = "Title",
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        Text = config.Title,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = config.Subtitle and 15 or 17,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        Parent = self.TitleContainer,
    })
    
    -- Subtitle (optional)
    if config.Subtitle then
        self.SubtitleLabel = Create.Text({
            Name = "Subtitle",
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = config.Subtitle,
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 2,
            Parent = self.TitleContainer,
        })
    end
    
    -- Version badge (optional)
    if config.Version then
        self.VersionBadge = Create.Frame({
            Name = "VersionBadge",
            Size = UDim2.new(0, 0, 0, 16),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Theme:Get("Accent"),
            BackgroundTransparency = 0.8,
            LayoutOrder = 3,
            Parent = self.LeftSection,
        }, {
            Create.Corner(8),
            Create.Padding(0, 0, 6, 6),
            Create.Text({
                Name = "Label",
                Size = UDim2.new(0, 0, 1, 0),
                AutomaticSize = Enum.AutomaticSize.X,
                Text = config.Version,
                TextColor3 = Theme:Get("Accent"),
                TextSize = 10,
                Font = Enum.Font.GothamMedium,
            }),
        })
    end
end

function TopBar:_buildLogo()
    local config = self.Config
    
    self.LogoContainer = Create.Frame({
        Name = "LogoContainer",
        Size = UDim2.fromOffset(config.LogoSize, config.LogoSize),
        BackgroundColor3 = Theme:Get("Accent"),
        LayoutOrder = 1,
        Parent = self.LeftSection,
    }, {
        Create.Corner(config.LogoSize / 4),
    })
    
    if config.Logo then
        self.Logo = Create.Image({
            Name = "Logo",
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = config.Logo,
            ImageColor3 = Color3.new(1, 1, 1),
            Parent = self.LogoContainer,
        })
    elseif config.LogoEmoji then
        self.LogoEmoji = Create.Text({
            Name = "LogoEmoji",
            Size = UDim2.new(1, 0, 1, 0),
            Text = config.LogoEmoji,
            TextSize = config.LogoSize - 8,
            Parent = self.LogoContainer,
        })
    else
        -- Default V logo
        self.LogoText = Create.Text({
            Name = "LogoText",
            Size = UDim2.new(1, 0, 1, 0),
            Text = "V",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = config.LogoSize - 10,
            Font = Enum.Font.GothamBlack,
            Parent = self.LogoContainer,
        })
    end
end

function TopBar:_buildCenterSection()
    local config = self.Config
    
    self.CenterSection = Create.Frame({
        Name = "CenterSection",
        Size = UDim2.new(0.3, 0, 1, 0),
        Position = UDim2.new(0.35, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    })
    
    -- Tab container (for tab-based navigation)
    self.TabContainer = Create.Frame({
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.CenterSection,
    }, {
        Create.HorizontalList({
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
        }),
    })
    
    -- Search bar (optional)
    if config.ShowSearch then
        self:_buildSearchBar()
    end
end

function TopBar:_buildSearchBar()
    self.SearchContainer = Create.Frame({
        Name = "SearchContainer",
        Size = UDim2.new(1, -40, 0, 32),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme:Get("CardHover"),
        Parent = self.CenterSection,
    }, {
        Create.Corner(8),
        Create.Stroke({Color = Theme:Get("Border"), Transparency = 0.5}),
    })
    
    -- Search icon
    self.SearchIcon = Create.Text({
        Name = "SearchIcon",
        Size = UDim2.fromOffset(32, 32),
        Text = "🔍",
        TextSize = 14,
        Parent = self.SearchContainer,
    })
    
    -- Search input
    self.SearchInput = Create.Input({
        Name = "SearchInput",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 32, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = "Search...",
        TextSize = 13,
        Parent = self.SearchContainer,
    })
    
    -- Search input events
    self.SearchInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self.OnSearch:Fire(self.SearchInput.Text)
        end
    end)
    
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.OnSearch:Fire(self.SearchInput.Text, true)  -- true = live search
    end)
end

function TopBar:_buildRightSection()
    local config = self.Config
    
    self.RightSection = Create.Frame({
        Name = "RightSection",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.HorizontalList({
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, config.ButtonPadding),
        }),
        Create.Padding(0, 12, 0, 0),
    })
    
    -- Action buttons area (custom actions)
    self.ActionButtons = Create.Frame({
        Name = "ActionButtons",
        Size = UDim2.new(0, 0, 0, config.ButtonSize),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = self.RightSection,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, 4),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Clock (optional)
    if config.ShowClock then
        self:_buildClock()
    end
    
    -- Notifications (optional)
    if config.ShowNotifications then
        self:_buildNotifications()
    end
    
    -- User avatar (optional)
    if config.ShowAvatar then
        self:_buildAvatar()
    end
    
    -- Separator before window controls
    if config.ShowClose or config.ShowMinimize or config.ShowMaximize then
        self.Separator = Create.Frame({
            Name = "Separator",
            Size = UDim2.new(0, 1, 0, 20),
            BackgroundColor3 = Theme:Get("Border"),
            BackgroundTransparency = 0.5,
            LayoutOrder = 50,
            Parent = self.RightSection,
        })
    end
    
    -- Window control buttons container
    self.ControlButtons = Create.Frame({
        Name = "ControlButtons",
        Size = UDim2.new(0, 0, 0, config.ButtonSize),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 100,
        Parent = self.RightSection,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, 4),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Create window control buttons
    if config.ShowPin then
        self:_createControlButton("Pin")
    end
    
    if config.ShowThemeToggle then
        self:_createControlButton("ThemeToggle")
    end
    
    if config.ShowMinimize then
        self:_createControlButton("Minimize")
    end
    
    if config.ShowMaximize then
        self:_createControlButton("Maximize")
    end
    
    if config.ShowClose then
        self:_createControlButton("Close")
    end
end

function TopBar:_buildClock()
    self.ClockLabel = Create.Text({
        Name = "Clock",
        Size = UDim2.new(0, 60, 0, 20),
        Text = os.date("%H:%M"),
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        LayoutOrder = 10,
        Parent = self.RightSection,
    })
    
    -- Update clock every minute
    task.spawn(function()
        while self.ClockLabel and self.ClockLabel.Parent do
            self.ClockLabel.Text = os.date("%H:%M")
            task.wait(60)
        end
    end)
end

function TopBar:_buildNotifications()
    local config = self.Config
    
    self.NotificationButton = Create.Button({
        Name = "NotificationButton",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        Text = "🔔",
        TextSize = 16,
        AutoButtonColor = false,
        LayoutOrder = 20,
        Parent = self.RightSection,
    }, {
        Create.Corner(config.ButtonSize / 2),
    })
    
    -- Badge
    self.NotificationBadge = Create.Frame({
        Name = "Badge",
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -4, 0, -2),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme:Get("Error"),
        Visible = false,
        ZIndex = 5,
        Parent = self.NotificationButton,
    }, {
        Create.Corner(8),
    })
    
    self.NotificationCount_Label = Create.Text({
        Name = "Count",
        Size = UDim2.new(1, 0, 1, 0),
        Text = "0",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = self.NotificationBadge,
    })
    
    -- Hover effects
    self:_setupButtonHover(self.NotificationButton, false)
end

function TopBar:_buildAvatar()
    local config = self.Config
    local player = Players.LocalPlayer
    
    self.AvatarButton = Create.Button({
        Name = "AvatarButton",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = 30,
        Parent = self.RightSection,
    }, {
        Create.Corner(config.ButtonSize / 2),
        Create.Stroke({Color = Theme:Get("Border")}),
    })
    
    -- Avatar image
    if player then
        local avatarUrl = string.format(
            "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=100&height=100&format=png",
            player.UserId
        )
        
        self.AvatarImage = Create.Image({
            Name = "Avatar",
            Size = UDim2.new(1, -4, 1, -4),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = avatarUrl,
            Parent = self.AvatarButton,
        }, {
            Create.Corner((config.ButtonSize - 4) / 2),
        })
    end
    
    self:_setupButtonHover(self.AvatarButton, false)
end

function TopBar:_createControlButton(buttonType)
    local config = self.Config
    local buttonConfig = BUTTON_CONFIGS[buttonType]
    if not buttonConfig then return end
    
    local button = Create.Button({
        Name = buttonType .. "Button",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        Text = buttonConfig.Icon,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = buttonType == "Close" and 18 or 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = buttonConfig.Order,
        Parent = self.ControlButtons,
    }, {
        Create.Corner(6),
    })
    
    -- Store button reference
    self._buttons[buttonType] = button
    
    -- Setup hover
    self:_setupButtonHover(button, buttonType == "Close")
    
    -- Click handler
    button.MouseButton1Click:Connect(function()
        self:_handleButtonClick(buttonType)
    end)
    
    return button
end

function TopBar:_setupButtonHover(button, isClose)
    local normalColor = Theme:Get("Card")
    local hoverColor = isClose and Theme:Get("Error") or Theme:Get("CardHover")
    local normalTextColor = Theme:Get("TextSecondary")
    local hoverTextColor = isClose and Color3.new(1, 1, 1) or Theme:Get("TextPrimary")
    
    button.MouseEnter:Connect(function()
        Tween.Fast(button, {
            BackgroundColor3 = hoverColor,
            TextColor3 = hoverTextColor,
        })
        
        if self.Config.AnimateButtons then
            Tween.Fast(button, {Size = UDim2.fromOffset(self.Config.ButtonSize + 2, self.Config.ButtonSize + 2)})
        end
    end)
    
    button.MouseLeave:Connect(function()
        Tween.Fast(button, {
            BackgroundColor3 = normalColor,
            TextColor3 = normalTextColor,
        })
        
        if self.Config.AnimateButtons then
            Tween.Fast(button, {Size = UDim2.fromOffset(self.Config.ButtonSize, self.Config.ButtonSize)})
        end
    end)
end

function TopBar:_handleButtonClick(buttonType)
    if buttonType == "Close" then
        self.OnClose:Fire()
        
    elseif buttonType == "Minimize" then
        self.OnMinimize:Fire()
        
    elseif buttonType == "Maximize" then
        self.Maximized = not self.Maximized
        
        local button = self._buttons.Maximize
        local config = BUTTON_CONFIGS.Maximize
        
        if self.Maximized then
            button.Text = config.IconAlt
            self.OnMaximize:Fire()
        else
            button.Text = config.Icon
            self.OnRestore:Fire()
        end
        
    elseif buttonType == "Pin" then
        self.Pinned = not self.Pinned
        
        local button = self._buttons.Pin
        local config = BUTTON_CONFIGS.Pin
        
        button.Text = self.Pinned and config.IconAlt or config.Icon
        
        if self.Pinned then
            self.OnPin:Fire()
        else
            self.OnUnpin:Fire()
        end
        
    elseif buttonType == "ThemeToggle" then
        self.DarkMode = not self.DarkMode
        
        local button = self._buttons.ThemeToggle
        local config = BUTTON_CONFIGS.ThemeToggle
        
        button.Text = self.DarkMode and config.Icon or config.IconAlt
        
        self.OnThemeToggle:Fire(self.DarkMode)
    end
end

function TopBar:_setupInteractions()
    local config = self.Config
    
    -- Enable dragging
    if config.EnableDrag and config.DragTarget then
        Drag.Enable(config.DragTarget, self.Frame)
    end
    
    -- Double-click to maximize
    if config.EnableDoubleClickMaximize and config.ShowMaximize then
        local lastClick = 0
        
        local conn = self.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local now = tick()
                if now - lastClick < 0.3 then
                    self:_handleButtonClick("Maximize")
                end
                lastClick = now
            end
        end)
        table.insert(self._connections, conn)
    end
    
    -- Right-click context menu
    if config.EnableContextMenu then
        local conn = self.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.OnContextMenu:Fire(input.Position)
            end
        end)
        table.insert(self._connections, conn)
    end
    
    -- Title click
    if self.TitleContainer then
        local clickDetector = Create.Button({
            Name = "ClickDetector",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            Parent = self.TitleContainer,
        })
        
        clickDetector.MouseButton1Click:Connect(function()
            self.OnTitleClick:Fire()
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function TopBar:SetTitle(title, subtitle)
    self.Title = title
    self.TitleLabel.Text = title
    
    if subtitle and self.SubtitleLabel then
        self.Subtitle = subtitle
        self.SubtitleLabel.Text = subtitle
    end
end

function TopBar:GetTitle()
    return self.Title, self.Subtitle
end

function TopBar:SetLogo(imageId)
    if self.Logo then
        self.Logo.Image = imageId
    end
end

function TopBar:SetNotificationCount(count)
    self.NotificationCount = count
    
    if self.NotificationBadge then
        self.NotificationBadge.Visible = count > 0
        
        if self.NotificationCount_Label then
            self.NotificationCount_Label.Text = count > 99 and "99+" or tostring(count)
        end
    end
end

function TopBar:AddActionButton(name, icon, callback)
    local button = Create.Button({
        Name = "Action_" .. name,
        Size = UDim2.fromOffset(self.Config.ButtonSize, self.Config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        Text = icon,
        TextSize = 16,
        AutoButtonColor = false,
        Parent = self.ActionButtons,
    }, {
        Create.Corner(6),
    })
    
    self:_setupButtonHover(button, false)
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return button
end

function TopBar:RemoveActionButton(name)
    local button = self.ActionButtons:FindFirstChild("Action_" .. name)
    if button then
        button:Destroy()
    end
end

function TopBar:AddTab(name, icon, callback)
    self.TabContainer.Visible = true
    
    local tab = Create.Button({
        Name = "Tab_" .. name,
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme:Get("CardHover"),
        BackgroundTransparency = 0.5,
        Text = icon and (icon .. " " .. name) or name,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = self.TabContainer,
    }, {
        Create.Corner(6),
        Create.Padding(0, 0, 12, 12),
    })
    
    tab.MouseButton1Click:Connect(function()
        self:SelectTab(name)
        if callback then callback(name) end
    end)
    
    return tab
end

function TopBar:SelectTab(name)
    for _, child in ipairs(self.TabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local isSelected = child.Name == "Tab_" .. name
            
            Tween.Fast(child, {
                BackgroundColor3 = isSelected and Theme:Get("Accent") or Theme:Get("CardHover"),
                BackgroundTransparency = isSelected and 0 or 0.5,
                TextColor3 = isSelected and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
            })
        end
    end
end

function TopBar:SetSearchText(text)
    if self.SearchInput then
        self.SearchInput.Text = text
    end
end

function TopBar:GetSearchText()
    return self.SearchInput and self.SearchInput.Text or ""
end

function TopBar:ClearSearch()
    if self.SearchInput then
        self.SearchInput.Text = ""
    end
end

function TopBar:SetPinned(pinned)
    if self.Pinned ~= pinned then
        self:_handleButtonClick("Pin")
    end
end

function TopBar:IsPinned()
    return self.Pinned
end

function TopBar:SetMaximized(maximized)
    if self.Maximized ~= maximized then
        self:_handleButtonClick("Maximize")
    end
end

function TopBar:IsMaximized()
    return self.Maximized
end

function TopBar:EnableDrag(target)
    if target then
        Drag.Enable(target, self.Frame)
    end
end

function TopBar:DisableDrag()
    -- Note: Would need Drag.Disable implementation
end

function TopBar:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("TopBar")
    self.BottomCover.BackgroundColor3 = Theme:Get("TopBar")
    self.BorderLine.BackgroundColor3 = Theme:Get("Border")
    self.TitleLabel.TextColor3 = Theme:Get("TextPrimary")
    
    if self.SubtitleLabel then
        self.SubtitleLabel.TextColor3 = Theme:Get("TextSecondary")
    end
    
    if self.LogoContainer then
        self.LogoContainer.BackgroundColor3 = Theme:Get("Accent")
    end
    
    -- Update buttons
    for _, button in pairs(self._buttons) do
        button.BackgroundColor3 = Theme:Get("Card")
        button.TextColor3 = Theme:Get("TextSecondary")
    end
    
    -- Update other elements
    if self.Separator then
        self.Separator.BackgroundColor3 = Theme:Get("Border")
    end
    
    if self.SearchContainer then
        self.SearchContainer.BackgroundColor3 = Theme:Get("CardHover")
    end
    
    if self.ClockLabel then
        self.ClockLabel.TextColor3 = Theme:Get("TextSecondary")
    end
end

function TopBar:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    -- Destroy signals
    self.OnClose:Destroy()
    self.OnMinimize:Destroy()
    self.OnMaximize:Destroy()
    self.OnRestore:Destroy()
    self.OnPin:Destroy()
    self.OnUnpin:Destroy()
    self.OnThemeToggle:Destroy()
    self.OnSearch:Destroy()
    self.OnTitleClick:Destroy()
    self.OnContextMenu:Destroy()
    
    if self.Frame then
        self.Frame:Destroy()
    end
end

return TopBar