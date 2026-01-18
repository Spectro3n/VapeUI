--[[
    VapeUI Theme System
    Centralized color management - NO hardcoded colors anywhere else.
]]

local Theme = {}
Theme.__index = Theme

-- ═══════════════════════════════════════════════════════════════════
-- COLOR PALETTES
-- ═══════════════════════════════════════════════════════════════════

Theme.Palettes = {
    Dark = {
        -- Base
        Window = Color3.fromRGB(18, 18, 18),
        Sidebar = Color3.fromRGB(21, 21, 21),
        TopBar = Color3.fromRGB(24, 24, 24),
        Content = Color3.fromRGB(18, 18, 18),
        
        -- Cards
        Card = Color3.fromRGB(26, 26, 26),
        CardHover = Color3.fromRGB(32, 32, 32),
        CardActive = Color3.fromRGB(36, 36, 36),
        
        -- Borders
        Border = Color3.fromRGB(38, 38, 38),
        Divider = Color3.fromRGB(35, 35, 35),
        
        -- Text
        TextPrimary = Color3.fromRGB(225, 225, 225),
        TextSecondary = Color3.fromRGB(160, 160, 160),
        TextMuted = Color3.fromRGB(100, 100, 100),
        TextDisabled = Color3.fromRGB(60, 60, 60),
        
        -- Accent
        Accent = Color3.fromRGB(0, 255, 140),
        AccentHover = Color3.fromRGB(0, 230, 125),
        AccentDark = Color3.fromRGB(0, 180, 100),
        
        -- Components
        ToggleOff = Color3.fromRGB(45, 45, 45),
        ToggleOn = Color3.fromRGB(0, 255, 140),
        SliderBackground = Color3.fromRGB(40, 40, 40),
        SliderFill = Color3.fromRGB(0, 255, 140),
        
        -- Feedback
        Success = Color3.fromRGB(0, 255, 140),
        Warning = Color3.fromRGB(255, 200, 60),
        Error = Color3.fromRGB(255, 80, 80),
        Info = Color3.fromRGB(80, 180, 255),
        
        -- Shadow
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.6,
    },
    
    Midnight = {
        Window = Color3.fromRGB(12, 14, 20),
        Sidebar = Color3.fromRGB(15, 17, 24),
        TopBar = Color3.fromRGB(18, 20, 28),
        Content = Color3.fromRGB(12, 14, 20),
        Card = Color3.fromRGB(20, 23, 32),
        CardHover = Color3.fromRGB(26, 30, 42),
        CardActive = Color3.fromRGB(30, 35, 48),
        Border = Color3.fromRGB(35, 40, 55),
        Divider = Color3.fromRGB(30, 35, 48),
        TextPrimary = Color3.fromRGB(230, 235, 245),
        TextSecondary = Color3.fromRGB(150, 160, 180),
        TextMuted = Color3.fromRGB(90, 100, 120),
        TextDisabled = Color3.fromRGB(55, 60, 75),
        Accent = Color3.fromRGB(100, 140, 255),
        AccentHover = Color3.fromRGB(80, 120, 235),
        AccentDark = Color3.fromRGB(60, 100, 200),
        ToggleOff = Color3.fromRGB(40, 45, 60),
        ToggleOn = Color3.fromRGB(100, 140, 255),
        SliderBackground = Color3.fromRGB(35, 40, 55),
        SliderFill = Color3.fromRGB(100, 140, 255),
        Success = Color3.fromRGB(80, 220, 140),
        Warning = Color3.fromRGB(255, 190, 70),
        Error = Color3.fromRGB(255, 90, 90),
        Info = Color3.fromRGB(100, 180, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.5,
    },
    
    Crimson = {
        Window = Color3.fromRGB(18, 14, 14),
        Sidebar = Color3.fromRGB(22, 17, 17),
        TopBar = Color3.fromRGB(26, 20, 20),
        Content = Color3.fromRGB(18, 14, 14),
        Card = Color3.fromRGB(30, 22, 22),
        CardHover = Color3.fromRGB(38, 28, 28),
        CardActive = Color3.fromRGB(44, 32, 32),
        Border = Color3.fromRGB(50, 35, 35),
        Divider = Color3.fromRGB(42, 30, 30),
        TextPrimary = Color3.fromRGB(240, 225, 225),
        TextSecondary = Color3.fromRGB(180, 150, 150),
        TextMuted = Color3.fromRGB(120, 95, 95),
        TextDisabled = Color3.fromRGB(75, 55, 55),
        Accent = Color3.fromRGB(255, 70, 85),
        AccentHover = Color3.fromRGB(235, 55, 70),
        AccentDark = Color3.fromRGB(200, 45, 60),
        ToggleOff = Color3.fromRGB(50, 38, 38),
        ToggleOn = Color3.fromRGB(255, 70, 85),
        SliderBackground = Color3.fromRGB(45, 35, 35),
        SliderFill = Color3.fromRGB(255, 70, 85),
        Success = Color3.fromRGB(100, 230, 130),
        Warning = Color3.fromRGB(255, 180, 60),
        Error = Color3.fromRGB(255, 70, 85),
        Info = Color3.fromRGB(100, 170, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.5,
    },
    
    Purple = {
        Window = Color3.fromRGB(16, 14, 22),
        Sidebar = Color3.fromRGB(20, 17, 28),
        TopBar = Color3.fromRGB(24, 20, 34),
        Content = Color3.fromRGB(16, 14, 22),
        Card = Color3.fromRGB(28, 24, 38),
        CardHover = Color3.fromRGB(36, 30, 48),
        CardActive = Color3.fromRGB(42, 36, 56),
        Border = Color3.fromRGB(48, 40, 65),
        Divider = Color3.fromRGB(40, 34, 54),
        TextPrimary = Color3.fromRGB(235, 230, 245),
        TextSecondary = Color3.fromRGB(170, 160, 190),
        TextMuted = Color3.fromRGB(110, 100, 130),
        TextDisabled = Color3.fromRGB(65, 58, 80),
        Accent = Color3.fromRGB(160, 100, 255),
        AccentHover = Color3.fromRGB(140, 80, 235),
        AccentDark = Color3.fromRGB(120, 60, 200),
        ToggleOff = Color3.fromRGB(45, 38, 60),
        ToggleOn = Color3.fromRGB(160, 100, 255),
        SliderBackground = Color3.fromRGB(40, 34, 55),
        SliderFill = Color3.fromRGB(160, 100, 255),
        Success = Color3.fromRGB(100, 230, 160),
        Warning = Color3.fromRGB(255, 190, 80),
        Error = Color3.fromRGB(255, 85, 100),
        Info = Color3.fromRGB(120, 180, 255),
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.5,
    },
}

-- ═══════════════════════════════════════════════════════════════════
-- CURRENT THEME
-- ═══════════════════════════════════════════════════════════════════

Theme.Current = Theme.Palettes.Dark
Theme.CurrentName = "Dark"

-- ═══════════════════════════════════════════════════════════════════
-- METHODS
-- ═══════════════════════════════════════════════════════════════════

function Theme:Set(paletteName)
    if type(paletteName) == "string" and self.Palettes[paletteName] then
        self.Current = self.Palettes[paletteName]
        self.CurrentName = paletteName
        return true
    elseif type(paletteName) == "table" then
        self.Current = paletteName
        self.CurrentName = "Custom"
        return true
    end
    return false
end

function Theme:Get(key)
    return self.Current[key]
end

function Theme:GetColor(colorName)
    return self.Current[colorName] or Color3.fromRGB(255, 0, 255) -- Magenta fallback
end

function Theme:AddPalette(name, palette)
    self.Palettes[name] = palette
end

function Theme:GetPaletteNames()
    local names = {}
    for name in pairs(self.Palettes) do
        table.insert(names, name)
    end
    return names
end

return Theme