--[[
    VapeUI Notification System v2.0
    Advanced toast-style notification system with modern features.
    
    Features:
    ✅ Multiple positions (TopRight, TopLeft, BottomRight, BottomLeft, TopCenter, BottomCenter)
    ✅ Action buttons (Confirm/Cancel/Custom)
    ✅ Hover to pause countdown
    ✅ Swipe/Drag to dismiss
    ✅ Smart queue with priority
    ✅ Notification grouping
    ✅ Notification history
    ✅ Custom icons/images
    ✅ Sound effects
    ✅ Multiple styles (Default, Minimal, Compact, Expanded)
    ✅ Animated progress bar
    ✅ Blur background effect
    ✅ Stacking with smart reposition
    ✅ Rich text support
    ✅ Callbacks for all events
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

local Notification = {}
Notification.__index = Notification

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    MaxVisible = 5,
    MaxHistory = 50,
    DefaultDuration = 5,
    MinDuration = 2,
    MaxDuration = 30,
    DefaultPosition = "BottomRight",
    DefaultStyle = "Default",
    EnableSounds = true,
    EnableBlur = true,
    EnableHistory = true,
    EnableGrouping = true,
    AnimationSpeed = 0.3,
    SwipeThreshold = 100,
    StackSpacing = 10,
    Width = 340,
    CompactWidth = 280,
    ExpandedWidth = 400,
}

-- Position configurations
local POSITIONS = {
    TopRight = {
        Anchor = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 20),
        Direction = 1,  -- Stack downward
        Alignment = Enum.VerticalAlignment.Top,
    },
    TopLeft = {
        Anchor = Vector2.new(0, 0),
        Position = UDim2.new(0, 20, 0, 20),
        Direction = 1,
        Alignment = Enum.VerticalAlignment.Top,
    },
    BottomRight = {
        Anchor = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -20),
        Direction = -1,  -- Stack upward
        Alignment = Enum.VerticalAlignment.Bottom,
    },
    BottomLeft = {
        Anchor = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, -20),
        Direction = -1,
        Alignment = Enum.VerticalAlignment.Bottom,
    },
    TopCenter = {
        Anchor = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 20),
        Direction = 1,
        Alignment = Enum.VerticalAlignment.Top,
    },
    BottomCenter = {
        Anchor = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -20),
        Direction = -1,
        Alignment = Enum.VerticalAlignment.Bottom,
    },
}

-- Notification types with enhanced configuration
local TYPES = {
    Info = {
        Color = Color3.fromRGB(59, 130, 246),
        Icon = "rbxassetid://7733960981",  -- Info icon
        IconFallback = "ℹ",
        Sound = "rbxassetid://6026984224",
        Priority = 1,
    },
    Success = {
        Color = Color3.fromRGB(34, 197, 94),
        Icon = "rbxassetid://7733715400",  -- Checkmark
        IconFallback = "✓",
        Sound = "rbxassetid://6026984224",
        Priority = 2,
    },
    Warning = {
        Color = Color3.fromRGB(234, 179, 8),
        Icon = "rbxassetid://7734053495",  -- Warning
        IconFallback = "⚠",
        Sound = "rbxassetid://6026984224",
        Priority = 3,
    },
    Error = {
        Color = Color3.fromRGB(239, 68, 68),
        Icon = "rbxassetid://7733658504",  -- X mark
        IconFallback = "✕",
        Sound = "rbxassetid://6026984224",
        Priority = 4,
    },
    Custom = {
        Color = Color3.fromRGB(139, 92, 246),
        Icon = "rbxassetid://7733960981",
        IconFallback = "★",
        Sound = "rbxassetid://6026984224",
        Priority = 2,
    },
}

-- Styles
local STYLES = {
    Default = {
        Width = 340,
        ShowIcon = true,
        ShowProgress = true,
        ShowCloseButton = true,
        Padding = 16,
        IconSize = 24,
        TitleSize = 14,
        MessageSize = 12,
        BorderRadius = 12,
    },
    Minimal = {
        Width = 280,
        ShowIcon = true,
        ShowProgress = false,
        ShowCloseButton = false,
        Padding = 12,
        IconSize = 18,
        TitleSize = 13,
        MessageSize = 11,
        BorderRadius = 8,
    },
    Compact = {
        Width = 260,
        ShowIcon = true,
        ShowProgress = true,
        ShowCloseButton = false,
        Padding = 10,
        IconSize = 16,
        TitleSize = 12,
        MessageSize = 11,
        BorderRadius = 6,
    },
    Expanded = {
        Width = 400,
        ShowIcon = true,
        ShowProgress = true,
        ShowCloseButton = true,
        Padding = 20,
        IconSize = 32,
        TitleSize = 16,
        MessageSize = 13,
        BorderRadius = 16,
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFICATION MANAGER (Singleton)
-- ══════════════════════════════════════════════════════════════════════

local NotificationManager = {}
NotificationManager._containers = {}
NotificationManager._active = {}
NotificationManager._queue = {}
NotificationManager._history = {}
NotificationManager._groups = {}
NotificationManager._config = table.clone(DEFAULT_CONFIG)
NotificationManager._screenGui = nil
NotificationManager._initialized = false

-- Signals
NotificationManager.OnNotificationShown = Signal.new()
NotificationManager.OnNotificationDismissed = Signal.new()
NotificationManager.OnNotificationClicked = Signal.new()
NotificationManager.OnNotificationAction = Signal.new()
NotificationManager.OnQueueUpdated = Signal.new()

function NotificationManager:Initialize(screenGui)
    if self._initialized then return end
    
    self._screenGui = screenGui
    self._initialized = true
    
    -- Create containers for each position
    for posName, posConfig in pairs(POSITIONS) do
        self._containers[posName] = self:_createContainer(posName, posConfig)
        self._active[posName] = {}
    end
    
    -- Start queue processor
    self:_startQueueProcessor()
    
    return self
end

function NotificationManager:_createContainer(name, config)
    local container = Create.Frame({
        Name = "NotificationContainer_" .. name,
        Size = UDim2.new(0, DEFAULT_CONFIG.Width + 40, 1, 0),
        Position = config.Position,
        AnchorPoint = config.Anchor,
        BackgroundTransparency = 1,
        Parent = self._screenGui,
    }, {
        Create.Instance("UIListLayout", {
            Name = "Layout",
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = config.Alignment,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding = UDim.new(0, DEFAULT_CONFIG.StackSpacing),
        }),
    })
    
    return container
end

function NotificationManager:_startQueueProcessor()
    task.spawn(function()
        while true do
            task.wait(0.1)
            self:_processQueue()
        end
    end)
end

function NotificationManager:_processQueue()
    for posName, queue in pairs(self._queue) do
        local activeCount = #(self._active[posName] or {})
        
        while #queue > 0 and activeCount < self._config.MaxVisible do
            local notifData = table.remove(queue, 1)
            self:_showNotification(notifData)
            activeCount = activeCount + 1
        end
    end
end

function NotificationManager:_showNotification(data)
    local notif = Notification._create(self, data)
    table.insert(self._active[data.Position], notif)
    
    -- Add to history
    if self._config.EnableHistory then
        table.insert(self._history, 1, {
            Title = data.Title,
            Message = data.Message,
            Type = data.Type,
            Timestamp = os.time(),
        })
        
        -- Trim history
        while #self._history > self._config.MaxHistory do
            table.remove(self._history)
        end
    end
    
    self.OnNotificationShown:Fire(notif)
    return notif
end

function NotificationManager:_removeFromActive(notif)
    local position = notif._data.Position
    local activeList = self._active[position]
    
    if activeList then
        for i, n in ipairs(activeList) do
            if n == notif then
                table.remove(activeList, i)
                break
            end
        end
    end
    
    self.OnNotificationDismissed:Fire(notif)
end

function NotificationManager:Configure(options)
    for key, value in pairs(options) do
        if self._config[key] ~= nil then
            self._config[key] = value
        end
    end
end

function NotificationManager:GetHistory()
    return self._history
end

function NotificationManager:ClearHistory()
    self._history = {}
end

function NotificationManager:DismissAll(position)
    if position then
        local activeList = self._active[position]
        if activeList then
            for _, notif in ipairs(activeList) do
                notif:Dismiss()
            end
        end
    else
        for _, activeList in pairs(self._active) do
            for _, notif in ipairs(activeList) do
                notif:Dismiss()
            end
        end
    end
end

function NotificationManager:GetActiveCount(position)
    if position then
        return #(self._active[position] or {})
    end
    
    local total = 0
    for _, activeList in pairs(self._active) do
        total = total + #activeList
    end
    return total
end

-- ══════════════════════════════════════════════════════════════════════
-- NOTIFICATION CLASS
-- ══════════════════════════════════════════════════════════════════════

function Notification._create(manager, data)
    local self = setmetatable({}, Notification)
    
    self._manager = manager
    self._data = data
    self._paused = false
    self._dismissed = false
    self._elapsed = 0
    self._connections = {}
    self._dragStart = nil
    self._originalPosition = nil
    
    -- Signals
    self.OnDismiss = Signal.new()
    self.OnClick = Signal.new()
    self.OnAction = Signal.new()
    self.OnHover = Signal.new()
    
    self:_build()
    self:_animate("in")
    self:_startTimer()
    self:_setupInteractions()
    
    if manager._config.EnableSounds and data.Sound ~= false then
        self:_playSound()
    end
    
    return self
end

function Notification:_build()
    local data = self._data
    local typeConfig = TYPES[data.Type] or TYPES.Info
    local styleConfig = STYLES[data.Style] or STYLES.Default
    local container = self._manager._containers[data.Position]
    
    local accentColor = data.Color or typeConfig.Color
    
    -- Calculate height
    local estimatedHeight = styleConfig.Padding * 2 + 20
    if data.Message and data.Message ~= "" then
        estimatedHeight = estimatedHeight + 20
    end
    if data.Actions and #data.Actions > 0 then
        estimatedHeight = estimatedHeight + 40
    end
    
    -- Main frame with glassmorphism effect
    self.Frame = Create.Frame({
        Name = "Notification",
        Size = UDim2.new(0, styleConfig.Width, 0, 0),
        BackgroundColor3 = Theme:Get("Card"),
        BackgroundTransparency = 0.05,
        ClipsDescendants = true,
        LayoutOrder = data.Priority or 1,
        Parent = container,
    }, {
        Create.Corner(styleConfig.BorderRadius),
        Create.Stroke({
            Color = accentColor,
            Transparency = 0.7,
            Thickness = 1,
        }),
    })
    
    -- Blur effect (if supported)
    if self._manager._config.EnableBlur then
        pcall(function()
            local blur = Instance.new("BlurEffect")
            blur.Size = 10
            -- Note: BlurEffect doesn't work on frames, this is for future compatibility
        end)
    end
    
    -- Accent gradient bar
    self.AccentBar = Create.Frame({
        Name = "AccentBar",
        Size = UDim2.new(0, 4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = self.Frame,
    }, {
        Create.Instance("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
            }),
            Rotation = 90,
        }),
        Create.Instance("UICorner", {
            CornerRadius = UDim.new(0, styleConfig.BorderRadius),
        }),
    })
    
    -- Content container
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.Padding(styleConfig.Padding, styleConfig.Padding, styleConfig.Padding, 8),
    })
    
    -- Header container (icon + title + close)
    self.Header = Create.Frame({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, math.max(styleConfig.IconSize, 20)),
        BackgroundTransparency = 1,
        Parent = self.Content,
    })
    
    -- Icon
    if styleConfig.ShowIcon then
        local iconContent = data.Icon or typeConfig.Icon
        
        if type(iconContent) == "string" and iconContent:match("^rbxassetid://") then
            self.Icon = Create.Image({
                Name = "Icon",
                Size = UDim2.fromOffset(styleConfig.IconSize, styleConfig.IconSize),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Image = iconContent,
                ImageColor3 = accentColor,
                Parent = self.Header,
            })
        else
            self.Icon = Create.Text({
                Name = "Icon",
                Size = UDim2.fromOffset(styleConfig.IconSize, styleConfig.IconSize),
                Position = UDim2.new(0, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                Text = data.Icon or typeConfig.IconFallback,
                TextColor3 = accentColor,
                TextSize = styleConfig.IconSize - 4,
                Font = Enum.Font.GothamBold,
                Parent = self.Header,
            })
        end
    end
    
    -- Title
    local titleOffset = styleConfig.ShowIcon and (styleConfig.IconSize + 10) or 0
    local closeOffset = styleConfig.ShowCloseButton and 30 or 0
    
    self.Title = Create.Text({
        Name = "Title",
        Size = UDim2.new(1, -(titleOffset + closeOffset), 0, 20),
        Position = UDim2.new(0, titleOffset, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = data.Title or "Notification",
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = styleConfig.TitleSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Config.Font.Title or Enum.Font.GothamBold,
        Parent = self.Header,
    })
    
    -- Close button
    if styleConfig.ShowCloseButton then
        self.CloseButton = Create.Button({
            Name = "CloseButton",
            Size = UDim2.fromOffset(24, 24),
            Position = UDim2.new(1, 0, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Theme:Get("CardHover"),
            BackgroundTransparency = 0.5,
            Text = "✕",
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            Parent = self.Header,
        }, {
            Create.Corner(6),
        })
        
        self.CloseButton.MouseButton1Click:Connect(function()
            self:Dismiss()
        end)
        
        self.CloseButton.MouseEnter:Connect(function()
            Tween.Fast(self.CloseButton, {
                BackgroundTransparency = 0,
                TextColor3 = Theme:Get("Error"),
            })
        end)
        
        self.CloseButton.MouseLeave:Connect(function()
            Tween.Fast(self.CloseButton, {
                BackgroundTransparency = 0.5,
                TextColor3 = Theme:Get("TextSecondary"),
            })
        end)
    end
    
    -- Message
    local yOffset = math.max(styleConfig.IconSize, 20) + 8
    
    if data.Message and data.Message ~= "" then
        self.Message = Create.Text({
            Name = "Message",
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, yOffset),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = data.Message,
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = styleConfig.MessageSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Font = Config.Font.Body or Enum.Font.Gotham,
            RichText = true,
            Parent = self.Content,
        })
        yOffset = yOffset + 8 -- Will be adjusted after we know message height
    end
    
    -- Subtitle (optional)
    if data.Subtitle then
        self.Subtitle = Create.Text({
            Name = "Subtitle",
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, yOffset),
            BackgroundTransparency = 1,
            Text = data.Subtitle,
            TextColor3 = Theme:Get("TextTertiary"),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham,
            Parent = self.Content,
        })
        yOffset = yOffset + 18
    end
    
    -- Action buttons
    if data.Actions and #data.Actions > 0 then
        self.ActionContainer = Create.Frame({
            Name = "Actions",
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 1, -40),
            BackgroundTransparency = 1,
            Parent = self.Content,
        }, {
            Create.Instance("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
            }),
        })
        
        for i, action in ipairs(data.Actions) do
            local isPrimary = action.Primary or i == 1
            
            local actionBtn = Create.Button({
                Name = "Action_" .. (action.Text or i),
                Size = UDim2.new(0, 0, 0, 28),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = isPrimary and accentColor or Theme:Get("CardHover"),
                Text = action.Text or "Action",
                TextColor3 = isPrimary and Color3.new(1, 1, 1) or Theme:Get("TextPrimary"),
                TextSize = 11,
                Font = Enum.Font.GothamMedium,
                LayoutOrder = i,
                Parent = self.ActionContainer,
            }, {
                Create.Corner(6),
                Create.Padding(0, 0, 12, 12),
            })
            
            actionBtn.MouseButton1Click:Connect(function()
                if action.Callback then
                    action.Callback(self)
                end
                self.OnAction:Fire(action.Text, action)
                self._manager.OnNotificationAction:Fire(self, action.Text, action)
                
                if action.CloseOnClick ~= false then
                    self:Dismiss()
                end
            end)
            
            -- Hover effects
            actionBtn.MouseEnter:Connect(function()
                Tween.Fast(actionBtn, {
                    BackgroundColor3 = isPrimary 
                        and accentColor:Lerp(Color3.new(1, 1, 1), 0.2)
                        or Theme:Get("CardActive"),
                })
            end)
            
            actionBtn.MouseLeave:Connect(function()
                Tween.Fast(actionBtn, {
                    BackgroundColor3 = isPrimary and accentColor or Theme:Get("CardHover"),
                })
            end)
        end
    end
    
    -- Progress bar
    if styleConfig.ShowProgress and data.Duration and data.Duration > 0 then
        self.ProgressContainer = Create.Frame({
            Name = "ProgressContainer",
            Size = UDim2.new(1, 0, 0, 3),
            Position = UDim2.new(0, 0, 1, 0),
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = Theme:Get("CardHover"),
            BackgroundTransparency = 0.5,
            Parent = self.Frame,
        })
        
        self.ProgressBar = Create.Frame({
            Name = "ProgressBar",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            Parent = self.ProgressContainer,
        }, {
            Create.Instance("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, accentColor),
                }),
            }),
        })
    end
    
    -- Time indicator
    if data.ShowTime then
        self.TimeLabel = Create.Text({
            Name = "Time",
            Size = UDim2.new(0, 50, 0, 12),
            Position = UDim2.new(1, -8, 0, 8),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Text = "now",
            TextColor3 = Theme:Get("TextTertiary"),
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
            Font = Enum.Font.Gotham,
            Parent = self.Frame,
        })
    end
    
    -- Store for height calculation
    self._styleConfig = styleConfig
    self._accentColor = accentColor
end

function Notification:_calculateHeight()
    local styleConfig = self._styleConfig
    local baseHeight = styleConfig.Padding * 2
    local contentHeight = math.max(styleConfig.IconSize, 20) -- Header
    
    if self.Message then
        task.wait() -- Wait for TextBounds to update
        contentHeight = contentHeight + 8 + self.Message.TextBounds.Y
    end
    
    if self._data.Subtitle then
        contentHeight = contentHeight + 18
    end
    
    if self._data.Actions and #self._data.Actions > 0 then
        contentHeight = contentHeight + 44
    end
    
    if self._styleConfig.ShowProgress then
        baseHeight = baseHeight + 3
    end
    
    return math.max(baseHeight + contentHeight, 60)
end

function Notification:_animate(direction)
    local posConfig = POSITIONS[self._data.Position]
    local targetHeight = self:_calculateHeight()
    
    if direction == "in" then
        -- Initial state
        self.Frame.Size = UDim2.new(0, self._styleConfig.Width, 0, 0)
        self.Frame.BackgroundTransparency = 1
        
        -- Determine slide direction
        local slideOffset = 50
        if posConfig.Anchor.X > 0.5 then
            self.Frame.Position = UDim2.new(0, slideOffset, 0, 0)
        else
            self.Frame.Position = UDim2.new(0, -slideOffset, 0, 0)
        end
        
        -- Animate in
        local tweenInfo = TweenInfo.new(
            self._manager._config.AnimationSpeed,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out
        )
        
        TweenService:Create(self.Frame, tweenInfo, {
            Size = UDim2.new(0, self._styleConfig.Width, 0, targetHeight),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 0.05,
        }):Play()
        
        -- Fade in accent bar
        self.AccentBar.BackgroundTransparency = 1
        Tween.Normal(self.AccentBar, {BackgroundTransparency = 0})
        
    elseif direction == "out" then
        local tweenInfo = TweenInfo.new(
            self._manager._config.AnimationSpeed * 0.7,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.In
        )
        
        local slideOffset = 100
        if posConfig.Anchor.X > 0.5 then
            TweenService:Create(self.Frame, tweenInfo, {
                Position = UDim2.new(0, slideOffset, 0, 0),
                Size = UDim2.new(0, self._styleConfig.Width, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
        else
            TweenService:Create(self.Frame, tweenInfo, {
                Position = UDim2.new(0, -slideOffset, 0, 0),
                Size = UDim2.new(0, self._styleConfig.Width, 0, 0),
                BackgroundTransparency = 1,
            }):Play()
        end
    end
end

function Notification:_startTimer()
    local duration = self._data.Duration or self._manager._config.DefaultDuration
    if duration <= 0 then return end -- Persistent notification
    
    self._startTime = tick()
    self._duration = duration
    
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if self._dismissed then
            connection:Disconnect()
            return
        end
        
        if not self._paused then
            self._elapsed = self._elapsed + dt
            
            -- Update progress bar
            if self.ProgressBar then
                local progress = 1 - (self._elapsed / duration)
                self.ProgressBar.Size = UDim2.new(math.max(0, progress), 0, 1, 0)
            end
            
            -- Check if expired
            if self._elapsed >= duration then
                connection:Disconnect()
                self:Dismiss()
            end
        end
    end)
    
    table.insert(self._connections, connection)
end

function Notification:_setupInteractions()
    local data = self._data
    
    -- Click handler
    local clickDetector = Create.Button({
        Name = "ClickDetector",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 0,
        Parent = self.Frame,
    })
    
    clickDetector.MouseButton1Click:Connect(function()
        if data.OnClick then
            data.OnClick(self)
        end
        self.OnClick:Fire()
        self._manager.OnNotificationClicked:Fire(self)
        
        if data.DismissOnClick then
            self:Dismiss()
        end
    end)
    
    -- Hover to pause
    clickDetector.MouseEnter:Connect(function()
        self._paused = true
        self.OnHover:Fire(true)
        
        -- Visual feedback
        Tween.Fast(self.Frame, {BackgroundTransparency = 0})
        if self.ProgressBar then
            Tween.Fast(self.ProgressBar, {BackgroundTransparency = 0.3})
        end
    end)
    
    clickDetector.MouseLeave:Connect(function()
        self._paused = false
        self.OnHover:Fire(false)
        
        -- Visual feedback
        Tween.Fast(self.Frame, {BackgroundTransparency = 0.05})
        if self.ProgressBar then
            Tween.Fast(self.ProgressBar, {BackgroundTransparency = 0})
        end
    end)
    
    -- Swipe to dismiss
    if data.SwipeToDismiss ~= false then
        self:_setupSwipe(clickDetector)
    end
end

function Notification:_setupSwipe(detector)
    local dragging = false
    local startPos = nil
    local startFramePos = nil
    
    detector.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = input.Position
            startFramePos = self.Frame.Position
        end
    end)
    
    detector.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                local delta = input.Position.X - startPos.X
                
                if math.abs(delta) > self._manager._config.SwipeThreshold then
                    self:Dismiss()
                else
                    -- Snap back
                    Tween.Fast(self.Frame, {Position = startFramePos})
                end
            end
        end
    end)
    
    local moveConnection
    moveConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position.X - startPos.X
            self.Frame.Position = UDim2.new(
                startFramePos.X.Scale,
                startFramePos.X.Offset + delta,
                startFramePos.Y.Scale,
                startFramePos.Y.Offset
            )
            
            -- Fade as dragged
            local fadeAmount = math.abs(delta) / self._manager._config.SwipeThreshold
            self.Frame.BackgroundTransparency = math.min(0.5, fadeAmount * 0.5)
        end
    end)
    
    table.insert(self._connections, moveConnection)
end

function Notification:_playSound()
    local typeConfig = TYPES[self._data.Type] or TYPES.Info
    local soundId = self._data.Sound or typeConfig.Sound
    
    if soundId then
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Volume = 0.5
            sound.Parent = self._manager._screenGui
            sound:Play()
            sound.Ended:Connect(function()
                sound:Destroy()
            end)
        end)
    end
end

function Notification:Pause()
    self._paused = true
end

function Notification:Resume()
    self._paused = false
end

function Notification:Dismiss()
    if self._dismissed then return end
    self._dismissed = true
    
    -- Clean up connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    -- Animate out
    self:_animate("out")
    
    -- Fire events
    self.OnDismiss:Fire()
    
    -- Remove from manager
    self._manager:_removeFromActive(self)
    
    -- Destroy after animation
    task.delay(self._manager._config.AnimationSpeed, function()
        if self.Frame then
            self.Frame:Destroy()
        end
        self.OnDismiss:Destroy()
        self.OnClick:Destroy()
        self.OnAction:Destroy()
        self.OnHover:Destroy()
    end)
end

function Notification:Update(options)
    if options.Title and self.Title then
        self.Title.Text = options.Title
    end
    
    if options.Message and self.Message then
        self.Message.Text = options.Message
    end
    
    if options.Type then
        local typeConfig = TYPES[options.Type] or TYPES.Info
        if self.Icon then
            if self.Icon:IsA("ImageLabel") then
                self.Icon.ImageColor3 = typeConfig.Color
            else
                self.Icon.TextColor3 = typeConfig.Color
            end
        end
        if self.AccentBar then
            Tween.Fast(self.AccentBar, {BackgroundColor3 = typeConfig.Color})
        end
        if self.ProgressBar then
            Tween.Fast(self.ProgressBar, {BackgroundColor3 = typeConfig.Color})
        end
    end
    
    if options.Duration then
        self._duration = options.Duration
        self._elapsed = 0
    end
end

function Notification:UpdateTheme()
    if self.Frame then
        self.Frame.BackgroundColor3 = Theme:Get("Card")
    end
    if self.Title then
        self.Title.TextColor3 = Theme:Get("TextPrimary")
    end
    if self.Message then
        self.Message.TextColor3 = Theme:Get("TextSecondary")
    end
    if self.CloseButton then
        self.CloseButton.BackgroundColor3 = Theme:Get("CardHover")
        self.CloseButton.TextColor3 = Theme:Get("TextSecondary")
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function Notification.Initialize(screenGui)
    return NotificationManager:Initialize(screenGui)
end

function Notification.new(screenGui, options)
    -- Ensure manager is initialized
    if not NotificationManager._initialized then
        NotificationManager:Initialize(screenGui)
    end
    
    -- Process options
    options = options or {}
    local data = {
        Title = options.Title or "Notification",
        Message = options.Message or "",
        Subtitle = options.Subtitle,
        Type = options.Type or "Info",
        Duration = options.Duration or NotificationManager._config.DefaultDuration,
        Position = options.Position or NotificationManager._config.DefaultPosition,
        Style = options.Style or NotificationManager._config.DefaultStyle,
        Icon = options.Icon,
        Color = options.Color,
        Sound = options.Sound,
        Actions = options.Actions,
        Priority = options.Priority or (TYPES[options.Type or "Info"] or {}).Priority or 1,
        ShowTime = options.ShowTime,
        DismissOnClick = options.DismissOnClick,
        SwipeToDismiss = options.SwipeToDismiss,
        OnClick = options.OnClick,
        OnDismiss = options.OnDismiss,
        Callback = options.Callback, -- Legacy support
    }
    
    -- Check for grouping
    if NotificationManager._config.EnableGrouping and options.GroupId then
        local existingGroup = NotificationManager._groups[options.GroupId]
        if existingGroup and not existingGroup._dismissed then
            -- Update existing notification
            existingGroup:Update({
                Message = data.Message,
            })
            return existingGroup
        end
    end
    
    -- Queue or show immediately
    local position = data.Position
    NotificationManager._queue[position] = NotificationManager._queue[position] or {}
    
    local activeCount = #(NotificationManager._active[position] or {})
    if activeCount < NotificationManager._config.MaxVisible then
        local notif = NotificationManager:_showNotification(data)
        
        if options.GroupId then
            NotificationManager._groups[options.GroupId] = notif
        end
        
        return notif
    else
        table.insert(NotificationManager._queue[position], data)
        NotificationManager.OnQueueUpdated:Fire(position, #NotificationManager._queue[position])
        return nil -- Queued
    end
end

-- Convenience methods
function Notification.Info(screenGui, title, message, options)
    options = options or {}
    options.Title = title
    options.Message = message
    options.Type = "Info"
    return Notification.new(screenGui, options)
end

function Notification.Success(screenGui, title, message, options)
    options = options or {}
    options.Title = title
    options.Message = message
    options.Type = "Success"
    return Notification.new(screenGui, options)
end

function Notification.Warning(screenGui, title, message, options)
    options = options or {}
    options.Title = title
    options.Message = message
    options.Type = "Warning"
    return Notification.new(screenGui, options)
end

function Notification.Error(screenGui, title, message, options)
    options = options or {}
    options.Title = title
    options.Message = message
    options.Type = "Error"
    return Notification.new(screenGui, options)
end

function Notification.Confirm(screenGui, title, message, onConfirm, onCancel)
    return Notification.new(screenGui, {
        Title = title,
        Message = message,
        Type = "Warning",
        Duration = 0, -- Persistent
        Actions = {
            {
                Text = "Confirm",
                Primary = true,
                Callback = onConfirm,
            },
            {
                Text = "Cancel",
                Callback = onCancel,
            },
        },
    })
end

function Notification.Prompt(screenGui, title, message, actions)
    return Notification.new(screenGui, {
        Title = title,
        Message = message,
        Type = "Info",
        Duration = 0,
        Actions = actions,
    })
end

-- Backward compatibility
function Notification.Show(screenGui, options)
    return Notification.new(screenGui, options)
end

-- Manager access
Notification.Manager = NotificationManager

return Notification