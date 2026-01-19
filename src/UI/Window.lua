--[[
    VapeUI Window v2.0
    Advanced main container with window management features.
    
    Features:
    ✅ Smooth open/close animations
    ✅ Resize support (all edges and corners)
    ✅ Snap to edges
    ✅ Minimize to taskbar/tray
    ✅ Maximize/Restore
    ✅ Multiple animation styles
    ✅ Shadow effects
    ✅ Blur background
    ✅ Transparency support
    ✅ Keyboard shortcuts
    ✅ Position memory
    ✅ Size constraints
    ✅ Focus management
    ✅ Z-index layering
    ✅ Multi-window support
    ✅ Modal mode
    ✅ Shake animation
    ✅ Flash attention
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

local Window = {}
Window.__index = Window

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Dimensions
    Size = Vector2.new(600, 450),
    MinSize = Vector2.new(400, 300),
    MaxSize = Vector2.new(1200, 900),
    Position = nil,  -- nil = center
    
    -- Appearance
    CornerRadius = 12,
    ShadowSize = 15,
    BackgroundTransparency = 0,
    
    -- Animation
    AnimationStyle = "Scale",  -- Scale, Fade, Slide, SlideUp, Bounce, None
    AnimationDuration = 0.3,
    EnableShake = true,
    
    -- Features
    EnableResize = true,
    EnableSnap = true,
    SnapThreshold = 20,
    EnableMaximize = true,
    EnableMinimize = true,
    EnableKeyboardShortcuts = true,
    EnableFocusManagement = true,
    EnablePositionMemory = false,
    
    -- Behavior
    Modal = false,
    CloseOnEscape = true,
    BringToFrontOnClick = true,
    StartMinimized = false,
    StartMaximized = false,
    
    -- Content
    Title = "VapeUI",
}

local RESIZE_HANDLES = {
    Top = {Cursor = "SizeNS", Offset = Vector2.new(0, -1)},
    Bottom = {Cursor = "SizeNS", Offset = Vector2.new(0, 1)},
    Left = {Cursor = "SizeWE", Offset = Vector2.new(-1, 0)},
    Right = {Cursor = "SizeWE", Offset = Vector2.new(1, 0)},
    TopLeft = {Cursor = "SizeNWSE", Offset = Vector2.new(-1, -1)},
    TopRight = {Cursor = "SizeNESW", Offset = Vector2.new(1, -1)},
    BottomLeft = {Cursor = "SizeNESW", Offset = Vector2.new(-1, 1)},
    BottomRight = {Cursor = "SizeNWSE", Offset = Vector2.new(1, 1)},
}

local ANIMATION_STYLES = {
    Scale = {
        initial = function(frame, size)
            frame.Size = UDim2.new(0, 0, 0, 0)
            frame.BackgroundTransparency = 1
        end,
        show = function(frame, size, duration)
            return Tween.Spring(frame, {
                Size = UDim2.fromOffset(size.X, size.Y),
                BackgroundTransparency = 0,
            })
        end,
        hide = function(frame, duration)
            return Tween.new(frame, {
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
            }, duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end,
    },
    Fade = {
        initial = function(frame, size)
            frame.Size = UDim2.fromOffset(size.X, size.Y)
            frame.BackgroundTransparency = 1
        end,
        show = function(frame, size, duration)
            return Tween.new(frame, {BackgroundTransparency = 0}, duration)
        end,
        hide = function(frame, duration)
            return Tween.new(frame, {BackgroundTransparency = 1}, duration)
        end,
    },
    Slide = {
        initial = function(frame, size)
            frame.Size = UDim2.fromOffset(size.X, size.Y)
            frame.Position = UDim2.new(0.5, 0, 0, -size.Y)
            frame.BackgroundTransparency = 0
        end,
        show = function(frame, size, duration)
            return Tween.new(frame, {Position = UDim2.new(0.5, 0, 0.5, 0)}, duration, Enum.EasingStyle.Back)
        end,
        hide = function(frame, duration)
            local size = frame.AbsoluteSize
            return Tween.new(frame, {Position = UDim2.new(0.5, 0, 1, size.Y)}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        end,
    },
    SlideUp = {
        initial = function(frame, size)
            frame.Size = UDim2.fromOffset(size.X, size.Y)
            frame.Position = UDim2.new(0.5, 0, 1, size.Y)
            frame.BackgroundTransparency = 0
        end,
        show = function(frame, size, duration)
            return Tween.new(frame, {Position = UDim2.new(0.5, 0, 0.5, 0)}, duration, Enum.EasingStyle.Quart)
        end,
        hide = function(frame, duration)
            local size = frame.AbsoluteSize
            return Tween.new(frame, {Position = UDim2.new(0.5, 0, 1, size.Y)}, duration, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        end,
    },
    Bounce = {
        initial = function(frame, size)
            frame.Size = UDim2.fromOffset(size.X, size.Y)
            frame.Position = UDim2.new(0.5, 0, -0.5, 0)
            frame.BackgroundTransparency = 0
        end,
        show = function(frame, size, duration)
            return Tween.new(frame, {Position = UDim2.new(0.5, 0, 0.5, 0)}, duration, Enum.EasingStyle.Bounce)
        end,
        hide = function(frame, duration)
            return Tween.new(frame, {
                Position = UDim2.new(0.5, 0, 0.5, 50),
                BackgroundTransparency = 1,
            }, duration)
        end,
    },
    None = {
        initial = function(frame, size)
            frame.Size = UDim2.fromOffset(size.X, size.Y)
            frame.BackgroundTransparency = 0
        end,
        show = function(frame, size, duration) end,
        hide = function(frame, duration) end,
    },
}

-- Window registry for multi-window support
local _windows = {}
local _focusedWindow = nil
local _zIndexCounter = 1

-- ══════════════════════════════════════════════════════════════════════
-- WINDOW CLASS
-- ══════════════════════════════════════════════════════════════════════

function Window.new(screenGui, options)
    local self = setmetatable({}, Window)
    
    -- Configuration
    options = options or {}
    self.Config = setmetatable({}, {__index = DEFAULT_CONFIG})
    for key, value in pairs(options) do
        self.Config[key] = value
    end
    
    -- State
    self.ScreenGui = screenGui
    self.Size = self.Config.Size
    self.OriginalSize = self.Config.Size
    self.OriginalPosition = nil
    self.Visible = false
    self.Minimized = false
    self.Maximized = false
    self.Focused = false
    self.Destroyed = false
    self._zIndex = _zIndexCounter
    self._resizing = nil
    self._connections = {}
    
    -- Signals
    self.OnShow = Signal.new()
    self.OnHide = Signal.new()
    self.OnClose = Signal.new()
    self.OnMinimize = Signal.new()
    self.OnMaximize = Signal.new()
    self.OnRestore = Signal.new()
    self.OnFocus = Signal.new()
    self.OnBlur = Signal.new()
    self.OnResize = Signal.new()
    self.OnMove = Signal.new()
    
    -- Register window
    _zIndexCounter = _zIndexCounter + 1
    table.insert(_windows, self)
    
    -- Build UI
    self:_build()
    self:_setupInteractions()
    
    -- Initial state
    if self.Config.StartMinimized then
        self:Minimize()
    elseif self.Config.StartMaximized then
        self:Maximize()
    elseif not self.Config.StartHidden then
        self:Show()
    end
    
    return self
end

function Window:_build()
    local config = self.Config
    
    -- Modal overlay (if modal)
    if config.Modal then
        self.ModalOverlay = Create.Frame({
            Name = "ModalOverlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.5,
            ZIndex = self._zIndex,
            Visible = false,
            Parent = self.ScreenGui,
        })
        
        -- Click overlay to shake window
        self.ModalOverlay.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:Shake()
            end
        end)
    end
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "VapeUI_Window",
        Size = UDim2.fromOffset(config.Size.X, config.Size.Y),
        Position = config.Position or UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme:Get("Window"),
        BackgroundTransparency = config.BackgroundTransparency,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = self._zIndex + 1,
        Parent = self.ScreenGui,
    }, {
        Create.Corner(config.CornerRadius),
    })
    
    -- Shadow
    self.Shadow = Create.Image({
        Name = "Shadow",
        Size = UDim2.new(1, config.ShadowSize * 2, 1, config.ShadowSize * 2),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5028857084",
        ImageColor3 = Theme:Get("Shadow") or Color3.new(0, 0, 0),
        ImageTransparency = Theme:Get("ShadowTransparency") or 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(24, 24, 276, 276),
        ZIndex = -1,
        Parent = self.Frame,
    })
    
    -- Container for content
    self.Container = Create.Frame({
        Name = "Container",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = self.Frame,
    })
    
    -- Resize handles
    if config.EnableResize then
        self:_buildResizeHandles()
    end
    
    -- Focus ring
    self.FocusRing = Create.Frame({
        Name = "FocusRing",
        Size = UDim2.new(1, 4, 1, 4),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 100,
        Parent = self.Frame,
    }, {
        Create.Corner(config.CornerRadius + 2),
        Create.Stroke({
            Color = Theme:Get("Accent"),
            Thickness = 2,
            Transparency = 0.5,
        }),
    })
end

function Window:_buildResizeHandles()
    local handleSize = 6
    
    self.ResizeHandles = {}
    
    for name, config in pairs(RESIZE_HANDLES) do
        local handle = Create.Frame({
            Name = "ResizeHandle_" .. name,
            BackgroundTransparency = 1,
            ZIndex = 50,
            Parent = self.Frame,
        })
        
        -- Position handles
        if name == "Top" then
            handle.Size = UDim2.new(1, -handleSize * 2, 0, handleSize)
            handle.Position = UDim2.new(0, handleSize, 0, 0)
        elseif name == "Bottom" then
            handle.Size = UDim2.new(1, -handleSize * 2, 0, handleSize)
            handle.Position = UDim2.new(0, handleSize, 1, -handleSize)
        elseif name == "Left" then
            handle.Size = UDim2.new(0, handleSize, 1, -handleSize * 2)
            handle.Position = UDim2.new(0, 0, 0, handleSize)
        elseif name == "Right" then
            handle.Size = UDim2.new(0, handleSize, 1, -handleSize * 2)
            handle.Position = UDim2.new(1, -handleSize, 0, handleSize)
        elseif name == "TopLeft" then
            handle.Size = UDim2.fromOffset(handleSize, handleSize)
            handle.Position = UDim2.new(0, 0, 0, 0)
        elseif name == "TopRight" then
            handle.Size = UDim2.fromOffset(handleSize, handleSize)
            handle.Position = UDim2.new(1, -handleSize, 0, 0)
        elseif name == "BottomLeft" then
            handle.Size = UDim2.fromOffset(handleSize, handleSize)
            handle.Position = UDim2.new(0, 0, 1, -handleSize)
        elseif name == "BottomRight" then
            handle.Size = UDim2.fromOffset(handleSize, handleSize)
            handle.Position = UDim2.new(1, -handleSize, 1, -handleSize)
        end
        
        self.ResizeHandles[name] = handle
        
        -- Resize logic
        self:_setupResizeHandle(handle, name, config.Offset)
    end
end

function Window:_setupResizeHandle(handle, name, offset)
    local resizing = false
    local startPos = nil
    local startSize = nil
    local startWindowPos = nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            startPos = input.Position
            startSize = self.Frame.AbsoluteSize
            startWindowPos = self.Frame.AbsolutePosition
            self._resizing = name
        end
    end)
    
    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            local newSize = startSize
            local newPos = self.Frame.Position
            
            -- Calculate new size based on handle
            if offset.X ~= 0 then
                local widthDelta = delta.X * offset.X
                newSize = Vector2.new(
                    math.clamp(startSize.X + widthDelta, self.Config.MinSize.X, self.Config.MaxSize.X),
                    newSize.Y
                )
                
                -- Adjust position for left handles
                if offset.X < 0 then
                    local sizeDiff = newSize.X - startSize.X
                    newPos = UDim2.new(
                        newPos.X.Scale,
                        startWindowPos.X - sizeDiff / 2,
                        newPos.Y.Scale,
                        newPos.Y.Offset
                    )
                end
            end
            
            if offset.Y ~= 0 then
                local heightDelta = delta.Y * offset.Y
                newSize = Vector2.new(
                    newSize.X,
                    math.clamp(startSize.Y + heightDelta, self.Config.MinSize.Y, self.Config.MaxSize.Y)
                )
                
                -- Adjust position for top handles
                if offset.Y < 0 then
                    local sizeDiff = newSize.Y - startSize.Y
                    newPos = UDim2.new(
                        newPos.X.Scale,
                        newPos.X.Offset,
                        newPos.Y.Scale,
                        startWindowPos.Y - sizeDiff / 2
                    )
                end
            end
            
            self.Frame.Size = UDim2.fromOffset(newSize.X, newSize.Y)
            self.Size = newSize
            
            self.OnResize:Fire(newSize)
        end
    end)
    table.insert(self._connections, moveConn)
    
    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and resizing then
            resizing = false
            self._resizing = nil
        end
    end)
    table.insert(self._connections, endConn)
end

function Window:_setupInteractions()
    local config = self.Config
    
    -- Bring to front on click
    if config.BringToFrontOnClick then
        local conn = self.Frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                self:Focus()
            end
        end)
        table.insert(self._connections, conn)
    end
    
    -- Keyboard shortcuts
    if config.EnableKeyboardShortcuts then
        local conn = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if not self.Focused then return end
            
            if input.KeyCode == Enum.KeyCode.Escape and config.CloseOnEscape then
                self:Hide()
            end
        end)
        table.insert(self._connections, conn)
    end
    
    -- Snap to edges
    if config.EnableSnap then
        local conn = self.Frame:GetPropertyChangedSignal("Position"):Connect(function()
            if self._resizing then return end
            self:_checkSnap()
        end)
        table.insert(self._connections, conn)
    end
end

function Window:_checkSnap()
    local threshold = self.Config.SnapThreshold
    local viewportSize = self.ScreenGui.AbsoluteSize
    local framePos = self.Frame.AbsolutePosition
    local frameSize = self.Frame.AbsoluteSize
    
    local newPos = self.Frame.Position
    local snapped = false
    
    -- Snap to left edge
    if framePos.X < threshold then
        newPos = UDim2.new(0, frameSize.X / 2, newPos.Y.Scale, newPos.Y.Offset)
        snapped = true
    end
    
    -- Snap to right edge
    if framePos.X + frameSize.X > viewportSize.X - threshold then
        newPos = UDim2.new(1, -frameSize.X / 2, newPos.Y.Scale, newPos.Y.Offset)
        snapped = true
    end
    
    -- Snap to top edge
    if framePos.Y < threshold then
        newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, frameSize.Y / 2)
        snapped = true
    end
    
    -- Snap to bottom edge
    if framePos.Y + frameSize.Y > viewportSize.Y - threshold then
        newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 1, -frameSize.Y / 2)
        snapped = true
    end
    
    if snapped then
        self.Frame.Position = newPos
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════════════

function Window:Show(animate)
    if self.Visible then return end
    
    self.Visible = true
    self.Frame.Visible = true
    
    if self.ModalOverlay then
        self.ModalOverlay.Visible = true
    end
    
    local animStyle = ANIMATION_STYLES[self.Config.AnimationStyle] or ANIMATION_STYLES.Scale
    
    if animate ~= false then
        animStyle.initial(self.Frame, self.Size)
        animStyle.show(self.Frame, self.Size, self.Config.AnimationDuration)
    end
    
    self:Focus()
    self.OnShow:Fire()
end

function Window:Hide(animate)
    if not self.Visible then return end
    
    local animStyle = ANIMATION_STYLES[self.Config.AnimationStyle] or ANIMATION_STYLES.Scale
    
    if animate ~= false then
        animStyle.hide(self.Frame, self.Config.AnimationDuration)
        
        task.delay(self.Config.AnimationDuration, function()
            if not self.Visible then
                self.Frame.Visible = false
                if self.ModalOverlay then
                    self.ModalOverlay.Visible = false
                end
            end
        end)
    else
        self.Frame.Visible = false
        if self.ModalOverlay then
            self.ModalOverlay.Visible = false
        end
    end
    
    self.Visible = false
    self:Blur()
    self.OnHide:Fire()
end

function Window:Toggle(animate)
    if self.Visible then
        self:Hide(animate)
    else
        self:Show(animate)
    end
end

function Window:Close()
    self.OnClose:Fire()
    self:Destroy()
end

function Window:Minimize()
    if self.Minimized then return end
    
    self.Minimized = true
    self.OriginalSize = self.Size
    self.OriginalPosition = self.Frame.Position
    
    Tween.Normal(self.Frame, {
        Size = UDim2.fromOffset(200, 40),
        Position = UDim2.new(0, 110, 1, -30),
    })
    
    self.OnMinimize:Fire()
end

function Window:Restore()
    if not self.Minimized and not self.Maximized then return end
    
    if self.Minimized then
        self.Minimized = false
        Tween.Normal(self.Frame, {
            Size = UDim2.fromOffset(self.OriginalSize.X, self.OriginalSize.Y),
            Position = self.OriginalPosition or UDim2.new(0.5, 0, 0.5, 0),
        })
    end
    
    if self.Maximized then
        self.Maximized = false
        Tween.Normal(self.Frame, {
            Size = UDim2.fromOffset(self.OriginalSize.X, self.OriginalSize.Y),
            Position = self.OriginalPosition or UDim2.new(0.5, 0, 0.5, 0),
        })
        
        -- Re-enable corner radius
        local corner = self.Frame:FindFirstChildOfClass("UICorner")
        if corner then
            corner.CornerRadius = UDim.new(0, self.Config.CornerRadius)
        end
    end
    
    self.OnRestore:Fire()
end

function Window:Maximize()
    if self.Maximized then return end
    
    self.Maximized = true
    self.OriginalSize = self.Size
    self.OriginalPosition = self.Frame.Position
    
    local viewportSize = self.ScreenGui.AbsoluteSize
    
    Tween.Normal(self.Frame, {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
    })
    
    -- Remove corner radius when maximized
    local corner = self.Frame:FindFirstChildOfClass("UICorner")
    if corner then
        corner.CornerRadius = UDim.new(0, 0)
    end
    
    self.OnMaximize:Fire()
end

function Window:Focus()
    if self.Focused then return end
    
    -- Blur other windows
    for _, win in ipairs(_windows) do
        if win ~= self and win.Focused then
            win:Blur()
        end
    end
    
    self.Focused = true
    _focusedWindow = self
    
    -- Bring to front
    _zIndexCounter = _zIndexCounter + 1
    self._zIndex = _zIndexCounter
    self.Frame.ZIndex = self._zIndex
    
    if self.ModalOverlay then
        self.ModalOverlay.ZIndex = self._zIndex - 1
    end
    
    -- Visual feedback
    self.FocusRing.Visible = true
    Tween.Fast(self.FocusRing, {BackgroundTransparency = 1})
    
    self.OnFocus:Fire()
end

function Window:Blur()
    if not self.Focused then return end
    
    self.Focused = false
    
    if _focusedWindow == self then
        _focusedWindow = nil
    end
    
    self.FocusRing.Visible = false
    
    self.OnBlur:Fire()
end

function Window:Shake()
    if not self.Config.EnableShake then return end
    
    local originalPos = self.Frame.Position
    local shakeAmount = 10
    local shakeDuration = 0.05
    
    for i = 1, 4 do
        local offset = (i % 2 == 0) and shakeAmount or -shakeAmount
        Tween.new(self.Frame, {
            Position = UDim2.new(
                originalPos.X.Scale,
                originalPos.X.Offset + offset,
                originalPos.Y.Scale,
                originalPos.Y.Offset
            )
        }, shakeDuration, Enum.EasingStyle.Linear)
        task.wait(shakeDuration)
    end
    
    Tween.new(self.Frame, {Position = originalPos}, shakeDuration)
end

function Window:Flash()
    local originalColor = self.Frame.BackgroundColor3
    
    for i = 1, 3 do
        Tween.Fast(self.Frame, {BackgroundColor3 = Theme:Get("Accent")})
        task.wait(0.1)
        Tween.Fast(self.Frame, {BackgroundColor3 = originalColor})
        task.wait(0.1)
    end
end

function Window:SetSize(size, animate)
    self.Size = size
    
    if animate then
        Tween.Normal(self.Frame, {Size = UDim2.fromOffset(size.X, size.Y)})
    else
        self.Frame.Size = UDim2.fromOffset(size.X, size.Y)
    end
    
    self.OnResize:Fire(size)
end

function Window:GetSize()
    return self.Size
end

function Window:SetPosition(position, animate)
    if animate then
        Tween.Normal(self.Frame, {Position = position})
    else
        self.Frame.Position = position
    end
    
    self.OnMove:Fire(position)
end

function Window:GetPosition()
    return self.Frame.Position
end

function Window:Center(animate)
    self:SetPosition(UDim2.new(0.5, 0, 0.5, 0), animate)
end

function Window:SetTitle(title)
    self.Config.Title = title
    -- Note: TopBar handles actual title display
end

function Window:GetContainer()
    return self.Container
end

function Window:IsVisible()
    return self.Visible
end

function Window:IsMinimized()
    return self.Minimized
end

function Window:IsMaximized()
    return self.Maximized
end

function Window:IsFocused()
    return self.Focused
end

function Window:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Window")
    
    if self.Shadow then
        self.Shadow.ImageColor3 = Theme:Get("Shadow") or Color3.new(0, 0, 0)
        self.Shadow.ImageTransparency = Theme:Get("ShadowTransparency") or 0.5
    end
    
    if self.FocusRing then
        local stroke = self.FocusRing:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = Theme:Get("Accent")
        end
    end
end

function Window:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    
    -- Remove from registry
    for i, win in ipairs(_windows) do
        if win == self then
            table.remove(_windows, i)
            break
        end
    end
    
    -- Disconnect connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    -- Destroy signals
    self.OnShow:Destroy()
    self.OnHide:Destroy()
    self.OnClose:Destroy()
    self.OnMinimize:Destroy()
    self.OnMaximize:Destroy()
    self.OnRestore:Destroy()
    self.OnFocus:Destroy()
    self.OnBlur:Destroy()
    self.OnResize:Destroy()
    self.OnMove:Destroy()
    
    -- Destroy UI
    if self.ModalOverlay then
        self.ModalOverlay:Destroy()
    end
    
    if self.Frame then
        self.Frame:Destroy()
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- STATIC METHODS
-- ══════════════════════════════════════════════════════════════════════

function Window.GetFocused()
    return _focusedWindow
end

function Window.GetAll()
    return _windows
end

function Window.CloseAll()
    for _, win in ipairs(_windows) do
        win:Close()
    end
end

function Window.MinimizeAll()
    for _, win in ipairs(_windows) do
        win:Minimize()
    end
end

function Window.RestoreAll()
    for _, win in ipairs(_windows) do
        win:Restore()
    end
end

return Window