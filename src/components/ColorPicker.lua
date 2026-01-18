--[[
    VapeUI Color Picker
    HSV color selection with preview.
]]

local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

local UserInputService = Services:Get("UserInputService")

local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(parent, options)
    local self = setmetatable({}, ColorPicker)
    
    options = options or {}
    self.Name = options.Name or "Color"
    self.Flag = options.Flag or self.Name
    self.Default = options.Default or Color3.fromRGB(255, 255, 255)
    self.Callback = options.Callback or function() end
    
    self.Value = self.Default
    self.Open = false
    self._connections = {}
    
    -- HSV values
    local h, s, v = self.Default:ToHSV()
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    
    -- Signals
    self.OnChanged = Signal.new()
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "ColorPicker_" .. self.Name,
        Size = UDim2.new(1, 0, 0, Config.Card.Height),
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    }, {
        Create.Corner(Config.Card.CornerRadius),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.6,
        }),
    })
    
    -- Header button
    self.Header = Create.Button({
        Name = "Header",
        Size = UDim2.new(1, 0, 0, Config.Card.Height),
        BackgroundTransparency = 1,
        Font = Enum.Font.SourceSans,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Frame,
    })
    
    -- Label
    self.Label = Create.Text({
        Name = "Label",
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, Config.Card.Padding, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header,
    })
    
    -- Color preview
    self.Preview = Create.Frame({
        Name = "Preview",
        Size = UDim2.fromOffset(Config.ColorPicker.PreviewSize, Config.ColorPicker.PreviewSize),
        Position = UDim2.new(1, -Config.Card.Padding - Config.ColorPicker.PreviewSize, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Default,
        BorderSizePixel = 0,
        Parent = self.Header,
    }, {
        Create.Corner(4),
        Create.Stroke({
            Color = Theme:Get("Border"),
            Transparency = 0.3,
        }),
    })
    
    -- Picker container
    self.PickerContainer = Create.Frame({
        Name = "PickerContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, Config.Card.Height + 8),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.Frame,
    }, {
        Create.Padding(0, Config.Card.Padding, Config.Card.Padding, Config.Card.Padding),
    })
    
    -- Saturation/Value picker
    self.SaturationFrame = Create.Image({
        Name = "Saturation",
        Size = UDim2.new(1, -Config.ColorPicker.HueBarWidth - 10, 0, Config.ColorPicker.PaletteSize),
        BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1),
        Image = "rbxassetid://4155801252", -- Saturation gradient
        Parent = self.PickerContainer,
    }, {
        Create.Corner(4),
    })
    
    -- Saturation cursor
    self.SaturationCursor = Create.Frame({
        Name = "Cursor",
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(self.Saturation, 0, 1 - self.Brightness, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.SaturationFrame,
    }, {
        Create.Corner(6),
        Create.Stroke({
            Color = Color3.new(0, 0, 0),
            Thickness = 2,
        }),
    })
    
    -- Hue slider
    self.HueFrame = Create.Image({
        Name = "Hue",
        Size = UDim2.new(0, Config.ColorPicker.HueBarWidth, 0, Config.ColorPicker.PaletteSize),
        Position = UDim2.new(1, 0, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://3641079629", -- Hue gradient
        Parent = self.PickerContainer,
    }, {
        Create.Corner(4),
    })
    
    -- Hue cursor
    self.HueCursor = Create.Frame({
        Name = "Cursor",
        Size = UDim2.new(1, 4, 0, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, self.Hue, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.HueFrame,
    }, {
        Create.Corner(2),
        Create.Stroke({
            Color = Color3.new(0, 0, 0),
            Thickness = 1,
        }),
    })
    
    -- Header click to toggle
    self.Header.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Setup drag interactions
    self:_setupDrag()
    
    return self
end

function ColorPicker:_setupDrag()
    local satDragging = false
    local hueDragging = false
    
    -- Saturation drag
    self.SaturationFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            satDragging = true
            self:_updateSaturation(input)
        end
    end)
    
    -- Hue drag
    self.HueFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            self:_updateHue(input)
        end
    end)
    
    -- Global input changed
    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.Touch then
            if satDragging then
                self:_updateSaturation(input)
            elseif hueDragging then
                self:_updateHue(input)
            end
        end
    end))
    
    -- Global input ended
    table.insert(self._connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            satDragging = false
            hueDragging = false
        end
    end))
end

function ColorPicker:_updateSaturation(input)
    local frame = self.SaturationFrame
    local x = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
    local y = math.clamp((input.Position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
    
    self.Saturation = x
    self.Brightness = 1 - y
    
    self.SaturationCursor.Position = UDim2.new(x, 0, y, 0)
    self:_updateColor()
end

function ColorPicker:_updateHue(input)
    local frame = self.HueFrame
    local y = math.clamp((input.Position.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
    
    self.Hue = y
    
    self.HueCursor.Position = UDim2.new(0.5, 0, y, 0)
    self.SaturationFrame.BackgroundColor3 = Color3.fromHSV(self.Hue, 1, 1)
    self:_updateColor()
end

function ColorPicker:_updateColor()
    self.Value = Color3.fromHSV(self.Hue, self.Saturation, self.Brightness)
    self.Preview.BackgroundColor3 = self.Value
    self.Callback(self.Value)
    self.OnChanged:Fire(self.Value)
end

function ColorPicker:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        local height = Config.Card.Height + Config.ColorPicker.PaletteSize + 24
        self.PickerContainer.Visible = true
        Tween.Normal(self.Frame, {Size = UDim2.new(1, 0, 0, height)})
        Tween.Normal(self.PickerContainer, {Size = UDim2.new(1, 0, 0, Config.ColorPicker.PaletteSize + 16)})
    else
        Tween.Normal(self.Frame, {Size = UDim2.new(1, 0, 0, Config.Card.Height)})
        Tween.Normal(self.PickerContainer, {Size = UDim2.new(1, 0, 0, 0)})
        task.delay(Config.Animation.Normal, function()
            if not self.Open then
                self.PickerContainer.Visible = false
            end
        end)
    end
end

function ColorPicker:Set(color, skipCallback)
    local h, s, v = color:ToHSV()
    self.Hue = h
    self.Saturation = s
    self.Brightness = v
    self.Value = color
    
    self.Preview.BackgroundColor3 = color
    self.SaturationFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    self.SaturationCursor.Position = UDim2.new(s, 0, 1 - v, 0)
    self.HueCursor.Position = UDim2.new(0.5, 0, h, 0)
    
    if not skipCallback then
        self.Callback(color)
        self.OnChanged:Fire(color)
    end
end

function ColorPicker:Get()
    return self.Value
end

function ColorPicker:GetHex()
    local r = math.floor(self.Value.R * 255)
    local g = math.floor(self.Value.G * 255)
    local b = math.floor(self.Value.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

function ColorPicker:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.Label.TextColor3 = Theme:Get("TextPrimary")
    
    local frameStroke = self.Frame:FindFirstChildOfClass("UIStroke")
    if frameStroke then
        frameStroke.Color = Theme:Get("Border")
    end
    
    local previewStroke = self.Preview:FindFirstChildOfClass("UIStroke")
    if previewStroke then
        previewStroke.Color = Theme:Get("Border")
    end
end

function ColorPicker:Destroy()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    self._connections = {}
    self.OnChanged:Destroy()
    self.Frame:Destroy()
end

return ColorPicker