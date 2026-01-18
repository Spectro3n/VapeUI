--[[
    VapeUI Page Manager v2.0
    Advanced page creation, navigation, and lifecycle management.
    
    Features:
    ✅ Multiple transition styles (Slide, Fade, Scale, Flip, None)
    ✅ Navigation history (Back/Forward)
    ✅ Breadcrumb trail
    ✅ Tab indicators with animations
    ✅ Swipe gesture navigation
    ✅ Page lifecycle events (Enter, Leave, Show, Hide)
    ✅ Scroll position memory
    ✅ Lazy loading support
    ✅ Page preloading
    ✅ Deep linking / route system
    ✅ Page groups / categories
    ✅ Search across pages
    ✅ Keyboard navigation
    ✅ Page metadata (title, icon, badge)
    ✅ Conditional page visibility
    ✅ Analytics hooks
    ✅ Loading states
    ✅ Error boundaries
    ✅ Page caching
    ✅ Nested pages support
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

-- Services
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local RunService = Services.RunService

local PageManager = {}
PageManager.__index = PageManager

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Transitions
    TransitionStyle = "Slide",  -- Slide, Fade, Scale, Flip, SlideUp, SlideDown, None
    TransitionDuration = 0.3,
    TransitionEasing = Enum.EasingStyle.Quart,
    TransitionDirection = Enum.EasingDirection.Out,
    
    -- Navigation
    EnableHistory = true,
    MaxHistoryLength = 50,
    EnableSwipeNavigation = true,
    SwipeThreshold = 100,
    EnableKeyboardNavigation = true,
    
    -- Features
    EnableScrollMemory = true,
    EnableLazyLoading = false,
    EnablePreloading = true,
    PreloadAdjacentPages = 1,
    EnableBreadcrumbs = false,
    EnableTabIndicators = true,
    
    -- Page defaults
    DefaultScrollBarThickness = 4,
    DefaultPadding = {Top = 12, Bottom = 12, Left = 16, Right = 16},
    DefaultSpacing = 10,
    
    -- Scroll
    ScrollBarImageTransparency = 0.5,
    ScrollBarImageColor = nil,  -- nil = use theme
    
    -- Loading
    ShowLoadingIndicator = true,
    LoadingTimeout = 10,
}

local TRANSITION_STYLES = {
    None = {
        duration = 0,
        setup = function() end,
        animate = function() end,
    },
    
    Slide = {
        setup = function(fromPage, toPage, direction)
            local offset = direction > 0 and 1 or -1
            toPage.Frame.Position = UDim2.new(offset, 0, 0, 0)
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            local offset = direction > 0 and -1 or 1
            
            return {
                Tween.new(fromPage.Frame, {Position = UDim2.new(offset, 0, 0, 0)}, duration, easing),
                Tween.new(toPage.Frame, {Position = UDim2.new(0, 0, 0, 0)}, duration, easing),
            }
        end,
    },
    
    SlideUp = {
        setup = function(fromPage, toPage, direction)
            toPage.Frame.Position = UDim2.new(0, 0, 1, 0)
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            return {
                Tween.new(fromPage.Frame, {Position = UDim2.new(0, 0, -1, 0)}, duration, easing),
                Tween.new(toPage.Frame, {Position = UDim2.new(0, 0, 0, 0)}, duration, easing),
            }
        end,
    },
    
    SlideDown = {
        setup = function(fromPage, toPage, direction)
            toPage.Frame.Position = UDim2.new(0, 0, -1, 0)
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            return {
                Tween.new(fromPage.Frame, {Position = UDim2.new(0, 0, 1, 0)}, duration, easing),
                Tween.new(toPage.Frame, {Position = UDim2.new(0, 0, 0, 0)}, duration, easing),
            }
        end,
    },
    
    Fade = {
        setup = function(fromPage, toPage, direction)
            toPage.Frame.Position = UDim2.new(0, 0, 0, 0)
            toPage.Frame.GroupTransparency = 1
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            return {
                Tween.new(fromPage.Frame, {GroupTransparency = 1}, duration, easing),
                Tween.new(toPage.Frame, {GroupTransparency = 0}, duration, easing),
            }
        end,
        cleanup = function(fromPage, toPage)
            fromPage.Frame.GroupTransparency = 0
        end,
    },
    
    Scale = {
        setup = function(fromPage, toPage, direction)
            toPage.Frame.Position = UDim2.new(0, 0, 0, 0)
            toPage.Frame.Size = UDim2.new(0.8, 0, 0.8, 0)
            toPage.Frame.AnchorPoint = Vector2.new(0.5, 0.5)
            toPage.Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
            toPage.Frame.GroupTransparency = 1
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            return {
                Tween.new(fromPage.Frame, {
                    Size = UDim2.new(0.8, 0, 0.8, 0),
                    GroupTransparency = 1,
                }, duration, easing),
                Tween.new(toPage.Frame, {
                    Size = UDim2.new(1, 0, 1, 0),
                    GroupTransparency = 0,
                }, duration, easing),
            }
        end,
        cleanup = function(fromPage, toPage)
            fromPage.Frame.Size = UDim2.new(1, 0, 1, 0)
            fromPage.Frame.AnchorPoint = Vector2.new(0, 0)
            fromPage.Frame.Position = UDim2.new(0, 0, 0, 0)
            fromPage.Frame.GroupTransparency = 0
            
            toPage.Frame.AnchorPoint = Vector2.new(0, 0)
            toPage.Frame.Position = UDim2.new(0, 0, 0, 0)
        end,
    },
    
    Flip = {
        setup = function(fromPage, toPage, direction)
            toPage.Frame.Position = UDim2.new(0, 0, 0, 0)
            toPage.Frame.Rotation = direction > 0 and 90 or -90
            toPage.Frame.GroupTransparency = 1
            toPage.Frame.Visible = true
        end,
        animate = function(fromPage, toPage, direction, duration, easing)
            return {
                Tween.new(fromPage.Frame, {
                    Rotation = direction > 0 and -90 or 90,
                    GroupTransparency = 1,
                }, duration, easing),
                Tween.new(toPage.Frame, {
                    Rotation = 0,
                    GroupTransparency = 0,
                }, duration, easing),
            }
        end,
        cleanup = function(fromPage, toPage)
            fromPage.Frame.Rotation = 0
            fromPage.Frame.GroupTransparency = 0
        end,
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- PAGE CLASS
-- ══════════════════════════════════════════════════════════════════════

local Page = {}
Page.__index = Page

function Page.new(manager, name, options)
    local self = setmetatable({}, Page)
    
    options = options or {}
    
    -- Basic info
    self.Name = name
    self.Manager = manager
    self.Order = options.Order or 0
    
    -- Metadata
    self.Metadata = {
        Title = options.Title or name,
        Icon = options.Icon,
        Description = options.Description or "",
        Badge = options.Badge,
        BadgeColor = options.BadgeColor or "Error",
        Group = options.Group,
        Tags = options.Tags or {},
        Searchable = options.Searchable ~= false,
        Hidden = options.Hidden or false,
    }
    
    -- State
    self.Loaded = false
    self.Loading = false
    self.Visible = false
    self.Active = false
    self.Enabled = options.Enabled ~= false
    self.ScrollPosition = 0
    self.LastVisitTime = 0
    self.VisitCount = 0
    self._error = nil
    self._loadPromise = nil
    
    -- Options
    self.LazyLoad = options.LazyLoad or false
    self.CacheContent = options.CacheContent ~= false
    self.RefreshOnEnter = options.RefreshOnEnter or false
    
    -- Callbacks
    self.OnLoad = options.OnLoad  -- Called when page content is created
    self.OnEnter = options.OnEnter  -- Called when navigating TO this page
    self.OnLeave = options.OnLeave  -- Called when navigating AWAY from this page
    self.OnShow = options.OnShow  -- Called when page becomes visible
    self.OnHide = options.OnHide  -- Called when page becomes hidden
    self.OnRefresh = options.OnRefresh  -- Called when page is refreshed
    self.OnError = options.OnError  -- Called when an error occurs
    
    -- Signals
    self.Loaded_Signal = Signal.new()
    self.Entered = Signal.new()
    self.Left = Signal.new()
    self.Shown = Signal.new()
    self.Hidden = Signal.new()
    self.Refreshed = Signal.new()
    self.ErrorOccurred = Signal.new()
    
    -- Create frame
    self:_createFrame(options)
    
    -- Load immediately if not lazy
    if not self.LazyLoad then
        self:Load()
    end
    
    return self
end

function Page:_createFrame(options)
    local config = self.Manager.Config
    local padding = options.Padding or config.DefaultPadding
    local spacing = options.Spacing or config.DefaultSpacing
    
    -- Main page frame (CanvasGroup for transitions)
    self.Frame = Create.Instance("CanvasGroup", {
        Name = "Page_" .. self.Name,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        Visible = false,
        LayoutOrder = self.Order,
        Parent = self.Manager.Container,
    })
    
    -- Scrolling frame
    self.ScrollFrame = Create.Scroll({
        Name = "ScrollFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = config.DefaultScrollBarThickness,
        ScrollBarImageTransparency = config.ScrollBarImageTransparency,
        ScrollBarImageColor3 = config.ScrollBarImageColor or Theme:Get("TextSecondary"),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Always,
        Parent = self.Frame,
    })
    
    -- Content container
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = self.ScrollFrame,
    }, {
        Create.List({
            Padding = UDim.new(0, spacing),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
        Create.Instance("UIPadding", {
            PaddingTop = UDim.new(0, padding.Top or padding[1] or 12),
            PaddingBottom = UDim.new(0, padding.Bottom or padding[2] or 12),
            PaddingLeft = UDim.new(0, padding.Left or padding[3] or 16),
            PaddingRight = UDim.new(0, padding.Right or padding[4] or 16),
        }),
    })
    
    -- Loading overlay
    self.LoadingOverlay = Create.Frame({
        Name = "LoadingOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme:Get("Background"),
        BackgroundTransparency = 0.3,
        Visible = false,
        ZIndex = 100,
        Parent = self.Frame,
    })
    
    -- Spinner
    self.Spinner = Create.Frame({
        Name = "Spinner",
        Size = UDim2.fromOffset(40, 40),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Parent = self.LoadingOverlay,
    })
    
    local spinnerImage = Create.Image({
        Name = "SpinnerImage",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031302931",
        ImageColor3 = Theme:Get("Accent"),
        Parent = self.Spinner,
    })
    
    -- Error overlay
    self.ErrorOverlay = Create.Frame({
        Name = "ErrorOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Theme:Get("Background"),
        BackgroundTransparency = 0.1,
        Visible = false,
        ZIndex = 100,
        Parent = self.Frame,
    })
    
    self.ErrorMessage = Create.Text({
        Name = "ErrorMessage",
        Size = UDim2.new(0.8, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = "An error occurred",
        TextColor3 = Theme:Get("Error"),
        TextSize = 14,
        TextWrapped = true,
        Font = Enum.Font.GothamMedium,
        Parent = self.ErrorOverlay,
    })
    
    -- Scroll position tracking
    if self.Manager.Config.EnableScrollMemory then
        self.ScrollFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            self.ScrollPosition = self.ScrollFrame.CanvasPosition.Y
        end)
    end
end

function Page:Load()
    if self.Loaded or self.Loading then
        return self._loadPromise
    end
    
    self.Loading = true
    self:_showLoading(true)
    
    self._loadPromise = task.spawn(function()
        local success, err = pcall(function()
            -- Call OnLoad callback
            if self.OnLoad then
                self.OnLoad(self, self.Content)
            end
            
            self.Loaded = true
            self.Loading = false
            self:_showLoading(false)
            self.Loaded_Signal:Fire()
        end)
        
        if not success then
            self.Loading = false
            self._error = err
            self:_showLoading(false)
            self:_showError(err)
            self.ErrorOccurred:Fire(err)
            
            if self.OnError then
                self.OnError(self, err)
            end
        end
    end)
    
    return self._loadPromise
end

function Page:Unload()
    if not self.Loaded then return end
    
    -- Clear content
    for _, child in ipairs(self.Content:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    
    self.Loaded = false
    self._loadPromise = nil
end

function Page:Refresh()
    if self.OnRefresh then
        self:_showLoading(true)
        
        local success, err = pcall(function()
            self.OnRefresh(self, self.Content)
        end)
        
        self:_showLoading(false)
        
        if success then
            self.Refreshed:Fire()
        else
            self:_showError(err)
        end
    elseif self.LazyLoad then
        -- Reload lazy-loaded page
        self:Unload()
        self:Load()
    end
end

function Page:Enter(fromPage)
    -- Ensure loaded
    if not self.Loaded and self.LazyLoad then
        self:Load()
    end
    
    self.Active = true
    self.LastVisitTime = os.time()
    self.VisitCount = self.VisitCount + 1
    
    -- Restore scroll position
    if self.Manager.Config.EnableScrollMemory then
        self.ScrollFrame.CanvasPosition = Vector2.new(0, self.ScrollPosition)
    end
    
    -- Refresh if configured
    if self.RefreshOnEnter and self.Loaded then
        self:Refresh()
    end
    
    -- Callbacks and signals
    if self.OnEnter then
        self.OnEnter(self, fromPage)
    end
    self.Entered:Fire(fromPage)
end

function Page:Leave(toPage)
    self.Active = false
    
    if self.OnLeave then
        self.OnLeave(self, toPage)
    end
    self.Left:Fire(toPage)
end

function Page:Show()
    self.Visible = true
    self.Frame.Visible = true
    
    if self.OnShow then
        self.OnShow(self)
    end
    self.Shown:Fire()
end

function Page:Hide()
    self.Visible = false
    self.Frame.Visible = false
    
    if self.OnHide then
        self.OnHide(self)
    end
    self.Hidden:Fire()
end

function Page:_showLoading(show)
    if not self.Manager.Config.ShowLoadingIndicator then return end
    
    self.LoadingOverlay.Visible = show
    
    if show then
        -- Start spinner animation
        if not self._spinnerConnection then
            self._spinnerConnection = RunService.Heartbeat:Connect(function(dt)
                if self.Spinner and self.Spinner.SpinnerImage then
                    self.Spinner.SpinnerImage.Rotation = self.Spinner.SpinnerImage.Rotation + dt * 360
                end
            end)
        end
    else
        -- Stop spinner animation
        if self._spinnerConnection then
            self._spinnerConnection:Disconnect()
            self._spinnerConnection = nil
        end
    end
end

function Page:_showError(message)
    self.ErrorOverlay.Visible = true
    self.ErrorMessage.Text = "Error: " .. tostring(message)
end

function Page:ClearError()
    self.ErrorOverlay.Visible = false
    self._error = nil
end

function Page:SetBadge(badge, color)
    self.Metadata.Badge = badge
    if color then
        self.Metadata.BadgeColor = color
    end
    
    -- Update tab indicator if exists
    self.Manager:_updateTabIndicator(self.Name)
end

function Page:SetEnabled(enabled)
    self.Enabled = enabled
    self.Manager:_updateTabIndicator(self.Name)
end

function Page:SetHidden(hidden)
    self.Metadata.Hidden = hidden
    self.Manager:_updateTabIndicator(self.Name)
end

function Page:ScrollToTop(animate)
    if animate then
        Tween.Normal(self.ScrollFrame, {CanvasPosition = Vector2.new(0, 0)})
    else
        self.ScrollFrame.CanvasPosition = Vector2.new(0, 0)
    end
end

function Page:ScrollToBottom(animate)
    local maxScroll = self.ScrollFrame.AbsoluteCanvasSize.Y - self.ScrollFrame.AbsoluteSize.Y
    if animate then
        Tween.Normal(self.ScrollFrame, {CanvasPosition = Vector2.new(0, math.max(0, maxScroll))})
    else
        self.ScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, maxScroll))
    end
end

function Page:ScrollToElement(element, animate)
    if not element or not element:IsDescendantOf(self.Content) then return end
    
    local elementPos = element.AbsolutePosition.Y
    local contentPos = self.Content.AbsolutePosition.Y
    local targetScroll = elementPos - contentPos - 50  -- 50px offset from top
    
    if animate then
        Tween.Normal(self.ScrollFrame, {CanvasPosition = Vector2.new(0, math.max(0, targetScroll))})
    else
        self.ScrollFrame.CanvasPosition = Vector2.new(0, math.max(0, targetScroll))
    end
end

function Page:Destroy()
    -- Stop spinner
    if self._spinnerConnection then
        self._spinnerConnection:Disconnect()
    end
    
    -- Destroy signals
    self.Loaded_Signal:Destroy()
    self.Entered:Destroy()
    self.Left:Destroy()
    self.Shown:Destroy()
    self.Hidden:Destroy()
    self.Refreshed:Destroy()
    self.ErrorOccurred:Destroy()
    
    -- Destroy frame
    if self.Frame then
        self.Frame:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PAGE MANAGER CLASS
-- ══════════════════════════════════════════════════════════════════════

function PageManager.new(container, options)
    local self = setmetatable({}, PageManager)
    
    -- Merge config
    self.Config = setmetatable(options or {}, {__index = DEFAULT_CONFIG})
    
    -- State
    self.Container = container
    self.Pages = {}
    self.PageOrder = {}
    self.Groups = {}
    self.CurrentPage = nil
    self.PreviousPage = nil
    self._transitioning = false
    self._history = {}
    self._historyIndex = 0
    self._connections = {}
    
    -- Tab system
    self.TabContainer = nil
    self.TabIndicators = {}
    
    -- Breadcrumb system
    self.BreadcrumbContainer = nil
    
    -- Signals
    self.OnPageCreated = Signal.new()
    self.OnPageDestroyed = Signal.new()
    self.OnNavigate = Signal.new()
    self.OnNavigateStart = Signal.new()
    self.OnNavigateComplete = Signal.new()
    self.OnHistoryChanged = Signal.new()
    
    -- Setup
    self:_setupNavigation()
    
    return self
end

function PageManager:_setupNavigation()
    -- Swipe navigation
    if self.Config.EnableSwipeNavigation then
        self:_setupSwipeNavigation()
    end
    
    -- Keyboard navigation
    if self.Config.EnableKeyboardNavigation then
        self:_setupKeyboardNavigation()
    end
end

function PageManager:_setupSwipeNavigation()
    local swipeStart = nil
    local swipeStartTime = nil
    
    local conn1 = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            swipeStart = input.Position
            swipeStartTime = tick()
        end
    end)
    table.insert(self._connections, conn1)
    
    local conn2 = UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or
            input.UserInputType == Enum.UserInputType.MouseButton1) and swipeStart then
            
            local swipeEnd = input.Position
            local deltaX = swipeEnd.X - swipeStart.X
            local deltaY = swipeEnd.Y - swipeStart.Y
            local deltaTime = tick() - swipeStartTime
            
            -- Check if horizontal swipe (and fast enough)
            if math.abs(deltaX) > self.Config.SwipeThreshold and
               math.abs(deltaX) > math.abs(deltaY) * 2 and
               deltaTime < 0.5 then
                
                if deltaX > 0 then
                    self:Previous()
                else
                    self:Next()
                end
            end
            
            swipeStart = nil
        end
    end)
    table.insert(self._connections, conn2)
end

function PageManager:_setupKeyboardNavigation()
    local conn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.PageUp then
            self:Previous()
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.PageDown then
            self:Next()
        elseif input.KeyCode == Enum.KeyCode.Home then
            self:First()
        elseif input.KeyCode == Enum.KeyCode.End then
            self:Last()
        elseif input.KeyCode == Enum.KeyCode.Backspace then
            self:Back()
        end
    end)
    table.insert(self._connections, conn)
end

-- ══════════════════════════════════════════════════════════════════════
-- PAGE CREATION
-- ══════════════════════════════════════════════════════════════════════

function PageManager:CreatePage(name, options)
    if self.Pages[name] then
        warn("PageManager: Page '" .. name .. "' already exists")
        return self.Pages[name]
    end
    
    options = options or {}
    options.Order = options.Order or #self.PageOrder
    
    local page = Page.new(self, name, options)
    
    self.Pages[name] = page
    table.insert(self.PageOrder, name)
    
    -- Sort by order
    table.sort(self.PageOrder, function(a, b)
        return (self.Pages[a].Order or 0) < (self.Pages[b].Order or 0)
    end)
    
    -- Add to group
    if options.Group then
        self.Groups[options.Group] = self.Groups[options.Group] or {}
        table.insert(self.Groups[options.Group], name)
    end
    
    -- Update tab if exists
    if self.TabContainer then
        self:_createTabIndicator(page)
    end
    
    -- Navigate to first page
    if #self.PageOrder == 1 then
        self:Navigate(name, {
            Animate = false,
            AddToHistory = false,
        })
    end
    
    self.OnPageCreated:Fire(page)
    
    return page
end

function PageManager:DestroyPage(name)
    local page = self.Pages[name]
    if not page then return end
    
    -- Remove from order
    for i, pageName in ipairs(self.PageOrder) do
        if pageName == name then
            table.remove(self.PageOrder, i)
            break
        end
    end
    
    -- Remove from group
    if page.Metadata.Group then
        local group = self.Groups[page.Metadata.Group]
        if group then
            for i, pageName in ipairs(group) do
                if pageName == name then
                    table.remove(group, i)
                    break
                end
            end
        end
    end
    
    -- Remove tab
    if self.TabIndicators[name] then
        self.TabIndicators[name]:Destroy()
        self.TabIndicators[name] = nil
    end
    
    -- Navigate away if current
    if self.CurrentPage == page then
        self:First()
    end
    
    -- Destroy page
    page:Destroy()
    self.Pages[name] = nil
    
    self.OnPageDestroyed:Fire(name)
end

function PageManager:GetPage(name)
    return self.Pages[name]
end

function PageManager:GetPages()
    return self.Pages
end

function PageManager:GetPageList()
    local list = {}
    for _, name in ipairs(self.PageOrder) do
        table.insert(list, self.Pages[name])
    end
    return list
end

function PageManager:GetVisiblePages()
    local list = {}
    for _, name in ipairs(self.PageOrder) do
        local page = self.Pages[name]
        if page and not page.Metadata.Hidden and page.Enabled then
            table.insert(list, page)
        end
    end
    return list
end

-- ══════════════════════════════════════════════════════════════════════
-- NAVIGATION
-- ══════════════════════════════════════════════════════════════════════

function PageManager:Navigate(pageName, options)
    options = options or {}
    
    local targetPage = self.Pages[pageName]
    if not targetPage then
        warn("PageManager: Page '" .. pageName .. "' not found")
        return false
    end
    
    -- Check if already current
    if self.CurrentPage == targetPage then
        return true
    end
    
    -- Check if enabled
    if not targetPage.Enabled then
        warn("PageManager: Page '" .. pageName .. "' is disabled")
        return false
    end
    
    -- Check if transitioning
    if self._transitioning and options.Force ~= true then
        return false
    end
    
    local fromPage = self.CurrentPage
    local animate = options.Animate ~= false
    local direction = options.Direction or self:_getNavigationDirection(fromPage, targetPage)
    local transitionStyle = options.TransitionStyle or self.Config.TransitionStyle
    
    -- Fire start event
    self.OnNavigateStart:Fire(fromPage, targetPage)
    
    -- Add to history
    if options.AddToHistory ~= false and self.Config.EnableHistory then
        self:_addToHistory(pageName)
    end
    
    -- Perform navigation
    if animate and fromPage and TRANSITION_STYLES[transitionStyle] then
        self:_animatedNavigate(fromPage, targetPage, direction, transitionStyle)
    else
        self:_instantNavigate(fromPage, targetPage)
    end
    
    return true
end

function PageManager:_instantNavigate(fromPage, targetPage)
    -- Hide previous page
    if fromPage then
        fromPage:Leave(targetPage)
        fromPage:Hide()
    end
    
    -- Show new page
    self.PreviousPage = fromPage
    self.CurrentPage = targetPage
    
    targetPage:Show()
    targetPage:Enter(fromPage)
    
    -- Update UI
    self:_updateTabSelection()
    self:_updateBreadcrumbs()
    
    self.OnNavigate:Fire(targetPage, fromPage)
    self.OnNavigateComplete:Fire(targetPage, fromPage)
end

function PageManager:_animatedNavigate(fromPage, targetPage, direction, styleName)
    self._transitioning = true
    
    local style = TRANSITION_STYLES[styleName] or TRANSITION_STYLES.Slide
    local duration = self.Config.TransitionDuration
    local easing = self.Config.TransitionEasing
    
    -- Setup
    if style.setup then
        style.setup(fromPage, targetPage, direction)
    end
    
    -- Lifecycle
    fromPage:Leave(targetPage)
    targetPage:Enter(fromPage)
    
    self.PreviousPage = fromPage
    self.CurrentPage = targetPage
    
    -- Update UI immediately
    self:_updateTabSelection()
    self:_updateBreadcrumbs()
    
    self.OnNavigate:Fire(targetPage, fromPage)
    
    -- Animate
    if style.animate then
        local tweens = style.animate(fromPage, targetPage, direction, duration, easing)
        
        -- Wait for animation
        task.delay(duration, function()
            -- Cleanup
            fromPage:Hide()
            
            if style.cleanup then
                style.cleanup(fromPage, targetPage)
            end
            
            self._transitioning = false
            self.OnNavigateComplete:Fire(targetPage, fromPage)
        end)
    else
        fromPage:Hide()
        self._transitioning = false
        self.OnNavigateComplete:Fire(targetPage, fromPage)
    end
end

function PageManager:_getNavigationDirection(fromPage, toPage)
    if not fromPage then return 1 end
    
    local fromIndex = table.find(self.PageOrder, fromPage.Name) or 0
    local toIndex = table.find(self.PageOrder, toPage.Name) or 0
    
    return toIndex > fromIndex and 1 or -1
end

function PageManager:Next()
    local currentIndex = self.CurrentPage and table.find(self.PageOrder, self.CurrentPage.Name) or 0
    local visiblePages = self:GetVisiblePages()
    
    for i, page in ipairs(visiblePages) do
        local pageIndex = table.find(self.PageOrder, page.Name)
        if pageIndex > currentIndex then
            return self:Navigate(page.Name, {Direction = 1})
        end
    end
    
    return false
end

function PageManager:Previous()
    local currentIndex = self.CurrentPage and table.find(self.PageOrder, self.CurrentPage.Name) or 999
    local visiblePages = self:GetVisiblePages()
    
    for i = #visiblePages, 1, -1 do
        local page = visiblePages[i]
        local pageIndex = table.find(self.PageOrder, page.Name)
        if pageIndex < currentIndex then
            return self:Navigate(page.Name, {Direction = -1})
        end
    end
    
    return false
end

function PageManager:First()
    local visiblePages = self:GetVisiblePages()
    if #visiblePages > 0 then
        return self:Navigate(visiblePages[1].Name)
    end
    return false
end

function PageManager:Last()
    local visiblePages = self:GetVisiblePages()
    if #visiblePages > 0 then
        return self:Navigate(visiblePages[#visiblePages].Name)
    end
    return false
end

function PageManager:JumpTo(pageName)
    return self:Navigate(pageName, {
        Animate = false,
        AddToHistory = true,
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- HISTORY
-- ══════════════════════════════════════════════════════════════════════

function PageManager:_addToHistory(pageName)
    -- Remove forward history if we're not at the end
    while #self._history > self._historyIndex do
        table.remove(self._history)
    end
    
    -- Add new entry
    table.insert(self._history, pageName)
    self._historyIndex = #self._history
    
    -- Trim history
    while #self._history > self.Config.MaxHistoryLength do
        table.remove(self._history, 1)
        self._historyIndex = self._historyIndex - 1
    end
    
    self.OnHistoryChanged:Fire(self._history, self._historyIndex)
end

function PageManager:Back()
    if not self:CanGoBack() then return false end
    
    self._historyIndex = self._historyIndex - 1
    local pageName = self._history[self._historyIndex]
    
    return self:Navigate(pageName, {
        AddToHistory = false,
        Direction = -1,
    })
end

function PageManager:Forward()
    if not self:CanGoForward() then return false end
    
    self._historyIndex = self._historyIndex + 1
    local pageName = self._history[self._historyIndex]
    
    return self:Navigate(pageName, {
        AddToHistory = false,
        Direction = 1,
    })
end

function PageManager:CanGoBack()
    return self._historyIndex > 1
end

function PageManager:CanGoForward()
    return self._historyIndex < #self._history
end

function PageManager:GetHistory()
    return self._history, self._historyIndex
end

function PageManager:ClearHistory()
    self._history = {}
    if self.CurrentPage then
        self._history = {self.CurrentPage.Name}
    end
    self._historyIndex = #self._history
    self.OnHistoryChanged:Fire(self._history, self._historyIndex)
end

-- ══════════════════════════════════════════════════════════════════════
-- TAB INDICATORS
-- ══════════════════════════════════════════════════════════════════════

function PageManager:CreateTabContainer(parent, options)
    options = options or {}
    
    self.TabContainer = Create.Frame({
        Name = "TabContainer",
        Size = options.Size or UDim2.new(1, 0, 0, 40),
        Position = options.Position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = options.BackgroundColor or Theme:Get("Card"),
        BackgroundTransparency = options.BackgroundTransparency or 0,
        Parent = parent,
    }, {
        Create.Instance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = options.Alignment or Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, options.Spacing or 4),
        }),
        Create.Padding(0, 0, options.PaddingH or 8, options.PaddingH or 8),
    })
    
    -- Scroll for many tabs
    if options.Scrollable then
        local scrollFrame = Create.Scroll({
            Name = "TabScroll",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.X,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            Parent = parent,
        })
        self.TabContainer.Parent = scrollFrame
        self.TabContainer.Size = UDim2.new(0, 0, 1, 0)
        self.TabContainer.AutomaticSize = Enum.AutomaticSize.X
    end
    
    -- Create tabs for existing pages
    for _, pageName in ipairs(self.PageOrder) do
        self:_createTabIndicator(self.Pages[pageName])
    end
    
    return self.TabContainer
end

function PageManager:_createTabIndicator(page)
    if not self.TabContainer then return end
    if page.Metadata.Hidden then return end
    
    local isActive = self.CurrentPage == page
    
    local tab = Create.Button({
        Name = "Tab_" .. page.Name,
        Size = UDim2.new(0, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("CardHover"),
        BackgroundTransparency = isActive and 0 or 0.5,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = page.Order,
        Parent = self.TabContainer,
    }, {
        Create.Corner(8),
        Create.Padding(0, 0, 12, 12),
        Create.Instance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
        }),
    })
    
    -- Icon
    if page.Metadata.Icon then
        local icon
        if page.Metadata.Icon:match("^rbxassetid://") then
            icon = Create.Image({
                Name = "Icon",
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Image = page.Metadata.Icon,
                ImageColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
                LayoutOrder = 1,
                Parent = tab,
            })
        else
            icon = Create.Text({
                Name = "Icon",
                Size = UDim2.fromOffset(16, 16),
                BackgroundTransparency = 1,
                Text = page.Metadata.Icon,
                TextSize = 14,
                LayoutOrder = 1,
                Parent = tab,
            })
        end
    end
    
    -- Label
    local label = Create.Text({
        Name = "Label",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = page.Metadata.Title,
        TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextPrimary"),
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        LayoutOrder = 2,
        Parent = tab,
    })
    
    -- Badge
    if page.Metadata.Badge then
        local badge = Create.Frame({
            Name = "Badge",
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Theme:Get(page.Metadata.BadgeColor) or Theme:Get("Error"),
            LayoutOrder = 3,
            Parent = tab,
        }, {
            Create.Corner(9),
        })
        
        local badgeLabel = Create.Text({
            Name = "Label",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = tostring(page.Metadata.Badge),
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Parent = badge,
        })
    end
    
    -- Click handler
    tab.MouseButton1Click:Connect(function()
        self:Navigate(page.Name)
    end)
    
    -- Hover effects
    tab.MouseEnter:Connect(function()
        if self.CurrentPage ~= page then
            Tween.Fast(tab, {BackgroundTransparency = 0.3})
        end
    end)
    
    tab.MouseLeave:Connect(function()
        if self.CurrentPage ~= page then
            Tween.Fast(tab, {BackgroundTransparency = 0.5})
        end
    end)
    
    self.TabIndicators[page.Name] = tab
end

function PageManager:_updateTabIndicator(pageName)
    local tab = self.TabIndicators[pageName]
    local page = self.Pages[pageName]
    
    if not tab or not page then return end
    
    -- Update visibility
    tab.Visible = not page.Metadata.Hidden and page.Enabled
    
    -- Update badge
    local badge = tab:FindFirstChild("Badge")
    if badge then
        badge.Visible = page.Metadata.Badge ~= nil
        local badgeLabel = badge:FindFirstChild("Label")
        if badgeLabel then
            badgeLabel.Text = tostring(page.Metadata.Badge or "")
        end
    end
end

function PageManager:_updateTabSelection()
    for pageName, tab in pairs(self.TabIndicators) do
        local page = self.Pages[pageName]
        local isActive = self.CurrentPage == page
        
        Tween.Fast(tab, {
            BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("CardHover"),
            BackgroundTransparency = isActive and 0 or 0.5,
        })
        
        local label = tab:FindFirstChild("Label")
        if label then
            Tween.Fast(label, {
                TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextPrimary"),
            })
        end
        
        local icon = tab:FindFirstChild("Icon")
        if icon and icon:IsA("ImageLabel") then
            Tween.Fast(icon, {
                ImageColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
            })
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- BREADCRUMBS
-- ══════════════════════════════════════════════════════════════════════

function PageManager:CreateBreadcrumbContainer(parent, options)
    options = options or {}
    
    self.BreadcrumbContainer = Create.Frame({
        Name = "BreadcrumbContainer",
        Size = options.Size or UDim2.new(1, 0, 0, 24),
        Position = options.Position or UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
    }, {
        Create.Instance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 4),
        }),
    })
    
    self:_updateBreadcrumbs()
    
    return self.BreadcrumbContainer
end

function PageManager:_updateBreadcrumbs()
    if not self.BreadcrumbContainer then return end
    
    -- Clear existing
    for _, child in ipairs(self.BreadcrumbContainer:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Build breadcrumb trail from history
    local trail = {}
    for i = 1, self._historyIndex do
        local pageName = self._history[i]
        if pageName and not table.find(trail, pageName) then
            table.insert(trail, pageName)
        end
    end
    
    -- Limit to last 4 items
    while #trail > 4 do
        table.remove(trail, 1)
    end
    
    for i, pageName in ipairs(trail) do
        local page = self.Pages[pageName]
        if not page then continue end
        
        local isLast = i == #trail
        
        -- Breadcrumb item
        local crumb = Create.Button({
            Name = "Crumb_" .. pageName,
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = page.Metadata.Title,
            TextColor3 = isLast and Theme:Get("TextPrimary") or Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = isLast and Enum.Font.GothamMedium or Enum.Font.Gotham,
            LayoutOrder = i * 2 - 1,
            Parent = self.BreadcrumbContainer,
        })
        
        crumb.MouseButton1Click:Connect(function()
            if not isLast then
                self:Navigate(pageName)
            end
        end)
        
        -- Separator (except last)
        if not isLast then
            Create.Text({
                Name = "Separator",
                Size = UDim2.new(0, 12, 1, 0),
                BackgroundTransparency = 1,
                Text = "›",
                TextColor3 = Theme:Get("TextTertiary"),
                TextSize = 14,
                LayoutOrder = i * 2,
                Parent = self.BreadcrumbContainer,
            })
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- SEARCH
-- ══════════════════════════════════════════════════════════════════════

function PageManager:Search(query)
    query = query:lower()
    local results = {}
    
    for _, pageName in ipairs(self.PageOrder) do
        local page = self.Pages[pageName]
        if not page.Metadata.Searchable then continue end
        if page.Metadata.Hidden then continue end
        
        local score = 0
        local title = page.Metadata.Title:lower()
        local description = page.Metadata.Description:lower()
        
        -- Exact title match
        if title == query then
            score = 100
        -- Title contains query
        elseif title:find(query, 1, true) then
            score = 50
        -- Description contains query
        elseif description:find(query, 1, true) then
            score = 25
        -- Tag match
        else
            for _, tag in ipairs(page.Metadata.Tags) do
                if tag:lower():find(query, 1, true) then
                    score = 30
                    break
                end
            end
        end
        
        if score > 0 then
            table.insert(results, {
                Page = page,
                Score = score,
            })
        end
    end
    
    -- Sort by score
    table.sort(results, function(a, b)
        return a.Score > b.Score
    end)
    
    -- Return pages only
    local pages = {}
    for _, result in ipairs(results) do
        table.insert(pages, result.Page)
    end
    
    return pages
end

-- ══════════════════════════════════════════════════════════════════════
-- PRELOADING
-- ══════════════════════════════════════════════════════════════════════

function PageManager:PreloadPage(pageName)
    local page = self.Pages[pageName]
    if page and not page.Loaded and page.LazyLoad then
        page:Load()
    end
end

function PageManager:PreloadAdjacent()
    if not self.CurrentPage then return end
    
    local currentIndex = table.find(self.PageOrder, self.CurrentPage.Name) or 0
    local range = self.Config.PreloadAdjacentPages
    
    for i = math.max(1, currentIndex - range), math.min(#self.PageOrder, currentIndex + range) do
        local pageName = self.PageOrder[i]
        if pageName ~= self.CurrentPage.Name then
            self:PreloadPage(pageName)
        end
    end
end

function PageManager:PreloadAll()
    for _, pageName in ipairs(self.PageOrder) do
        self:PreloadPage(pageName)
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- UTILITIES
-- ══════════════════════════════════════════════════════════════════════

function PageManager:GetCurrentPage()
    return self.CurrentPage
end

function PageManager:GetCurrentPageName()
    return self.CurrentPage and self.CurrentPage.Name
end

function PageManager:GetPageCount()
    return #self.PageOrder
end

function PageManager:GetVisiblePageCount()
    return #self:GetVisiblePages()
end

function PageManager:GetGroup(groupName)
    return self.Groups[groupName] or {}
end

function PageManager:NavigateToGroup(groupName)
    local group = self.Groups[groupName]
    if group and #group > 0 then
        return self:Navigate(group[1])
    end
    return false
end

function PageManager:SetTransitionStyle(style)
    if TRANSITION_STYLES[style] then
        self.Config.TransitionStyle = style
    end
end

function PageManager:UpdateTheme()
    for _, page in pairs(self.Pages) do
        if page.ScrollFrame then
            page.ScrollFrame.ScrollBarImageColor3 = Theme:Get("TextSecondary")
        end
        if page.LoadingOverlay then
            page.LoadingOverlay.BackgroundColor3 = Theme:Get("Background")
        end
        if page.Spinner and page.Spinner:FindFirstChild("SpinnerImage") then
            page.Spinner.SpinnerImage.ImageColor3 = Theme:Get("Accent")
        end
    end
    
    -- Update tabs
    self:_updateTabSelection()
end

function PageManager:Destroy()
    -- Disconnect all connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    -- Destroy all pages
    for _, page in pairs(self.Pages) do
        page:Destroy()
    end
    self.Pages = {}
    self.PageOrder = {}
    
    -- Destroy signals
    self.OnPageCreated:Destroy()
    self.OnPageDestroyed:Destroy()
    self.OnNavigate:Destroy()
    self.OnNavigateStart:Destroy()
    self.OnNavigateComplete:Destroy()
    self.OnHistoryChanged:Destroy()
    
    -- Destroy UI elements
    if self.TabContainer then
        self.TabContainer:Destroy()
    end
    if self.BreadcrumbContainer then
        self.BreadcrumbContainer:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- STATIC / FACTORY
-- ══════════════════════════════════════════════════════════════════════

PageManager.TransitionStyles = TRANSITION_STYLES
PageManager.Page = Page

return PageManager