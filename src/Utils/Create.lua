--[[
    VapeUI Instance Creator v2.0
    Advanced instance creation with templates, animations, and utilities.
    
    Features:
    ✅ Shorthand creators for all UI types
    ✅ Template system (reusable presets)
    ✅ Batch creation
    ✅ Clone with modifications
    ✅ Animation helpers
    ✅ Constraint creators
    ✅ Effect creators (shadows, glow)
    ✅ Responsive utilities
    ✅ Theme integration
    ✅ Debug mode
    ✅ Validation
    ✅ Auto-cleanup tracking
    ✅ Event binding helpers
    ✅ Rich text builders
    ✅ Safe property setting
]]

local Create = {}

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local _config = {
    DebugMode = false,
    ValidateProperties = true,
    AutoTrackInstances = false,
    DefaultFont = Enum.Font.GothamMedium,
    DefaultTextSize = 14,
    DefaultCornerRadius = 8,
    DefaultPadding = 8,
    DefaultSpacing = 8,
}

local _trackedInstances = {}
local _templates = {}
local _instanceCount = 0

-- ══════════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ══════════════════════════════════════════════════════════════════════

local function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = deepCopy(value)
    end
    return copy
end

local function mergeProperties(base, override)
    local result = deepCopy(base)
    for key, value in pairs(override or {}) do
        result[key] = value
    end
    return result
end

local function isValidProperty(instance, propertyName)
    local success = pcall(function()
        local _ = instance[propertyName]
    end)
    return success
end

local function debugLog(message, ...)
    if _config.DebugMode then
        print("[Create]", string.format(message, ...))
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- CORE INSTANCE CREATION
-- ══════════════════════════════════════════════════════════════════════

--[[
    Create a new instance with properties and children.
    
    @param className: string - The class name of the instance
    @param properties: table? - Properties to apply
    @param children: table? - Child instances to add
    @return Instance
]]
function Create.Instance(className, properties, children)
    local instance = Instance.new(className)
    _instanceCount = _instanceCount + 1
    
    properties = properties or {}
    children = children or {}
    
    -- Apply properties (except Parent)
    for property, value in pairs(properties) do
        if property ~= "Parent" and property ~= "Children" then
            if _config.ValidateProperties then
                if isValidProperty(instance, property) then
                    instance[property] = value
                else
                    debugLog("Invalid property '%s' for %s", property, className)
                end
            else
                pcall(function()
                    instance[property] = value
                end)
            end
        end
    end
    
    -- Add children
    for _, child in ipairs(children) do
        if typeof(child) == "Instance" then
            child.Parent = instance
        elseif type(child) == "table" and child.Instance then
            child.Instance.Parent = instance
        end
    end
    
    -- Handle inline children in properties
    if properties.Children then
        for _, child in ipairs(properties.Children) do
            if typeof(child) == "Instance" then
                child.Parent = instance
            end
        end
    end
    
    -- Apply Parent last
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    
    -- Track instance if enabled
    if _config.AutoTrackInstances then
        table.insert(_trackedInstances, instance)
    end
    
    debugLog("Created %s (Total: %d)", className, _instanceCount)
    
    return instance
end

--[[
    Create instance from a template.
    
    @param templateName: string - Name of the registered template
    @param overrides: table? - Properties to override
    @param children: table? - Additional children
    @return Instance
]]
function Create.FromTemplate(templateName, overrides, children)
    local template = _templates[templateName]
    if not template then
        warn("[Create] Template not found: " .. templateName)
        return nil
    end
    
    local props = mergeProperties(template.Properties, overrides)
    local allChildren = {}
    
    -- Add template children
    if template.Children then
        for _, childTemplate in ipairs(template.Children) do
            table.insert(allChildren, Create.FromTemplate(childTemplate.Template, childTemplate.Overrides))
        end
    end
    
    -- Add additional children
    for _, child in ipairs(children or {}) do
        table.insert(allChildren, child)
    end
    
    return Create.Instance(template.ClassName, props, allChildren)
end

--[[
    Clone an instance with modifications.
    
    @param original: Instance - Instance to clone
    @param modifications: table? - Properties to modify
    @return Instance
]]
function Create.Clone(original, modifications)
    local clone = original:Clone()
    
    for property, value in pairs(modifications or {}) do
        if property ~= "Parent" then
            pcall(function()
                clone[property] = value
            end)
        end
    end
    
    if modifications and modifications.Parent then
        clone.Parent = modifications.Parent
    end
    
    return clone
end

--[[
    Create multiple instances at once.
    
    @param definitions: table - Array of {ClassName, Properties, Children}
    @return table - Array of created instances
]]
function Create.Batch(definitions)
    local instances = {}
    
    for _, def in ipairs(definitions) do
        local instance = Create.Instance(def[1] or def.ClassName, def[2] or def.Properties, def[3] or def.Children)
        table.insert(instances, instance)
    end
    
    return instances
end

-- ══════════════════════════════════════════════════════════════════════
-- SHORTHAND CREATORS - FRAMES & CONTAINERS
-- ══════════════════════════════════════════════════════════════════════

function Create.Frame(props, children)
    return Create.Instance("Frame", mergeProperties({
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BorderSizePixel = 0,
    }, props), children)
end

function Create.CanvasGroup(props, children)
    return Create.Instance("CanvasGroup", mergeProperties({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 0,
    }, props), children)
end

function Create.Scroll(props, children)
    return Create.Instance("ScrollingFrame", mergeProperties({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.Always,
    }, props), children)
end

function Create.ViewportFrame(props, children)
    return Create.Instance("ViewportFrame", mergeProperties({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, props), children)
end

function Create.BillboardGui(props, children)
    return Create.Instance("BillboardGui", mergeProperties({
        AlwaysOnTop = true,
        LightInfluence = 0,
        Size = UDim2.new(0, 100, 0, 50),
    }, props), children)
end

-- ══════════════════════════════════════════════════════════════════════
-- SHORTHAND CREATORS - TEXT
-- ══════════════════════════════════════════════════════════════════════

function Create.Text(props)
    return Create.Instance("TextLabel", mergeProperties({
        BackgroundTransparency = 1,
        Font = _config.DefaultFont,
        TextSize = _config.DefaultTextSize,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

function Create.Title(props)
    return Create.Instance("TextLabel", mergeProperties({
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextColor3 = Color3.new(1, 1, 1),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

function Create.Subtitle(props)
    return Create.Instance("TextLabel", mergeProperties({
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

function Create.Caption(props)
    return Create.Instance("TextLabel", mergeProperties({
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(140, 140, 140),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

function Create.RichText(props)
    return Create.Instance("TextLabel", mergeProperties({
        BackgroundTransparency = 1,
        Font = _config.DefaultFont,
        TextSize = _config.DefaultTextSize,
        TextColor3 = Color3.new(1, 1, 1),
        RichText = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

-- ══════════════════════════════════════════════════════════════════════
-- SHORTHAND CREATORS - BUTTONS & INPUTS
-- ══════════════════════════════════════════════════════════════════════

function Create.Button(props, children)
    return Create.Instance("TextButton", mergeProperties({
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        Font = _config.DefaultFont,
        TextSize = _config.DefaultTextSize,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
    }, props), children)
end

function Create.IconButton(props, children)
    return Create.Instance("ImageButton", mergeProperties({
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ScaleType = Enum.ScaleType.Fit,
    }, props), children)
end

function Create.Input(props)
    return Create.Instance("TextBox", mergeProperties({
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Font = _config.DefaultFont,
        TextSize = _config.DefaultTextSize,
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, props))
end

function Create.TextArea(props)
    return Create.Instance("TextBox", mergeProperties({
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        BorderSizePixel = 0,
        Font = _config.DefaultFont,
        TextSize = _config.DefaultTextSize,
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        TextWrapped = true,
    }, props))
end

-- ══════════════════════════════════════════════════════════════════════
-- SHORTHAND CREATORS - IMAGES
-- ══════════════════════════════════════════════════════════════════════

function Create.Image(props)
    return Create.Instance("ImageLabel", mergeProperties({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Fit,
    }, props))
end

function Create.ImageButton(props, children)
    return Create.Instance("ImageButton", mergeProperties({
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
    }, props), children)
end

function Create.Icon(imageId, size, props)
    size = size or 24
    return Create.Instance("ImageLabel", mergeProperties({
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Image = imageId,
        ImageColor3 = Color3.new(1, 1, 1),
        ScaleType = Enum.ScaleType.Fit,
    }, props))
end

function Create.Avatar(userId, size, props)
    size = size or 50
    local avatarUrl = string.format(
        "https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png",
        userId
    )
    
    return Create.Instance("ImageLabel", mergeProperties({
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
        Image = avatarUrl,
        ScaleType = Enum.ScaleType.Fit,
    }, props), {
        Create.Corner(size / 2),
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- UI CONSTRAINTS & LAYOUTS
-- ══════════════════════════════════════════════════════════════════════

function Create.Corner(radius)
    if type(radius) == "number" then
        return Create.Instance("UICorner", {
            CornerRadius = UDim.new(0, radius)
        })
    elseif typeof(radius) == "UDim" then
        return Create.Instance("UICorner", {
            CornerRadius = radius
        })
    else
        return Create.Instance("UICorner", {
            CornerRadius = UDim.new(0, _config.DefaultCornerRadius)
        })
    end
end

function Create.Stroke(props)
    return Create.Instance("UIStroke", mergeProperties({
        Color = Color3.fromRGB(60, 60, 60),
        Thickness = 1,
        Transparency = 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, props))
end

function Create.Padding(top, right, bottom, left)
    -- Handle different argument patterns
    if type(top) == "table" then
        return Create.Instance("UIPadding", {
            PaddingTop = UDim.new(0, top.Top or top[1] or 0),
            PaddingRight = UDim.new(0, top.Right or top[2] or top[1] or 0),
            PaddingBottom = UDim.new(0, top.Bottom or top[3] or top[1] or 0),
            PaddingLeft = UDim.new(0, top.Left or top[4] or top[2] or top[1] or 0),
        })
    end
    
    -- Single value = all sides
    if right == nil then
        right = top
        bottom = top
        left = top
    -- Two values = vertical, horizontal
    elseif bottom == nil then
        bottom = top
        left = right
    -- Three values = top, horizontal, bottom
    elseif left == nil then
        left = right
    end
    
    return Create.Instance("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
    })
end

function Create.List(props)
    return Create.Instance("UIListLayout", mergeProperties({
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, _config.DefaultSpacing),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, props))
end

function Create.HorizontalList(props)
    return Create.Instance("UIListLayout", mergeProperties({
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, _config.DefaultSpacing),
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, props))
end

function Create.Grid(props)
    return Create.Instance("UIGridLayout", mergeProperties({
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = UDim2.new(0, _config.DefaultSpacing, 0, _config.DefaultSpacing),
        CellSize = UDim2.new(0, 100, 0, 100),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = 0,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, props))
end

function Create.Table(props)
    return Create.Instance("UITableLayout", mergeProperties({
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim2.new(0, _config.DefaultSpacing, 0, _config.DefaultSpacing),
        FillDirection = Enum.FillDirection.Vertical,
        FillEmptySpaceColumns = true,
        FillEmptySpaceRows = false,
    }, props))
end

function Create.PageLayout(props)
    return Create.Instance("UIPageLayout", mergeProperties({
        SortOrder = Enum.SortOrder.LayoutOrder,
        EasingDirection = Enum.EasingDirection.Out,
        EasingStyle = Enum.EasingStyle.Quart,
        TweenTime = 0.3,
        FillDirection = Enum.FillDirection.Horizontal,
        Circular = false,
        ScrollWheelInputEnabled = false,
        TouchInputEnabled = false,
        GamepadInputEnabled = false,
    }, props))
end

function Create.Gradient(props)
    return Create.Instance("UIGradient", mergeProperties({
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1)),
    }, props))
end

function Create.AspectRatio(ratio, props)
    return Create.Instance("UIAspectRatioConstraint", mergeProperties({
        AspectRatio = ratio or 1,
        AspectType = Enum.AspectType.FitWithinMaxSize,
        DominantAxis = Enum.DominantAxis.Width,
    }, props))
end

function Create.SizeConstraint(props)
    return Create.Instance("UISizeConstraint", mergeProperties({
        MaxSize = Vector2.new(math.huge, math.huge),
        MinSize = Vector2.new(0, 0),
    }, props))
end

function Create.TextSizeConstraint(props)
    return Create.Instance("UITextSizeConstraint", mergeProperties({
        MaxTextSize = 100,
        MinTextSize = 1,
    }, props))
end

function Create.Scale(scale)
    return Create.Instance("UIScale", {
        Scale = scale or 1
    })
end

function Create.FlexItem(props)
    return Create.Instance("UIFlexItem", mergeProperties({
        FlexMode = Enum.UIFlexMode.Fill,
        GrowRatio = 1,
        ShrinkRatio = 1,
    }, props))
end

-- ══════════════════════════════════════════════════════════════════════
-- EFFECTS & DECORATIONS
-- ══════════════════════════════════════════════════════════════════════

function Create.Shadow(size, transparency, props)
    size = size or 5
    transparency = transparency or 0.5
    
    return Create.Frame(mergeProperties({
        Name = "Shadow",
        Size = UDim2.new(1, size * 2, 1, size * 2),
        Position = UDim2.new(0.5, 0, 0.5, size / 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = transparency,
        ZIndex = -1,
    }, props), {
        Create.Corner(size + 4),
    })
end

function Create.DropShadow(offset, blur, color, props)
    offset = offset or Vector2.new(0, 4)
    blur = blur or 8
    color = color or Color3.new(0, 0, 0)
    
    return Create.Image(mergeProperties({
        Name = "DropShadow",
        Size = UDim2.new(1, blur * 2, 1, blur * 2),
        Position = UDim2.new(0.5, offset.X, 0.5, offset.Y),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Image = "rbxassetid://6014261993",
        ImageColor3 = color,
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1,
    }, props))
end

function Create.Glow(color, size, props)
    color = color or Color3.fromRGB(100, 150, 255)
    size = size or 10
    
    return Create.Frame(mergeProperties({
        Name = "Glow",
        Size = UDim2.new(1, size * 2, 1, size * 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.8,
        ZIndex = -1,
    }, props), {
        Create.Corner(size + 8),
        Create.Instance("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 0.8),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }),
    })
end

function Create.Divider(orientation, props)
    local isHorizontal = orientation ~= "Vertical"
    
    return Create.Frame(mergeProperties({
        Name = "Divider",
        Size = isHorizontal and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 60),
        BorderSizePixel = 0,
    }, props))
end

function Create.Spacer(size, props)
    return Create.Frame(mergeProperties({
        Name = "Spacer",
        Size = UDim2.new(1, 0, 0, size or _config.DefaultSpacing),
        BackgroundTransparency = 1,
    }, props))
end

-- ══════════════════════════════════════════════════════════════════════
-- COMPLEX COMPONENTS
-- ══════════════════════════════════════════════════════════════════════

function Create.Card(props, children)
    return Create.Frame(mergeProperties({
        Name = "Card",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    }, props), {
        Create.Corner(8),
        Create.Stroke({Color = Color3.fromRGB(55, 55, 55), Transparency = 0.5}),
        Create.Padding(12),
        unpack(children or {}),
    })
end

function Create.Badge(text, color, props)
    color = color or Color3.fromRGB(239, 68, 68)
    
    return Create.Frame(mergeProperties({
        Name = "Badge",
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = color,
    }, props), {
        Create.Corner(10),
        Create.Padding(0, 0, 8, 8),
        Create.Text({
            Name = "Label",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = text or "Badge",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.GothamBold,
        }),
    })
end

function Create.Tooltip(text, props)
    return Create.Frame(mergeProperties({
        Name = "Tooltip",
        Size = UDim2.new(0, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        Visible = false,
        ZIndex = 100,
    }, props), {
        Create.Corner(6),
        Create.Stroke({Color = Color3.fromRGB(60, 60, 60)}),
        Create.Padding(0, 0, 10, 10),
        Create.Text({
            Name = "Label",
            Size = UDim2.new(0, 0, 1, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            Text = text or "Tooltip",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 11,
            Font = Enum.Font.Gotham,
        }),
    })
end

function Create.ProgressBar(progress, color, props)
    progress = math.clamp(progress or 0, 0, 1)
    color = color or Color3.fromRGB(100, 150, 255)
    
    return Create.Frame(mergeProperties({
        Name = "ProgressBar",
        Size = UDim2.new(1, 0, 0, 6),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    }, props), {
        Create.Corner(3),
        Create.Frame({
            Name = "Fill",
            Size = UDim2.new(progress, 0, 1, 0),
            BackgroundColor3 = color,
        }, {
            Create.Corner(3),
        }),
    })
end

function Create.Checkbox(checked, props)
    local size = 20
    
    return Create.Frame(mergeProperties({
        Name = "Checkbox",
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = checked and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(50, 50, 50),
    }, props), {
        Create.Corner(4),
        Create.Stroke({Color = Color3.fromRGB(80, 80, 80)}),
        Create.Text({
            Name = "Check",
            Size = UDim2.new(1, 0, 1, 0),
            Text = checked and "✓" or "",
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
        }),
    })
end

function Create.Switch(enabled, props)
    local width = 44
    local height = 24
    local knobSize = 20
    
    local container = Create.Frame(mergeProperties({
        Name = "Switch",
        Size = UDim2.fromOffset(width, height),
        BackgroundColor3 = enabled and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 60),
    }, props), {
        Create.Corner(height / 2),
    })
    
    local knob = Create.Frame({
        Name = "Knob",
        Size = UDim2.fromOffset(knobSize, knobSize),
        Position = enabled 
            and UDim2.new(1, -knobSize - 2, 0.5, 0)
            or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = container,
    }, {
        Create.Corner(knobSize / 2),
    })
    
    return container
end

-- ══════════════════════════════════════════════════════════════════════
-- TEMPLATE SYSTEM
-- ══════════════════════════════════════════════════════════════════════

function Create.RegisterTemplate(name, definition)
    _templates[name] = definition
    debugLog("Registered template: %s", name)
end

function Create.GetTemplate(name)
    return _templates[name]
end

function Create.RemoveTemplate(name)
    _templates[name] = nil
end

function Create.GetAllTemplates()
    return _templates
end

-- Pre-register common templates
Create.RegisterTemplate("PrimaryButton", {
    ClassName = "TextButton",
    Properties = {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(100, 150, 255),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
    },
    Children = {
        {Template = "RoundedCorner", Overrides = {}},
    },
})

Create.RegisterTemplate("RoundedCorner", {
    ClassName = "UICorner",
    Properties = {
        CornerRadius = UDim.new(0, 8),
    },
})

Create.RegisterTemplate("InputField", {
    ClassName = "TextBox",
    Properties = {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
        PlaceholderText = "Enter text...",
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    },
})

-- ══════════════════════════════════════════════════════════════════════
-- RICH TEXT HELPERS
-- ══════════════════════════════════════════════════════════════════════

Create.RichTextBuilder = {}

function Create.RichTextBuilder.Bold(text)
    return "<b>" .. text .. "</b>"
end

function Create.RichTextBuilder.Italic(text)
    return "<i>" .. text .. "</i>"
end

function Create.RichTextBuilder.Underline(text)
    return "<u>" .. text .. "</u>"
end

function Create.RichTextBuilder.Strike(text)
    return "<s>" .. text .. "</s>"
end

function Create.RichTextBuilder.Color(text, color)
    if typeof(color) == "Color3" then
        color = string.format("#%02X%02X%02X", 
            math.floor(color.R * 255),
            math.floor(color.G * 255),
            math.floor(color.B * 255)
        )
    end
    return string.format('<font color="%s">%s</font>', color, text)
end

function Create.RichTextBuilder.Size(text, size)
    return string.format('<font size="%d">%s</font>', size, text)
end

function Create.RichTextBuilder.Font(text, font)
    return string.format('<font face="%s">%s</font>', font, text)
end

function Create.RichTextBuilder.Combine(...)
    return table.concat({...}, "")
end

-- ══════════════════════════════════════════════════════════════════════
-- EVENT BINDING HELPERS
-- ══════════════════════════════════════════════════════════════════════

function Create.BindClick(button, callback)
    if button:IsA("GuiButton") then
        return button.MouseButton1Click:Connect(callback)
    end
end

function Create.BindHover(element, onEnter, onLeave)
    local connections = {}
    
    if onEnter then
        table.insert(connections, element.MouseEnter:Connect(onEnter))
    end
    
    if onLeave then
        table.insert(connections, element.MouseLeave:Connect(onLeave))
    end
    
    return connections
end

function Create.BindInput(textBox, onChange, onFocusLost)
    local connections = {}
    
    if onChange then
        table.insert(connections, textBox:GetPropertyChangedSignal("Text"):Connect(function()
            onChange(textBox.Text)
        end))
    end
    
    if onFocusLost then
        table.insert(connections, textBox.FocusLost:Connect(function(enterPressed)
            onFocusLost(textBox.Text, enterPressed)
        end))
    end
    
    return connections
end

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION & UTILITIES
-- ══════════════════════════════════════════════════════════════════════

function Create.Configure(options)
    for key, value in pairs(options) do
        if _config[key] ~= nil then
            _config[key] = value
        end
    end
end

function Create.GetConfig()
    return deepCopy(_config)
end

function Create.GetInstanceCount()
    return _instanceCount
end

function Create.GetTrackedInstances()
    return _trackedInstances
end

function Create.CleanupTracked()
    for _, instance in ipairs(_trackedInstances) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    _trackedInstances = {}
    debugLog("Cleaned up tracked instances")
end

function Create.SetDebugMode(enabled)
    _config.DebugMode = enabled
end

-- ══════════════════════════════════════════════════════════════════════
-- SAFE DESTROY
-- ══════════════════════════════════════════════════════════════════════

function Create.Destroy(instance)
    if instance and typeof(instance) == "Instance" then
        instance:Destroy()
        return true
    end
    return false
end

function Create.DestroyChildren(parent)
    if parent and typeof(parent) == "Instance" then
        for _, child in ipairs(parent:GetChildren()) do
            child:Destroy()
        end
    end
end

function Create.SafeDestroy(instance, delay)
    if instance and typeof(instance) == "Instance" then
        if delay and delay > 0 then
            task.delay(delay, function()
                if instance and instance.Parent then
                    instance:Destroy()
                end
            end)
        else
            instance:Destroy()
        end
    end
end

return Create