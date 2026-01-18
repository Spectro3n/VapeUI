--[[
    VapeUI Configuration
    All settings and defaults centralized.
]]

local Config = {}

-- ═══════════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════════

Config.Window = {
    DefaultSize = Vector2.new(680, 480),
    MinSize = Vector2.new(500, 350),
    CornerRadius = 10,
    ShadowSize = 25,
    DragSmoothing = 0.08,
}

-- ═══════════════════════════════════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════════════════════════════════

Config.Sidebar = {
    Width = 180,
    CollapsedWidth = 50,
    TabHeight = 40,
    TabPadding = 4,
    IconSize = 18,
    IndicatorWidth = 3,
    IndicatorPadding = 8,
}

-- ═══════════════════════════════════════════════════════════════════
-- TOPBAR
-- ═══════════════════════════════════════════════════════════════════

Config.TopBar = {
    Height = 45,
    TitleSize = 15,
    ButtonSize = 28,
    ButtonPadding = 8,
}

-- ═══════════════════════════════════════════════════════════════════
-- COMPONENTS
-- ═══════════════════════════════════════════════════════════════════

Config.Card = {
    Height = 38,
    Padding = 12,
    CornerRadius = 6,
    Spacing = 6,
}

Config.Toggle = {
    Width = 40,
    Height = 22,
    IndicatorSize = 16,
    IndicatorPadding = 3,
}

Config.Slider = {
    Height = 6,
    KnobSize = 14,
    CornerRadius = 3,
}

Config.Dropdown = {
    MaxVisibleItems = 6,
    ItemHeight = 32,
    CornerRadius = 6,
}

Config.Button = {
    Height = 32,
    CornerRadius = 6,
    Padding = 12,
}

Config.Input = {
    Height = 32,
    CornerRadius = 6,
    Padding = 10,
}

-- ═══════════════════════════════════════════════════════════════════
-- ANIMATION
-- ═══════════════════════════════════════════════════════════════════

Config.Animation = {
    Fast = 0.1,
    Normal = 0.15,
    Slow = 0.25,
    Spring = 0.35,
    EasingStyle = Enum.EasingStyle.Quad,
    EasingDirection = Enum.EasingDirection.Out,
}

-- ═══════════════════════════════════════════════════════════════════
-- FONTS
-- ═══════════════════════════════════════════════════════════════════

Config.Font = {
    Title = Enum.Font.GothamBold,
    Heading = Enum.Font.GothamMedium,
    Body = Enum.Font.Gotham,
    Small = Enum.Font.Gotham,
    SizeTitle = 16,
    SizeHeading = 14,
    SizeBody = 13,
    SizeSmall = 11,
}

-- ═══════════════════════════════════════════════════════════════════
-- KEYBINDS
-- ═══════════════════════════════════════════════════════════════════

Config.Keybinds = {
    ToggleUI = Enum.KeyCode.RightShift,
    CloseDropdowns = Enum.KeyCode.Escape,
}

-- ═══════════════════════════════════════════════════════════════════
-- MISC
-- ═══════════════════════════════════════════════════════════════════

Config.Misc = {
    BlurEnabled = true,
    BlurSize = 12,
    NotificationDuration = 4,
    TooltipDelay = 0.5,
}

return Config