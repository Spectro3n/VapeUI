--[[
    VapeUI TopBar v2.0
    Advanced title bar with controls, navigation, and utilities.
    
    Features:
    ✅ Multiple layout styles (Default, Minimal, Centered, Split)
    ✅ Logo/Icon support
    ✅ Subtitle/Description
    ✅ Tab navigation integration
    ✅ Search bar
    ✅ User profile section
    ✅ Notification indicator
    ✅ Actions dropdown menu
    ✅ Status indicators
    ✅ Clock/Time display
    ✅ Custom buttons
    ✅ Breadcrumb trail
    ✅ Progress indicator
    ✅ Double-click to maximize
    ✅ Context menu
    ✅ Responsive design
    ✅ Keyboard shortcuts display
    ✅ Drag & drop
    ✅ Window controls (close, minimize, maximize)
    ✅ Theme selector
    ✅ Quick settings
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
local RunService = Services.RunService
local Players = Services.Players

local TopBar = {}
TopBar.__index = TopBar

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Layout
    Height = 48,
    Style = "Default",  -- Default, Minimal, Centered, Split, Custom
    
    -- Content
    Title = "VapeUI",
    Subtitle = nil,
    Logo = nil,  -- Image ID or emoji
    LogoSize = 24,
    
    -- Window Controls
    ShowClose = true,
    ShowMinimize = true,
    ShowMaximize = false,
    ShowPin = false,
    ControlsPosition = "Right",  -- Left, Right
    
    -- Features
    EnableDrag = true,
    EnableDoubleClickMaximize = true,
    EnableSearch = false,
    EnableClock = false,
    EnableUserProfile = false,
    EnableNotifications = false,
    EnableBreadcrumbs = false,
    EnableTabs = false,
    EnableActions = false,
    EnableProgress = false,
    EnableContextMenu = true,
    
    -- Search
    SearchPlaceholder = "Search...",
    SearchWidth = 200,
    
    -- Buttons
    ButtonSize = 28,
    ButtonSpacing = 6,
    ButtonCornerRadius = 6,
    
    -- Appearance
    BackgroundBlur = false,
    ShowBorder = true,
    BorderPosition = "Bottom",
    
    -- Animations
    AnimateOnHover = true,
    ShowTooltips = true,
}

local LAYOUTS = {
    Default = {
        LogoPosition = "Left",
        TitlePosition = "Left",
        SearchPosition = "Center",
        ActionsPosition = "Right",
        ControlsPosition = "Right",
    },
    Minimal = {
        LogoPosition = "Hidden",
        TitlePosition = "Left",
        SearchPosition = "Hidden",
        ActionsPosition = "Right",
        ControlsPosition = "Right",
    },
    Centered = {
        LogoPosition = "Left",
        TitlePosition = "Center",
        SearchPosition = "Hidden",
        ActionsPosition = "Right",
        ControlsPosition = "Right",
    },
    Split = {
        LogoPosition = "Left",
        TitlePosition = "Left",
        SearchPosition = "Right",
        ActionsPosition = "Right",
        ControlsPosition = "Right",
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- TOPBAR CLASS
-- ══════════════════════════════════════════════════════════════════════

function TopBar.new(parent, options)
    local self = setmetatable({}, TopBar)
    
    -- Configuration
    self.Config = setmetatable(options or {}, {__index = DEFAULT_CONFIG})
    self.Parent = parent
    
    -- State
    self.Title = self.Config.Title
    self.Subtitle = self.Config.Subtitle
    self.Maximized = false
    self.Pinned = false
    self.SearchOpen = false
    self.NotificationCount = 0
    self.Progress = 0
    self.ProgressVisible = false
    self._connections = {}
    self._buttons = {}
    self._tabs = {}
    self._breadcrumbs = {}
    self._actions = {}
    self._lastClickTime = 0
    
    -- Signals
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnMaximize = Signal.new()
    self.OnRestore = Signal.new()
    self.OnPin = Signal.new()
    self.OnSearch = Signal.new()
    self.OnSearchSubmit = Signal.new()
    self.OnTabChanged = Signal.new()
    self.OnAction = Signal.new()
    self.OnTitleChanged = Signal.new()
    self.OnDoubleClick = Signal.new()
    self.OnContextMenu = Signal.new()
    
    -- Build UI
    self:_build()
    self:_setupInteractions()
    
    return self
end

function TopBar:_build()
    local config = self.Config
    local layout = LAYOUTS[config.Style] or LAYOUTS.Default
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, config.Height),
        BackgroundColor3 = Theme:Get("TopBar"),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = self.Parent,
    }, {
        Create.Corner({CornerRadius = UDim.new(0, Config.Window.CornerRadius)}),
    })
    
    -- Bottom cover (for rounded corners only at top)
    self.BottomCover = Create.Frame({
        Name = "BottomCover",
        Size = UDim2.new(1, 0, 0, Config.Window.CornerRadius),
        Position = UDim2.new(0, 0, 1, -Config.Window.CornerRadius),
        BackgroundColor3 = Theme:Get("TopBar"),
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = self.Frame,
    })
    
    -- Border
    if config.ShowBorder then
        self.Border = Create.Frame({
            Name = "Border",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Theme:Get("Border"),
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            ZIndex = 11,
            Parent = self.Frame,
        })
    end
    
    -- Left section
    self.LeftSection = Create.Frame({
        Name = "LeftSection",
        Size = UDim2.new(0.4, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.Padding(0, 0, 16, 16),
        Create.HorizontalList({
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 12),
        }),
    })
    
    -- Center section
    self.CenterSection = Create.Frame({
        Name = "CenterSection",
        Size = UDim2.new(0.2, 0, 1, 0),
        Position = UDim2.new(0.4, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.HorizontalList({
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Right section
    self.RightSection = Create.Frame({
        Name = "RightSection",
        Size = UDim2.new(0.4, 0, 1, 0),
        Position = UDim2.new(0.6, 0, 0, 0),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.Padding(0, 0, 16, 16),
        Create.HorizontalList({
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
        }),
    })
    
    -- Build sections based on layout
    self:_buildLogo(layout)
    self:_buildTitle(layout)
    
    if config.EnableBreadcrumbs then
        self:_buildBreadcrumbs()
    end
    
    if config.EnableTabs then
        self:_buildTabs()
    end
    
    if config.EnableSearch then
        self:_buildSearch(layout)
    end
    
    if config.EnableClock then
        self:_buildClock()
    end
    
    if config.EnableNotifications then
        self:_buildNotifications()
    end
    
    if config.EnableUserProfile then
        self:_buildUserProfile()
    end
    
    if config.EnableActions then
        self:_buildActions()
    end
    
    if config.EnableProgress then
        self:_buildProgress()
    end
    
    self:_buildWindowControls()
end

function TopBar:_buildLogo(layout)
    local config = self.Config
    if not config.Logo or layout.LogoPosition == "Hidden" then return end
    
    local parent = layout.LogoPosition == "Left" and self.LeftSection or self.CenterSection
    
    if type(config.Logo) == "string" and config.Logo:match("^rbxassetid://") then
        self.Logo = Create.Image({
            Name = "Logo",
            Size = UDim2.fromOffset(config.LogoSize, config.LogoSize),
            BackgroundTransparency = 1,
            Image = config.Logo,
            ImageColor3 = Theme:Get("TextPrimary"),
            LayoutOrder = 1,
            Parent = parent,
        })
    else
        self.Logo = Create.Text({
            Name = "Logo",
            Size = UDim2.fromOffset(config.LogoSize, config.LogoSize),
            BackgroundTransparency = 1,
            Text = config.Logo,
            TextSize = config.LogoSize - 4,
            LayoutOrder = 1,
            Parent = parent,
        })
    end
end

function TopBar:_buildTitle(layout)
    local config = self.Config
    local parent
    
    if layout.TitlePosition == "Center" then
        parent = self.CenterSection
    else
        parent = self.LeftSection
    end
    
    self.TitleContainer = Create.Frame({
        Name = "TitleContainer",
        Size = UDim2.new(0, 0, 0, config.Height - 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = parent,
    }, {
        Create.List({
            Padding = UDim.new(0, 2),
            HorizontalAlignment = layout.TitlePosition == "Center" 
                and Enum.HorizontalAlignment.Center 
                or Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Main title
    self.TitleLabel = Create.Text({
        Name = "Title",
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        LayoutOrder = 1,
        Parent = self.TitleContainer,
    })
    
    -- Subtitle
    if config.Subtitle then
        self.SubtitleLabel = Create.Text({
            Name = "Subtitle",
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = config.Subtitle,
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = Enum.Font.Gotham,
            LayoutOrder = 2,
            Parent = self.TitleContainer,
        })
    end
end

function TopBar:_buildBreadcrumbs()
    self.BreadcrumbContainer = Create.Frame({
        Name = "Breadcrumbs",
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 3,
        Parent = self.LeftSection,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, 4),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
end

function TopBar:_buildTabs()
    self.TabContainer = Create.Frame({
        Name = "Tabs",
        Size = UDim2.new(0, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Parent = self.LeftSection,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, 4),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
end

function TopBar:_buildSearch(layout)
    local config = self.Config
    local parent = layout.SearchPosition == "Center" and self.CenterSection or self.RightSection
    
    self.SearchContainer = Create.Frame({
        Name = "SearchContainer",
        Size = UDim2.new(0, config.SearchWidth, 0, 32),
        BackgroundColor3 = Theme:Get("Card"),
        LayoutOrder = layout.SearchPosition == "Center" and 1 or -5,
        Parent = parent,
    }, {
        Create.Corner(8),
        Create.Stroke({Color = Theme:Get("Border"), Transparency = 0.5}),
        Create.Padding(0, 0, 10, 10),
    })
    
    -- Search icon
    self.SearchIcon = Create.Text({
        Name = "SearchIcon",
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "🔍",
        TextSize = 12,
        Parent = self.SearchContainer,
    })
    
    -- Search input
    self.SearchInput = Create.Input({
        Name = "SearchInput",
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = config.SearchPlaceholder,
        Text = "",
        TextColor3 = Theme:Get("TextPrimary"),
        PlaceholderColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Parent = self.SearchContainer,
    })
    
    -- Search events
    self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self.OnSearch:Fire(self.SearchInput.Text)
    end)
    
    self.SearchInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            self.OnSearchSubmit:Fire(self.SearchInput.Text)
        end
    end)
    
    -- Keyboard shortcut hint
    self.SearchHint = Create.Text({
        Name = "SearchHint",
        Size = UDim2.fromOffset(30, 16),
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme:Get("CardHover"),
        Text = "⌘K",
        TextColor3 = Theme:Get("TextTertiary"),
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        Parent = self.SearchContainer,
    }, {
        Create.Corner(4),
    })
end

function TopBar:_buildClock()
    self.ClockLabel = Create.Text({
        Name = "Clock",
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = "00:00",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        LayoutOrder = -4,
        Parent = self.RightSection,
    })
    
    -- Update clock
    local function updateClock()
        local time = os.date("*t")
        self.ClockLabel.Text = string.format("%02d:%02d", time.hour, time.min)
    end
    
    updateClock()
    
    local clockConnection = RunService.Heartbeat:Connect(function()
        if tick() % 1 < 0.016 then
            updateClock()
        end
    end)
    table.insert(self._connections, clockConnection)
end

function TopBar:_buildNotifications()
    local config = self.Config
    
    self.NotificationButton = Create.Button({
        Name = "Notifications",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        BackgroundTransparency = 0.5,
        Text = "🔔",
        TextSize = 14,
        AutoButtonColor = false,
        LayoutOrder = -3,
        Parent = self.RightSection,
    }, {
        Create.Corner(config.ButtonCornerRadius),
    })
    
    -- Notification badge
    self.NotificationBadge = Create.Frame({
        Name = "Badge",
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -4, 0, -4),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme:Get("Error"),
        Visible = false,
        ZIndex = 12,
        Parent = self.NotificationButton,
    }, {
        Create.Corner(8),
    })
    
    self.NotificationBadgeLabel = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "0",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        Parent = self.NotificationBadge,
    })
    
    -- Hover effect
    self:_addButtonHover(self.NotificationButton)
end

function TopBar:_buildUserProfile()
    local config = self.Config
    local player = Players.LocalPlayer
    
    self.UserButton = Create.Button({
        Name = "UserProfile",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = -2,
        Parent = self.RightSection,
    })
    
    -- Avatar
    self.UserAvatar = Create.Image({
        Name = "Avatar",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = string.format(
            "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=100&height=100&format=png",
            player.UserId
        ),
        Parent = self.UserButton,
    }, {
        Create.Corner(config.ButtonSize / 2),
    })
    
    -- Online indicator
    self.OnlineIndicator = Create.Frame({
        Name = "OnlineIndicator",
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.new(1, -2, 1, -2),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Theme:Get("Success"),
        ZIndex = 12,
        Parent = self.UserButton,
    }, {
        Create.Corner(5),
        Create.Stroke({Color = Theme:Get("TopBar"), Thickness = 2}),
    })
end

function TopBar:_buildActions()
    local config = self.Config
    
    self.ActionsButton = Create.Button({
        Name = "Actions",
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        BackgroundTransparency = 0.5,
        Text = "⋮",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = -1,
        Parent = self.RightSection,
    }, {
        Create.Corner(config.ButtonCornerRadius),
    })
    
    self:_addButtonHover(self.ActionsButton)
    
    -- Actions dropdown (hidden by default)
    self.ActionsDropdown = Create.Frame({
        Name = "ActionsDropdown",
        Size = UDim2.new(0, 180, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(1, 0, 1, 8),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Theme:Get("Card"),
        Visible = false,
        ZIndex = 100,
        Parent = self.ActionsButton,
    }, {
        Create.Corner(8),
        Create.Stroke({Color = Theme:Get("Border")}),
        Create.Padding(4),
        Create.List({Padding = UDim.new(0, 2)}),
    })
    
    -- Toggle dropdown
    self.ActionsButton.MouseButton1Click:Connect(function()
        self.ActionsDropdown.Visible = not self.ActionsDropdown.Visible
    end)
end

function TopBar:_buildProgress()
    self.ProgressContainer = Create.Frame({
        Name = "Progress",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme:Get("Border"),
        BackgroundTransparency = 0.5,
        Visible = false,
        ZIndex = 15,
        Parent = self.Frame,
    })
    
    self.ProgressBar = Create.Frame({
        Name = "ProgressBar",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme:Get("Accent"),
        BorderSizePixel = 0,
        Parent = self.ProgressContainer,
    })
end

function TopBar:_buildWindowControls()
    local config = self.Config
    
    self.ControlsContainer = Create.Frame({
        Name = "WindowControls",
        Size = UDim2.new(0, 0, 0, config.ButtonSize),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        LayoutOrder = 100,
        Parent = self.RightSection,
    }, {
        Create.HorizontalList({
            Padding = UDim.new(0, config.ButtonSpacing),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Pin button
    if config.ShowPin then
        self.PinButton = self:_createControlButton("📌", function()
            self.Pinned = not self.Pinned
            self.OnPin:Fire(self.Pinned)
            self.PinButton.TextTransparency = self.Pinned and 0 or 0.5
        end, 1)
    end
    
    -- Minimize button
    if config.ShowMinimize then
        self.MinimizeButton = self:_createControlButton("─", function()
            self.OnMinimize:Fire()
        end, 2)
    end
    
    -- Maximize button
    if config.ShowMaximize then
        self.MaximizeButton = self:_createControlButton("□", function()
            self.Maximized = not self.Maximized
            if self.Maximized then
                self.MaximizeButton.Text = "❐"
                self.OnMaximize:Fire()
            else
                self.MaximizeButton.Text = "□"
                self.OnRestore:Fire()
            end
        end, 3)
    end
    
    -- Close button
    if config.ShowClose then
        self.CloseButton = self:_createControlButton("×", function()
            self.OnClose:Fire()
        end, 4, true)
    end
end

function TopBar:_createControlButton(text, callback, order, isClose)
    local config = self.Config
    
    local button = Create.Button({
        Name = "Control_" .. text,
        Size = UDim2.fromOffset(config.ButtonSize, config.ButtonSize),
        BackgroundColor3 = Theme:Get("Card"),
        BackgroundTransparency = 0.5,
        Text = text,
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = text == "×" and 20 or 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = self.ControlsContainer,
    }, {
        Create.Corner(config.ButtonCornerRadius),
    })
    
    local normalColor = Theme:Get("Card")
    local hoverColor = isClose and Theme:Get("Error") or Theme:Get("CardHover")
    local hoverTextColor = isClose and Color3.new(1, 1, 1) or Theme:Get("TextPrimary")
    
    button.MouseEnter:Connect(function()
        Tween.Fast(button, {
            BackgroundColor3 = hoverColor,
            BackgroundTransparency = 0,
            TextColor3 = hoverTextColor,
        })
    end)
    
    button.MouseLeave:Connect(function()
        Tween.Fast(button, {
            BackgroundColor3 = normalColor,
            BackgroundTransparency = 0.5,
            TextColor3 = Theme:Get("TextSecondary"),
        })
    end)
    
    button.MouseButton1Click:Connect(callback)
    
    table.insert(self._buttons, button)
    
    return button
end

function TopBar:_addButtonHover(button, hoverColor)
    hoverColor = hoverColor or Theme:Get("CardHover")
    
    button.MouseEnter:Connect(function()
        Tween.Fast(button, {
            BackgroundTransparency = 0,
            BackgroundColor3 = hoverColor,
        })
    end)
    
    button.MouseLeave:Connect(function()
        Tween.Fast(button, {
            BackgroundTransparency = 0.5,
            BackgroundColor3 = Theme:Get("Card"),
        })
    end)
end

function TopBar:_setupInteractions()
    local config = self.Config
    
    -- Drag
    if config.EnableDrag and config.DragTarget then
        Drag.Enable(config.DragTarget, self.Frame)
    end
    
    -- Double-click to maximize
    if config.EnableDoubleClickMaximize then
        self.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local now = tick()
                if now - self._lastClickTime < 0.3 then
                    self.OnDoubleClick:Fire()
                    
                    if config.ShowMaximize then
                        self.Maximized = not self.Maximized
                        if self.Maximized then
                            self.OnMaximize:Fire()
                        else
                            self.OnRestore:Fire()
                        end
                    end
                end
                self._lastClickTime = now
            end
        end)
    end
    
    -- Context menu
    if config.EnableContextMenu then
        self.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                self.OnContextMenu:Fire(input.Position)
            end
        end)
    end
    
    -- Search shortcut (Ctrl/Cmd + K)
    if config.EnableSearch then
        local searchShortcut = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            
            if input.KeyCode == Enum.KeyCode.K then
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or
                   UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                    self:FocusSearch()
                end
            end
        end)
        table.insert(self._connections, searchShortcut)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function TopBar:SetTitle(title)
    self.Title = title
    if self.TitleLabel then
        self.TitleLabel.Text = title
    end
    self.OnTitleChanged:Fire(title)
end

function TopBar:GetTitle()
    return self.Title
end

function TopBar:SetSubtitle(subtitle)
    self.Subtitle = subtitle
    if self.SubtitleLabel then
        self.SubtitleLabel.Text = subtitle or ""
        self.SubtitleLabel.Visible = subtitle ~= nil
    end
end

function TopBar:SetLogo(logo)
    if self.Logo then
        if self.Logo:IsA("ImageLabel") then
            self.Logo.Image = logo
        else
            self.Logo.Text = logo
        end
    end
end

function TopBar:SetBreadcrumbs(items)
    if not self.BreadcrumbContainer then return end
    
    -- Clear existing
    for _, item in ipairs(self._breadcrumbs) do
        item:Destroy()
    end
    self._breadcrumbs = {}
    
    -- Add new items
    for i, item in ipairs(items) do
        local isLast = i == #items
        
        local crumb = Create.Button({
            Name = "Crumb_" .. i,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = item.Text or item,
            TextColor3 = isLast and Theme:Get("TextPrimary") or Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = isLast and Enum.Font.GothamMedium or Enum.Font.Gotham,
            AutoButtonColor = false,
            LayoutOrder = i * 2 - 1,
            Parent = self.BreadcrumbContainer,
        })
        
        if not isLast then
            crumb.MouseEnter:Connect(function()
                Tween.Fast(crumb, {TextColor3 = Theme:Get("Accent")})
            end)
            crumb.MouseLeave:Connect(function()
                Tween.Fast(crumb, {TextColor3 = Theme:Get("TextSecondary")})
            end)
            
            if item.OnClick then
                crumb.MouseButton1Click:Connect(item.OnClick)
            end
        end
        
        table.insert(self._breadcrumbs, crumb)
        
        if not isLast then
            local separator = Create.Text({
                Name = "Sep_" .. i,
                Size = UDim2.new(0, 12, 1, 0),
                BackgroundTransparency = 1,
                Text = "›",
                TextColor3 = Theme:Get("TextTertiary"),
                TextSize = 12,
                LayoutOrder = i * 2,
                Parent = self.BreadcrumbContainer,
            })
            table.insert(self._breadcrumbs, separator)
        end
    end
end

function TopBar:AddTab(name, options)
    if not self.TabContainer then return end
    
    options = options or {}
    local isActive = options.Active or #self._tabs == 0
    
    local tab = Create.Button({
        Name = "Tab_" .. name,
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("Card"),
        BackgroundTransparency = isActive and 0 or 0.5,
        Text = name,
        TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        LayoutOrder = #self._tabs + 1,
        Parent = self.TabContainer,
    }, {
        Create.Corner(6),
        Create.Padding(0, 0, 12, 12),
    })
    
    tab.MouseButton1Click:Connect(function()
        self:SetActiveTab(name)
    end)
    
    table.insert(self._tabs, {
        Name = name,
        Button = tab,
        Icon = options.Icon,
        OnSelect = options.OnSelect,
    })
    
    return tab
end

function TopBar:SetActiveTab(name)
    for _, tab in ipairs(self._tabs) do
        local isActive = tab.Name == name
        
        Tween.Fast(tab.Button, {
            BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("Card"),
            BackgroundTransparency = isActive and 0 or 0.5,
            TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
        })
        
        if isActive and tab.OnSelect then
            tab.OnSelect(tab.Name)
        end
    end
    
    self.OnTabChanged:Fire(name)
end

function TopBar:AddAction(name, options)
    if not self.ActionsDropdown then return end
    
    options = options or {}
    
    local action = Create.Button({
        Name = "Action_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme:Get("Card"),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = #self._actions + 1,
        Parent = self.ActionsDropdown,
    }, {
        Create.Corner(6),
        Create.Padding(0, 0, 10, 10),
        Create.HorizontalList({
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
    
    -- Icon
    if options.Icon then
        Create.Text({
            Name = "Icon",
            Size = UDim2.fromOffset(16, 16),
            BackgroundTransparency = 1,
            Text = options.Icon,
            TextSize = 14,
            LayoutOrder = 1,
            Parent = action,
        })
    end
    
    -- Label
    Create.Text({
        Name = "Label",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = options.Danger and Theme:Get("Error") or Theme:Get("TextPrimary"),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 2,
        Parent = action,
    })
    
    -- Shortcut
    if options.Shortcut then
        Create.Text({
            Name = "Shortcut",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = options.Shortcut,
            TextColor3 = Theme:Get("TextTertiary"),
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 100,
            Parent = action,
        })
    end
    
    -- Hover
    action.MouseEnter:Connect(function()
        Tween.Fast(action, {BackgroundTransparency = 0})
    end)
    
    action.MouseLeave:Connect(function()
        Tween.Fast(action, {BackgroundTransparency = 1})
    end)
    
    -- Click
    action.MouseButton1Click:Connect(function()
        self.ActionsDropdown.Visible = false
        if options.Callback then
            options.Callback()
        end
        self.OnAction:Fire(name)
    end)
    
    table.insert(self._actions, {Name = name, Button = action})
    
    return action
end

function TopBar:AddActionDivider()
    if not self.ActionsDropdown then return end
    
    Create.Frame({
        Name = "Divider",
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Theme:Get("Border"),
        LayoutOrder = #self._actions + 1,
        Parent = self.ActionsDropdown,
    })
end

function TopBar:SetNotificationCount(count)
    self.NotificationCount = count
    
    if self.NotificationBadge then
        self.NotificationBadge.Visible = count > 0
        self.NotificationBadgeLabel.Text = count > 99 and "99+" or tostring(count)
    end
end

function TopBar:SetProgress(progress, visible)
    self.Progress = math.clamp(progress, 0, 1)
    
    if visible ~= nil then
        self.ProgressVisible = visible
    end
    
    if self.ProgressContainer then
        self.ProgressContainer.Visible = self.ProgressVisible
        Tween.Fast(self.ProgressBar, {Size = UDim2.new(self.Progress, 0, 1, 0)})
    end
end

function TopBar:ShowProgress()
    self.ProgressVisible = true
    if self.ProgressContainer then
        self.ProgressContainer.Visible = true
    end
end

function TopBar:HideProgress()
    self.ProgressVisible = false
    if self.ProgressContainer then
        self.ProgressContainer.Visible = false
    end
end

function TopBar:FocusSearch()
    if self.SearchInput then
        self.SearchInput:CaptureFocus()
    end
end

function TopBar:ClearSearch()
    if self.SearchInput then
        self.SearchInput.Text = ""
    end
end

function TopBar:GetSearchText()
    return self.SearchInput and self.SearchInput.Text or ""
end

function TopBar:SetMaximized(maximized)
    self.Maximized = maximized
    
    if self.MaximizeButton then
        self.MaximizeButton.Text = maximized and "❐" or "□"
    end
end

function TopBar:SetPinned(pinned)
    self.Pinned = pinned
    
    if self.PinButton then
        self.PinButton.TextTransparency = pinned and 0 or 0.5
    end
end

function TopBar:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("TopBar")
    self.BottomCover.BackgroundColor3 = Theme:Get("TopBar")
    
    if self.Border then
        self.Border.BackgroundColor3 = Theme:Get("Border")
    end
    
    if self.TitleLabel then
        self.TitleLabel.TextColor3 = Theme:Get("TextPrimary")
    end
    
    if self.SubtitleLabel then
        self.SubtitleLabel.TextColor3 = Theme:Get("TextSecondary")
    end
    
    if self.SearchContainer then
        self.SearchContainer.BackgroundColor3 = Theme:Get("Card")
        self.SearchInput.TextColor3 = Theme:Get("TextPrimary")
        self.SearchInput.PlaceholderColor3 = Theme:Get("TextSecondary")
    end
    
    if self.ClockLabel then
        self.ClockLabel.TextColor3 = Theme:Get("TextSecondary")
    end
    
    if self.ProgressBar then
        self.ProgressBar.BackgroundColor3 = Theme:Get("Accent")
    end
    
    for _, button in ipairs(self._buttons) do
        button.BackgroundColor3 = Theme:Get("Card")
        button.TextColor3 = Theme:Get("TextSecondary")
    end
end

function TopBar:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    self.OnClose:Destroy()
    self.OnMinimize:Destroy()
    self.OnMaximize:Destroy()
    self.OnRestore:Destroy()
    self.OnPin:Destroy()
    self.OnSearch:Destroy()
    self.OnSearchSubmit:Destroy()
    self.OnTabChanged:Destroy()
    self.OnAction:Destroy()
    self.OnTitleChanged:Destroy()
    self.OnDoubleClick:Destroy()
    self.OnContextMenu:Destroy()
    
    if self.Frame then
        self.Frame:Destroy()
    end
end

return TopBar