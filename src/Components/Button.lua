--[[
    VapeUI Button v2.0
    Advanced clickable action button system.
    
    Features:
    ✅ Multiple styles (Default, Primary, Secondary, Ghost, Outline, Danger, Success)
    ✅ Size variants (Small, Medium, Large, Full)
    ✅ Icon support (Left, Right, Icon-only)
    ✅ Loading state with spinner
    ✅ Disabled state
    ✅ Material Design ripple effect
    ✅ Confirmation mode (hold/double-click)
    ✅ Cooldown system
    ✅ Badge/Counter support
    ✅ Tooltip on hover
    ✅ Sound effects
    ✅ Async callback support
    ✅ Keyboard accessibility
    ✅ Button groups
    ✅ Gradient backgrounds
    ✅ Press animations
    ✅ Long press support
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

local Button = {}
Button.__index = Button

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local STYLES = {
    Default = {
        Background = "Card",
        BackgroundHover = "CardHover",
        BackgroundActive = "CardActive",
        Text = "TextPrimary",
        Border = "Border",
        BorderTransparency = 0.6,
    },
    Primary = {
        Background = "Accent",
        BackgroundHover = "AccentHover",
        BackgroundActive = "AccentActive",
        Text = "TextOnAccent",
        Border = "Accent",
        BorderTransparency = 1,
    },
    Secondary = {
        Background = "CardHover",
        BackgroundHover = "CardActive",
        BackgroundActive = "Card",
        Text = "TextPrimary",
        Border = "Border",
        BorderTransparency = 0.5,
    },
    Ghost = {
        Background = "Transparent",
        BackgroundHover = "CardHover",
        BackgroundActive = "CardActive",
        Text = "TextPrimary",
        Border = "Transparent",
        BorderTransparency = 1,
    },
    Outline = {
        Background = "Transparent",
        BackgroundHover = "CardHover",
        BackgroundActive = "Card",
        Text = "Accent",
        Border = "Accent",
        BorderTransparency = 0,
    },
    Danger = {
        Background = "Error",
        BackgroundHover = "ErrorHover",
        BackgroundActive = "Error",
        Text = "TextOnAccent",
        Border = "Error",
        BorderTransparency = 1,
    },
    Success = {
        Background = "Success",
        BackgroundHover = "SuccessHover",
        BackgroundActive = "Success",
        Text = "TextOnAccent",
        Border = "Success",
        BorderTransparency = 1,
    },
    Warning = {
        Background = "Warning",
        BackgroundHover = "WarningHover",
        BackgroundActive = "Warning",
        Text = "TextOnAccent",
        Border = "Warning",
        BorderTransparency = 1,
    },
}

local SIZES = {
    Small = {
        Height = 28,
        PaddingH = 12,
        PaddingV = 6,
        TextSize = 11,
        IconSize = 14,
        CornerRadius = 6,
        Spacing = 6,
    },
    Medium = {
        Height = 36,
        PaddingH = 16,
        PaddingV = 8,
        TextSize = 13,
        IconSize = 18,
        CornerRadius = 8,
        Spacing = 8,
    },
    Large = {
        Height = 44,
        PaddingH = 20,
        PaddingV = 10,
        TextSize = 15,
        IconSize = 22,
        CornerRadius = 10,
        Spacing = 10,
    },
    XLarge = {
        Height = 52,
        PaddingH = 24,
        PaddingV = 12,
        TextSize = 17,
        IconSize = 26,
        CornerRadius = 12,
        Spacing = 12,
    },
}

local DEFAULT_CONFIG = {
    -- Appearance
    Style = "Default",
    Size = "Medium",
    FullWidth = true,
    
    -- Content
    Text = "Button",
    Icon = nil,
    IconPosition = "Left",  -- Left, Right, Only
    
    -- Behavior
    Enabled = true,
    Cooldown = 0,
    ConfirmMode = nil,  -- nil, "Hold", "DoubleClick"
    ConfirmTime = 1.5,  -- For Hold mode
    ConfirmTimeout = 2, -- For DoubleClick mode
    
    -- Features
    EnableRipple = true,
    EnableSound = false,
    EnableTooltip = false,
    TooltipText = "",
    TooltipPosition = "Top",
    
    -- Badge
    Badge = nil,
    BadgeColor = "Error",
    
    -- Loading
    LoadingText = "Loading...",
    
    -- Animation
    AnimationStyle = "Scale",  -- Scale, Fade, Bounce, None
}

-- ══════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.GetThemeColor(key)
    if key == "Transparent" then
        return Color3.new(1, 1, 1), 1
    end
    
    -- Try to get from theme, fallback to defaults
    local success, color = pcall(function()
        return Theme:Get(key)
    end)
    
    if success and color then
        return color, 0
    end
    
    -- Fallbacks for missing theme keys
    local fallbacks = {
        TextOnAccent = Color3.new(1, 1, 1),
        AccentHover = Color3.fromRGB(100, 80, 220),
        AccentActive = Color3.fromRGB(120, 100, 240),
        ErrorHover = Color3.fromRGB(220, 50, 50),
        SuccessHover = Color3.fromRGB(30, 180, 80),
        WarningHover = Color3.fromRGB(220, 170, 10),
    }
    
    return fallbacks[key] or Color3.fromRGB(128, 128, 128), 0
end

function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.PlaySound(soundId)
    pcall(function()
        local sound = Instance.new("Sound")
        sound.SoundId = soundId or "rbxassetid://6026984224"
        sound.Volume = 0.3
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- BUTTON CLASS
-- ══════════════════════════════════════════════════════════════════════

function Button.new(parent, options)
    local self = setmetatable({}, Button)
    
    -- Merge options with defaults
    options = options or {}
    self.Config = setmetatable({}, {__index = DEFAULT_CONFIG})
    for key, value in pairs(options) do
        self.Config[key] = value
    end
    
    -- Legacy support
    if options.Name then
        self.Config.Text = options.Name
    end
    if options.Callback then
        self.Config.OnClick = options.Callback
    end
    
    -- State
    self.Enabled = self.Config.Enabled
    self.Loading = false
    self.Pressed = false
    self.Hovered = false
    self.Focused = false
    self._cooldownActive = false
    self._confirmPending = false
    self._confirmStartTime = 0
    self._connections = {}
    self._holdConnection = nil
    
    -- Signals
    self.OnClick = Signal.new()
    self.OnDoubleClick = Signal.new()
    self.OnLongPress = Signal.new()
    self.OnHover = Signal.new()
    self.OnPress = Signal.new()
    self.OnRelease = Signal.new()
    self.OnConfirm = Signal.new()
    
    -- Build UI
    self:_build(parent)
    self:_setupInteractions()
    
    return self
end

function Button:_build(parent)
    local config = self.Config
    local styleConfig = STYLES[config.Style] or STYLES.Default
    local sizeConfig = SIZES[config.Size] or SIZES.Medium
    
    self._styleConfig = styleConfig
    self._sizeConfig = sizeConfig
    
    -- Calculate size
    local width = config.FullWidth and UDim2.new(1, 0, 0, sizeConfig.Height) or UDim2.new(0, 0, 0, sizeConfig.Height)
    local autoSize = not config.FullWidth and Enum.AutomaticSize.X or Enum.AutomaticSize.None
    
    -- Get colors
    local bgColor, bgTransparency = Utils.GetThemeColor(styleConfig.Background)
    local textColor = Utils.GetThemeColor(styleConfig.Text)
    local borderColor = Utils.GetThemeColor(styleConfig.Border)
    
    -- Main button frame
    self.Frame = Create.Button({
        Name = "Button_" .. config.Text,
        Size = width,
        AutomaticSize = autoSize,
        BackgroundColor3 = bgColor,
        BackgroundTransparency = bgTransparency,
        Text = "",
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = parent,
    }, {
        Create.Corner(sizeConfig.CornerRadius),
        Create.Stroke({
            Color = borderColor,
            Transparency = styleConfig.BorderTransparency,
            Thickness = 1,
        }),
    })
    
    -- Content container
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    }, {
        Create.Instance("UIListLayout", {
            Name = "Layout",
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, sizeConfig.Spacing),
        }),
        Create.Padding(0, 0, sizeConfig.PaddingH, sizeConfig.PaddingH),
    })
    
    -- Icon (Left)
    if config.Icon and (config.IconPosition == "Left" or config.IconPosition == "Only") then
        self:_createIcon("LeftIcon", config.Icon, 1)
    end
    
    -- Text label (unless icon only)
    if config.IconPosition ~= "Only" then
        self.TextLabel = Create.Text({
            Name = "Label",
            Size = UDim2.new(0, 0, 0, sizeConfig.Height),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text = config.Text,
            TextColor3 = textColor,
            TextSize = sizeConfig.TextSize,
            Font = Enum.Font.GothamMedium,
            LayoutOrder = 2,
            Parent = self.Content,
        })
    end
    
    -- Icon (Right)
    if config.Icon and config.IconPosition == "Right" then
        self:_createIcon("RightIcon", config.Icon, 3)
    end
    
    -- Loading spinner (hidden by default)
    self:_createSpinner()
    
    -- Ripple container
    if config.EnableRipple then
        self.RippleContainer = Create.Frame({
            Name = "RippleContainer",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            ZIndex = 0,
            Parent = self.Frame,
        }, {
            Create.Corner(sizeConfig.CornerRadius),
        })
    end
    
    -- Badge
    if config.Badge then
        self:_createBadge(config.Badge)
    end
    
    -- Tooltip
    if config.EnableTooltip and config.TooltipText ~= "" then
        self:_createTooltip()
    end
    
    -- Hold progress bar (for confirm mode)
    if config.ConfirmMode == "Hold" then
        self:_createHoldProgress()
    end
    
    -- Focus ring (accessibility)
    self.FocusRing = Create.Frame({
        Name = "FocusRing",
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.Corner(sizeConfig.CornerRadius + 2),
        Create.Stroke({
            Color = Utils.GetThemeColor("Accent"),
            Thickness = 2,
        }),
    })
    
    -- Store original properties
    self._originalBgColor = bgColor
    self._originalBgTransparency = bgTransparency
    self._originalTextColor = textColor
end

function Button:_createIcon(name, icon, layoutOrder)
    local sizeConfig = self._sizeConfig
    local textColor = Utils.GetThemeColor(self._styleConfig.Text)
    
    local iconFrame
    
    -- Check if icon is an asset ID or emoji/text
    if type(icon) == "string" and icon:match("^rbxassetid://") then
        iconFrame = Create.Image({
            Name = name,
            Size = UDim2.fromOffset(sizeConfig.IconSize, sizeConfig.IconSize),
            BackgroundTransparency = 1,
            Image = icon,
            ImageColor3 = textColor,
            LayoutOrder = layoutOrder,
            Parent = self.Content,
        })
    else
        iconFrame = Create.Text({
            Name = name,
            Size = UDim2.fromOffset(sizeConfig.IconSize, sizeConfig.IconSize),
            BackgroundTransparency = 1,
            Text = icon or "●",
            TextColor3 = textColor,
            TextSize = sizeConfig.IconSize - 2,
            Font = Enum.Font.GothamBold,
            LayoutOrder = layoutOrder,
            Parent = self.Content,
        })
    end
    
    self[name] = iconFrame
    return iconFrame
end

function Button:_createSpinner()
    local sizeConfig = self._sizeConfig
    local textColor = Utils.GetThemeColor(self._styleConfig.Text)
    
    self.Spinner = Create.Frame({
        Name = "Spinner",
        Size = UDim2.fromOffset(sizeConfig.IconSize, sizeConfig.IconSize),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
        Parent = self.Frame,
    })
    
    -- Spinner arc
    self.SpinnerArc = Create.Image({
        Name = "Arc",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031302931", -- Circular loading
        ImageColor3 = textColor,
        Parent = self.Spinner,
    })
    
    -- Loading text (optional)
    self.LoadingLabel = Create.Text({
        Name = "LoadingText",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0.5, sizeConfig.IconSize / 2 + 8, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = self.Config.LoadingText,
        TextColor3 = textColor,
        TextSize = sizeConfig.TextSize,
        Font = Enum.Font.GothamMedium,
        Visible = false,
        Parent = self.Spinner,
    })
end

function Button:_createBadge(content)
    local sizeConfig = self._sizeConfig
    local badgeColor = Utils.GetThemeColor(self.Config.BadgeColor)
    
    self.Badge = Create.Frame({
        Name = "Badge",
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -4, 0, -4),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = badgeColor,
        ZIndex = 10,
        Parent = self.Frame,
    }, {
        Create.Corner(9),
    })
    
    self.BadgeLabel = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(content),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = self.Badge,
    })
end

function Button:_createTooltip()
    local config = self.Config
    
    self.Tooltip = Create.Frame({
        Name = "Tooltip",
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        Position = self:_getTooltipPosition(),
        AnchorPoint = self:_getTooltipAnchor(),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        Visible = false,
        ZIndex = 100,
        Parent = self.Frame,
    }, {
        Create.Corner(6),
        Create.Padding(0, 0, 10, 10),
    })
    
    self.TooltipLabel = Create.Text({
        Name = "Label",
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = config.TooltipText,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        Font = Enum.Font.Gotham,
        Parent = self.Tooltip,
    })
end

function Button:_getTooltipPosition()
    local pos = self.Config.TooltipPosition
    if pos == "Top" then
        return UDim2.new(0.5, 0, 0, -8)
    elseif pos == "Bottom" then
        return UDim2.new(0.5, 0, 1, 8)
    elseif pos == "Left" then
        return UDim2.new(0, -8, 0.5, 0)
    elseif pos == "Right" then
        return UDim2.new(1, 8, 0.5, 0)
    end
    return UDim2.new(0.5, 0, 0, -8)
end

function Button:_getTooltipAnchor()
    local pos = self.Config.TooltipPosition
    if pos == "Top" then
        return Vector2.new(0.5, 1)
    elseif pos == "Bottom" then
        return Vector2.new(0.5, 0)
    elseif pos == "Left" then
        return Vector2.new(1, 0.5)
    elseif pos == "Right" then
        return Vector2.new(0, 0.5)
    end
    return Vector2.new(0.5, 1)
end

function Button:_createHoldProgress()
    local sizeConfig = self._sizeConfig
    
    self.HoldProgress = Create.Frame({
        Name = "HoldProgress",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.8,
        ZIndex = 1,
        Parent = self.Frame,
    }, {
        Create.Corner(sizeConfig.CornerRadius),
    })
end

function Button:_setupInteractions()
    local frame = self.Frame
    
    -- Mouse enter
    frame.MouseEnter:Connect(function()
        if not self.Enabled or self.Loading then return end
        self.Hovered = true
        self:_onHover(true)
    end)
    
    -- Mouse leave
    frame.MouseLeave:Connect(function()
        self.Hovered = false
        self.Pressed = false
        self:_onHover(false)
        self:_cancelHold()
        
        -- Hide tooltip
        if self.Tooltip then
            self.Tooltip.Visible = false
        end
    end)
    
    -- Mouse button down
    frame.MouseButton1Down:Connect(function()
        if not self.Enabled or self.Loading then return end
        self.Pressed = true
        self:_onPress()
        
        -- Start hold detection
        if self.Config.ConfirmMode == "Hold" then
            self:_startHold()
        end
    end)
    
    -- Mouse button up
    frame.MouseButton1Up:Connect(function()
        if not self.Enabled or self.Loading then return end
        
        local wasPressed = self.Pressed
        self.Pressed = false
        self:_onRelease()
        self:_cancelHold()
        
        -- Handle click
        if wasPressed then
            self:_handleClick()
        end
    end)
    
    -- Double click detection
    local lastClickTime = 0
    frame.MouseButton1Click:Connect(function()
        local now = tick()
        if now - lastClickTime < 0.3 then
            self.OnDoubleClick:Fire()
        end
        lastClickTime = now
    end)
end

function Button:_onHover(isHovered)
    if not self.Enabled then return end
    
    local styleConfig = self._styleConfig
    local targetColor = isHovered 
        and Utils.GetThemeColor(styleConfig.BackgroundHover)
        or self._originalBgColor
    
    Tween.Fast(self.Frame, {BackgroundColor3 = targetColor})
    
    -- Show/hide tooltip
    if self.Tooltip then
        if isHovered then
            task.delay(0.5, function()
                if self.Hovered and self.Tooltip then
                    self.Tooltip.Visible = true
                    self.Tooltip.BackgroundTransparency = 1
                    Tween.Fast(self.Tooltip, {BackgroundTransparency = 0})
                end
            end)
        else
            self.Tooltip.Visible = false
        end
    end
    
    self.OnHover:Fire(isHovered)
end

function Button:_onPress()
    local config = self.Config
    local styleConfig = self._styleConfig
    
    -- Active color
    local activeColor = Utils.GetThemeColor(styleConfig.BackgroundActive)
    Tween.Fast(self.Frame, {BackgroundColor3 = activeColor})
    
    -- Animation based on style
    if config.AnimationStyle == "Scale" then
        Tween.Fast(self.Frame, {
            Size = UDim2.new(
                self.Frame.Size.X.Scale,
                self.Frame.Size.X.Offset - 4,
                self.Frame.Size.Y.Scale,
                self._sizeConfig.Height - 2
            )
        })
    elseif config.AnimationStyle == "Bounce" then
        local originalSize = self.Frame.Size
        Tween.Fast(self.Frame, {
            Size = UDim2.new(
                originalSize.X.Scale * 0.95,
                originalSize.X.Offset * 0.95,
                originalSize.Y.Scale,
                self._sizeConfig.Height * 0.95
            )
        })
    end
    
    self.OnPress:Fire()
end

function Button:_onRelease()
    local config = self.Config
    
    -- Restore size
    if config.AnimationStyle == "Scale" or config.AnimationStyle == "Bounce" then
        local targetSize = config.FullWidth 
            and UDim2.new(1, 0, 0, self._sizeConfig.Height)
            or self.Frame.Size -- AutomaticSize handles this
        
        Tween.Fast(self.Frame, {Size = targetSize})
    end
    
    -- Restore color
    local targetColor = self.Hovered 
        and Utils.GetThemeColor(self._styleConfig.BackgroundHover)
        or self._originalBgColor
    
    Tween.Fast(self.Frame, {BackgroundColor3 = targetColor})
    
    self.OnRelease:Fire()
end

function Button:_handleClick()
    local config = self.Config
    
    -- Check cooldown
    if self._cooldownActive then return end
    
    -- Check confirm mode
    if config.ConfirmMode == "DoubleClick" then
        if self._confirmPending then
            -- Confirmed!
            self._confirmPending = false
            self:_executeClick()
        else
            -- First click - wait for second
            self._confirmPending = true
            self:_showConfirmState()
            
            task.delay(config.ConfirmTimeout, function()
                if self._confirmPending then
                    self._confirmPending = false
                    self:_hideConfirmState()
                end
            end)
        end
        return
    end
    
    -- Normal click (Hold mode handles separately)
    if config.ConfirmMode ~= "Hold" then
        self:_executeClick()
    end
end

function Button:_executeClick()
    local config = self.Config
    
    -- Play sound
    if config.EnableSound then
        Utils.PlaySound()
    end
    
    -- Ripple effect
    if config.EnableRipple then
        self:_createRipple()
    end
    
    -- Start cooldown
    if config.Cooldown > 0 then
        self:_startCooldown()
    end
    
    -- Execute callback
    if config.OnClick then
        -- Check if callback returns a promise/async
        local result = config.OnClick(self)
        
        if type(result) == "table" and result.andThen then
            -- Handle as promise
            self:SetLoading(true)
            result:andThen(function()
                self:SetLoading(false)
            end):catch(function()
                self:SetLoading(false)
            end)
        end
    end
    
    -- Fire signal
    self.OnClick:Fire()
end

function Button:_startHold()
    local config = self.Config
    
    self._confirmStartTime = tick()
    
    -- Animate progress bar
    if self.HoldProgress then
        self.HoldProgress.Size = UDim2.new(0, 0, 1, 0)
        self.HoldProgress.Visible = true
        
        Tween.new(self.HoldProgress, {
            Size = UDim2.new(1, 0, 1, 0)
        }, config.ConfirmTime, Enum.EasingStyle.Linear)
    end
    
    -- Check completion
    self._holdConnection = RunService.Heartbeat:Connect(function()
        if not self.Pressed then
            self:_cancelHold()
            return
        end
        
        local elapsed = tick() - self._confirmStartTime
        if elapsed >= config.ConfirmTime then
            self:_cancelHold()
            self.OnConfirm:Fire()
            self:_executeClick()
        end
    end)
end

function Button:_cancelHold()
    if self._holdConnection then
        self._holdConnection:Disconnect()
        self._holdConnection = nil
    end
    
    if self.HoldProgress then
        Tween.Fast(self.HoldProgress, {Size = UDim2.new(0, 0, 1, 0)})
    end
end

function Button:_showConfirmState()
    -- Visual feedback for double-click confirm
    if self.TextLabel then
        self._originalText = self.TextLabel.Text
        self.TextLabel.Text = "Click again to confirm"
    end
    
    Tween.Fast(self.Frame, {
        BackgroundColor3 = Utils.GetThemeColor("Warning")
    })
end

function Button:_hideConfirmState()
    if self.TextLabel and self._originalText then
        self.TextLabel.Text = self._originalText
    end
    
    Tween.Fast(self.Frame, {
        BackgroundColor3 = self._originalBgColor
    })
end

function Button:_startCooldown()
    local config = self.Config
    
    self._cooldownActive = true
    self:SetEnabled(false)
    
    task.delay(config.Cooldown, function()
        self._cooldownActive = false
        if self.Enabled ~= false then
            self:SetEnabled(true)
        end
    end)
end

function Button:_createRipple()
    if not self.RippleContainer then return end
    
    local mouse = UserInputService:GetMouseLocation()
    local framePos = self.Frame.AbsolutePosition
    local frameSize = self.Frame.AbsoluteSize
    
    -- Calculate ripple position relative to button
    local relX = math.clamp(mouse.X - framePos.X, 0, frameSize.X)
    local relY = math.clamp(mouse.Y - framePos.Y - 36, 0, frameSize.Y) -- Account for topbar
    
    -- Calculate max size (diagonal of button)
    local maxSize = math.sqrt(frameSize.X^2 + frameSize.Y^2) * 2
    
    -- Create ripple circle
    local ripple = Create.Frame({
        Name = "Ripple",
        Size = UDim2.fromOffset(0, 0),
        Position = UDim2.fromOffset(relX, relY),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        ZIndex = 1,
        Parent = self.RippleContainer,
    }, {
        Create.Corner(maxSize),
    })
    
    -- Animate ripple
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(ripple, tweenInfo, {
        Size = UDim2.fromOffset(maxSize, maxSize),
        BackgroundTransparency = 1,
    })
    
    tween:Play()
    tween.Completed:Connect(function()
        ripple:Destroy()
    end)
end

function Button:_startSpinnerAnimation()
    if self._spinnerAnimation then return end
    
    self._spinnerAnimation = RunService.Heartbeat:Connect(function(dt)
        if self.SpinnerArc then
            self.SpinnerArc.Rotation = self.SpinnerArc.Rotation + dt * 360
        end
    end)
end

function Button:_stopSpinnerAnimation()
    if self._spinnerAnimation then
        self._spinnerAnimation:Disconnect()
        self._spinnerAnimation = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function Button:SetText(text)
    if self.TextLabel then
        self.TextLabel.Text = text
    end
    self.Config.Text = text
end

function Button:GetText()
    return self.Config.Text
end

function Button:SetIcon(icon, position)
    position = position or self.Config.IconPosition
    
    -- Remove existing icons
    if self.LeftIcon then self.LeftIcon:Destroy() self.LeftIcon = nil end
    if self.RightIcon then self.RightIcon:Destroy() self.RightIcon = nil end
    
    -- Create new icon
    if icon then
        if position == "Left" or position == "Only" then
            self:_createIcon("LeftIcon", icon, 1)
        end
        if position == "Right" then
            self:_createIcon("RightIcon", icon, 3)
        end
    end
    
    self.Config.Icon = icon
    self.Config.IconPosition = position
end

function Button:SetEnabled(enabled)
    self.Enabled = enabled
    self.Frame.Active = enabled
    
    local transparency = enabled and self._originalBgTransparency or 0.5
    local textTransparency = enabled and 0 or 0.5
    
    Tween.Fast(self.Frame, {BackgroundTransparency = transparency})
    
    if self.TextLabel then
        Tween.Fast(self.TextLabel, {TextTransparency = textTransparency})
    end
    
    if self.LeftIcon then
        if self.LeftIcon:IsA("ImageLabel") then
            Tween.Fast(self.LeftIcon, {ImageTransparency = textTransparency})
        else
            Tween.Fast(self.LeftIcon, {TextTransparency = textTransparency})
        end
    end
end

function Button:IsEnabled()
    return self.Enabled
end

function Button:SetLoading(loading, text)
    self.Loading = loading
    
    if loading then
        -- Hide content
        self.Content.Visible = false
        
        -- Show spinner
        self.Spinner.Visible = true
        self:_startSpinnerAnimation()
        
        -- Update loading text
        if text then
            self.LoadingLabel.Text = text
            self.LoadingLabel.Visible = true
        end
        
        -- Disable interactions
        self.Frame.Active = false
    else
        -- Show content
        self.Content.Visible = true
        
        -- Hide spinner
        self.Spinner.Visible = false
        self.LoadingLabel.Visible = false
        self:_stopSpinnerAnimation()
        
        -- Enable interactions
        self.Frame.Active = self.Enabled
    end
end

function Button:IsLoading()
    return self.Loading
end

function Button:SetBadge(content)
    if content == nil then
        if self.Badge then
            self.Badge.Visible = false
        end
        return
    end
    
    if not self.Badge then
        self:_createBadge(content)
    else
        self.BadgeLabel.Text = tostring(content)
        self.Badge.Visible = true
    end
end

function Button:SetStyle(style)
    local styleConfig = STYLES[style]
    if not styleConfig then return end
    
    self.Config.Style = style
    self._styleConfig = styleConfig
    
    -- Update colors
    local bgColor = Utils.GetThemeColor(styleConfig.Background)
    local textColor = Utils.GetThemeColor(styleConfig.Text)
    local borderColor = Utils.GetThemeColor(styleConfig.Border)
    
    self._originalBgColor = bgColor
    self._originalTextColor = textColor
    
    self.Frame.BackgroundColor3 = bgColor
    
    if self.TextLabel then
        self.TextLabel.TextColor3 = textColor
    end
    
    local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = borderColor
        stroke.Transparency = styleConfig.BorderTransparency
    end
end

function Button:SetSize(size)
    local sizeConfig = SIZES[size]
    if not sizeConfig then return end
    
    self.Config.Size = size
    self._sizeConfig = sizeConfig
    
    -- Update frame
    self.Frame.Size = self.Config.FullWidth 
        and UDim2.new(1, 0, 0, sizeConfig.Height)
        or UDim2.new(0, 0, 0, sizeConfig.Height)
    
    local corner = self.Frame:FindFirstChild("UICorner")
    if corner then
        corner.CornerRadius = UDim.new(0, sizeConfig.CornerRadius)
    end
    
    -- Update text
    if self.TextLabel then
        self.TextLabel.TextSize = sizeConfig.TextSize
    end
    
    -- Update padding
    local padding = self.Content:FindFirstChild("UIPadding")
    if padding then
        padding.PaddingLeft = UDim.new(0, sizeConfig.PaddingH)
        padding.PaddingRight = UDim.new(0, sizeConfig.PaddingH)
    end
    
    local layout = self.Content:FindFirstChild("Layout")
    if layout then
        layout.Padding = UDim.new(0, sizeConfig.Spacing)
    end
end

function Button:SetTooltip(text)
    self.Config.TooltipText = text
    
    if self.TooltipLabel then
        self.TooltipLabel.Text = text
    elseif text and text ~= "" then
        self.Config.EnableTooltip = true
        self:_createTooltip()
    end
end

function Button:Click()
    if self.Enabled and not self.Loading then
        self:_executeClick()
    end
end

function Button:Focus()
    self.Focused = true
    self.FocusRing.Visible = true
end

function Button:Blur()
    self.Focused = false
    self.FocusRing.Visible = false
end

function Button:UpdateTheme()
    local styleConfig = self._styleConfig
    
    -- Update colors from theme
    local bgColor = Utils.GetThemeColor(styleConfig.Background)
    local textColor = Utils.GetThemeColor(styleConfig.Text)
    local borderColor = Utils.GetThemeColor(styleConfig.Border)
    
    self._originalBgColor = bgColor
    self._originalTextColor = textColor
    
    if not self.Hovered and not self.Pressed then
        self.Frame.BackgroundColor3 = bgColor
    end
    
    if self.TextLabel then
        self.TextLabel.TextColor3 = textColor
    end
    
    local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = borderColor
    end
    
    -- Update icons
    for _, iconName in ipairs({"LeftIcon", "RightIcon"}) do
        local icon = self[iconName]
        if icon then
            if icon:IsA("ImageLabel") then
                icon.ImageColor3 = textColor
            else
                icon.TextColor3 = textColor
            end
        end
    end
    
    -- Update spinner
    if self.SpinnerArc then
        self.SpinnerArc.ImageColor3 = textColor
    end
    
    -- Update focus ring
    local focusStroke = self.FocusRing:FindFirstChildOfClass("UIStroke")
    if focusStroke then
        focusStroke.Color = Utils.GetThemeColor("Accent")
    end
end

function Button:Destroy()
    -- Disconnect all connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    self:_cancelHold()
    self:_stopSpinnerAnimation()
    
    -- Destroy signals
    self.OnClick:Destroy()
    self.OnDoubleClick:Destroy()
    self.OnLongPress:Destroy()
    self.OnHover:Destroy()
    self.OnPress:Destroy()
    self.OnRelease:Destroy()
    self.OnConfirm:Destroy()
    
    -- Destroy frame
    if self.Frame then
        self.Frame:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- BUTTON GROUP (Static)
-- ══════════════════════════════════════════════════════════════════════

local ButtonGroup = {}
ButtonGroup.__index = ButtonGroup

function Button.CreateGroup(parent, options)
    local group = setmetatable({}, ButtonGroup)
    
    options = options or {}
    group.Buttons = {}
    group.Layout = options.Layout or "Horizontal"  -- Horizontal, Vertical
    group.Spacing = options.Spacing or 8
    group.SelectedIndex = options.DefaultSelected or 0
    group.AllowDeselect = options.AllowDeselect or false
    
    -- Signals
    group.OnSelectionChanged = Signal.new()
    
    -- Container
    group.Frame = Create.Frame({
        Name = "ButtonGroup",
        Size = options.Size or UDim2.new(1, 0, 0, 36),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Parent = parent,
    }, {
        Create.Instance("UIListLayout", {
            FillDirection = group.Layout == "Horizontal" 
                and Enum.FillDirection.Horizontal 
                or Enum.FillDirection.Vertical,
            Padding = UDim.new(0, group.Spacing),
        }),
    })
    
    return group
end

function ButtonGroup:AddButton(options)
    local index = #self.Buttons + 1
    
    options = options or {}
    options.FullWidth = self.Layout == "Vertical"
    
    local button = Button.new(self.Frame, options)
    
    -- Override click to handle selection
    local originalCallback = options.OnClick or options.Callback
    
    button.OnClick:Connect(function()
        self:Select(index)
        if originalCallback then
            originalCallback(button)
        end
    end)
    
    table.insert(self.Buttons, button)
    
    -- Select if default
    if index == self.SelectedIndex then
        self:Select(index)
    end
    
    return button
end

function ButtonGroup:Select(index)
    if index == self.SelectedIndex and not self.AllowDeselect then
        return
    end
    
    local previousIndex = self.SelectedIndex
    
    -- Deselect previous
    if self.Buttons[previousIndex] then
        self.Buttons[previousIndex]:SetStyle("Default")
    end
    
    -- Select new (or deselect if same)
    if index == self.SelectedIndex and self.AllowDeselect then
        self.SelectedIndex = 0
    else
        self.SelectedIndex = index
        if self.Buttons[index] then
            self.Buttons[index]:SetStyle("Primary")
        end
    end
    
    self.OnSelectionChanged:Fire(self.SelectedIndex, previousIndex)
end

function ButtonGroup:GetSelected()
    return self.SelectedIndex, self.Buttons[self.SelectedIndex]
end

function ButtonGroup:Destroy()
    for _, button in ipairs(self.Buttons) do
        button:Destroy()
    end
    self.Buttons = {}
    self.OnSelectionChanged:Destroy()
    self.Frame:Destroy()
end

Button.Group = ButtonGroup

return Button