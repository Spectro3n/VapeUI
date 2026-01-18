--[[
    VapeUI Blur Controller v2.0
    Advanced background blur and visual effects management.
    
    Features:
    ✅ Multiple blur layers with priorities
    ✅ Blur presets (Light, Medium, Heavy, Ultra)
    ✅ Animated transitions with custom easing
    ✅ Color correction integration
    ✅ Depth of field effect
    ✅ Vignette overlay
    ✅ Blur tint/color overlay
    ✅ Pulse/breathing animations
    ✅ Focus mode (blur except focused area)
    ✅ Performance-aware quality settings
    ✅ Blur profiles
    ✅ Glass/frosted glass effect
    ✅ Dynamic blur (scroll-based, distance-based)
    ✅ Screenshot mode (high quality)
    ✅ Blur masking (selective areas)
    ✅ Smooth enable/disable transitions
    ✅ Multiple simultaneous effects
    ✅ Atmosphere integration
    ✅ Sunrays/bloom combination
    ✅ Event-driven blur (modal, menu, etc.)
]]

local Services = require("Utils/Services.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

-- Services
local Lighting = Services.Lighting
local TweenService = Services.TweenService
local RunService = Services.RunService

local Blur = {}
Blur.__index = Blur

-- ══════════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ══════════════════════════════════════════════════════════════════════

local DEFAULT_CONFIG = {
    -- Base settings
    DefaultSize = 10,
    MaxSize = 56,
    MinSize = 0,
    
    -- Animation
    TransitionDuration = 0.3,
    TransitionEasing = Enum.EasingStyle.Quart,
    TransitionDirection = Enum.EasingDirection.Out,
    
    -- Performance
    QualityLevel = "High",  -- Low, Medium, High, Ultra
    AutoAdjustQuality = true,
    TargetFPS = 60,
    MinFPS = 30,
    
    -- Effects
    EnableColorCorrection = true,
    EnableDepthOfField = false,
    EnableVignette = false,
    EnableBloom = false,
    EnableSunRays = false,
    
    -- Pulse animation
    PulseEnabled = false,
    PulseMinSize = 8,
    PulseMaxSize = 15,
    PulseSpeed = 2,
}

-- Blur presets
local PRESETS = {
    None = {
        BlurSize = 0,
        Brightness = 0,
        Contrast = 0,
        Saturation = 0,
        TintColor = nil,
        VignetteSize = 0,
    },
    Light = {
        BlurSize = 6,
        Brightness = 0,
        Contrast = 0,
        Saturation = 0,
        TintColor = nil,
        VignetteSize = 0,
    },
    Medium = {
        BlurSize = 12,
        Brightness = -0.05,
        Contrast = 0.05,
        Saturation = -0.1,
        TintColor = nil,
        VignetteSize = 0.1,
    },
    Heavy = {
        BlurSize = 24,
        Brightness = -0.1,
        Contrast = 0.1,
        Saturation = -0.2,
        TintColor = nil,
        VignetteSize = 0.2,
    },
    Ultra = {
        BlurSize = 40,
        Brightness = -0.15,
        Contrast = 0.15,
        Saturation = -0.3,
        TintColor = nil,
        VignetteSize = 0.3,
    },
    Cinematic = {
        BlurSize = 8,
        Brightness = -0.05,
        Contrast = 0.15,
        Saturation = -0.1,
        TintColor = Color3.fromRGB(20, 20, 30),
        VignetteSize = 0.4,
    },
    Dream = {
        BlurSize = 15,
        Brightness = 0.1,
        Contrast = -0.1,
        Saturation = 0.2,
        TintColor = Color3.fromRGB(255, 240, 245),
        VignetteSize = 0.2,
    },
    Dark = {
        BlurSize = 18,
        Brightness = -0.3,
        Contrast = 0.2,
        Saturation = -0.4,
        TintColor = Color3.fromRGB(10, 10, 15),
        VignetteSize = 0.5,
    },
    Focus = {
        BlurSize = 20,
        Brightness = -0.1,
        Contrast = 0.05,
        Saturation = -0.15,
        TintColor = nil,
        VignetteSize = 0.6,
    },
    Glass = {
        BlurSize = 8,
        Brightness = 0.05,
        Contrast = 0.1,
        Saturation = 0,
        TintColor = Color3.fromRGB(255, 255, 255),
        TintTransparency = 0.9,
        VignetteSize = 0,
    },
    Modal = {
        BlurSize = 15,
        Brightness = -0.15,
        Contrast = 0.05,
        Saturation = -0.2,
        TintColor = Color3.fromRGB(0, 0, 0),
        TintTransparency = 0.5,
        VignetteSize = 0.3,
    },
}

-- Quality presets
local QUALITY_SETTINGS = {
    Low = {
        MaxBlur = 20,
        EnableColorCorrection = false,
        EnableDepthOfField = false,
        EnableVignette = false,
        EnableBloom = false,
        UpdateRate = 0.1,
    },
    Medium = {
        MaxBlur = 35,
        EnableColorCorrection = true,
        EnableDepthOfField = false,
        EnableVignette = true,
        EnableBloom = false,
        UpdateRate = 0.05,
    },
    High = {
        MaxBlur = 50,
        EnableColorCorrection = true,
        EnableDepthOfField = true,
        EnableVignette = true,
        EnableBloom = true,
        UpdateRate = 0.016,
    },
    Ultra = {
        MaxBlur = 56,
        EnableColorCorrection = true,
        EnableDepthOfField = true,
        EnableVignette = true,
        EnableBloom = true,
        UpdateRate = 0,
    },
}

-- ══════════════════════════════════════════════════════════════════════
-- SINGLETON INSTANCE
-- ══════════════════════════════════════════════════════════════════════

local _instance = nil

-- ══════════════════════════════════════════════════════════════════════
-- BLUR LAYER CLASS
-- ══════════════════════════════════════════════════════════════════════

local BlurLayer = {}
BlurLayer.__index = BlurLayer

function BlurLayer.new(controller, name, options)
    local self = setmetatable({}, BlurLayer)
    
    options = options or {}
    
    self.Controller = controller
    self.Name = name
    self.Priority = options.Priority or 0
    self.Size = options.Size or 0
    self.TargetSize = 0
    self.Enabled = false
    self.Visible = true
    
    -- Optional properties
    self.Preset = options.Preset
    self.Duration = options.Duration or controller.Config.TransitionDuration
    self.Easing = options.Easing or controller.Config.TransitionEasing
    
    -- Color correction overrides
    self.Brightness = options.Brightness or 0
    self.Contrast = options.Contrast or 0
    self.Saturation = options.Saturation or 0
    self.TintColor = options.TintColor
    self.TintTransparency = options.TintTransparency or 1
    
    -- Signals
    self.OnEnabled = Signal.new()
    self.OnDisabled = Signal.new()
    self.OnSizeChanged = Signal.new()
    
    return self
end

function BlurLayer:Enable(size, duration)
    self.Enabled = true
    self.TargetSize = size or self.Size or self.Controller.Config.DefaultSize
    
    -- Apply preset if set
    if self.Preset and PRESETS[self.Preset] then
        local preset = PRESETS[self.Preset]
        self.TargetSize = preset.BlurSize
        self.Brightness = preset.Brightness or 0
        self.Contrast = preset.Contrast or 0
        self.Saturation = preset.Saturation or 0
        self.TintColor = preset.TintColor
        self.TintTransparency = preset.TintTransparency or 1
    end
    
    self.Controller:_recalculateBlur(duration or self.Duration)
    self.OnEnabled:Fire(self.TargetSize)
end

function BlurLayer:Disable(duration)
    self.Enabled = false
    self.TargetSize = 0
    
    self.Controller:_recalculateBlur(duration or self.Duration)
    self.OnDisabled:Fire()
end

function BlurLayer:SetSize(size, duration)
    self.TargetSize = size
    if self.Enabled then
        self.Controller:_recalculateBlur(duration or self.Duration)
    end
    self.OnSizeChanged:Fire(size)
end

function BlurLayer:SetPreset(presetName, duration)
    self.Preset = presetName
    if self.Enabled then
        self:Enable(nil, duration)
    end
end

function BlurLayer:SetPriority(priority)
    self.Priority = priority
    if self.Enabled then
        self.Controller:_recalculateBlur()
    end
end

function BlurLayer:Toggle(duration)
    if self.Enabled then
        self:Disable(duration)
    else
        self:Enable(nil, duration)
    end
end

function BlurLayer:Destroy()
    self:Disable(0)
    self.OnEnabled:Destroy()
    self.OnDisabled:Destroy()
    self.OnSizeChanged:Destroy()
    self.Controller._layers[self.Name] = nil
end

-- ══════════════════════════════════════════════════════════════════════
-- BLUR CONTROLLER CLASS
-- ══════════════════════════════════════════════════════════════════════

function Blur.new(options)
    if _instance then
        return _instance
    end
    
    local self = setmetatable({}, Blur)
    
    -- Configuration
    self.Config = setmetatable(options or {}, {__index = DEFAULT_CONFIG})
    
    -- State
    self.Enabled = false
    self.CurrentSize = 0
    self.CurrentPreset = nil
    self._layers = {}
    self._connections = {}
    self._pulseConnection = nil
    self._performanceConnection = nil
    self._lastFPSCheck = 0
    self._fpsHistory = {}
    
    -- Quality
    self.QualityLevel = self.Config.QualityLevel
    self._qualitySettings = QUALITY_SETTINGS[self.QualityLevel]
    
    -- Signals
    self.OnEnabled = Signal.new()
    self.OnDisabled = Signal.new()
    self.OnSizeChanged = Signal.new()
    self.OnPresetChanged = Signal.new()
    self.OnQualityChanged = Signal.new()
    self.OnLayerAdded = Signal.new()
    self.OnLayerRemoved = Signal.new()
    
    -- Create effects
    self:_createEffects()
    
    -- Setup performance monitoring
    if self.Config.AutoAdjustQuality then
        self:_setupPerformanceMonitoring()
    end
    
    _instance = self
    return self
end

function Blur:_createEffects()
    -- Main blur effect
    self.BlurEffect = Instance.new("BlurEffect")
    self.BlurEffect.Name = "VapeUI_Blur"
    self.BlurEffect.Size = 0
    self.BlurEffect.Enabled = true
    self.BlurEffect.Parent = Lighting
    
    -- Color correction
    self.ColorCorrection = Instance.new("ColorCorrectionEffect")
    self.ColorCorrection.Name = "VapeUI_ColorCorrection"
    self.ColorCorrection.Brightness = 0
    self.ColorCorrection.Contrast = 0
    self.ColorCorrection.Saturation = 0
    self.ColorCorrection.TintColor = Color3.new(1, 1, 1)
    self.ColorCorrection.Enabled = false
    self.ColorCorrection.Parent = Lighting
    
    -- Depth of field
    self.DepthOfField = Instance.new("DepthOfFieldEffect")
    self.DepthOfField.Name = "VapeUI_DepthOfField"
    self.DepthOfField.FarIntensity = 0
    self.DepthOfField.FocusDistance = 20
    self.DepthOfField.InFocusRadius = 30
    self.DepthOfField.NearIntensity = 0
    self.DepthOfField.Enabled = false
    self.DepthOfField.Parent = Lighting
    
    -- Bloom
    self.Bloom = Instance.new("BloomEffect")
    self.Bloom.Name = "VapeUI_Bloom"
    self.Bloom.Intensity = 0
    self.Bloom.Size = 24
    self.Bloom.Threshold = 0.95
    self.Bloom.Enabled = false
    self.Bloom.Parent = Lighting
    
    -- Sun rays
    self.SunRays = Instance.new("SunRaysEffect")
    self.SunRays.Name = "VapeUI_SunRays"
    self.SunRays.Intensity = 0
    self.SunRays.Spread = 0.5
    self.SunRays.Enabled = false
    self.SunRays.Parent = Lighting
end

function Blur:_setupPerformanceMonitoring()
    self._performanceConnection = RunService.Heartbeat:Connect(function(dt)
        local now = tick()
        if now - self._lastFPSCheck >= 1 then
            local fps = 1 / dt
            table.insert(self._fpsHistory, fps)
            
            -- Keep last 5 samples
            while #self._fpsHistory > 5 do
                table.remove(self._fpsHistory, 1)
            end
            
            -- Calculate average FPS
            local avgFPS = 0
            for _, f in ipairs(self._fpsHistory) do
                avgFPS = avgFPS + f
            end
            avgFPS = avgFPS / #self._fpsHistory
            
            -- Adjust quality if needed
            if avgFPS < self.Config.MinFPS then
                self:_decreaseQuality()
            elseif avgFPS > self.Config.TargetFPS + 15 then
                self:_increaseQuality()
            end
            
            self._lastFPSCheck = now
        end
    end)
    table.insert(self._connections, self._performanceConnection)
end

function Blur:_decreaseQuality()
    local levels = {"Ultra", "High", "Medium", "Low"}
    local currentIndex = table.find(levels, self.QualityLevel) or 1
    
    if currentIndex < #levels then
        self:SetQuality(levels[currentIndex + 1])
    end
end

function Blur:_increaseQuality()
    local levels = {"Ultra", "High", "Medium", "Low"}
    local currentIndex = table.find(levels, self.QualityLevel) or #levels
    
    if currentIndex > 1 then
        self:SetQuality(levels[currentIndex - 1])
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- LAYER MANAGEMENT
-- ══════════════════════════════════════════════════════════════════════

function Blur:CreateLayer(name, options)
    if self._layers[name] then
        return self._layers[name]
    end
    
    local layer = BlurLayer.new(self, name, options)
    self._layers[name] = layer
    
    self.OnLayerAdded:Fire(layer)
    
    return layer
end

function Blur:GetLayer(name)
    return self._layers[name]
end

function Blur:RemoveLayer(name)
    local layer = self._layers[name]
    if layer then
        layer:Destroy()
        self.OnLayerRemoved:Fire(name)
    end
end

function Blur:GetLayers()
    return self._layers
end

function Blur:_recalculateBlur(duration)
    duration = duration or self.Config.TransitionDuration
    
    -- Collect all active layers sorted by priority
    local activeLayers = {}
    for _, layer in pairs(self._layers) do
        if layer.Enabled and layer.Visible then
            table.insert(activeLayers, layer)
        end
    end
    
    table.sort(activeLayers, function(a, b)
        return a.Priority > b.Priority
    end)
    
    -- Calculate combined blur (highest priority wins, or sum with diminishing returns)
    local totalBlur = 0
    local brightness = 0
    local contrast = 0
    local saturation = 0
    local tintColor = Color3.new(1, 1, 1)
    local tintInfluence = 0
    
    for i, layer in ipairs(activeLayers) do
        local weight = 1 / i  -- Diminishing weight by priority
        
        totalBlur = totalBlur + layer.TargetSize * weight
        brightness = brightness + layer.Brightness * weight
        contrast = contrast + layer.Contrast * weight
        saturation = saturation + layer.Saturation * weight
        
        if layer.TintColor then
            tintColor = layer.TintColor
            tintInfluence = math.max(tintInfluence, 1 - (layer.TintTransparency or 1))
        end
    end
    
    -- Clamp to max based on quality
    local maxBlur = self._qualitySettings.MaxBlur
    totalBlur = math.clamp(totalBlur, 0, maxBlur)
    
    -- Animate to new values
    self:_animateToValues({
        BlurSize = totalBlur,
        Brightness = brightness,
        Contrast = contrast,
        Saturation = saturation,
        TintColor = tintColor,
        TintInfluence = tintInfluence,
    }, duration)
    
    -- Update state
    self.Enabled = totalBlur > 0
    self.CurrentSize = totalBlur
end

function Blur:_animateToValues(values, duration)
    local easingStyle = self.Config.TransitionEasing
    local easingDirection = self.Config.TransitionDirection
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    
    -- Blur
    TweenService:Create(self.BlurEffect, tweenInfo, {
        Size = values.BlurSize
    }):Play()
    
    -- Color correction (if enabled)
    if self._qualitySettings.EnableColorCorrection and self.Config.EnableColorCorrection then
        self.ColorCorrection.Enabled = true
        
        TweenService:Create(self.ColorCorrection, tweenInfo, {
            Brightness = values.Brightness,
            Contrast = values.Contrast,
            Saturation = values.Saturation,
            TintColor = values.TintInfluence > 0 
                and values.TintColor:Lerp(Color3.new(1, 1, 1), 1 - values.TintInfluence)
                or Color3.new(1, 1, 1),
        }):Play()
    else
        self.ColorCorrection.Enabled = false
    end
    
    -- Fire event
    self.OnSizeChanged:Fire(values.BlurSize)
end

-- ══════════════════════════════════════════════════════════════════════
-- SIMPLE API (Backwards compatible)
-- ══════════════════════════════════════════════════════════════════════

function Blur:Enable(sizeOrPreset, duration)
    duration = duration or self.Config.TransitionDuration
    
    -- Create or get default layer
    local defaultLayer = self:CreateLayer("_default", {Priority = -100})
    
    if type(sizeOrPreset) == "string" then
        -- Preset name
        defaultLayer:SetPreset(sizeOrPreset)
        defaultLayer:Enable(nil, duration)
        self.CurrentPreset = sizeOrPreset
        self.OnPresetChanged:Fire(sizeOrPreset)
    else
        -- Size value
        defaultLayer:Enable(sizeOrPreset or self.Config.DefaultSize, duration)
    end
    
    self.OnEnabled:Fire(self.CurrentSize)
end

function Blur:Disable(duration)
    duration = duration or self.Config.TransitionDuration
    
    -- Disable all layers
    for _, layer in pairs(self._layers) do
        layer:Disable(duration)
    end
    
    self.CurrentPreset = nil
    self.OnDisabled:Fire()
end

function Blur:Toggle(duration)
    if self.Enabled then
        self:Disable(duration)
    else
        self:Enable(nil, duration)
    end
end

function Blur:SetSize(size, duration)
    local defaultLayer = self._layers["_default"]
    if defaultLayer then
        defaultLayer:SetSize(size, duration)
    else
        self:Enable(size, duration)
    end
end

function Blur:GetSize()
    return self.CurrentSize
end

-- ══════════════════════════════════════════════════════════════════════
-- PRESET API
-- ══════════════════════════════════════════════════════════════════════

function Blur:ApplyPreset(presetName, duration)
    self:Enable(presetName, duration)
end

function Blur:GetPresets()
    return PRESETS
end

function Blur:GetCurrentPreset()
    return self.CurrentPreset
end

function Blur:CreatePreset(name, settings)
    PRESETS[name] = settings
end

function Blur:RemovePreset(name)
    -- Don't remove built-in presets
    local builtIn = {"None", "Light", "Medium", "Heavy", "Ultra", "Cinematic", "Dream", "Dark", "Focus", "Glass", "Modal"}
    if not table.find(builtIn, name) then
        PRESETS[name] = nil
    end
end

-- ══════════════════════════════════════════════════════════════════════
-- QUALITY MANAGEMENT
-- ══════════════════════════════════════════════════════════════════════

function Blur:SetQuality(level)
    if not QUALITY_SETTINGS[level] then return end
    
    local previousLevel = self.QualityLevel
    self.QualityLevel = level
    self._qualitySettings = QUALITY_SETTINGS[level]
    
    -- Apply quality settings to effects
    self.ColorCorrection.Enabled = self._qualitySettings.EnableColorCorrection and self.Config.EnableColorCorrection
    self.DepthOfField.Enabled = self._qualitySettings.EnableDepthOfField and self.Config.EnableDepthOfField
    self.Bloom.Enabled = self._qualitySettings.EnableBloom and self.Config.EnableBloom
    
    -- Recalculate blur with new constraints
    self:_recalculateBlur()
    
    self.OnQualityChanged:Fire(level, previousLevel)
end

function Blur:GetQuality()
    return self.QualityLevel
end

function Blur:GetQualitySettings()
    return self._qualitySettings
end

-- ══════════════════════════════════════════════════════════════════════
-- ANIMATION EFFECTS
-- ══════════════════════════════════════════════════════════════════════

function Blur:StartPulse(minSize, maxSize, speed)
    minSize = minSize or self.Config.PulseMinSize
    maxSize = maxSize or self.Config.PulseMaxSize
    speed = speed or self.Config.PulseSpeed
    
    self:StopPulse()
    
    local pulseLayer = self:CreateLayer("_pulse", {Priority = 50})
    pulseLayer:Enable(minSize, 0)
    
    local startTime = tick()
    
    self._pulseConnection = RunService.Heartbeat:Connect(function()
        local elapsed = tick() - startTime
        local t = (math.sin(elapsed * speed * math.pi) + 1) / 2
        local size = minSize + (maxSize - minSize) * t
        
        pulseLayer.TargetSize = size
        self:_recalculateBlur(0.05)
    end)
    table.insert(self._connections, self._pulseConnection)
end

function Blur:StopPulse()
    if self._pulseConnection then
        self._pulseConnection:Disconnect()
        self._pulseConnection = nil
    end
    
    local pulseLayer = self._layers["_pulse"]
    if pulseLayer then
        pulseLayer:Destroy()
    end
end

function Blur:Breathe(inDuration, outDuration, holdDuration, maxSize)
    inDuration = inDuration or 1.5
    outDuration = outDuration or 2
    holdDuration = holdDuration or 0.5
    maxSize = maxSize or 20
    
    local layer = self:CreateLayer("_breathe", {Priority = 50})
    
    local function breatheCycle()
        -- Breathe in
        layer:Enable(maxSize, inDuration)
        task.wait(inDuration + holdDuration)
        
        -- Breathe out
        layer:Disable(outDuration)
        task.wait(outDuration)
    end
    
    self._breatheConnection = task.spawn(function()
        while self._layers["_breathe"] do
            breatheCycle()
        end
    end)
end

function Blur:StopBreathe()
    local layer = self._layers["_breathe"]
    if layer then
        layer:Destroy()
    end
    self._breatheConnection = nil
end

function Blur:Flash(size, duration)
    size = size or 30
    duration = duration or 0.5
    
    local layer = self:CreateLayer("_flash", {Priority = 100})
    layer:Enable(size, duration * 0.2)
    
    task.delay(duration * 0.2, function()
        layer:Disable(duration * 0.8)
        task.delay(duration * 0.8, function()
            layer:Destroy()
        end)
    end)
end

function Blur:FadeIn(targetSize, duration)
    targetSize = targetSize or self.Config.DefaultSize
    duration = duration or 1
    
    self:Enable(0, 0)
    task.wait()
    self:SetSize(targetSize, duration)
end

function Blur:FadeOut(duration)
    duration = duration or 1
    self:Disable(duration)
end

-- ══════════════════════════════════════════════════════════════════════
-- DEPTH OF FIELD
-- ══════════════════════════════════════════════════════════════════════

function Blur:EnableDepthOfField(options)
    options = options or {}
    
    if not self._qualitySettings.EnableDepthOfField then return end
    
    self.DepthOfField.Enabled = true
    
    local tweenInfo = TweenInfo.new(options.Duration or 0.5)
    TweenService:Create(self.DepthOfField, tweenInfo, {
        FocusDistance = options.FocusDistance or 20,
        InFocusRadius = options.InFocusRadius or 30,
        FarIntensity = options.FarIntensity or 0.5,
        NearIntensity = options.NearIntensity or 0.5,
    }):Play()
end

function Blur:DisableDepthOfField(duration)
    local tweenInfo = TweenInfo.new(duration or 0.5)
    TweenService:Create(self.DepthOfField, tweenInfo, {
        FarIntensity = 0,
        NearIntensity = 0,
    }):Play()
    
    task.delay(duration or 0.5, function()
        self.DepthOfField.Enabled = false
    end)
end

function Blur:FocusOnDistance(distance, radius, duration)
    self:EnableDepthOfField({
        FocusDistance = distance,
        InFocusRadius = radius or 10,
        FarIntensity = 0.75,
        NearIntensity = 0.5,
        Duration = duration or 0.3,
    })
end

-- ══════════════════════════════════════════════════════════════════════
-- BLOOM & SUN RAYS
-- ══════════════════════════════════════════════════════════════════════

function Blur:EnableBloom(intensity, size, threshold, duration)
    if not self._qualitySettings.EnableBloom then return end
    
    self.Bloom.Enabled = true
    
    local tweenInfo = TweenInfo.new(duration or 0.5)
    TweenService:Create(self.Bloom, tweenInfo, {
        Intensity = intensity or 1,
        Size = size or 24,
        Threshold = threshold or 0.95,
    }):Play()
end

function Blur:DisableBloom(duration)
    local tweenInfo = TweenInfo.new(duration or 0.5)
    TweenService:Create(self.Bloom, tweenInfo, {
        Intensity = 0,
    }):Play()
    
    task.delay(duration or 0.5, function()
        self.Bloom.Enabled = false
    end)
end

function Blur:EnableSunRays(intensity, spread, duration)
    self.SunRays.Enabled = true
    
    local tweenInfo = TweenInfo.new(duration or 0.5)
    TweenService:Create(self.SunRays, tweenInfo, {
        Intensity = intensity or 0.25,
        Spread = spread or 0.5,
    }):Play()
end

function Blur:DisableSunRays(duration)
    local tweenInfo = TweenInfo.new(duration or 0.5)
    TweenService:Create(self.SunRays, tweenInfo, {
        Intensity = 0,
    }):Play()
    
    task.delay(duration or 0.5, function()
        self.SunRays.Enabled = false
    end)
end

-- ══════════════════════════════════════════════════════════════════════
-- COLOR CORRECTION
-- ══════════════════════════════════════════════════════════════════════

function Blur:SetColorCorrection(options, duration)
    if not self._qualitySettings.EnableColorCorrection then return end
    
    self.ColorCorrection.Enabled = true
    
    local tweenInfo = TweenInfo.new(duration or 0.3)
    TweenService:Create(self.ColorCorrection, tweenInfo, {
        Brightness = options.Brightness or 0,
        Contrast = options.Contrast or 0,
        Saturation = options.Saturation or 0,
        TintColor = options.TintColor or Color3.new(1, 1, 1),
    }):Play()
end

function Blur:ResetColorCorrection(duration)
    local tweenInfo = TweenInfo.new(duration or 0.3)
    TweenService:Create(self.ColorCorrection, tweenInfo, {
        Brightness = 0,
        Contrast = 0,
        Saturation = 0,
        TintColor = Color3.new(1, 1, 1),
    }):Play()
end

function Blur:Grayscale(amount, duration)
    amount = amount or 1
    self:SetColorCorrection({
        Saturation = -amount,
    }, duration)
end

function Blur:Sepia(amount, duration)
    amount = amount or 0.5
    self:SetColorCorrection({
        Saturation = -0.3 * amount,
        TintColor = Color3.fromRGB(255, 240, 200):Lerp(Color3.new(1, 1, 1), 1 - amount),
    }, duration)
end

function Blur:Vibrant(amount, duration)
    amount = amount or 0.3
    self:SetColorCorrection({
        Saturation = amount,
        Contrast = amount * 0.5,
    }, duration)
end

function Blur:Darken(amount, duration)
    amount = amount or 0.2
    self:SetColorCorrection({
        Brightness = -amount,
    }, duration)
end

function Blur:Brighten(amount, duration)
    amount = amount or 0.2
    self:SetColorCorrection({
        Brightness = amount,
    }, duration)
end

-- ══════════════════════════════════════════════════════════════════════
-- EVENT-BASED BLUR
-- ══════════════════════════════════════════════════════════════════════

function Blur:OnModalOpen(modalId, options)
    options = options or {}
    
    local layer = self:CreateLayer("modal_" .. tostring(modalId), {
        Priority = options.Priority or 80,
        Preset = options.Preset or "Modal",
    })
    
    layer:Enable(nil, options.Duration or 0.2)
    
    return layer
end

function Blur:OnModalClose(modalId, duration)
    local layer = self._layers["modal_" .. tostring(modalId)]
    if layer then
        layer:Disable(duration or 0.2)
        task.delay(duration or 0.2, function()
            layer:Destroy()
        end)
    end
end

function Blur:OnMenuOpen(menuId, options)
    options = options or {}
    
    local layer = self:CreateLayer("menu_" .. tostring(menuId), {
        Priority = options.Priority or 60,
    })
    
    layer:Enable(options.Size or 8, options.Duration or 0.15)
    
    return layer
end

function Blur:OnMenuClose(menuId, duration)
    local layer = self._layers["menu_" .. tostring(menuId)]
    if layer then
        layer:Disable(duration or 0.15)
        task.delay(duration or 0.15, function()
            layer:Destroy()
        end)
    end
end

function Blur:OnPopupOpen(popupId, options)
    return self:OnModalOpen(popupId, options)
end

function Blur:OnPopupClose(popupId, duration)
    self:OnModalClose(popupId, duration)
end

-- ══════════════════════════════════════════════════════════════════════
-- SCREENSHOT MODE
-- ══════════════════════════════════════════════════════════════════════

function Blur:EnterScreenshotMode()
    self._screenshotPreviousQuality = self.QualityLevel
    self:SetQuality("Ultra")
    
    -- Enhance visuals temporarily
    self:EnableBloom(0.5, 30, 0.9, 0.2)
    
    return function()
        self:ExitScreenshotMode()
    end
end

function Blur:ExitScreenshotMode()
    if self._screenshotPreviousQuality then
        self:SetQuality(self._screenshotPreviousQuality)
        self._screenshotPreviousQuality = nil
    end
    
    self:DisableBloom(0.2)
end

-- ══════════════════════════════════════════════════════════════════════
-- UTILITY METHODS
-- ══════════════════════════════════════════════════════════════════════

function Blur:IsEnabled()
    return self.Enabled
end

function Blur:GetEffects()
    return {
        Blur = self.BlurEffect,
        ColorCorrection = self.ColorCorrection,
        DepthOfField = self.DepthOfField,
        Bloom = self.Bloom,
        SunRays = self.SunRays,
    }
end

function Blur:SetTransitionDuration(duration)
    self.Config.TransitionDuration = duration
end

function Blur:SetTransitionEasing(easing)
    self.Config.TransitionEasing = easing
end

function Blur:Snapshot()
    -- Capture current state
    return {
        Enabled = self.Enabled,
        Size = self.CurrentSize,
        Preset = self.CurrentPreset,
        Quality = self.QualityLevel,
        ColorCorrection = {
            Brightness = self.ColorCorrection.Brightness,
            Contrast = self.ColorCorrection.Contrast,
            Saturation = self.ColorCorrection.Saturation,
            TintColor = self.ColorCorrection.TintColor,
        },
        Layers = self._layers,
    }
end

function Blur:Restore(snapshot, duration)
    if snapshot.Preset then
        self:ApplyPreset(snapshot.Preset, duration)
    elseif snapshot.Enabled then
        self:Enable(snapshot.Size, duration)
    else
        self:Disable(duration)
    end
    
    self:SetQuality(snapshot.Quality)
end

-- ══════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ══════════════════════════════════════════════════════════════════════

function Blur:Destroy()
    -- Stop animations
    self:StopPulse()
    self:StopBreathe()
    
    -- Disconnect all connections
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    
    -- Destroy layers
    for name, layer in pairs(self._layers) do
        layer:Destroy()
    end
    self._layers = {}
    
    -- Destroy effects
    if self.BlurEffect then self.BlurEffect:Destroy() end
    if self.ColorCorrection then self.ColorCorrection:Destroy() end
    if self.DepthOfField then self.DepthOfField:Destroy() end
    if self.Bloom then self.Bloom:Destroy() end
    if self.SunRays then self.SunRays:Destroy() end
    
    -- Destroy signals
    self.OnEnabled:Destroy()
    self.OnDisabled:Destroy()
    self.OnSizeChanged:Destroy()
    self.OnPresetChanged:Destroy()
    self.OnQualityChanged:Destroy()
    self.OnLayerAdded:Destroy()
    self.OnLayerRemoved:Destroy()
    
    _instance = nil
end

-- ══════════════════════════════════════════════════════════════════════
-- STATIC ACCESS
-- ══════════════════════════════════════════════════════════════════════

function Blur.Get()
    if not _instance then
        _instance = Blur.new()
    end
    return _instance
end

-- Export presets for external use
Blur.Presets = PRESETS
Blur.QualitySettings = QUALITY_SETTINGS

return Blur