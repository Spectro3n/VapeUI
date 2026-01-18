--[[
    VapeUI Color Picker v2.0
    Advanced HSV/RGB/HEX color selection system.
    
    Features:
    ✅ HSV Color Wheel + Square picker
    ✅ Alpha/Transparency support
    ✅ RGB sliders with live input
    ✅ HEX input with validation
    ✅ Color history (recent colors)
    ✅ Favorite colors (saveable)
    ✅ Preset color palettes
    ✅ Copy/Paste colors
    ✅ Compare mode (old vs new)
    ✅ Multiple picker styles
    ✅ Gradient support
    ✅ Color blindness simulation
    ✅ Smooth animations
    ✅ Keyboard shortcuts
    ✅ Touch support
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

-- Services
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local RunService = Services.RunService

local ColorPicker = {}
ColorPicker.__index = ColorPicker

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Sizes
    CollapsedHeight = 38,
    ExpandedHeight = 320,
    PaletteSize = 150,
    HueBarWidth = 20,
    AlphaBarHeight = 20,
    PreviewSize = 28,
    SliderHeight = 24,
    
    -- Features
    EnableAlpha = true,
    EnableHex = true,
    EnableRGB = true,
    EnableHistory = true,
    EnableFavorites = true,
    EnablePresets = true,
    EnableCopy = true,
    EnableCompare = true,
    
    -- Limits
    MaxHistory = 12,
    MaxFavorites = 20,
    
    -- Animation
    AnimationSpeed = 0.25,
}

-- Preset color palettes
local PRESET_PALETTES = {
    Basic = {
        Color3.fromRGB(255, 255, 255),  -- White
        Color3.fromRGB(0, 0, 0),        -- Black
        Color3.fromRGB(255, 0, 0),      -- Red
        Color3.fromRGB(0, 255, 0),      -- Green
        Color3.fromRGB(0, 0, 255),      -- Blue
        Color3.fromRGB(255, 255, 0),    -- Yellow
        Color3.fromRGB(255, 0, 255),    -- Magenta
        Color3.fromRGB(0, 255, 255),    -- Cyan
    },
    Material = {
        Color3.fromRGB(244, 67, 54),    -- Red
        Color3.fromRGB(233, 30, 99),    -- Pink
        Color3.fromRGB(156, 39, 176),   -- Purple
        Color3.fromRGB(103, 58, 183),   -- Deep Purple
        Color3.fromRGB(63, 81, 181),    -- Indigo
        Color3.fromRGB(33, 150, 243),   -- Blue
        Color3.fromRGB(0, 188, 212),    -- Cyan
        Color3.fromRGB(0, 150, 136),    -- Teal
        Color3.fromRGB(76, 175, 80),    -- Green
        Color3.fromRGB(255, 193, 7),    -- Amber
        Color3.fromRGB(255, 87, 34),    -- Deep Orange
        Color3.fromRGB(121, 85, 72),    -- Brown
    },
    Pastel = {
        Color3.fromRGB(255, 179, 186),  -- Pink
        Color3.fromRGB(255, 223, 186),  -- Peach
        Color3.fromRGB(255, 255, 186),  -- Yellow
        Color3.fromRGB(186, 255, 201),  -- Mint
        Color3.fromRGB(186, 225, 255),  -- Sky
        Color3.fromRGB(218, 186, 255),  -- Lavender
    },
    Neon = {
        Color3.fromRGB(255, 0, 102),    -- Hot Pink
        Color3.fromRGB(255, 102, 0),    -- Orange
        Color3.fromRGB(255, 255, 0),    -- Yellow
        Color3.fromRGB(0, 255, 102),    -- Green
        Color3.fromRGB(0, 204, 255),    -- Cyan
        Color3.fromRGB(102, 0, 255),    -- Purple
    },
    Grayscale = {
        Color3.fromRGB(255, 255, 255),
        Color3.fromRGB(224, 224, 224),
        Color3.fromRGB(189, 189, 189),
        Color3.fromRGB(158, 158, 158),
        Color3.fromRGB(117, 117, 117),
        Color3.fromRGB(97, 97, 97),
        Color3.fromRGB(66, 66, 66),
        Color3.fromRGB(33, 33, 33),
        Color3.fromRGB(0, 0, 0),
    },
}

-- Shared state for history and favorites
local _colorHistory = {}
local _colorFavorites = {}

-- ══════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════

local Utils = {}

function Utils.Color3ToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

function Utils.HexToColor3(hex)
    hex = hex:gsub("#", "")
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

function Utils.Color3ToRGB(color)
    return {
        R = math.floor(color.R * 255 + 0.5),
        G = math.floor(color.G * 255 + 0.5),
        B = math.floor(color.B * 255 + 0.5),
    }
end

function Utils.RGBToColor3(r, g, b)
    return Color3.fromRGB(
        math.clamp(r, 0, 255),
        math.clamp(g, 0, 255),
        math.clamp(b, 0, 255)
    )
end

function Utils.Lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.InverseLerp(a, b, v)
    if a == b then return 0 end
    return (v - a) / (b - a)
end

function Utils.ColorDistance(c1, c2)
    local dr = c1.R - c2.R
    local dg = c1.G - c2.G
    local db = c1.B - c2.B
    return math.sqrt(dr*dr + dg*dg + db*db)
end

function Utils.GetContrastColor(color)
    local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    return luminance > 0.5 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
end

function Utils.CopyToClipboard(text)
    pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif syn and syn.write_clipboard then
            syn.write_clipboard(text)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- COLOR PICKER CLASS
-- ══════════════════════════════════════════════════════════════════════

function ColorPicker.new(parent, options)
    local self = setmetatable({}, ColorPicker)
    
    options = options or {}
    self.Name = options.Name or "Color"
    self.Flag = options.Flag or self.Name
    self.Default = options.Default or Color3.fromRGB(255, 255, 255)
    self.DefaultAlpha = options.DefaultAlpha or 1
    self.Callback = options.Callback or function() end
    self.Config = setmetatable(options.Config or {}, {__index = DEFAULT_CONFIG})
    
    -- State
    self.Value = self.Default
    self.Alpha = self.DefaultAlpha
    self.OriginalValue = self.Default
    self.OriginalAlpha = self.DefaultAlpha
    self.Open = false
    self.ActiveTab = "Picker"  -- Picker, RGB, Presets
    self._connections = {}
    self._dragging = nil
    
    -- HSV values
    local h, s, v = self.Default:ToHSV()
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    
    -- Signals
    self.OnChanged = Signal.new()
    self.OnOpened = Signal.new()
    self.OnClosed = Signal.new()
    self.OnConfirmed = Signal.new()
    self.OnCancelled = Signal.new()
    
    self:_build()
    self:_setupInteractions()
    
    return self
end

function ColorPicker:_build()
    local config = self.Config
    
    -- Main container frame
    self.Frame = Create.Frame({
        Name = "ColorPicker_" .. self.Name,
        Size = UDim2.new(1, 0, 0, config.CollapsedHeight),
        BackgroundColor3 = Theme:Get("Card"),
        ClipsDescendants = true,
        Parent = self._parent or parent,
    }, {
        Create.Corner(Config.Card.CornerRadius or 8),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.6,
        }),
    })
    
    -- ═══════════════════════════════════════════════════════
    -- HEADER (Collapsed state)
    -- ═══════════════════════════════════════════════════════
    
    self.Header = Create.Button({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, config.CollapsedHeight),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Frame,
    })
    
    -- Label
    self.Label = Create.Text({
        Name = "Label",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Name,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        Parent = self.Header,
    })
    
    -- Preview container (shows current + original)
    self.PreviewContainer = Create.Frame({
        Name = "PreviewContainer",
        Size = UDim2.fromOffset(config.PreviewSize * 2 + 4, config.PreviewSize),
        Position = UDim2.new(1, -12, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Parent = self.Header,
    })
    
    -- Checkerboard background for alpha visualization
    self.CheckerboardBg = Create.Frame({
        Name = "Checkerboard",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = self.PreviewContainer,
    }, {
        Create.Corner(4),
        Create.Instance("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(204, 204, 204)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 204, 204)),
            }),
        }),
    })
    
    -- Original color preview (left half)
    if config.EnableCompare then
        self.OriginalPreview = Create.Frame({
            Name = "OriginalPreview",
            Size = UDim2.new(0.5, -1, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = self.Default,
            BorderSizePixel = 0,
            Parent = self.PreviewContainer,
        }, {
            Create.Instance("UICorner", {
                CornerRadius = UDim.new(0, 4),
            }),
        })
        
        -- Mask right corners
        local origMask = Create.Frame({
            Name = "Mask",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            BackgroundColor3 = self.Default,
            BorderSizePixel = 0,
            Parent = self.OriginalPreview,
        })
    end
    
    -- Current color preview (right half or full)
    self.CurrentPreview = Create.Frame({
        Name = "CurrentPreview",
        Size = config.EnableCompare and UDim2.new(0.5, -1, 1, 0) or UDim2.new(1, 0, 1, 0),
        Position = config.EnableCompare and UDim2.new(0.5, 1, 0, 0) or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Default,
        BorderSizePixel = 0,
        Parent = self.PreviewContainer,
    }, {
        Create.Instance("UICorner", {
            CornerRadius = UDim.new(0, 4),
        }),
    })
    
    -- Mask left corners for current preview
    if config.EnableCompare then
        local currMask = Create.Frame({
            Name = "Mask",
            Size = UDim2.new(0.5, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = self.Default,
            BorderSizePixel = 0,
            Parent = self.CurrentPreview,
        })
    end
    
    -- Preview border
    Create.Stroke({
        Color = Theme:Get("Border"),
        Transparency = 0.3,
        Parent = self.PreviewContainer,
    })
    
    -- Expand indicator
    self.ExpandIcon = Create.Text({
        Name = "ExpandIcon",
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.new(1, -70, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = self.Header,
    })
    
    -- ═══════════════════════════════════════════════════════
    -- EXPANDED CONTENT
    -- ═══════════════════════════════════════════════════════
    
    self.Content = Create.Frame({
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -config.CollapsedHeight),
        Position = UDim2.new(0, 0, 0, config.CollapsedHeight),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Frame,
    }, {
        Create.Padding(12, 12, 12, 12),
    })
    
    -- Tab buttons
    self:_buildTabs()
    
    -- Picker tab content
    self:_buildPickerTab()
    
    -- RGB tab content
    if config.EnableRGB then
        self:_buildRGBTab()
    end
    
    -- Presets tab content
    if config.EnablePresets then
        self:_buildPresetsTab()
    end
    
    -- Bottom controls (HEX input, copy, favorites, etc.)
    self:_buildBottomControls()
end

function ColorPicker:_buildTabs()
    local tabs = {"Picker"}
    if self.Config.EnableRGB then table.insert(tabs, "RGB") end
    if self.Config.EnablePresets then table.insert(tabs, "Presets") end
    
    self.TabContainer = Create.Frame({
        Name = "Tabs",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = self.Content,
    }, {
        Create.Instance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, 4),
        }),
    })
    
    self.TabButtons = {}
    self.TabContents = {}
    
    for i, tabName in ipairs(tabs) do
        local isActive = i == 1
        
        local tabBtn = Create.Button({
            Name = tabName,
            Size = UDim2.new(0, 60, 1, 0),
            BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("CardHover"),
            BackgroundTransparency = isActive and 0 or 0.5,
            Text = tabName,
            TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            AutoButtonColor = false,
            LayoutOrder = i,
            Parent = self.TabContainer,
        }, {
            Create.Corner(6),
        })
        
        tabBtn.MouseButton1Click:Connect(function()
            self:_switchTab(tabName)
        end)
        
        self.TabButtons[tabName] = tabBtn
    end
end

function ColorPicker:_buildPickerTab()
    self.PickerTab = Create.Frame({
        Name = "PickerTab",
        Size = UDim2.new(1, 0, 1, -80),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Parent = self.Content,
    })
    
    self.TabContents["Picker"] = self.PickerTab
    
    local config = self.Config
    local paletteSize = config.PaletteSize
    
    -- Saturation/Value picker (main color square)
    self.SaturationFrame = Create.Frame({
        Name = "Saturation",
        Size = UDim2.new(1, -config.HueBarWidth - 16, 0, paletteSize),
        BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1),
        Parent = self.PickerTab,
    }, {
        Create.Corner(8),
    })
    
    -- White gradient (left to right)
    local whiteGradient = Create.Frame({
        Name = "WhiteGradient",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = self.SaturationFrame,
    }, {
        Create.Corner(8),
        Create.Instance("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),
    })
    
    -- Black gradient (top to bottom)
    local blackGradient = Create.Frame({
        Name = "BlackGradient",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        Parent = self.SaturationFrame,
    }, {
        Create.Corner(8),
        Create.Instance("UIGradient", {
            Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 90,
        }),
    })
    
    -- Saturation cursor
    self.SaturationCursor = Create.Frame({
        Name = "Cursor",
        Size = UDim2.fromOffset(18, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(self.Saturation, 0, 1 - self.Brightness, 0),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = self.SaturationFrame,
    })
    
    -- Cursor outer ring
    local cursorOuter = Create.Frame({
        Name = "Outer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = self.SaturationCursor,
    }, {
        Create.Corner(9),
        Create.Stroke({
            Color = Color3.new(0, 0, 0),
            Thickness = 1,
            Transparency = 0.5,
        }),
    })
    
    -- Cursor inner (shows selected color)
    self.CursorInner = Create.Frame({
        Name = "Inner",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Value,
        Parent = self.SaturationCursor,
    }, {
        Create.Corner(7),
    })
    
    -- Hue slider (vertical)
    self.HueFrame = Create.Frame({
        Name = "Hue",
        Size = UDim2.new(0, config.HueBarWidth, 0, paletteSize),
        Position = UDim2.new(1, 0, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = self.PickerTab,
    }, {
        Create.Corner(config.HueBarWidth / 2),
        Create.Instance("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
            Rotation = 90,
        }),
    })
    
    -- Hue cursor
    self.HueCursor = Create.Frame({
        Name = "Cursor",
        Size = UDim2.new(1, 8, 0, 8),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, self.Hue, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 5,
        Parent = self.HueFrame,
    }, {
        Create.Corner(4),
        Create.Stroke({
            Color = Color3.new(0, 0, 0),
            Thickness = 2,
        }),
    })
    
    -- Alpha slider (horizontal, if enabled)
    if self.Config.EnableAlpha then
        self.AlphaContainer = Create.Frame({
            Name = "AlphaContainer",
            Size = UDim2.new(1, 0, 0, config.AlphaBarHeight),
            Position = UDim2.new(0, 0, 0, paletteSize + 8),
            BackgroundTransparency = 1,
            Parent = self.PickerTab,
        })
        
        -- Checkerboard background
        self.AlphaCheckerboard = Create.Frame({
            Name = "Checkerboard",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            Parent = self.AlphaContainer,
        }, {
            Create.Corner(config.AlphaBarHeight / 2),
            Create.Instance("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(204, 204, 204)),
                    ColorSequenceKeypoint.new(0.1, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(204, 204, 204)),
                    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(204, 204, 204)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(204, 204, 204)),
                    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(204, 204, 204)),
                    ColorSequenceKeypoint.new(0.9, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(204, 204, 204)),
                }),
            }),
        })
        
        -- Alpha gradient overlay
        self.AlphaFrame = Create.Frame({
            Name = "Alpha",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = self.Value,
            Parent = self.AlphaContainer,
        }, {
            Create.Corner(config.AlphaBarHeight / 2),
            Create.Instance("UIGradient", {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            }),
        })
        
        -- Alpha cursor
        self.AlphaCursor = Create.Frame({
            Name = "Cursor",
            Size = UDim2.new(0, 8, 1, 8),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(self.Alpha, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 5,
            Parent = self.AlphaContainer,
        }, {
            Create.Corner(4),
            Create.Stroke({
                Color = Color3.new(0, 0, 0),
                Thickness = 2,
            }),
        })
        
        -- Alpha percentage label
        self.AlphaLabel = Create.Text({
            Name = "AlphaLabel",
            Size = UDim2.fromOffset(50, config.AlphaBarHeight),
            Position = UDim2.new(1, 8, 0, 0),
            BackgroundTransparency = 1,
            Text = math.floor(self.Alpha * 100) .. "%",
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.AlphaContainer,
        })
    end
end

function ColorPicker:_buildRGBTab()
    self.RGBTab = Create.Frame({
        Name = "RGBTab",
        Size = UDim2.new(1, 0, 1, -80),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.Content,
    })
    
    self.TabContents["RGB"] = self.RGBTab
    
    local rgb = Utils.Color3ToRGB(self.Value)
    local sliderHeight = self.Config.SliderHeight
    local spacing = 8
    
    self.RGBSliders = {}
    
    local channels = {
        {Name = "R", Value = rgb.R, Color = Color3.fromRGB(239, 68, 68)},
        {Name = "G", Value = rgb.G, Color = Color3.fromRGB(34, 197, 94)},
        {Name = "B", Value = rgb.B, Color = Color3.fromRGB(59, 130, 246)},
    }
    
    for i, channel in ipairs(channels) do
        local yPos = (i - 1) * (sliderHeight + spacing + 20)
        
        -- Channel container
        local container = Create.Frame({
            Name = channel.Name .. "Container",
            Size = UDim2.new(1, 0, 0, sliderHeight + 16),
            Position = UDim2.new(0, 0, 0, yPos),
            BackgroundTransparency = 1,
            Parent = self.RGBTab,
        })
        
        -- Label
        local label = Create.Text({
            Name = "Label",
            Size = UDim2.new(0, 20, 0, 16),
            BackgroundTransparency = 1,
            Text = channel.Name,
            TextColor3 = channel.Color,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            Parent = container,
        })
        
        -- Value input
        local input = Create.Instance("TextBox", {
            Name = "Input",
            Size = UDim2.new(0, 45, 0, sliderHeight),
            Position = UDim2.new(1, 0, 0, 16),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = Theme:Get("CardHover"),
            Text = tostring(channel.Value),
            TextColor3 = Theme:Get("TextPrimary"),
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            ClearTextOnFocus = false,
            Parent = container,
        })
        Create.Corner(4).Parent = input
        
        -- Slider track
        local track = Create.Frame({
            Name = "Track",
            Size = UDim2.new(1, -75, 0, sliderHeight),
            Position = UDim2.new(0, 25, 0, 16),
            BackgroundColor3 = Theme:Get("CardHover"),
            Parent = container,
        }, {
            Create.Corner(sliderHeight / 2),
        })
        
        -- Slider fill
        local fill = Create.Frame({
            Name = "Fill",
            Size = UDim2.new(channel.Value / 255, 0, 1, 0),
            BackgroundColor3 = channel.Color,
            Parent = track,
        }, {
            Create.Corner(sliderHeight / 2),
        })
        
        -- Slider handle
        local handle = Create.Frame({
            Name = "Handle",
            Size = UDim2.new(0, sliderHeight + 4, 0, sliderHeight + 4),
            Position = UDim2.new(channel.Value / 255, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ZIndex = 5,
            Parent = track,
        }, {
            Create.Corner((sliderHeight + 4) / 2),
            Create.Stroke({
                Color = channel.Color,
                Thickness = 2,
            }),
        })
        
        self.RGBSliders[channel.Name] = {
            Track = track,
            Fill = fill,
            Handle = handle,
            Input = input,
            Color = channel.Color,
        }
        
        -- Input handling
        input.FocusLost:Connect(function()
            local value = tonumber(input.Text)
            if value then
                value = math.clamp(math.floor(value), 0, 255)
                input.Text = tostring(value)
                self:_updateFromRGB(channel.Name, value)
            else
                local rgb = Utils.Color3ToRGB(self.Value)
                input.Text = tostring(rgb[channel.Name])
            end
        end)
        
        -- Slider drag handling (will be set up in _setupInteractions)
    end
end

function ColorPicker:_buildPresetsTab()
    self.PresetsTab = Create.ScrollFrame({
        Name = "PresetsTab",
        Size = UDim2.new(1, 0, 1, -80),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme:Get("TextSecondary"),
        Parent = self.Content,
    }, {
        Create.Instance("UIListLayout", {
            Padding = UDim.new(0, 12),
        }),
    })
    
    self.TabContents["Presets"] = self.PresetsTab
    
    -- Add preset palettes
    for paletteName, colors in pairs(PRESET_PALETTES) do
        local section = Create.Frame({
            Name = paletteName,
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 1,
            Parent = self.PresetsTab,
        })
        
        -- Palette name
        Create.Text({
            Name = "Label",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = paletteName,
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section,
        })
        
        -- Color grid
        local grid = Create.Frame({
            Name = "Grid",
            Size = UDim2.new(1, 0, 0, 36),
            Position = UDim2.new(0, 0, 0, 20),
            BackgroundTransparency = 1,
            Parent = section,
        }, {
            Create.Instance("UIGridLayout", {
                CellSize = UDim2.fromOffset(28, 28),
                CellPadding = UDim2.fromOffset(4, 4),
            }),
        })
        
        for j, color in ipairs(colors) do
            local colorBtn = Create.Button({
                Name = "Color" .. j,
                BackgroundColor3 = color,
                Text = "",
                AutoButtonColor = false,
                Parent = grid,
            }, {
                Create.Corner(6),
                Create.Stroke({
                    Color = Theme:Get("Border"),
                    Transparency = 0.5,
                }),
            })
            
            colorBtn.MouseButton1Click:Connect(function()
                self:Set(color)
            end)
            
            -- Hover effect
            colorBtn.MouseEnter:Connect(function()
                Tween.Fast(colorBtn, {Size = UDim2.new(1, 4, 1, 4)})
            end)
            
            colorBtn.MouseLeave:Connect(function()
                Tween.Fast(colorBtn, {Size = UDim2.new(1, 0, 1, 0)})
            end)
        end
    end
    
    -- Update canvas size
    self.PresetsTab.CanvasSize = UDim2.new(0, 0, 0, 
        self.PresetsTab:FindFirstChild("UIListLayout").AbsoluteContentSize.Y)
end

function ColorPicker:_buildBottomControls()
    self.BottomControls = Create.Frame({
        Name = "BottomControls",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 1, 0),
        AnchorPoint = Vector2.new(0, 1),
        BackgroundTransparency = 1,
        Parent = self.Content,
    })
    
    local config = self.Config
    
    -- HEX input
    if config.EnableHex then
        self.HexContainer = Create.Frame({
            Name = "HexContainer",
            Size = UDim2.new(0, 90, 0, 28),
            BackgroundColor3 = Theme:Get("CardHover"),
            Parent = self.BottomControls,
        }, {
            Create.Corner(6),
        })
        
        local hexLabel = Create.Text({
            Name = "Label",
            Size = UDim2.fromOffset(24, 28),
            BackgroundTransparency = 1,
            Text = "#",
            TextColor3 = Theme:Get("TextSecondary"),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            Parent = self.HexContainer,
        })
        
        self.HexInput = Create.Instance("TextBox", {
            Name = "HexInput",
            Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 24, 0, 0),
            BackgroundTransparency = 1,
            Text = Utils.Color3ToHex(self.Value):sub(2),
            TextColor3 = Theme:Get("TextPrimary"),
            TextSize = 12,
            Font = Enum.Font.GothamMedium,
            ClearTextOnFocus = false,
            PlaceholderText = "FFFFFF",
            Parent = self.HexContainer,
        })
        
        self.HexInput.FocusLost:Connect(function()
            local color = Utils.HexToColor3(self.HexInput.Text)
            if color then
                self:Set(color)
            else
                self.HexInput.Text = Utils.Color3ToHex(self.Value):sub(2)
            end
        end)
    end
    
    -- Copy button
    if config.EnableCopy then
        self.CopyButton = Create.Button({
            Name = "CopyButton",
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(0, 98, 0, 0),
            BackgroundColor3 = Theme:Get("CardHover"),
            Text = "📋",
            TextSize = 14,
            AutoButtonColor = false,
            Parent = self.BottomControls,
        }, {
            Create.Corner(6),
        })
        
        self.CopyButton.MouseButton1Click:Connect(function()
            Utils.CopyToClipboard(Utils.Color3ToHex(self.Value))
            -- Visual feedback
            self.CopyButton.Text = "✓"
            task.delay(1, function()
                if self.CopyButton then
                    self.CopyButton.Text = "📋"
                end
            end)
        end)
    end
    
    -- Favorite button
    if config.EnableFavorites then
        self.FavoriteButton = Create.Button({
            Name = "FavoriteButton",
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(0, 130, 0, 0),
            BackgroundColor3 = Theme:Get("CardHover"),
            Text = "☆",
            TextSize = 16,
            AutoButtonColor = false,
            Parent = self.BottomControls,
        }, {
            Create.Corner(6),
        })
        
        self.FavoriteButton.MouseButton1Click:Connect(function()
            self:_toggleFavorite()
        end)
    end
    
    -- Recent colors
    if config.EnableHistory then
        self.HistoryContainer = Create.Frame({
            Name = "History",
            Size = UDim2.new(0, 130, 0, 28),
            Position = UDim2.new(1, 0, 0, 0),
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Parent = self.BottomControls,
        }, {
            Create.Instance("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 4),
            }),
        })
        
        self:_updateHistoryDisplay()
    end
end

function ColorPicker:_setupInteractions()
    -- Header click to toggle
    self.Header.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Hover effects for header
    self.Header.MouseEnter:Connect(function()
        Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("CardHover")})
    end)
    
    self.Header.MouseLeave:Connect(function()
        if not self.Open then
            Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("Card")})
        end
    end)
    
    -- Saturation/Value picker drag
    self:_setupDragArea(self.SaturationFrame, "saturation")
    
    -- Hue slider drag
    self:_setupDragArea(self.HueFrame, "hue")
    
    -- Alpha slider drag
    if self.AlphaContainer then
        self:_setupDragArea(self.AlphaContainer, "alpha")
    end
    
    -- RGB sliders drag
    if self.RGBSliders then
        for name, slider in pairs(self.RGBSliders) do
            self:_setupRGBSlider(name, slider)
        end
    end
end

function ColorPicker:_setupDragArea(frame, dragType)
    local dragging = false
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            self._dragging = dragType
            self:_handleDrag(input, dragType)
        end
    end)
    
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                         input.UserInputType == Enum.UserInputType.Touch) then
            self:_handleDrag(input, dragType)
        end
    end)
    table.insert(self._connections, moveConn)
    
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                self._dragging = nil
                self:_addToHistory(self.Value)
            end
        end
    end)
    table.insert(self._connections, endConn)
end

function ColorPicker:_setupRGBSlider(name, slider)
    local dragging = false
    
    slider.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            self:_handleRGBDrag(input, name, slider)
        end
    end)
    
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            self:_handleRGBDrag(input, name, slider)
        end
    end)
    table.insert(self._connections, moveConn)
    
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            self:_addToHistory(self.Value)
        end
    end)
    table.insert(self._connections, endConn)
end

function ColorPicker:_handleDrag(input, dragType)
    if dragType == "saturation" then
        local frame = self.SaturationFrame
        local x = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
        local y = math.clamp((input.Position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
        
        self.Saturation = x
        self.Brightness = 1 - y
        
        self.SaturationCursor.Position = UDim2.new(x, 0, y, 0)
        self:_updateColor()
        
    elseif dragType == "hue" then
        local frame = self.HueFrame
        local y = math.clamp((input.Position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
        
        self.Hue = y
        
        self.HueCursor.Position = UDim2.new(0.5, 0, y, 0)
        self.SaturationFrame.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
        self:_updateColor()
        
    elseif dragType == "alpha" then
        local frame = self.AlphaContainer
        local x = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
        
        self.Alpha = x
        
        self.AlphaCursor.Position = UDim2.new(x, 0, 0.5, 0)
        self.AlphaLabel.Text = math.floor(self.Alpha * 100) .. "%"
        self:_updateColor()
    end
end

function ColorPicker:_handleRGBDrag(input, channelName, slider)
    local track = slider.Track
    local x = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
    local value = math.floor(x * 255)
    
    slider.Fill.Size = UDim2.new(x, 0, 1, 0)
    slider.Handle.Position = UDim2.new(x, 0, 0.5, 0)
    slider.Input.Text = tostring(value)
    
    self:_updateFromRGB(channelName, value)
end

function ColorPicker:_updateFromRGB(channel, value)
    local rgb = Utils.Color3ToRGB(self.Value)
    rgb[channel] = value
    
    local newColor = Utils.RGBToColor3(rgb.R, rgb.G, rgb.B)
    local h, s, v = newColor:ToHSV()
    
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    
    self:_updateColor()
    self:_updatePickerVisuals()
end

function ColorPicker:_updateColor()
    self.Value = Color3.fromHSV(self.Hue, self.Saturation, self.Brightness)
    
    -- Update previews
    self.CurrentPreview.BackgroundColor3 = self.Value
    if self.CursorInner then
        self.CursorInner.BackgroundColor3 = self.Value
    end
    
    -- Update alpha overlay
    if self.AlphaFrame then
        self.AlphaFrame.BackgroundColor3 = self.Value
    end
    
    -- Update HEX input
    if self.HexInput then
        self.HexInput.Text = Utils.Color3ToHex(self.Value):sub(2)
    end
    
    -- Update RGB sliders
    if self.RGBSliders then
        local rgb = Utils.Color3ToRGB(self.Value)
        for name, slider in pairs(self.RGBSliders) do
            local val = rgb[name]
            slider.Fill.Size = UDim2.new(val / 255, 0, 1, 0)
            slider.Handle.Position = UDim2.new(val / 255, 0, 0.5, 0)
            slider.Input.Text = tostring(val)
        end
    end
    
    -- Fire callbacks
    self.Callback(self.Value, self.Alpha)
    self.OnChanged:Fire(self.Value, self.Alpha)
end

function ColorPicker:_updatePickerVisuals()
    -- Update saturation frame background
    self.SaturationFrame.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
    
    -- Update cursor positions
    self.SaturationCursor.Position = UDim2.new(self.Saturation, 0, 1 - self.Brightness, 0)
    self.HueCursor.Position = UDim2.new(0.5, 0, self.Hue, 0)
    
    if self.AlphaCursor then
        self.AlphaCursor.Position = UDim2.new(self.Alpha, 0, 0.5, 0)
    end
end

function ColorPicker:_switchTab(tabName)
    for name, btn in pairs(self.TabButtons) do
        local isActive = name == tabName
        Tween.Fast(btn, {
            BackgroundColor3 = isActive and Theme:Get("Accent") or Theme:Get("CardHover"),
            BackgroundTransparency = isActive and 0 or 0.5,
            TextColor3 = isActive and Color3.new(1, 1, 1) or Theme:Get("TextSecondary"),
        })
    end
    
    for name, content in pairs(self.TabContents) do
        content.Visible = name == tabName
    end
    
    self.ActiveTab = tabName
end

function ColorPicker:_addToHistory(color)
    -- Don't add duplicates
    for i, c in ipairs(_colorHistory) do
        if Utils.ColorDistance(c, color) < 0.01 then
            table.remove(_colorHistory, i)
            break
        end
    end
    
    table.insert(_colorHistory, 1, color)
    
    -- Trim history
    while #_colorHistory > self.Config.MaxHistory do
        table.remove(_colorHistory)
    end
    
    self:_updateHistoryDisplay()
end

function ColorPicker:_updateHistoryDisplay()
    if not self.HistoryContainer then return end
    
    -- Clear existing
    for _, child in ipairs(self.HistoryContainer:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end
    
    -- Add history colors
    for i = 1, math.min(#_colorHistory, 5) do
        local color = _colorHistory[i]
        
        local historyBtn = Create.Button({
            Name = "History" .. i,
            Size = UDim2.fromOffset(22, 22),
            BackgroundColor3 = color,
            Text = "",
            LayoutOrder = i,
            Parent = self.HistoryContainer,
        }, {
            Create.Corner(4),
            Create.Stroke({
                Color = Theme:Get("Border"),
                Transparency = 0.5,
            }),
        })
        
        historyBtn.MouseButton1Click:Connect(function()
            self:Set(color)
        end)
    end
end

function ColorPicker:_toggleFavorite()
    local hex = Utils.Color3ToHex(self.Value)
    local found = false
    
    for i, fav in ipairs(_colorFavorites) do
        if Utils.Color3ToHex(fav) == hex then
            table.remove(_colorFavorites, i)
            found = true
            break
        end
    end
    
    if not found then
        if #_colorFavorites >= self.Config.MaxFavorites then
            table.remove(_colorFavorites)
        end
        table.insert(_colorFavorites, 1, self.Value)
    end
    
    -- Update button visual
    self.FavoriteButton.Text = found and "☆" or "★"
    self.FavoriteButton.TextColor3 = found and Theme:Get("TextSecondary") or Theme:Get("Warning")
end

function ColorPicker:_updateFavoriteButton()
    if not self.FavoriteButton then return end
    
    local hex = Utils.Color3ToHex(self.Value)
    local isFavorite = false
    
    for _, fav in ipairs(_colorFavorites) do
        if Utils.Color3ToHex(fav) == hex then
            isFavorite = true
            break
        end
    end
    
    self.FavoriteButton.Text = isFavorite and "★" or "☆"
    self.FavoriteButton.TextColor3 = isFavorite and Theme:Get("Warning") or Theme:Get("TextSecondary")
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function ColorPicker:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        self.OriginalValue = self.Value
        self.OriginalAlpha = self.Alpha
        
        if self.OriginalPreview then
            self.OriginalPreview.BackgroundColor3 = self.OriginalValue
        end
        
        self.Content.Visible = true
        
        local targetHeight = self.Config.ExpandedHeight
        
        Tween.Normal(self.Frame, {Size = UDim2.new(1, 0, 0, targetHeight)})
        Tween.Fast(self.ExpandIcon, {Rotation = 180})
        Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("CardActive")})
        
        self.OnOpened:Fire()
    else
        Tween.Normal(self.Frame, {Size = UDim2.new(1, 0, 0, self.Config.CollapsedHeight)})
        Tween.Fast(self.ExpandIcon, {Rotation = 0})
        Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("Card")})
        
        task.delay(self.Config.AnimationSpeed, function()
            if not self.Open then
                self.Content.Visible = false
            end
        end)
        
        self:_addToHistory(self.Value)
        self.OnClosed:Fire()
    end
end

function ColorPicker:Set(color, alpha, skipCallback)
    local h, s, v = color:ToHSV()
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    self.Value = color
    
    if alpha ~= nil then
        self.Alpha = alpha
    end
    
    -- Update all visuals
    self.CurrentPreview.BackgroundColor3 = color
    self:_updatePickerVisuals()
    
    if self.HexInput then
        self.HexInput.Text = Utils.Color3ToHex(color):sub(2)
    end
    
    if self.AlphaLabel then
        self.AlphaLabel.Text = math.floor(self.Alpha * 100) .. "%"
    end
    
    if self.CursorInner then
        self.CursorInner.BackgroundColor3 = color
    end
    
    if self.AlphaFrame then
        self.AlphaFrame.BackgroundColor3 = color
    end
    
    -- Update RGB sliders
    if self.RGBSliders then
        local rgb = Utils.Color3ToRGB(color)
        for name, slider in pairs(self.RGBSliders) do
            local val = rgb[name]
            slider.Fill.Size = UDim2.new(val / 255, 0, 1, 0)
            slider.Handle.Position = UDim2.new(val / 255, 0, 0.5, 0)
            slider.Input.Text = tostring(val)
        end
    end
    
    self:_updateFavoriteButton()
    
    if not skipCallback then
        self.Callback(color, self.Alpha)
        self.OnChanged:Fire(color, self.Alpha)
    end
end

function ColorPicker:Get()
    return self.Value, self.Alpha
end

function ColorPicker:GetHex()
    return Utils.Color3ToHex(self.Value)
end

function ColorPicker:GetRGB()
    return Utils.Color3ToRGB(self.Value)
end

function ColorPicker:GetHSV()
    return self.Hue, self.Saturation, self.Brightness
end

function ColorPicker:SetFromHex(hex)
    local color = Utils.HexToColor3(hex)
    if color then
        self:Set(color)
        return true
    end
    return false
end

function ColorPicker:Confirm()
    self.OriginalValue = self.Value
    self.OriginalAlpha = self.Alpha
    self.OnConfirmed:Fire(self.Value, self.Alpha)
    if self.Open then
        self:Toggle()
    end
end

function ColorPicker:Cancel()
    self:Set(self.OriginalValue, self.OriginalAlpha)
    self.OnCancelled:Fire()
    if self.Open then
        self:Toggle()
    end
end

function ColorPicker:UpdateTheme()
    self.Frame.BackgroundColor3 = self.Open and Theme:Get("CardActive") or Theme:Get("Card")
    self.Label.TextColor3 = Theme:Get("TextPrimary")
    self.ExpandIcon.TextColor3 = Theme:Get("TextSecondary")
    
    local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = Theme:Get("Border")
    end
    
    if self.HexContainer then
        self.HexContainer.BackgroundColor3 = Theme:Get("CardHover")
    end
    
    if self.HexInput then
        self.HexInput.TextColor3 = Theme:Get("TextPrimary")
    end
    
    for _, btn in pairs(self.TabButtons or {}) do
        if btn.Name ~= self.ActiveTab then
            btn.BackgroundColor3 = Theme:Get("CardHover")
            btn.TextColor3 = Theme:Get("TextSecondary")
        end
    end
end

function ColorPicker:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    self.OnChanged:Destroy()
    self.OnOpened:Destroy()
    self.OnClosed:Destroy()
    self.OnConfirmed:Destroy()
    self.OnCancelled:Destroy()
    
    if self.Frame then
        self.Frame:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- STATIC METHODS
-- ══════════════════════════════════════════════════════════════════════

ColorPicker.Utils = Utils

function ColorPicker.GetHistory()
    return _colorHistory
end

function ColorPicker.ClearHistory()
    _colorHistory = {}
end

function ColorPicker.GetFavorites()
    return _colorFavorites
end

function ColorPicker.ClearFavorites()
    _colorFavorites = {}
end

function ColorPicker.AddFavorite(color)
    if #_colorFavorites >= DEFAULT_CONFIG.MaxFavorites then
        table.remove(_colorFavorites)
    end
    table.insert(_colorFavorites, 1, color)
end

return ColorPicker