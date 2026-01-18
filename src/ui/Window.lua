--[[
    VapeUI Window
    Main container for the entire UI.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)
local Drag = require(script.Parent.Parent.utils.Drag)
local Tween = require(script.Parent.Parent.utils.Tween)
local Signal = require(script.Parent.Parent.core.Signal)

local Window = {}
Window.__index = Window

function Window.new(screenGui, options)
    local self = setmetatable({}, Window)
    
    options = options or {}
    self.Title = options.Title or "VapeUI"
    self.Size = options.Size or Config.Window.DefaultSize
    
    -- Signals
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnMaximize = Signal.new()
    
    -- State
    self.Visible = true
    self.Minimized = false
    
    -- Create main frame
    self.Frame = Create.Frame({
        Name = "VapeUI_Window",
        Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme:Get("Window"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screenGui,
    }, {
        Create.Corner(Config.Window.CornerRadius),
    })
    
    -- Shadow
    self.Shadow = Create.Image({
        Name = "Shadow",
        Size = UDim2.new(1, Config.Window.ShadowSize * 2, 1, Config.Window.ShadowSize * 2),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme:Get("Shadow"),
        ImageTransparency = Theme:Get("ShadowTransparency"),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = -1,
        Parent = self.Frame,
    })
    
    -- Container for content (sidebar + content area)
    self.Container = Create.Frame({
        Name = "Container",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Frame,
    })
    
    return self
end

function Window:SetVisible(visible)
    self.Visible = visible
    
    if visible then
        self.Frame.Visible = true
        self.Frame.Size = UDim2.new(0, 0, 0, 0)
        self.Frame.BackgroundTransparency = 1
        Tween.Spring(self.Frame, {
            Size = UDim2.fromOffset(self.Size.X, self.Size.Y),
            BackgroundTransparency = 0,
        })
    else
        Tween.Normal(self.Frame, {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
        })
        task.delay(Config.Animation.Normal, function()
            if not self.Visible then
                self.Frame.Visible = false
            end
        end)
    end
end

function Window:Toggle()
    self:SetVisible(not self.Visible)
end

function Window:Destroy()
    self.OnClose:Fire()
    self.Frame:Destroy()
end

function Window:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Window")
    self.Shadow.ImageColor3 = Theme:Get("Shadow")
    self.Shadow.ImageTransparency = Theme:Get("ShadowTransparency")
end

return Window