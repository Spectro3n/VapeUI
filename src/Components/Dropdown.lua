--[[
    VapeUI Dropdown
    Selection menu.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(parent, options)
    local self = setmetatable({}, Dropdown)
    
    options = options or {}
    self.Name = options.Name or "Dropdown"
    self.Flag = options.Flag
    self.Options = options.Options or {}
    self.Default = options.Default
    self.MultiSelect = options.MultiSelect or false
    self.Callback = options.Callback or function() end
    
    self.Value = self.MultiSelect and {} or nil
    self.Open = false
    
    self.OnChanged = Signal.new()
    
    -- Main Frame
    self.Frame = Create.Frame({
        Name = "Dropdown_" .. self.Name,
        Size = UDim2.new(1, 0, 0, Config.Card.Height),
        BackgroundColor3 = Theme:Get("Card"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    }, {
        Create.Corner(Config.Card.CornerRadius),
        Create.Stroke({ Color = Theme:Get("Border"), Transparency = 0.6 }),
    })
    
    -- Header
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
        Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, Config.Card.Padding, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Heading,
        Text = self.Name,
        TextColor3 = Theme:Get("TextPrimary"),
        TextSize = Config.Font.SizeBody,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header,
    })
    
    -- Selected Display
    self.SelectedLabel = Create.Text({
        Name = "Selected",
        Size = UDim2.new(0.45, -30, 1, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Body,
        Text = "Select...",
        TextColor3 = Theme:Get("TextSecondary"),
        TextSize = Config.Font.SizeSmall,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.Header,
    })
    
    -- Arrow
    self.Arrow = Create.Text({
        Name = "Arrow",
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -Config.Card.Padding - 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Config.Font.Title,
        Text = "▼",
        TextColor3 = Theme:Get("TextMuted"),
        TextSize = 10,
        Parent = self.Header,
    })
    
    -- Options Container
    self.OptionsContainer = Create.Scroll({
        Name = "OptionsContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, Config.Card.Height + 4),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme:Get("Accent"),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        Visible = false,
        Parent = self.Frame,
    }, {
        Create.List({ Padding = UDim.new(0, 2) }),
        Create.Padding(4, 8, 4, 8),
    })
    
    -- Header click
    self.Header.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Populate options
    self:_populateOptions()
    
    -- Set default
    if self.Default then
        if self.MultiSelect and type(self.Default) == "table" then
            for _, v in ipairs(self.Default) do
                self:Select(v, true)
            end
        else
            self:Select(self.Default, true)
        end
    end
    
    return self
end

function Dropdown:_populateOptions()
    for _, child in ipairs(self.OptionsContainer:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, option in ipairs(self.Options) do
        local optBtn = Create.Button({
            Name = "Option_" .. option,
            Size = UDim2.new(1, 0, 0, Config.Dropdown.ItemHeight),
            BackgroundColor3 = Theme:Get("Card"),
            Font = Config.Font.Body,
            Text = option,
            TextColor3 = Theme:Get("TextPrimary"),
            TextSize = Config.Font.SizeBody,
            AutoButtonColor = false,
            Parent = self.OptionsContainer,
        }, {
            Create.Corner(4),
        })
        
        optBtn.MouseEnter:Connect(function()
            if not self:_isSelected(option) then
                Tween.Fast(optBtn, { BackgroundColor3 = Theme:Get("CardHover") })
            end
        end)
        
        optBtn.MouseLeave:Connect(function()
            if not self:_isSelected(option) then
                Tween.Fast(optBtn, { BackgroundColor3 = Theme:Get("Card") })
            end
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            self:Select(option)
        end)
    end
end

function Dropdown:_isSelected(option)
    if self.MultiSelect then
        return table.find(self.Value, option) ~= nil
    else
        return self.Value == option
    end
end

function Dropdown:_updateOptionVisuals()
    for _, child in ipairs(self.OptionsContainer:GetChildren()) do
        if child:IsA("TextButton") then
            local option = child.Name:gsub("Option_", "")
            local isSelected = self:_isSelected(option)
            Tween.Fast(child, {
                BackgroundColor3 = isSelected and Theme:Get("Accent") or Theme:Get("Card"),
                TextColor3 = isSelected and Color3.fromRGB(10, 10, 10) or Theme:Get("TextPrimary"),
            })
        end
    end
end

function Dropdown:Toggle()
    self.Open = not self.Open
    
    if self.Open then
        local itemCount = math.min(#self.Options, Config.Dropdown.MaxVisibleItems)
        local containerHeight = itemCount * (Config.Dropdown.ItemHeight + 2) + 8
        
        self.OptionsContainer.Visible = true
        Tween.Normal(self.Frame, { Size = UDim2.new(1, 0, 0, Config.Card.Height + containerHeight + 8) })
        Tween.Normal(self.OptionsContainer, { Size = UDim2.new(1, 0, 0, containerHeight) })
        Tween.Fast(self.Arrow, { Rotation = 180 })
    else
        Tween.Normal(self.Frame, { Size = UDim2.new(1, 0, 0, Config.Card.Height) })
        Tween.Normal(self.OptionsContainer, { Size = UDim2.new(1, 0, 0, 0) })
        Tween.Fast(self.Arrow, { Rotation = 0 })
        task.delay(Config.Animation.Normal, function()
            if not self.Open then
                self.OptionsContainer.Visible = false
            end
        end)
    end
end

function Dropdown:Select(option, skipCallback)
    if self.MultiSelect then
        local index = table.find(self.Value, option)
        if index then
            table.remove(self.Value, index)
        else
            table.insert(self.Value, option)
        end
        self.SelectedLabel.Text = #self.Value > 0 and table.concat(self.Value, ", ") or "Select..."
    else
        self.Value = option
        self.SelectedLabel.Text = option or "Select..."
        self:Toggle()
    end
    
    self:_updateOptionVisuals()
    
    if not skipCallback then
        self.Callback(self.Value)
        self.OnChanged:Fire(self.Value)
    end
end

function Dropdown:Set(value, skipCallback)
    if self.MultiSelect then
        self.Value = type(value) == "table" and value or {}
        self.SelectedLabel.Text = #self.Value > 0 and table.concat(self.Value, ", ") or "Select..."
    else
        self.Value = value
        self.SelectedLabel.Text = value or "Select..."
    end
    self:_updateOptionVisuals()
    
    if not skipCallback then
        self.Callback(self.Value)
        self.OnChanged:Fire(self.Value)
    end
end

function Dropdown:Refresh(newOptions)
    self.Options = newOptions
    self:_populateOptions()
end

function Dropdown:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Card")
    self.Frame.UIStroke.Color = Theme:Get("Border")
    self.Label.TextColor3 = Theme:Get("TextPrimary")
    self.SelectedLabel.TextColor3 = Theme:Get("TextSecondary")
    self.Arrow.TextColor3 = Theme:Get("TextMuted")
    self:_updateOptionVisuals()
end

return Dropdown