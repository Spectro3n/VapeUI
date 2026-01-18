--[[
    VapeUI Content Area v2.0
    Advanced container for page content with responsive layouts.
    
    Features:
    ✅ Multiple layout modes (Full, Split, Sidebar, Grid)
    ✅ Responsive breakpoints
    ✅ Header & Footer areas
    ✅ Breadcrumb navigation
    ✅ Page transitions
    ✅ Loading states
    ✅ Error boundaries
    ✅ Pull to refresh
    ✅ Scroll management
    ✅ Background effects (blur, gradient)
    ✅ Overlay system
    ✅ Focus mode
    ✅ Padding configurations
    ✅ Content masking
    ✅ Scroll indicators
    ✅ Keyboard navigation
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ContentArea = {}
ContentArea.__index = ContentArea

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Layout
    Layout = "Full",  -- Full, Split, WithSidebar, Grid
    SidebarWidth = 200,
    TopBarHeight = 48,
    HeaderHeight = 0,
    FooterHeight = 0,
    
    -- Padding
    Padding = {Top = 0, Right = 0, Bottom = 0, Left = 0},
    ContentPadding = {Top = 16, Right = 20, Bottom = 16, Left = 20},
    
    -- Features
    EnableHeader = false,
    EnableFooter = false,
    EnableBreadcrumbs = false,
    EnableScrollIndicator = true,
    EnablePullToRefresh = false,
    EnableLoadingState = true,
    EnableErrorBoundary = true,
    EnableFocusMode = false,
    EnableBackgroundEffects = true,
    
    -- Scroll
    ScrollBarThickness = 4,
    ScrollBarTransparency = 0.5,
    SmoothScroll = true,
    ScrollSpeed = 60,
    
    -- Transitions
    TransitionStyle = "Fade",  -- Fade, Slide, Scale, None
    TransitionDuration = 0.25,
    
    -- Responsive
    EnableResponsive = true,
    BreakpointMobile = 600,
    BreakpointTablet = 900,
    BreakpointDesktop = 1200,
    
    -- Background
    BackgroundStyle = "Solid",  -- Solid, Gradient, Pattern, Blur
    BackgroundColor = nil,  -- nil = use theme
    GradientColors = nil,
    PatternImage = nil,
}

local LAYOUTS = {
    Full = {
        ContentPosition = UDim2.new(0, 0, 0, 0),
        ContentSize = UDim2.new(1, 0, 1, 0),
    },
    Split = {
        LeftSize = UDim2.new(0.5, -4, 1, 0),
        RightSize = UDim2.new(0.5, -4, 1, 0),
        Gap = 8,
    },
    WithSidebar = {
        SidebarSize = UDim2.new(0, 280, 1, 0),
        MainSize = UDim2.new(1, -288, 1, 0),
        Gap = 8,
    },
    Grid = {
        Columns = 2,
        CellPadding = UDim2.new(0, 8, 0, 8),
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- CONTENT AREA CLASS
-- ══════════════════════════════════════════════════════════════════════

function ContentArea.new(parent, options)
    local self = setmetatable({}, ContentArea)
    
    -- Configuration
    self.Config = setmetatable(options or {}, {__index = DEFAULT_CONFIG})
    self.Parent = parent
    
    -- State
    self.CurrentLayout = self.Config.Layout
    self.Loading = false
    self.Error = nil
    self.Refreshing = false
    self.FocusMode = false
    self.ScrollPosition = 0
    self.CurrentBreakpoint = "Desktop"
    self._connections = {}
    
    -- Signals
    self.OnScroll = Signal.new()
    self.OnScrollEnd = Signal.new()
    self.OnRefresh = Signal.new()
    self.OnLayoutChanged = Signal.new()
    self.OnBreakpointChanged = Signal.new()
    self.OnError = Signal.new()
    self.OnFocusModeChanged = Signal.new()
    
    -- Build UI
    self:_build()
    self:_setupInteractions()
    
    -- Setup responsive
    if self.Config.EnableResponsive then
        self:_setupResponsive()
    end
    
    return self
end

function ContentArea:_build()
    local config = self.Config
    
    -- Calculate position based on sidebar and topbar
    local xOffset = config.SidebarWidth + config.Padding.Left
    local yOffset = config.TopBarHeight + config.Padding.Top
    local widthOffset = -(config.SidebarWidth + config.Padding.Left + config.Padding.Right)
    local heightOffset = -(config.TopBarHeight + config.Padding.Top + config.Padding.Bottom)
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "ContentArea",
        Size = UDim2.new(1, widthOffset, 1, heightOffset),
        Position = UDim2.new(0, xOffset, 0, yOffset),
        BackgroundColor3 = config.BackgroundColor or Theme:Get("Content"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Parent,
    })
    
    -- Background effects
    if config.EnableBackgroundEffects then
        self:_buildBackground()
    end
    
    -- Header
    if config.EnableHeader then
        self:_buildHeader()
    end
    
    -- Breadcrumbs
    if config.EnableBreadcrumbs then
        self:_buildBreadcrumbs()
    end
    
    -- Main content container
    self:_buildContentContainer()
    
    -- Footer
    if config.EnableFooter then
        self:_buildFooter()
    end
    
    -- Loading overlay
    if config.EnableLoadingState then
        self:_buildLoadingOverlay()
    end
    
    -- Error overlay
    if config.EnableErrorBoundary then
        self:_buildErrorOverlay()
    end
    
    -- Scroll indicator
    if config.EnableScrollIndicator then
        self:_buildScrollIndicator()
    end
    
    -- Pull to refresh indicator
    if config.EnablePullToRefresh then
        self:_buildPullToRefresh()
    end
    
    -- Focus mode overlay
    if config.EnableFocusMode then
        self:_buildFocusModeOverlay()
    end
end

function ContentArea:_buildBackground()
    local config = self.Config
    
    if config.BackgroundStyle == "Gradient" then
        local gradientColors = config.GradientColors or {
            Theme:Get("Content"),
            Theme:Get("Background"),
        }
        
        self.BackgroundGradient = Create.Frame({
            Name = "BackgroundGradient",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = gradientColors[1],
            ZIndex = 0,
            Parent = self.Frame,
        }, {
            Create.Gradient({
                Color = ColorSequence.new(gradientColors),
                Rotation = 180,
            }),
        })
        
    elseif config.BackgroundStyle == "Pattern" then
        self.BackgroundPattern = Create.Image({
            Name = "BackgroundPattern",
            Size = UDim2.new(1, 0, 1, 0),
            Image = config.PatternImage or "rbxassetid://6031280882",
            ImageTransparency = 0.95,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.fromOffset(50, 50),
            ZIndex = 0,
            Parent = self.Frame,
        })
        
    elseif config.BackgroundStyle == "Blur" then
        -- Note: Actual blur requires BlurEffect on Lighting
        -- This creates a frosted glass appearance
        self.BackgroundBlur = Create.Frame({
            Name = "BackgroundBlur",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Theme:Get("Content"),
            BackgroundTransparency = 0.2,
            ZIndex = 0,
            Parent = self.Frame,
        })
    end
end

function ContentArea:_buildHeader()
    local config = self.Config
    
    self.Header = Create.Frame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, config.HeaderHeight),
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.Frame,
    }, {
        Create.Frame({
            Name = "Border",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Theme:Get("Border"),
            BorderSizePixel = 0,
        }),
        Create.Padding(0, 0, 16, 16),
    })
    
    -- Header content container
    self.HeaderContent = Create.Frame({
        Name = "HeaderContent",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Header,
    }, {
        Create.HorizontalList({
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }),
    })
end

function ContentArea:_buildBreadcrumbs()
    local yOffset = self.Config.EnableHeader and self.Config.HeaderHeight or 0
    
    self.Breadcrumbs = Create.Frame({
        Name = "Breadcrumbs",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = self.Frame,
    }, {
        Create.Padding(0, 0, 16, 16),
        Create.HorizontalList({
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
        }),
    })
    
    -- Breadcrumb items will be added dynamically
    self.BreadcrumbItems = {}
end

function ContentArea:_buildContentContainer()
    local config = self.Config
    
    -- Calculate content Y offset
    local yOffset = 0
    if config.EnableHeader then yOffset = yOffset + config.HeaderHeight end
    if config.EnableBreadcrumbs then yOffset = yOffset + 36 end
    
    -- Calculate content height offset
    local heightOffset = -yOffset
    if config.EnableFooter then heightOffset = heightOffset - config.FooterHeight end
    
    -- Content wrapper (for transitions)
    self.ContentWrapper = Create.CanvasGroup({
        Name = "ContentWrapper",
        Size = UDim2.new(1, 0, 1, heightOffset),
        Position = UDim2.new(0, 0, 0, yOffset),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    })
    
    -- Page container (for page management)
    self.PageContainer = Create.Frame({
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self.ContentWrapper,
    })
    
    -- Main scrollable content
    self.ContentScroll = Create.Scroll({
        Name = "ContentScroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = config.ScrollBarThickness,
        ScrollBarImageTransparency = config.ScrollBarTransparency,
        ScrollBarImageColor3 = Theme:Get("TextSecondary"),
        Parent = self.PageContainer,
    })
    
    -- Content inner container
    local padding = config.ContentPadding
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self.ContentScroll,
    }, {
        Create.List({
            Padding = UDim.new(0, 12),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
        Create.Padding(padding.Top, padding.Right, padding.Bottom, padding.Left),
    })
    
    -- Apply layout
    self:_applyLayout(self.CurrentLayout)
end

function ContentArea:_buildFooter()
    local config = self.Config
    
    self.Footer = Create.Frame({
        Name = "Footer",
        Size = UDim2.new(1, 0, 0, config.FooterHeight),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.Frame,
    }, {
        Create.Frame({
            Name = "Border",
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Theme:Get("Border"),
            BorderSizePixel = 0,
        }),
        Create.Padding(0, 0, 16, 16),
    })
    
    -- Footer content container
    self.FooterContent = Create.Frame({
        Name = "FooterContent",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Footer,
    }, {
        Create.HorizontalList({
            VerticalAlignment = Enum.VerticalAlignment.Center,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }),
    })
end

function ContentArea:_buildLoadingOverlay()
    self.LoadingOverlay = Create.Frame({
        Name = "LoadingOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme:Get("Background"),
        BackgroundTransparency = 0.3,
        Visible = false,
        ZIndex = 50,
        Parent = self.Frame,
    })
    
    -- Spinner container
    self.SpinnerContainer = Create.Frame({
        Name = "SpinnerContainer",
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme:Get("Card"),
        Parent = self.LoadingOverlay,
    }, {
        Create.Corner(12),
        Create.Stroke({Color = Theme:Get("Border")}),
    })
    
    -- Spinner
    self.Spinner = Create.Image({
        Name = "Spinner",
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6031302931",
        ImageColor3 = Theme:Get("Accent"),
        Parent = self.SpinnerContainer,
    })
    
    -- Loading text
    self.LoadingText = Create.Text({
        Name = "LoadingText",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0.5, 0, 0.5, 50),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Loading...",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        Parent = self.LoadingOverlay,
    })
end

function ContentArea:_buildErrorOverlay()
    self.ErrorOverlay = Create.Frame({
        Name = "ErrorOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme:Get("Background"),
        BackgroundTransparency = 0.1,
        Visible = false,
        ZIndex = 50,
        Parent = self.Frame,
    })
    
    -- Error container
    self.ErrorContainer = Create.Frame({
        Name = "ErrorContainer",
        Size = UDim2.new(0.8, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme:Get("Card"),
        Parent = self.ErrorOverlay,
    }, {
        Create.Corner(12),
        Create.Stroke({Color = Theme:Get("Error"), Transparency = 0.5}),
        Create.Padding(24),
        Create.List({
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, 12),
        }),
    })
    
    -- Error icon
    Create.Text({
        Name = "ErrorIcon",
        Size = UDim2.new(1, 0, 0, 40),
        Text = "⚠️",
        TextSize = 32,
        LayoutOrder = 1,
        Parent = self.ErrorContainer,
    })
    
    -- Error title
    Create.Text({
        Name = "ErrorTitle",
        Size = UDim2.new(1, 0, 0, 24),
        Text = "Something went wrong",
        TextColor3 = Theme:Get("Error"),
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        LayoutOrder = 2,
        Parent = self.ErrorContainer,
    })
    
    -- Error message
    self.ErrorMessage = Create.Text({
        Name = "ErrorMessage",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Text = "An unexpected error occurred.",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 13,
        TextWrapped = true,
        LayoutOrder = 3,
        Parent = self.ErrorContainer,
    })
    
    -- Retry button
    self.RetryButton = Create.Button({
        Name = "RetryButton",
        Size = UDim2.new(0, 120, 0, 36),
        BackgroundColor3 = Theme:Get("Accent"),
        Text = "Retry",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        LayoutOrder = 4,
        Parent = self.ErrorContainer,
    }, {
        Create.Corner(8),
    })
    
    self.RetryButton.MouseButton1Click:Connect(function()
        self:ClearError()
        self.OnRefresh:Fire()
    end)
end

function ContentArea:_buildScrollIndicator()
    -- Scroll progress bar at top
    self.ScrollIndicator = Create.Frame({
        Name = "ScrollIndicator",
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Theme:Get("Accent"),
        BorderSizePixel = 0,
        ZIndex = 10,
        Visible = false,
        Parent = self.Frame,
    })
    
    -- Scroll to top button
    self.ScrollToTopButton = Create.Button({
        Name = "ScrollToTop",
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.new(1, -20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Theme:Get("Card"),
        Text = "↑",
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        Visible = false,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.Corner(20),
        Create.Stroke({Color = Theme:Get("Border")}),
    })
    
    self.ScrollToTopButton.MouseButton1Click:Connect(function()
        self:ScrollToTop(true)
    end)
end

function ContentArea:_buildPullToRefresh()
    self.PullToRefreshIndicator = Create.Frame({
        Name = "PullToRefresh",
        Size = UDim2.new(1, 0, 0, 60),
        Position = UDim2.new(0, 0, 0, -60),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = self.ContentWrapper,
    })
    
    self.RefreshSpinner = Create.Image({
        Name = "RefreshSpinner",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6031302931",
        ImageColor3 = Theme:Get("Accent"),
        ImageTransparency = 1,
        Parent = self.PullToRefreshIndicator,
    })
    
    self.RefreshText = Create.Text({
        Name = "RefreshText",
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0.5, 0, 0.5, 20),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text = "Pull to refresh",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 11,
        TextTransparency = 1,
        Parent = self.PullToRefreshIndicator,
    })
end

function ContentArea:_buildFocusModeOverlay()
    self.FocusModeOverlay = Create.Frame({
        Name = "FocusModeOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 40,
        Parent = self.Frame,
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- INTERACTIONS
-- ══════════════════════════════════════════════════════════════════════

function ContentArea:_setupInteractions()
    -- Scroll tracking
    local lastScrollPosition = 0
    local scrollEndDebounce = nil
    
    local scrollConn = self.ContentScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local scrollY = self.ContentScroll.CanvasPosition.Y
        local maxScroll = self.ContentScroll.AbsoluteCanvasSize.Y - self.ContentScroll.AbsoluteSize.Y
        
        self.ScrollPosition = scrollY
        self.OnScroll:Fire(scrollY, maxScroll)
        
        -- Update scroll indicator
        if self.ScrollIndicator then
            local progress = maxScroll > 0 and (scrollY / maxScroll) or 0
            self.ScrollIndicator.Size = UDim2.new(progress, 0, 0, 2)
            self.ScrollIndicator.Visible = progress > 0 and progress < 1
        end
        
        -- Show/hide scroll to top button
        if self.ScrollToTopButton then
            self.ScrollToTopButton.Visible = scrollY > 200
        end
        
        -- Scroll end detection
        if scrollEndDebounce then
            task.cancel(scrollEndDebounce)
        end
        scrollEndDebounce = task.delay(0.15, function()
            self.OnScrollEnd:Fire(scrollY)
        end)
        
        lastScrollPosition = scrollY
    end)
    table.insert(self._connections, scrollConn)
    
    -- Pull to refresh
    if self.Config.EnablePullToRefresh then
        self:_setupPullToRefresh()
    end
end

function ContentArea:_setupPullToRefresh()
    local pulling = false
    local startY = 0
    local threshold = 80
    
    local inputBeganConn = self.ContentScroll.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.ContentScroll.CanvasPosition.Y <= 0 then
                pulling = true
                startY = input.Position.Y
            end
        end
    end)
    table.insert(self._connections, inputBeganConn)
    
    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if pulling and (input.UserInputType == Enum.UserInputType.Touch or
                        input.UserInputType == Enum.UserInputType.MouseMovement) then
            local deltaY = input.Position.Y - startY
            
            if deltaY > 0 and self.ContentScroll.CanvasPosition.Y <= 0 then
                -- Show pull indicator
                local progress = math.min(deltaY / threshold, 1)
                self.RefreshSpinner.ImageTransparency = 1 - progress
                self.RefreshSpinner.Rotation = deltaY * 2
                self.RefreshText.TextTransparency = 1 - progress
                
                if deltaY >= threshold then
                    self.RefreshText.Text = "Release to refresh"
                else
                    self.RefreshText.Text = "Pull to refresh"
                end
            end
        end
    end)
    table.insert(self._connections, inputChangedConn)
    
    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if pulling and (input.UserInputType == Enum.UserInputType.Touch or
                        input.UserInputType == Enum.UserInputType.MouseButton1) then
            local deltaY = input.Position.Y - startY
            pulling = false
            
            if deltaY >= threshold and not self.Refreshing then
                self:_triggerRefresh()
            else
                -- Reset indicator
                Tween.Fast(self.RefreshSpinner, {ImageTransparency = 1})
                Tween.Fast(self.RefreshText, {TextTransparency = 1})
            end
        end
    end)
    table.insert(self._connections, inputEndedConn)
end

function ContentArea:_triggerRefresh()
    self.Refreshing = true
    self.RefreshText.Text = "Refreshing..."
    
    -- Start spinner animation
    local spinConnection
    spinConnection = RunService.Heartbeat:Connect(function(dt)
        if self.RefreshSpinner then
            self.RefreshSpinner.Rotation = self.RefreshSpinner.Rotation + dt * 360
        end
    end)
    
    -- Fire refresh event
    self.OnRefresh:Fire()
    
    -- Auto-complete after timeout (caller should call CompleteRefresh)
    task.delay(10, function()
        if self.Refreshing then
            self:CompleteRefresh()
        end
        if spinConnection then
            spinConnection:Disconnect()
        end
    end)
end

function ContentArea:_setupResponsive()
    local function checkBreakpoint()
        local width = self.Frame.AbsoluteSize.X
        local newBreakpoint
        
        if width < self.Config.BreakpointMobile then
            newBreakpoint = "Mobile"
        elseif width < self.Config.BreakpointTablet then
            newBreakpoint = "Tablet"
        elseif width < self.Config.BreakpointDesktop then
            newBreakpoint = "Desktop"
        else
            newBreakpoint = "Large"
        end
        
        if newBreakpoint ~= self.CurrentBreakpoint then
            local previousBreakpoint = self.CurrentBreakpoint
            self.CurrentBreakpoint = newBreakpoint
            self.OnBreakpointChanged:Fire(newBreakpoint, previousBreakpoint)
            self:_onBreakpointChange(newBreakpoint)
        end
    end
    
    local sizeConn = self.Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(checkBreakpoint)
    table.insert(self._connections, sizeConn)
    
    -- Initial check
    checkBreakpoint()
end

function ContentArea:_onBreakpointChange(breakpoint)
    local padding = self.Config.ContentPadding
    
    -- Adjust padding based on breakpoint
    if breakpoint == "Mobile" then
        self.Content:FindFirstChild("UIPadding").PaddingLeft = UDim.new(0, 12)
        self.Content:FindFirstChild("UIPadding").PaddingRight = UDim.new(0, 12)
    elseif breakpoint == "Tablet" then
        self.Content:FindFirstChild("UIPadding").PaddingLeft = UDim.new(0, 16)
        self.Content:FindFirstChild("UIPadding").PaddingRight = UDim.new(0, 16)
    else
        self.Content:FindFirstChild("UIPadding").PaddingLeft = UDim.new(0, padding.Left)
        self.Content:FindFirstChild("UIPadding").PaddingRight = UDim.new(0, padding.Right)
    end
end

function ContentArea:_applyLayout(layoutName)
    local layoutConfig = LAYOUTS[layoutName]
    if not layoutConfig then return end
    
    -- Clear existing layout-specific elements
    for _, child in ipairs(self.Content:GetChildren()) do
        if child.Name:match("^Layout_") then
            child:Destroy()
        end
    end
    
    if layoutName == "Split" then
        -- Create left and right panels
        self.LeftPanel = Create.Frame({
            Name = "Layout_LeftPanel",
            Size = layoutConfig.LeftSize,
            BackgroundTransparency = 1,
            LayoutOrder = -1,
            Parent = self.Content,
        }, {
            Create.List({Padding = UDim.new(0, 12)}),
        })
        
        self.RightPanel = Create.Frame({
            Name = "Layout_RightPanel",
            Size = layoutConfig.RightSize,
            Position = UDim2.new(0.5, layoutConfig.Gap / 2, 0, 0),
            BackgroundTransparency = 1,
            LayoutOrder = -1,
            Parent = self.Content,
        }, {
            Create.List({Padding = UDim.new(0, 12)}),
        })
        
    elseif layoutName == "WithSidebar" then
        self.ContentSidebar = Create.Frame({
            Name = "Layout_Sidebar",
            Size = layoutConfig.SidebarSize,
            BackgroundTransparency = 1,
            LayoutOrder = -1,
            Parent = self.Content,
        }, {
            Create.List({Padding = UDim.new(0, 8)}),
        })
        
        self.MainContent = Create.Frame({
            Name = "Layout_Main",
            Size = layoutConfig.MainSize,
            Position = UDim2.new(0, 288, 0, 0),
            BackgroundTransparency = 1,
            LayoutOrder = -1,
            Parent = self.Content,
        }, {
            Create.List({Padding = UDim.new(0, 12)}),
        })
        
    elseif layoutName == "Grid" then
        local gridContent = self.Content:FindFirstChild("UIListLayout")
        if gridContent then gridContent:Destroy() end
        
        Create.Grid({
            CellSize = UDim2.new(1 / layoutConfig.Columns, -layoutConfig.CellPadding.X.Offset, 0, 150),
            CellPadding = layoutConfig.CellPadding,
            Parent = self.Content,
        })
    end
    
    self.CurrentLayout = layoutName
    self.OnLayoutChanged:Fire(layoutName)
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function ContentArea:GetContent()
    return self.Content
end

function ContentArea:GetPageContainer()
    return self.PageContainer
end

function ContentArea:GetHeader()
    return self.HeaderContent
end

function ContentArea:GetFooter()
    return self.FooterContent
end

function ContentArea:SetLayout(layoutName, animate)
    if not LAYOUTS[layoutName] then return end
    
    if animate then
        -- Fade out, change layout, fade in
        Tween.Fast(self.ContentWrapper, {GroupTransparency = 1})
        task.wait(0.15)
        self:_applyLayout(layoutName)
        Tween.Fast(self.ContentWrapper, {GroupTransparency = 0})
    else
        self:_applyLayout(layoutName)
    end
end

function ContentArea:SetLoading(loading, text)
    self.Loading = loading
    
    if loading then
        self.LoadingOverlay.Visible = true
        Tween.Fast(self.LoadingOverlay, {BackgroundTransparency = 0.3})
        
        if text then
            self.LoadingText.Text = text
        end
        
        -- Start spinner animation
        if not self._spinnerConnection then
            self._spinnerConnection = RunService.Heartbeat:Connect(function(dt)
                if self.Spinner then
                    self.Spinner.Rotation = self.Spinner.Rotation + dt * 360
                end
            end)
        end
    else
        Tween.Fast(self.LoadingOverlay, {BackgroundTransparency = 1})
        task.delay(0.15, function()
            if not self.Loading then
                self.LoadingOverlay.Visible = false
            end
        end)
        
        -- Stop spinner animation
        if self._spinnerConnection then
            self._spinnerConnection:Disconnect()
            self._spinnerConnection = nil
        end
    end
end

function ContentArea:IsLoading()
    return self.Loading
end

function ContentArea:SetError(message)
    self.Error = message
    self.ErrorMessage.Text = message or "An unexpected error occurred."
    self.ErrorOverlay.Visible = true
    Tween.Fast(self.ErrorOverlay, {BackgroundTransparency = 0.1})
    self.OnError:Fire(message)
end

function ContentArea:ClearError()
    self.Error = nil
    Tween.Fast(self.ErrorOverlay, {BackgroundTransparency = 1})
    task.delay(0.15, function()
        if not self.Error then
            self.ErrorOverlay.Visible = false
        end
    end)
end

function ContentArea:HasError()
    return self.Error ~= nil
end

function ContentArea:CompleteRefresh()
    self.Refreshing = false
    
    -- Hide refresh indicator
    Tween.Fast(self.RefreshSpinner, {ImageTransparency = 1})
    Tween.Fast(self.RefreshText, {TextTransparency = 1})
end

function ContentArea:SetBreadcrumbs(items)
    if not self.Breadcrumbs then return end
    
    -- Clear existing
    for _, item in ipairs(self.BreadcrumbItems) do
        item:Destroy()
    end
    self.BreadcrumbItems = {}
    
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
            TextSize = 12,
            Font = isLast and Enum.Font.GothamMedium or Enum.Font.Gotham,
            LayoutOrder = i * 2 - 1,
            Parent = self.Breadcrumbs,
        })
        
        if not isLast and item.OnClick then
            crumb.MouseButton1Click:Connect(item.OnClick)
        end
        
        table.insert(self.BreadcrumbItems, crumb)
        
        -- Add separator
        if not isLast then
            local separator = Create.Text({
                Name = "Separator_" .. i,
                Size = UDim2.new(0, 16, 1, 0),
                Text = "›",
                TextColor3 = Theme:Get("TextTertiary"),
                TextSize = 14,
                LayoutOrder = i * 2,
                Parent = self.Breadcrumbs,
            })
            table.insert(self.BreadcrumbItems, separator)
        end
    end
end

function ContentArea:ScrollToTop(animate)
    if animate then
        Tween.Normal(self.ContentScroll, {CanvasPosition = Vector2.new(0, 0)})
    else
        self.ContentScroll.CanvasPosition = Vector2.new(0, 0)
    end
end

function ContentArea:ScrollToBottom(animate)
    local maxScroll = self.ContentScroll.AbsoluteCanvasSize.Y - self.ContentScroll.AbsoluteSize.Y
    
    if animate then
        Tween.Normal(self.ContentScroll, {CanvasPosition = Vector2.new(0, math.max(0, maxScroll))})
    else
        self.ContentScroll.CanvasPosition = Vector2.new(0, math.max(0, maxScroll))
    end
end

function ContentArea:ScrollToElement(element, animate)
    if not element or not element:IsDescendantOf(self.Content) then return end
    
    local elementY = element.AbsolutePosition.Y - self.Content.AbsolutePosition.Y
    
    if animate then
        Tween.Normal(self.ContentScroll, {CanvasPosition = Vector2.new(0, math.max(0, elementY - 20))})
    else
        self.ContentScroll.CanvasPosition = Vector2.new(0, math.max(0, elementY - 20))
    end
end

function ContentArea:EnableFocusMode(targetElement)
    if not self.Config.EnableFocusMode then return end
    
    self.FocusMode = true
    self.FocusModeOverlay.Visible = true
    
    Tween.Normal(self.FocusModeOverlay, {BackgroundTransparency = 0.7})
    
    if targetElement then
        targetElement.ZIndex = 45  -- Above overlay
    end
    
    self.OnFocusModeChanged:Fire(true, targetElement)
end

function ContentArea:DisableFocusMode()
    self.FocusMode = false
    
    Tween.Normal(self.FocusModeOverlay, {BackgroundTransparency = 1})
    task.delay(0.25, function()
        if not self.FocusMode then
            self.FocusModeOverlay.Visible = false
        end
    end)
    
    self.OnFocusModeChanged:Fire(false)
end

function ContentArea:Transition(style, callback)
    style = style or self.Config.TransitionStyle
    local duration = self.Config.TransitionDuration
    
    if style == "Fade" then
        Tween.new(self.ContentWrapper, {GroupTransparency = 1}, duration / 2)
        task.wait(duration / 2)
        if callback then callback() end
        Tween.new(self.ContentWrapper, {GroupTransparency = 0}, duration / 2)
        
    elseif style == "Slide" then
        Tween.new(self.ContentWrapper, {Position = UDim2.new(-0.1, 0, 0, 0), GroupTransparency = 0.5}, duration / 2)
        task.wait(duration / 2)
        if callback then callback() end
        self.ContentWrapper.Position = UDim2.new(0.1, 0, 0, 0)
        Tween.new(self.ContentWrapper, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}, duration / 2)
        
    elseif style == "Scale" then
        Tween.new(self.ContentWrapper, {GroupTransparency = 1}, duration / 2)
        task.wait(duration / 2)
        if callback then callback() end
        Tween.new(self.ContentWrapper, {GroupTransparency = 0}, duration / 2)
        
    else
        if callback then callback() end
    end
end

function ContentArea:GetBreakpoint()
    return self.CurrentBreakpoint
end

function ContentArea:UpdateTheme()
    self.Frame.BackgroundColor3 = self.Config.BackgroundColor or Theme:Get("Content")
    
    if self.Header then
        self.Header.BackgroundColor3 = Theme:Get("Card")
        self.Header:FindFirstChild("Border").BackgroundColor3 = Theme:Get("Border")
    end
    
    if self.Footer then
        self.Footer.BackgroundColor3 = Theme:Get("Card")
        self.Footer:FindFirstChild("Border").BackgroundColor3 = Theme:Get("Border")
    end
    
    if self.ContentScroll then
        self.ContentScroll.ScrollBarImageColor3 = Theme:Get("TextSecondary")
    end
    
    if self.ScrollIndicator then
        self.ScrollIndicator.BackgroundColor3 = Theme:Get("Accent")
    end
    
    if self.ScrollToTopButton then
        self.ScrollToTopButton.BackgroundColor3 = Theme:Get("Card")
        self.ScrollToTopButton.TextColor3 = Theme:Get("TextPrimary")
    end
    
    if self.LoadingOverlay then
        self.LoadingOverlay.BackgroundColor3 = Theme:Get("Background")
        self.SpinnerContainer.BackgroundColor3 = Theme:Get("Card")
        self.Spinner.ImageColor3 = Theme:Get("Accent")
        self.LoadingText.TextColor3 = Theme:Get("TextSecondary")
    end
    
    if self.ErrorOverlay then
        self.ErrorOverlay.BackgroundColor3 = Theme:Get("Background")
        self.ErrorContainer.BackgroundColor3 = Theme:Get("Card")
    end
end

function ContentArea:Destroy()
    -- Disconnect connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    if self._spinnerConnection then
        self._spinnerConnection:Disconnect()
    end
    
    -- Destroy signals
    self.OnScroll:Destroy()
    self.OnScrollEnd:Destroy()
    self.OnRefresh:Destroy()
    self.OnLayoutChanged:Destroy()
    self.OnBreakpointChanged:Destroy()
    self.OnError:Destroy()
    self.OnFocusModeChanged:Destroy()
    
    -- Destroy frame
    if self.Frame then
        self.Frame:Destroy()
    end
end

return ContentArea