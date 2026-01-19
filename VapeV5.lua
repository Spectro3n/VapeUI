--[[
    ██╗   ██╗ █████╗ ██████╗ ███████╗    ██╗   ██╗███████╗
    ██║   ██║██╔══██╗██╔══██╗██╔════╝    ██║   ██║██╔════╝
    ██║   ██║███████║██████╔╝█████╗      ██║   ██║███████╗
    ╚██╗ ██╔╝██╔══██║██╔═══╝ ██╔══╝      ╚██╗ ██╔╝╚════██║
     ╚████╔╝ ██║  ██║██║     ███████╗     ╚████╔╝ ███████║
      ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚══════╝      ╚═══╝  ╚══════╝
    
    Vape V5 UI Library - Ultimate Adaptive UI Framework
    Version: 5.0.0
    
    🎮 COMO USAR:
    
    local VapeUI = loadstring(game:HttpGet("SUA_URL_AQUI"))()
    
    local Window = VapeUI:CreateWindow({
        Title = "Meu Menu",
        Subtitle = "v1.0",
        Logo = "https://i.imgur.com/XXXXX.png", -- Suporta Imgur, Discord, etc
        Theme = "Dark", -- Dark, Light, Custom
        Size = {700, 400},
        Keybind = "RightShift"
    })
    
    local Tab = Window:CreateTab({
        Name = "Combat",
        Icon = "⚔️" -- Suporta emojis!
    })
    
    local Module = Tab:CreateModule({
        Name = "Kill Aura",
        Callback = function(enabled)
            print("Kill Aura:", enabled)
        end
    })
    
    Module:CreateSlider({...})
    Module:CreateToggle({...})
    -- etc...
]]

-- ═══════════════════════════════════════════════════════════════════
-- 📦 CONFIGURAÇÃO PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

local VapeV5 = {
    Version = "5.0.0",
    Author = "VapeV5 Team",
    
    -- Configurações Globais (Editáveis pelo Dev)
    Settings = {
        -- 🎨 Tema Principal
        Theme = {
            Primary = Color3.fromRGB(26, 25, 26),
            Secondary = Color3.fromRGB(35, 34, 35),
            Accent = Color3.fromRGB(5, 134, 105),
            Text = Color3.fromRGB(200, 200, 200),
            TextDark = Color3.fromRGB(140, 140, 140),
            Success = Color3.fromRGB(90, 255, 90),
            Error = Color3.fromRGB(255, 90, 90),
            Warning = Color3.fromRGB(255, 170, 0),
        },
        
        -- 🔤 Fontes
        Fonts = {
            Regular = Font.fromEnum(Enum.Font.Gotham),
            Bold = Font.fromEnum(Enum.Font.GothamBold),
            SemiBold = Font.fromEnum(Enum.Font.GothamSemibold),
        },
        
        -- ⚡ Animações
        Animations = {
            Enabled = true,
            Speed = 0.16,
            Style = Enum.EasingStyle.Quart,
        },
        
        -- 🌈 Rainbow
        Rainbow = {
            Enabled = false,
            Speed = 1,
            UpdateRate = 60,
        },
        
        -- 🔧 Geral
        General = {
            Scale = 1,
            AutoScale = true,
            Blur = true,
            Notifications = true,
            Tooltips = true,
            Sounds = true,
        },
        
        -- 🔑 Keybinds
        Keybind = {"RightShift"},
    },
    
    -- Storage interno
    _windows = {},
    _modules = {},
    _connections = {},
    _rainbowTable = {},
    _loaded = false,
}

-- ═══════════════════════════════════════════════════════════════════
-- 🔧 SERVIÇOS DO ROBLOX
-- ═══════════════════════════════════════════════════════════════════

local Services = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    TextService = game:GetService("TextService"),
    GuiService = game:GetService("GuiService"),
    RunService = game:GetService("RunService"),
    HttpService = game:GetService("HttpService"),
    Players = game:GetService("Players"),
    CoreGui = game:GetService("CoreGui"),
}

-- Clone refs se disponível
local cloneref = cloneref or function(obj) return obj end
for name, service in pairs(Services) do
    Services[name] = cloneref(service)
end

local LocalPlayer = Services.Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════
-- 🛠️ UTILITÁRIOS
-- ═══════════════════════════════════════════════════════════════════

local Utils = {}

-- Gerar string aleatória para nomes
function Utils.RandomString(length)
    length = length or math.random(10, 20)
    local chars = {}
    for i = 1, length do
        chars[i] = string.char(math.random(65, 90))
    end
    return table.concat(chars)
end

-- Verificar se arquivo existe
function Utils.FileExists(path)
    local success, result = pcall(function()
        return readfile(path)
    end)
    return success and result ~= nil and result ~= ""
end

-- Carregar JSON
function Utils.LoadJSON(path)
    local success, result = pcall(function()
        return Services.HttpService:JSONDecode(readfile(path))
    end)
    return success and type(result) == "table" and result or nil
end

-- Salvar JSON
function Utils.SaveJSON(path, data)
    local success = pcall(function()
        writefile(path, Services.HttpService:JSONEncode(data))
    end)
    return success
end

-- Obter tamanho de texto
local TextBoundsParams = Instance.new("GetTextBoundsParams")
TextBoundsParams.Width = math.huge

function Utils.GetTextSize(text, size, font)
    TextBoundsParams.Text = text
    TextBoundsParams.Size = size or 14
    if typeof(font) == "Font" then
        TextBoundsParams.Font = font
    else
        TextBoundsParams.Font = VapeV5.Settings.Fonts.Regular
    end
    return Services.TextService:GetTextBoundsAsync(TextBoundsParams)
end

-- Remover tags rich text
function Utils.RemoveTags(str)
    str = str:gsub("<br%s*/>", "\n")
    return str:gsub("<[^<>]->", "")
end

-- Deep clone table
function Utils.DeepClone(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = Utils.DeepClone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Lerp Color
function Utils.LerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

-- ═══════════════════════════════════════════════════════════════════
-- 🎨 SISTEMA DE CORES
-- ═══════════════════════════════════════════════════════════════════

local ColorSystem = {}

function ColorSystem.Dark(color, amount)
    local h, s, v = color:ToHSV()
    local mainV = select(3, VapeV5.Settings.Theme.Primary:ToHSV())
    if mainV > 0.5 then
        return Color3.fromHSV(h, s, math.clamp(v + amount, 0, 1))
    else
        return Color3.fromHSV(h, s, math.clamp(v - amount, 0, 1))
    end
end

function ColorSystem.Light(color, amount)
    local h, s, v = color:ToHSV()
    local mainV = select(3, VapeV5.Settings.Theme.Primary:ToHSV())
    if mainV > 0.5 then
        return Color3.fromHSV(h, s, math.clamp(v - amount, 0, 1))
    else
        return Color3.fromHSV(h, s, math.clamp(v + amount, 0, 1))
    end
end

function ColorSystem.GetRainbow(hue)
    local s = 0.75 + (0.15 * math.min(hue / 0.03, 1))
    if hue > 0.57 then
        s = 0.9 - (0.4 * math.min((hue - 0.57) / 0.09, 1))
    end
    if hue > 0.66 then
        s = 0.5 + (0.4 * math.min((hue - 0.66) / 0.16, 1))
    end
    if hue > 0.87 then
        s = 0.9 - (0.15 * math.min((hue - 0.87) / 0.13, 1))
    end
    return hue, s, 1
end

function ColorSystem.GetTextColor(h, s, v)
    if v >= 0.7 and (s < 0.6 or (h > 0.04 and h < 0.56)) then
        return Color3.fromRGB(48, 48, 48)
    end
    return Color3.fromRGB(255, 255, 255)
end

function ColorSystem.FromHex(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(
        tonumber(hex:sub(1, 2), 16),
        tonumber(hex:sub(3, 4), 16),
        tonumber(hex:sub(5, 6), 16)
    )
end

function ColorSystem.ToHex(color)
    return string.format("#%02X%02X%02X", 
        math.floor(color.R * 255),
        math.floor(color.G * 255),
        math.floor(color.B * 255)
    )
end

VapeV5.Color = ColorSystem

-- ═══════════════════════════════════════════════════════════════════
-- 🎬 SISTEMA DE ANIMAÇÕES (TWEEN)
-- ═══════════════════════════════════════════════════════════════════

local TweenSystem = {
    _activeTweens = {},
}

function TweenSystem:Create(object, properties, duration, style, direction)
    if not VapeV5.Settings.Animations.Enabled then
        for prop, value in pairs(properties) do
            object[prop] = value
        end
        return
    end
    
    -- Cancelar tween anterior do mesmo objeto
    if self._activeTweens[object] then
        self._activeTweens[object]:Cancel()
    end
    
    local tweenInfo = TweenInfo.new(
        duration or VapeV5.Settings.Animations.Speed,
        style or VapeV5.Settings.Animations.Style,
        direction or Enum.EasingDirection.Out
    )
    
    local tween = Services.TweenService:Create(object, tweenInfo, properties)
    self._activeTweens[object] = tween
    
    tween.Completed:Once(function()
        self._activeTweens[object] = nil
    end)
    
    tween:Play()
    return tween
end

function TweenSystem:Cancel(object)
    if self._activeTweens[object] then
        self._activeTweens[object]:Cancel()
        self._activeTweens[object] = nil
    end
end

VapeV5.Tween = TweenSystem

-- ═══════════════════════════════════════════════════════════════════
-- 🖼️ SISTEMA DE ASSETS (Suporte a Imgur, Discord, etc)
-- ═══════════════════════════════════════════════════════════════════

local AssetSystem = {
    _cache = {},
    
    -- Assets embutidos (fallbacks)
    Embedded = {
        Logo = "rbxassetid://14657521312",
        Close = "rbxassetid://14368309446",
        Expand = "rbxassetid://14368353032",
        Arrow = "rbxassetid://14368316544",
        Dots = "rbxassetid://14368314459",
        Search = "rbxassetid://14425646684",
        Settings = "rbxassetid://14368318994",
        Bind = "rbxassetid://14368304734",
        Rainbow = {
            "rbxassetid://14368344374",
            "rbxassetid://14368345149",
            "rbxassetid://14368345840",
            "rbxassetid://14368346696",
        },
        Categories = {
            Combat = "rbxassetid://14368312652",
            Blatant = "rbxassetid://14368306745",
            Render = "rbxassetid://14368350193",
            Utility = "rbxassetid://14368359107",
            World = "rbxassetid://14368362492",
            Player = "rbxassetid://14397462778",
        },
        Notification = {
            Info = "rbxassetid://14368324807",
            Warning = "rbxassetid://14368361552",
            Error = "rbxassetid://14368301329",
            Success = "rbxassetid://14368302000",
        },
    },
}

-- Carregar asset de URL externa
function AssetSystem:LoadFromURL(url)
    if self._cache[url] then
        return self._cache[url]
    end
    
    -- Verificar se é URL do Imgur, Discord, etc
    if url:match("^https?://") then
        -- Para URLs externas, precisamos baixar e usar getcustomasset
        local fileName = "VapeV5_" .. Utils.RandomString(8) .. ".png"
        local filePath = "VapeV5/cache/" .. fileName
        
        local success = pcall(function()
            if not isfolder("VapeV5/cache") then
                makefolder("VapeV5")
                makefolder("VapeV5/cache")
            end
            
            local response = game:HttpGet(url)
            writefile(filePath, response)
        end)
        
        if success and getcustomasset then
            local asset = getcustomasset(filePath)
            self._cache[url] = asset
            return asset
        end
    end
    
    -- Fallback para rbxassetid
    if url:match("^rbxassetid://") then
        self._cache[url] = url
        return url
    end
    
    return ""
end

-- Obter asset embutido
function AssetSystem:Get(name)
    local parts = string.split(name, ".")
    local current = self.Embedded
    
    for _, part in ipairs(parts) do
        if current[part] then
            current = current[part]
        else
            return ""
        end
    end
    
    return current
end

VapeV5.Assets = AssetSystem

-- ═══════════════════════════════════════════════════════════════════
-- 🔔 SISTEMA DE NOTIFICAÇÕES
-- ═══════════════════════════════════════════════════════════════════

local NotificationSystem = {
    _container = nil,
    _queue = {},
}

function NotificationSystem:Init(parent)
    self._container = Instance.new("Frame")
    self._container.Name = "Notifications"
    self._container.Size = UDim2.new(1, 0, 1, 0)
    self._container.BackgroundTransparency = 1
    self._container.Parent = parent
end

function NotificationSystem:Send(options)
    if not VapeV5.Settings.General.Notifications then return end
    
    options = options or {}
    local title = options.Title or "Notification"
    local message = options.Message or ""
    local duration = options.Duration or 3
    local type = options.Type or "Info" -- Info, Warning, Error, Success
    local icon = options.Icon
    
    task.spawn(function()
        local theme = VapeV5.Settings.Theme
        
        -- Container da notificação
        local notif = Instance.new("Frame")
        notif.Name = "Notification"
        notif.Size = UDim2.fromOffset(
            math.max(Utils.GetTextSize(Utils.RemoveTags(message), 14, VapeV5.Settings.Fonts.Regular).X + 80, 280),
            80
        )
        notif.Position = UDim2.new(1, 20, 1, -(90 * (#self._container:GetChildren() + 1)))
        notif.BackgroundColor3 = theme.Primary
        notif.BackgroundTransparency = 0.1
        notif.BorderSizePixel = 0
        notif.Parent = self._container
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = notif
        
        local stroke = Instance.new("UIStroke")
        stroke.Color = ColorSystem.Light(theme.Primary, 0.1)
        stroke.Thickness = 1
        stroke.Parent = notif
        
        -- Ícone
        local iconLabel = Instance.new("ImageLabel")
        iconLabel.Size = UDim2.fromOffset(32, 32)
        iconLabel.Position = UDim2.fromOffset(15, 24)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Image = icon or AssetSystem:Get("Notification." .. type)
        iconLabel.Parent = notif
        
        -- Título
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -70, 0, 20)
        titleLabel.Position = UDim2.fromOffset(55, 15)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = theme.Text
        titleLabel.TextSize = 14
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.FontFace = VapeV5.Settings.Fonts.Bold
        titleLabel.Parent = notif
        
        -- Mensagem
        local messageLabel = Instance.new("TextLabel")
        messageLabel.Size = UDim2.new(1, -70, 0, 20)
        messageLabel.Position = UDim2.fromOffset(55, 38)
        messageLabel.BackgroundTransparency = 1
        messageLabel.Text = message
        messageLabel.TextColor3 = theme.TextDark
        messageLabel.TextSize = 12
        messageLabel.TextXAlignment = Enum.TextXAlignment.Left
        messageLabel.FontFace = VapeV5.Settings.Fonts.Regular
        messageLabel.RichText = true
        messageLabel.Parent = notif
        
        -- Barra de progresso
        local progressBar = Instance.new("Frame")
        progressBar.Size = UDim2.new(1, -10, 0, 3)
        progressBar.Position = UDim2.new(0, 5, 1, -8)
        progressBar.BackgroundColor3 = theme.Accent
        progressBar.BorderSizePixel = 0
        progressBar.Parent = notif
        
        local progressCorner = Instance.new("UICorner")
        progressCorner.CornerRadius = UDim.new(1, 0)
        progressCorner.Parent = progressBar
        
        -- Animação de entrada
        VapeV5.Tween:Create(notif, {
            Position = UDim2.new(1, -notif.Size.X.Offset - 20, notif.Position.Y.Scale, notif.Position.Y.Offset)
        }, 0.3)
        
        -- Animação da barra de progresso
        VapeV5.Tween:Create(progressBar, {
            Size = UDim2.new(0, 0, 0, 3)
        }, duration, Enum.EasingStyle.Linear)
        
        -- Remover após duração
        task.delay(duration, function()
            VapeV5.Tween:Create(notif, {
                Position = UDim2.new(1, 20, notif.Position.Y.Scale, notif.Position.Y.Offset)
            }, 0.3)
            
            task.wait(0.3)
            notif:Destroy()
            
            -- Reposicionar outras notificações
            for i, child in ipairs(self._container:GetChildren()) do
                if child:IsA("Frame") then
                    VapeV5.Tween:Create(child, {
                        Position = UDim2.new(1, -child.Size.X.Offset - 20, 1, -(90 * i))
                    }, 0.2)
                end
            end
        end)
    end)
end

VapeV5.Notify = function(title, message, duration, type)
    NotificationSystem:Send({
        Title = title,
        Message = message,
        Duration = duration,
        Type = type
    })
end

-- ═══════════════════════════════════════════════════════════════════
-- 🧱 COMPONENTES BASE
-- ═══════════════════════════════════════════════════════════════════

local Components = {}

-- Adicionar canto arredondado
function Components.AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or UDim.new(0, 6)
    corner.Parent = parent
    return corner
end

-- Adicionar blur/sombra
function Components.AddBlur(parent, options)
    options = options or {}
    
    local blur = Instance.new("Frame")
    blur.Name = "Blur"
    blur.Size = UDim2.new(1, 20, 1, 20)
    blur.Position = UDim2.fromOffset(-10, -10)
    blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blur.BackgroundTransparency = options.Transparency or 0.5
    blur.BorderSizePixel = 0
    blur.ZIndex = -1
    blur.Parent = parent
    
    Components.AddCorner(blur, options.Radius or UDim.new(0, 10))
    
    return blur
end

-- Adicionar stroke
function Components.AddStroke(parent, options)
    options = options or {}
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = options.Color or ColorSystem.Light(VapeV5.Settings.Theme.Primary, 0.1)
    stroke.Thickness = options.Thickness or 1
    stroke.Transparency = options.Transparency or 0
    stroke.Parent = parent
    
    return stroke
end

-- Botão de fechar
function Components.CreateCloseButton(parent, callback)
    local theme = VapeV5.Settings.Theme
    
    local button = Instance.new("ImageButton")
    button.Name = "CloseButton"
    button.Size = UDim2.fromOffset(24, 24)
    button.Position = UDim2.new(1, -35, 0, 10)
    button.BackgroundColor3 = Color3.new(1, 1, 1)
    button.BackgroundTransparency = 1
    button.AutoButtonColor = false
    button.Image = AssetSystem:Get("Close")
    button.ImageColor3 = ColorSystem.Light(theme.Text, 0.3)
    button.ImageTransparency = 0.5
    button.Parent = parent
    
    Components.AddCorner(button, UDim.new(1, 0))
    
    button.MouseEnter:Connect(function()
        button.ImageTransparency = 0.2
        VapeV5.Tween:Create(button, {BackgroundTransparency = 0.8}, 0.1)
    end)
    
    button.MouseLeave:Connect(function()
        button.ImageTransparency = 0.5
        VapeV5.Tween:Create(button, {BackgroundTransparency = 1}, 0.1)
    end)
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return button
end

-- Tooltip
function Components.AddTooltip(element, text)
    if not text or not VapeV5.Settings.General.Tooltips then return end
    
    local tooltip = VapeV5._tooltip
    if not tooltip then return end
    
    local function updatePosition(x, y)
        local size = Utils.GetTextSize(text, 12, VapeV5.Settings.Fonts.Regular)
        tooltip.Size = UDim2.fromOffset(size.X + 16, size.Y + 12)
        tooltip.Text = text
        
        local guiSize = VapeV5._gui.AbsoluteSize
        local scale = VapeV5._scale.Scale
        
        local posX = x + 16
        local posY = y - (tooltip.Size.Y.Offset / 2)
        
        if posX + tooltip.Size.X.Offset > guiSize.X then
            posX = x - tooltip.Size.X.Offset - 16
        end
        
        tooltip.Position = UDim2.fromOffset(posX / scale, posY / scale)
        tooltip.Visible = true
    end
    
    element.MouseEnter:Connect(function(x, y)
        updatePosition(x, y)
    end)
    
    element.MouseMoved:Connect(function(x, y)
        updatePosition(x, y)
    end)
    
    element.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)
end

-- Tornar arrastável
function Components.MakeDraggable(element, handle)
    handle = handle or element
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            local dragStart = input.Position
            local startPos = element.Position
            
            local dragConnection
            local releaseConnection
            
            dragConnection = Services.UserInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or
                   moveInput.UserInputType == Enum.UserInputType.Touch then
                    local delta = moveInput.Position - dragStart
                    local scale = VapeV5._scale and VapeV5._scale.Scale or 1
                    
                    element.Position = UDim2.fromOffset(
                        startPos.X.Offset + delta.X / scale,
                        startPos.Y.Offset + delta.Y / scale
                    )
                end
            end)
            
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragConnection then dragConnection:Disconnect() end
                    if releaseConnection then releaseConnection:Disconnect() end
                end
            end)
        end
    end)
end

VapeV5.Components = Components

-- ═══════════════════════════════════════════════════════════════════
-- 📦 COMPONENTES DE INPUT
-- ═══════════════════════════════════════════════════════════════════

local InputComponents = {}

-- Toggle/Switch
function InputComponents.CreateToggle(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Toggle",
        Enabled = options.Default or false,
        Callback = options.Callback or function() end,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "Toggle") .. "Toggle"
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BackgroundTransparency = 0
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = "          " .. (options.Name or "Toggle")
    container.TextXAlignment = Enum.TextXAlignment.Left
    container.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    container.TextSize = 14
    container.FontFace = VapeV5.Settings.Fonts.Regular
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Knob holder
    local knobHolder = Instance.new("Frame")
    knobHolder.Name = "KnobHolder"
    knobHolder.Size = UDim2.fromOffset(22, 12)
    knobHolder.Position = UDim2.new(1, -32, 0, 10)
    knobHolder.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.14)
    knobHolder.Parent = container
    Components.AddCorner(knobHolder, UDim.new(1, 0))
    
    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.fromOffset(8, 8)
    knob.Position = UDim2.fromOffset(2, 2)
    knob.BackgroundColor3 = theme.Primary
    knob.Parent = knobHolder
    Components.AddCorner(knob, UDim.new(1, 0))
    
    -- API
    function api:SetValue(value, silent)
        self.Enabled = value
        
        VapeV5.Tween:Create(knobHolder, {
            BackgroundColor3 = value and theme.Accent or ColorSystem.Light(theme.Primary, 0.14)
        }, 0.1)
        
        VapeV5.Tween:Create(knob, {
            Position = UDim2.fromOffset(value and 12 or 2, 2)
        }, 0.1)
        
        if not silent then
            self.Callback(value)
        end
    end
    
    function api:Toggle()
        self:SetValue(not self.Enabled)
    end
    
    function api:Save(data)
        data[options.Name] = {Enabled = self.Enabled}
    end
    
    function api:Load(data)
        if data.Enabled ~= self.Enabled then
            self:SetValue(data.Enabled)
        end
    end
    
    -- Eventos
    local hovered = false
    
    container.MouseEnter:Connect(function()
        hovered = true
        if not api.Enabled then
            VapeV5.Tween:Create(knobHolder, {
                BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.37)
            }, 0.1)
        end
    end)
    
    container.MouseLeave:Connect(function()
        hovered = false
        if not api.Enabled then
            VapeV5.Tween:Create(knobHolder, {
                BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.14)
            }, 0.1)
        end
    end)
    
    container.MouseButton1Click:Connect(function()
        api:Toggle()
    end)
    
    -- Aplicar valor inicial
    if options.Default then
        api:SetValue(true, true)
    end
    
    api.Object = container
    return api
end

-- Slider
function InputComponents.CreateSlider(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Slider",
        Value = options.Default or options.Min or 0,
        Min = options.Min or 0,
        Max = options.Max or 100,
        Decimal = options.Decimal or 1,
        Callback = options.Callback or function() end,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "Slider") .. "Slider"
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = ""
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(100, 20)
    title.Position = UDim2.fromOffset(10, 5)
    title.BackgroundTransparency = 1
    title.Text = options.Name or "Slider"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    title.TextSize = 12
    title.FontFace = VapeV5.Settings.Fonts.Regular
    title.Parent = container
    
    -- Valor
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.fromOffset(60, 20)
    valueLabel.Position = UDim2.new(1, -70, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(api.Value) .. (options.Suffix or "")
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    valueLabel.TextSize = 12
    valueLabel.FontFace = VapeV5.Settings.Fonts.Regular
    valueLabel.Parent = container
    
    -- Barra de fundo
    local barBg = Instance.new("Frame")
    barBg.Name = "BarBackground"
    barBg.Size = UDim2.new(1, -20, 0, 4)
    barBg.Position = UDim2.fromOffset(10, 35)
    barBg.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    barBg.BorderSizePixel = 0
    barBg.Parent = container
    Components.AddCorner(barBg, UDim.new(1, 0))
    
    -- Barra de preenchimento
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.fromScale((api.Value - api.Min) / (api.Max - api.Min), 1)
    barFill.BackgroundColor3 = theme.Accent
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Components.AddCorner(barFill, UDim.new(1, 0))
    
    -- Knob
    local knobHolder = Instance.new("Frame")
    knobHolder.Size = UDim2.fromOffset(16, 16)
    knobHolder.Position = UDim2.fromScale(1, 0.5)
    knobHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    knobHolder.BackgroundTransparency = 1
    knobHolder.Parent = barFill
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.Position = UDim2.fromScale(0.5, 0.5)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = theme.Accent
    knob.Parent = knobHolder
    Components.AddCorner(knob, UDim.new(1, 0))
    
    -- API
    function api:SetValue(value, silent)
        value = math.clamp(value, self.Min, self.Max)
        value = math.floor(value * self.Decimal) / self.Decimal
        
        self.Value = value
        valueLabel.Text = tostring(value) .. (options.Suffix or "")
        
        local percent = (value - self.Min) / (self.Max - self.Min)
        VapeV5.Tween:Create(barFill, {
            Size = UDim2.fromScale(math.max(percent, 0.02), 1)
        }, 0.1)
        
        if not silent then
            self.Callback(value)
        end
    end
    
    function api:Save(data)
        data[options.Name] = {Value = self.Value}
    end
    
    function api:Load(data)
        if self.Value ~= data.Value then
            self:SetValue(data.Value)
        end
    end
    
    -- Eventos de arraste
    local dragging = false
    
    local function updateFromInput(input)
        local percent = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local value = api.Min + (api.Max - api.Min) * percent
        api:SetValue(value)
    end
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.Position.Y - container.AbsolutePosition.Y > 20 then
                dragging = true
                updateFromInput(input)
            end
        end
    end)
    
    container.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)
    
    -- Hover effects
    container.MouseEnter:Connect(function()
        VapeV5.Tween:Create(knob, {Size = UDim2.fromOffset(16, 16)}, 0.1)
    end)
    
    container.MouseLeave:Connect(function()
        VapeV5.Tween:Create(knob, {Size = UDim2.fromOffset(14, 14)}, 0.1)
    end)
    
    api.Object = container
    return api
end

-- Dropdown
function InputComponents.CreateDropdown(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Dropdown",
        Value = options.Default or options.List[1] or "None",
        List = options.List or {},
        Callback = options.Callback or function() end,
        Expanded = false,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "Dropdown") .. "Dropdown"
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = ""
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Background da seleção
    local selectionBg = Instance.new("Frame")
    selectionBg.Size = UDim2.new(1, -20, 0, 30)
    selectionBg.Position = UDim2.fromOffset(10, 5)
    selectionBg.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
    selectionBg.Parent = container
    Components.AddCorner(selectionBg, UDim.new(0, 6))
    Components.AddStroke(selectionBg, {Color = ColorSystem.Light(theme.Primary, 0.08)})
    
    -- Texto atual
    local currentText = Instance.new("TextLabel")
    currentText.Size = UDim2.new(1, -30, 1, 0)
    currentText.Position = UDim2.fromOffset(10, 0)
    currentText.BackgroundTransparency = 1
    currentText.Text = (options.Name or "Dropdown") .. " - " .. api.Value
    currentText.TextXAlignment = Enum.TextXAlignment.Left
    currentText.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    currentText.TextSize = 13
    currentText.TextTruncate = Enum.TextTruncate.AtEnd
    currentText.FontFace = VapeV5.Settings.Fonts.Regular
    currentText.Parent = selectionBg
    
    -- Seta
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.fromOffset(8, 8)
    arrow.Position = UDim2.new(1, -20, 0.5, -4)
    arrow.BackgroundTransparency = 1
    arrow.Image = AssetSystem:Get("Arrow")
    arrow.ImageColor3 = theme.TextDark
    arrow.Rotation = 90
    arrow.Parent = selectionBg
    
    -- Container de opções
    local optionsContainer
    
    -- API
    function api:SetValue(value, silent)
        if table.find(self.List, value) then
            self.Value = value
        else
            self.Value = self.List[1] or "None"
        end
        
        currentText.Text = (options.Name or "Dropdown") .. " - " .. self.Value
        self:Collapse()
        
        if not silent then
            self.Callback(self.Value)
        end
    end
    
    function api:Expand()
        if self.Expanded then return end
        self.Expanded = true
        
        arrow.Rotation = 270
        
        local itemCount = #self.List - 1 -- Excluir item atual
        container.Size = UDim2.new(1, 0, 0, 40 + itemCount * 28)
        
        optionsContainer = Instance.new("Frame")
        optionsContainer.Size = UDim2.new(1, -20, 0, itemCount * 28)
        optionsContainer.Position = UDim2.fromOffset(10, 38)
        optionsContainer.BackgroundTransparency = 1
        optionsContainer.Parent = container
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = optionsContainer
        
        for i, item in ipairs(self.List) do
            if item == self.Value then continue end
            
            local option = Instance.new("TextButton")
            option.Size = UDim2.new(1, 0, 0, 28)
            option.BackgroundColor3 = theme.Primary
            option.BackgroundTransparency = 1
            option.BorderSizePixel = 0
            option.AutoButtonColor = false
            option.Text = "    " .. item
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.TextColor3 = ColorSystem.Dark(theme.Text, 0.2)
            option.TextSize = 13
            option.FontFace = VapeV5.Settings.Fonts.Regular
            option.Parent = optionsContainer
            
            option.MouseEnter:Connect(function()
                VapeV5.Tween:Create(option, {BackgroundTransparency = 0.5}, 0.1)
            end)
            
            option.MouseLeave:Connect(function()
                VapeV5.Tween:Create(option, {BackgroundTransparency = 1}, 0.1)
            end)
            
            option.MouseButton1Click:Connect(function()
                self:SetValue(item)
            end)
        end
    end
    
    function api:Collapse()
        if not self.Expanded then return end
        self.Expanded = false
        
        arrow.Rotation = 90
        container.Size = UDim2.new(1, 0, 0, 40)
        
        if optionsContainer then
            optionsContainer:Destroy()
            optionsContainer = nil
        end
    end
    
    function api:UpdateList(newList)
        self.List = newList
        if not table.find(self.List, self.Value) then
            self:SetValue(self.List[1])
        end
    end
    
    function api:Save(data)
        data[options.Name] = {Value = self.Value}
    end
    
    function api:Load(data)
        if self.Value ~= data.Value then
            self:SetValue(data.Value, true)
        end
    end
    
    -- Eventos
    selectionBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if api.Expanded then
                api:Collapse()
            else
                api:Expand()
            end
        end
    end)
    
    container.MouseEnter:Connect(function()
        VapeV5.Tween:Create(selectionBg, {
            BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.08)
        }, 0.1)
    end)
    
    container.MouseLeave:Connect(function()
        VapeV5.Tween:Create(selectionBg, {
            BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
        }, 0.1)
    end)
    
    api.Object = container
    return api
end

-- TextBox
function InputComponents.CreateTextBox(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "TextBox",
        Value = options.Default or "",
        Callback = options.Callback or function() end,
    }
    
    local container = Instance.new("Frame")
    container.Name = (options.Name or "TextBox") .. "TextBox"
    container.Size = UDim2.new(1, 0, 0, 58)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.fromOffset(10, 5)
    title.BackgroundTransparency = 1
    title.Text = options.Name or "TextBox"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = theme.Text
    title.TextSize = 12
    title.FontFace = VapeV5.Settings.Fonts.Regular
    title.Parent = container
    
    -- Background do input
    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -20, 0, 28)
    inputBg.Position = UDim2.fromOffset(10, 25)
    inputBg.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
    inputBg.Parent = container
    Components.AddCorner(inputBg, UDim.new(0, 4))
    
    -- Input
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 1, 0)
    input.Position = UDim2.fromOffset(8, 0)
    input.BackgroundTransparency = 1
    input.Text = api.Value
    input.PlaceholderText = options.Placeholder or "Enter text..."
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    input.PlaceholderColor3 = ColorSystem.Dark(theme.Text, 0.4)
    input.TextSize = 12
    input.FontFace = VapeV5.Settings.Fonts.Regular
    input.ClearTextOnFocus = false
    input.Parent = inputBg
    
    -- API
    function api:SetValue(value, silent)
        self.Value = value
        input.Text = value
        
        if not silent then
            self.Callback(value)
        end
    end
    
    function api:Save(data)
        data[options.Name] = {Value = self.Value}
    end
    
    function api:Load(data)
        if self.Value ~= data.Value then
            self:SetValue(data.Value, true)
        end
    end
    
    -- Eventos
    input.FocusLost:Connect(function(enterPressed)
        api.Value = input.Text
        api.Callback(api.Value, enterPressed)
    end)
    
    input:GetPropertyChangedSignal("Text"):Connect(function()
        api.Value = input.Text
    end)
    
    api.Object = container
    return api
end

-- Color Picker
function InputComponents.CreateColorPicker(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "ColorPicker",
        Hue = options.DefaultHue or 0.44,
        Sat = options.DefaultSat or 1,
        Value = options.DefaultValue or 1,
        Rainbow = false,
        Callback = options.Callback or function() end,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "ColorPicker") .. "ColorPicker"
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = ""
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(100, 20)
    title.Position = UDim2.fromOffset(10, 5)
    title.BackgroundTransparency = 1
    title.Text = options.Name or "Color"
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    title.TextSize = 12
    title.FontFace = VapeV5.Settings.Fonts.Regular
    title.Parent = container
    
    -- Preview de cor
    local preview = Instance.new("Frame")
    preview.Size = UDim2.fromOffset(16, 16)
    preview.Position = UDim2.new(1, -26, 0, 8)
    preview.BackgroundColor3 = Color3.fromHSV(api.Hue, api.Sat, api.Value)
    preview.Parent = container
    Components.AddCorner(preview, UDim.new(0, 4))
    
    -- Barra de hue
    local hueBar = Instance.new("Frame")
    hueBar.Size = UDim2.new(1, -20, 0, 4)
    hueBar.Position = UDim2.fromOffset(10, 35)
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.Parent = container
    Components.AddCorner(hueBar, UDim.new(1, 0))
    
    -- Gradiente rainbow
    local gradient = Instance.new("UIGradient")
    local keypoints = {}
    for i = 0, 1, 0.1 do
        table.insert(keypoints, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
    end
    gradient.Color = ColorSequence.new(keypoints)
    gradient.Parent = hueBar
    
    -- Knob
    local knobHolder = Instance.new("Frame")
    knobHolder.Size = UDim2.fromOffset(16, 16)
    knobHolder.Position = UDim2.fromScale(api.Hue, 0.5)
    knobHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    knobHolder.BackgroundTransparency = 1
    knobHolder.Parent = hueBar
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = UDim2.fromScale(0.5, 0.5)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = knobHolder
    Components.AddCorner(knob, UDim.new(1, 0))
    
    -- API
    function api:SetValue(h, s, v, silent)
        self.Hue = h or self.Hue
        self.Sat = s or self.Sat
        self.Value = v or self.Value
        
        preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
        
        VapeV5.Tween:Create(knobHolder, {
            Position = UDim2.fromScale(self.Hue, 0.5)
        }, 0.1)
        
        if not silent then
            self.Callback(self.Hue, self.Sat, self.Value)
        end
    end
    
    function api:GetColor()
        return Color3.fromHSV(self.Hue, self.Sat, self.Value)
    end
    
    function api:Save(data)
        data[options.Name] = {
            Hue = self.Hue,
            Sat = self.Sat,
            Value = self.Value,
            Rainbow = self.Rainbow
        }
    end
    
    function api:Load(data)
        self.Rainbow = data.Rainbow
        self:SetValue(data.Hue, data.Sat, data.Value, true)
    end
    
    -- Eventos de arraste
    local dragging = false
    
    container.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.Position.Y - container.AbsolutePosition.Y > 25 then
                dragging = true
                local percent = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                api:SetValue(percent)
            end
        end
    end)
    
    container.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Services.UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            api:SetValue(percent)
        end
    end)
    
    api.Object = container
    return api
end

-- Keybind
function InputComponents.CreateKeybind(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Keybind",
        Bind = options.Default or {},
        Callback = options.Callback or function() end,
        Listening = false,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "Keybind") .. "Keybind"
    container.Size = UDim2.new(1, 0, 0, 32)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = "          " .. (options.Name or "Keybind")
    container.TextXAlignment = Enum.TextXAlignment.Left
    container.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    container.TextSize = 14
    container.FontFace = VapeV5.Settings.Fonts.Regular
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Botão de bind
    local bindButton = Instance.new("TextButton")
    bindButton.Size = UDim2.fromOffset(60, 22)
    bindButton.Position = UDim2.new(1, -70, 0, 5)
    bindButton.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    bindButton.BorderSizePixel = 0
    bindButton.AutoButtonColor = false
    bindButton.Text = #api.Bind > 0 and table.concat(api.Bind, "+") or "None"
    bindButton.TextColor3 = ColorSystem.Dark(theme.Text, 0.3)
    bindButton.TextSize = 11
    bindButton.FontFace = VapeV5.Settings.Fonts.Regular
    bindButton.Parent = container
    Components.AddCorner(bindButton, UDim.new(0, 4))
    
    -- API
    function api:SetBind(keys, silent)
        self.Bind = keys or {}
        bindButton.Text = #self.Bind > 0 and table.concat(self.Bind, "+"):upper() or "None"
        
        local size = Utils.GetTextSize(bindButton.Text, 11, VapeV5.Settings.Fonts.Regular)
        bindButton.Size = UDim2.fromOffset(math.max(size.X + 16, 40), 22)
        bindButton.Position = UDim2.new(1, -bindButton.Size.X.Offset - 10, 0, 5)
        
        if not silent then
            self.Callback(self.Bind)
        end
    end
    
    function api:StartListening()
        self.Listening = true
        bindButton.Text = "..."
        bindButton.TextColor3 = theme.Accent
    end
    
    function api:StopListening(key)
        self.Listening = false
        bindButton.TextColor3 = ColorSystem.Dark(theme.Text, 0.3)
        
        if key then
            self:SetBind({key.Name})
        end
    end
    
    function api:Save(data)
        data[options.Name] = {Bind = self.Bind}
    end
    
    function api:Load(data)
        self:SetBind(data.Bind, true)
    end
    
    -- Eventos
    bindButton.MouseButton1Click:Connect(function()
        api:StartListening()
        VapeV5._bindingTarget = api
    end)
    
    api.Object = container
    return api
end

-- Button
function InputComponents.CreateButton(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Button",
        Callback = options.Callback or function() end,
    }
    
    local container = Instance.new("TextButton")
    container.Name = (options.Name or "Button") .. "Button"
    container.Size = UDim2.new(1, 0, 0, 36)
    container.BackgroundColor3 = ColorSystem.Dark(parent.BackgroundColor3, options.Darker and 0.02 or 0)
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = ""
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Botão interno
    local button = Instance.new("Frame")
    button.Size = UDim2.new(1, -20, 0, 28)
    button.Position = UDim2.fromOffset(10, 4)
    button.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    button.Parent = container
    Components.AddCorner(button, UDim.new(0, 6))
    
    -- Texto
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Text = options.Name or "Button"
    text.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    text.TextSize = 14
    text.FontFace = VapeV5.Settings.Fonts.Regular
    text.Parent = button
    
    -- Eventos
    container.MouseEnter:Connect(function()
        VapeV5.Tween:Create(button, {
            BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.1)
        }, 0.1)
    end)
    
    container.MouseLeave:Connect(function()
        VapeV5.Tween:Create(button, {
            BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
        }, 0.1)
    end)
    
    container.MouseButton1Click:Connect(function()
        api.Callback()
    end)
    
    api.Object = container
    return api
end

VapeV5.Inputs = InputComponents

-- ═══════════════════════════════════════════════════════════════════
-- 📁 SISTEMA DE MÓDULOS
-- ═══════════════════════════════════════════════════════════════════

local function CreateModule(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Module",
        Name = options.Name or "Module",
        Enabled = false,
        Options = {},
        Bind = options.Bind or {},
        Callback = options.Callback or function() end,
        _connections = {},
    }
    
    -- Container do módulo
    local container = Instance.new("TextButton")
    container.Name = options.Name .. "Module"
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = theme.Primary
    container.BorderSizePixel = 0
    container.AutoButtonColor = false
    container.Text = "            " .. options.Name
    container.TextXAlignment = Enum.TextXAlignment.Left
    container.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    container.TextSize = 14
    container.FontFace = VapeV5.Settings.Fonts.Regular
    container.Parent = parent
    
    Components.AddTooltip(container, options.Tooltip)
    
    -- Gradiente (para rainbow)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 90
    gradient.Enabled = false
    gradient.Parent = container
    
    -- Botão de expandir
    local dotsButton = Instance.new("TextButton")
    dotsButton.Name = "Dots"
    dotsButton.Size = UDim2.fromOffset(25, 40)
    dotsButton.Position = UDim2.new(1, -25, 0, 0)
    dotsButton.BackgroundTransparency = 1
    dotsButton.Text = ""
    dotsButton.Parent = container
    
    local dots = Instance.new("ImageLabel")
    dots.Size = UDim2.fromOffset(3, 16)
    dots.Position = UDim2.fromOffset(11, 12)
    dots.BackgroundTransparency = 1
    dots.Image = AssetSystem:Get("Dots")
    dots.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
    dots.Parent = dotsButton
    
    -- Bind indicator
    local bindLabel = Instance.new("TextButton")
    bindLabel.Name = "Bind"
    bindLabel.Size = UDim2.fromOffset(40, 22)
    bindLabel.Position = UDim2.new(1, -70, 0, 9)
    bindLabel.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    bindLabel.BorderSizePixel = 0
    bindLabel.AutoButtonColor = false
    bindLabel.Visible = false
    bindLabel.Text = ""
    bindLabel.TextColor3 = ColorSystem.Dark(theme.Text, 0.4)
    bindLabel.TextSize = 11
    bindLabel.FontFace = VapeV5.Settings.Fonts.Regular
    bindLabel.Parent = container
    Components.AddCorner(bindLabel, UDim.new(0, 4))
    
    -- Container de opções
    local optionsContainer = Instance.new("Frame")
    optionsContainer.Name = options.Name .. "Options"
    optionsContainer.Size = UDim2.new(1, 0, 0, 0)
    optionsContainer.BackgroundColor3 = ColorSystem.Dark(theme.Primary, 0.02)
    optionsContainer.BorderSizePixel = 0
    optionsContainer.ClipsDescendants = true
    optionsContainer.Visible = false
    optionsContainer.Parent = parent
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsContainer
    
    -- Divider quando ativado
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 1, -1)
    divider.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.1)
    divider.BorderSizePixel = 0
    divider.Visible = false
    divider.Parent = container
    
    -- API do módulo
    function api:Toggle(silent)
        self.Enabled = not self.Enabled
        
        if self.Enabled then
            container.BackgroundColor3 = theme.Accent
            container.TextColor3 = ColorSystem.GetTextColor(theme.Accent:ToHSV())
            dots.ImageColor3 = container.TextColor3
            divider.Visible = true
        else
            container.BackgroundColor3 = theme.Primary
            container.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
            dots.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
            divider.Visible = false
            
            -- Limpar conexões
            for _, conn in pairs(self._connections) do
                if conn.Disconnect then
                    conn:Disconnect()
                end
            end
            table.clear(self._connections)
        end
        
        if not silent then
            self.Callback(self.Enabled)
        end
    end
    
    function api:SetBind(keys)
        self.Bind = keys or {}
        
        if #self.Bind > 0 then
            bindLabel.Visible = true
            bindLabel.Text = table.concat(self.Bind, "+"):upper()
            local size = Utils.GetTextSize(bindLabel.Text, 11, VapeV5.Settings.Fonts.Regular)
            bindLabel.Size = UDim2.fromOffset(math.max(size.X + 12, 30), 22)
            bindLabel.Position = UDim2.new(1, -bindLabel.Size.X.Offset - 30, 0, 9)
        else
            bindLabel.Visible = false
        end
    end
    
    function api:ExpandOptions()
        optionsContainer.Visible = not optionsContainer.Visible
        
        if optionsContainer.Visible then
            local height = optionsLayout.AbsoluteContentSize.Y
            optionsContainer.Size = UDim2.new(1, 0, 0, height)
        end
    end
    
    function api:Clean(connection)
        table.insert(self._connections, connection)
    end
    
    -- Criar componentes de input
    function api:CreateToggle(opts)
        local toggle = InputComponents.CreateToggle(optionsContainer, opts)
        self.Options[opts.Name] = toggle
        return toggle
    end
    
    function api:CreateSlider(opts)
        local slider = InputComponents.CreateSlider(optionsContainer, opts)
        self.Options[opts.Name] = slider
        return slider
    end
    
    function api:CreateDropdown(opts)
        local dropdown = InputComponents.CreateDropdown(optionsContainer, opts)
        self.Options[opts.Name] = dropdown
        return dropdown
    end
    
    function api:CreateTextBox(opts)
        local textbox = InputComponents.CreateTextBox(optionsContainer, opts)
        self.Options[opts.Name] = textbox
        return textbox
    end
    
    function api:CreateColorPicker(opts)
        local picker = InputComponents.CreateColorPicker(optionsContainer, opts)
        self.Options[opts.Name] = picker
        return picker
    end
    
    function api:CreateKeybind(opts)
        local keybind = InputComponents.CreateKeybind(optionsContainer, opts)
        self.Options[opts.Name] = keybind
        return keybind
    end
    
    function api:CreateButton(opts)
        local button = InputComponents.CreateButton(optionsContainer, opts)
        return button
    end
    
    function api:CreateDivider(text)
        local dividerFrame = Instance.new("Frame")
        dividerFrame.Size = UDim2.new(1, 0, 0, text and 25 or 1)
        dividerFrame.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
        dividerFrame.BackgroundTransparency = text and 1 or 0
        dividerFrame.BorderSizePixel = 0
        dividerFrame.Parent = optionsContainer
        
        if text then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.Position = UDim2.fromOffset(10, 0)
            label.BackgroundTransparency = 1
            label.Text = text:upper()
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextColor3 = ColorSystem.Dark(theme.Text, 0.5)
            label.TextSize = 10
            label.FontFace = VapeV5.Settings.Fonts.Bold
            label.Parent = dividerFrame
        end
    end
    
    -- Eventos
    local hovered = false
    
    container.MouseEnter:Connect(function()
        hovered = true
        if not api.Enabled then
            container.TextColor3 = theme.Text
            container.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
        end
        bindLabel.Visible = #api.Bind > 0 or true
    end)
    
    container.MouseLeave:Connect(function()
        hovered = false
        if not api.Enabled and not optionsContainer.Visible then
            container.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
            container.BackgroundColor3 = theme.Primary
        end
        bindLabel.Visible = #api.Bind > 0
    end)
    
    container.MouseButton1Click:Connect(function()
        api:Toggle()
    end)
    
    container.MouseButton2Click:Connect(function()
        api:ExpandOptions()
    end)
    
    dotsButton.MouseButton1Click:Connect(function()
        api:ExpandOptions()
    end)
    
    dotsButton.MouseEnter:Connect(function()
        if not api.Enabled then
            dots.ImageColor3 = theme.Text
        end
    end)
    
    dotsButton.MouseLeave:Connect(function()
        if not api.Enabled then
            dots.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
        end
    end)
    
    bindLabel.MouseButton1Click:Connect(function()
        VapeV5._bindingTarget = {
            SetBind = function(_, keys, mouse)
                api:SetBind(keys)
            end,
            Bind = api.Bind
        }
    end)
    
    -- Atualizar tamanho quando opções mudam
    optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if optionsContainer.Visible then
            local scale = VapeV5._scale and VapeV5._scale.Scale or 1
            optionsContainer.Size = UDim2.new(1, 0, 0, optionsLayout.AbsoluteContentSize.Y / scale)
        end
    end)
    
    api.Object = container
    api.OptionsContainer = optionsContainer
    
    return api
end

-- ═══════════════════════════════════════════════════════════════════
-- 📂 SISTEMA DE CATEGORIAS/TABS
-- ═══════════════════════════════════════════════════════════════════

local function CreateCategory(parent, options)
    options = options or {}
    local theme = VapeV5.Settings.Theme
    
    local api = {
        Type = "Category",
        Name = options.Name or "Category",
        Expanded = false,
        Modules = {},
    }
    
    -- Window da categoria
    local window = Instance.new("TextButton")
    window.Name = options.Name .. "Category"
    window.Size = UDim2.fromOffset(220, 42)
    window.Position = options.Position or UDim2.fromOffset(240, 60)
    window.BackgroundColor3 = theme.Primary
    window.BorderSizePixel = 0
    window.AutoButtonColor = false
    window.Visible = false
    window.Text = ""
    window.Parent = parent
    
    Components.AddBlur(window)
    Components.AddCorner(window)
    Components.MakeDraggable(window)
    
    -- Ícone
    local icon = Instance.new("ImageLabel")
    icon.Size = options.IconSize or UDim2.fromOffset(16, 16)
    icon.Position = UDim2.fromOffset(12, 13)
    icon.BackgroundTransparency = 1
    icon.Image = options.Icon or ""
    icon.ImageColor3 = theme.Text
    icon.Parent = window
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 42)
    title.Position = UDim2.fromOffset(36, 0)
    title.BackgroundTransparency = 1
    title.Text = options.Name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = theme.Text
    title.TextSize = 14
    title.FontFace = VapeV5.Settings.Fonts.Regular
    title.Parent = window
    
    -- Botão de expandir
    local arrowButton = Instance.new("TextButton")
    arrowButton.Size = UDim2.fromOffset(40, 42)
    arrowButton.Position = UDim2.new(1, -40, 0, 0)
    arrowButton.BackgroundTransparency = 1
    arrowButton.Text = ""
    arrowButton.Parent = window
    
    local arrow = Instance.new("ImageLabel")
    arrow.Size = UDim2.fromOffset(10, 6)
    arrow.Position = UDim2.fromOffset(15, 18)
    arrow.BackgroundTransparency = 1
    arrow.Image = AssetSystem:Get("Expand")
    arrow.ImageColor3 = theme.TextDark
    arrow.Rotation = 180
    arrow.Parent = arrowButton
    
    -- Container de módulos
    local modulesContainer = Instance.new("ScrollingFrame")
    modulesContainer.Name = "Modules"
    modulesContainer.Size = UDim2.new(1, 0, 1, -42)
    modulesContainer.Position = UDim2.fromOffset(0, 38)
    modulesContainer.BackgroundTransparency = 1
    modulesContainer.BorderSizePixel = 0
    modulesContainer.ScrollBarThickness = 3
    modulesContainer.ScrollBarImageTransparency = 0.7
    modulesContainer.CanvasSize = UDim2.new()
    modulesContainer.Visible = false
    modulesContainer.Parent = window
    
    local modulesLayout = Instance.new("UIListLayout")
    modulesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    modulesLayout.Parent = modulesContainer
    
    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.fromOffset(0, 38)
    divider.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    divider.BorderSizePixel = 0
    divider.Visible = false
    divider.Parent = window
    
    -- API
    function api:Expand()
        self.Expanded = not self.Expanded
        
        modulesContainer.Visible = self.Expanded
        divider.Visible = self.Expanded
        arrow.Rotation = self.Expanded and 0 or 180
        
        if self.Expanded then
            local scale = VapeV5._scale and VapeV5._scale.Scale or 1
            local height = math.min(42 + modulesLayout.AbsoluteContentSize.Y / scale, 600)
            window.Size = UDim2.fromOffset(220, height)
        else
            window.Size = UDim2.fromOffset(220, 42)
        end
    end
    
    function api:CreateModule(opts)
        local module = CreateModule(modulesContainer, opts)
        self.Modules[opts.Name] = module
        VapeV5._modules[opts.Name] = module
        
        -- Ordenar módulos alfabeticamente
        local sorted = {}
        for name, mod in pairs(self.Modules) do
            table.insert(sorted, {name = name, mod = mod})
        end
        table.sort(sorted, function(a, b)
            return a.name < b.name
        end)
        
        for i, data in ipairs(sorted) do
            data.mod.Object.LayoutOrder = i
            data.mod.OptionsContainer.LayoutOrder = i
        end
        
        return module
    end
    
    -- Eventos
    arrowButton.MouseButton1Click:Connect(function()
        api:Expand()
    end)
    
    arrowButton.MouseEnter:Connect(function()
        arrow.ImageColor3 = theme.Text
    end)
    
    arrowButton.MouseLeave:Connect(function()
        arrow.ImageColor3 = theme.TextDark
    end)
    
    window.MouseButton2Click:Connect(function()
        api:Expand()
    end)
    
    -- Atualizar tamanho do canvas
    modulesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local scale = VapeV5._scale and VapeV5._scale.Scale or 1
        modulesContainer.CanvasSize = UDim2.fromOffset(0, modulesLayout.AbsoluteContentSize.Y / scale)
        
        if api.Expanded then
            local height = math.min(42 + modulesLayout.AbsoluteContentSize.Y / scale, 600)
            window.Size = UDim2.fromOffset(220, height)
        end
    end)
    
    api.Object = window
    api.Container = modulesContainer
    
    return api
end

-- ═══════════════════════════════════════════════════════════════════
-- 🪟 SISTEMA DE JANELA PRINCIPAL
-- ═══════════════════════════════════════════════════════════════════

function VapeV5:CreateWindow(options)
    options = options or {}
    local theme = self.Settings.Theme
    
    -- Aplicar configurações do usuário
    if options.Theme then
        if type(options.Theme) == "table" then
            for k, v in pairs(options.Theme) do
                theme[k] = v
            end
        elseif options.Theme == "Light" then
            theme.Primary = Color3.fromRGB(240, 240, 240)
            theme.Secondary = Color3.fromRGB(220, 220, 220)
            theme.Text = Color3.fromRGB(40, 40, 40)
            theme.TextDark = Color3.fromRGB(100, 100, 100)
        end
    end
    
    if options.AccentColor then
        theme.Accent = options.AccentColor
    end
    
    if options.Keybind then
        self.Settings.Keybind = type(options.Keybind) == "table" and options.Keybind or {options.Keybind}
    end
    
    local windowAPI = {
        Categories = {},
        Options = {},
        Visible = true,
    }
    
    -- ScreenGui principal
    local gui = Instance.new("ScreenGui")
    gui.Name = Utils.RandomString()
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    
    -- Tentar colocar no CoreGui, senão no PlayerGui
    local success = pcall(function()
        gui.Parent = Services.CoreGui
    end)
    
    if not success then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    self._gui = gui
    
    -- Container com escala
    local scaledContainer = Instance.new("Frame")
    scaledContainer.Name = "ScaledContainer"
    scaledContainer.Size = UDim2.fromScale(1, 1)
    scaledContainer.BackgroundTransparency = 1
    scaledContainer.Parent = gui
    
    local scale = Instance.new("UIScale")
    scale.Scale = self.Settings.General.AutoScale and math.max(gui.AbsoluteSize.X / 1920, 0.6) or self.Settings.General.Scale
    scale.Parent = scaledContainer
    self._scale = scale
    
    -- Atualizar tamanho quando a tela redimensiona
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if self.Settings.General.AutoScale then
            scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
        end
        scaledContainer.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
    end)
    
    scaledContainer.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
    
    -- Container do ClickGui
    local clickGui = Instance.new("Frame")
    clickGui.Name = "ClickGui"
    clickGui.Size = UDim2.fromScale(1, 1)
    clickGui.BackgroundTransparency = 1
    clickGui.Visible = false
    clickGui.Parent = scaledContainer
    
    -- Modal para manter foco
    local modal = Instance.new("TextButton")
    modal.Size = UDim2.fromScale(1, 1)
    modal.BackgroundTransparency = 1
    modal.Text = ""
    modal.Modal = true
    modal.Parent = clickGui
    
    self._clickGui = clickGui
    
    -- Inicializar notificações
    NotificationSystem:Init(scaledContainer)
    
    -- Tooltip global
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.fromOffset(100, 30)
    tooltip.Position = UDim2.fromScale(-1, -1)
    tooltip.ZIndex = 100
    tooltip.BackgroundColor3 = ColorSystem.Dark(theme.Primary, 0.05)
    tooltip.Visible = false
    tooltip.Text = ""
    tooltip.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
    tooltip.TextSize = 12
    tooltip.FontFace = self.Settings.Fonts.Regular
    tooltip.Parent = scaledContainer
    Components.AddCorner(tooltip)
    Components.AddStroke(tooltip)
    self._tooltip = tooltip
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📋 JANELA PRINCIPAL DO MENU
    -- ═══════════════════════════════════════════════════════════════
    
    local mainWindow = Instance.new("TextButton")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.fromOffset(220, 100)
    mainWindow.Position = UDim2.fromOffset(10, 60)
    mainWindow.BackgroundColor3 = ColorSystem.Dark(theme.Primary, 0.02)
    mainWindow.BorderSizePixel = 0
    mainWindow.AutoButtonColor = false
    mainWindow.Text = ""
    mainWindow.Parent = clickGui
    
    Components.AddBlur(mainWindow)
    Components.AddCorner(mainWindow)
    Components.MakeDraggable(mainWindow)
    
    -- Logo
    local logo
    if options.Logo then
        if options.Logo:match("^https?://") or options.Logo:match("^rbxassetid://") then
            logo = Instance.new("ImageLabel")
            logo.Size = UDim2.fromOffset(80, 24)
            logo.Position = UDim2.fromOffset(12, 10)
            logo.BackgroundTransparency = 1
            logo.Image = options.Logo:match("^https?://") and AssetSystem:LoadFromURL(options.Logo) or options.Logo
            logo.Parent = mainWindow
        end
    else
        -- Logo texto padrão
        logo = Instance.new("TextLabel")
        logo.Size = UDim2.fromOffset(100, 24)
        logo.Position = UDim2.fromOffset(12, 10)
        logo.BackgroundTransparency = 1
        logo.Text = options.Title or "Vape V5"
        logo.TextXAlignment = Enum.TextXAlignment.Left
        logo.TextColor3 = theme.Text
        logo.TextSize = 16
        logo.FontFace = self.Settings.Fonts.Bold
        logo.Parent = mainWindow
    end
    
    -- Subtítulo/Versão
    if options.Subtitle then
        local subtitle = Instance.new("TextLabel")
        subtitle.Size = UDim2.fromOffset(50, 16)
        subtitle.Position = logo and UDim2.new(0, logo.Size.X.Offset + 14, 0, 12) or UDim2.fromOffset(100, 12)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = options.Subtitle
        subtitle.TextColor3 = theme.Accent
        subtitle.TextSize = 12
        subtitle.FontFace = self.Settings.Fonts.Regular
        subtitle.Parent = mainWindow
    end
    
    -- Botão de configurações
    local settingsButton = Instance.new("TextButton")
    settingsButton.Size = UDim2.fromOffset(30, 30)
    settingsButton.Position = UDim2.new(1, -35, 0, 5)
    settingsButton.BackgroundTransparency = 1
    settingsButton.Text = ""
    settingsButton.Parent = mainWindow
    
    local settingsIcon = Instance.new("ImageLabel")
    settingsIcon.Size = UDim2.fromOffset(16, 16)
    settingsIcon.Position = UDim2.fromOffset(7, 7)
    settingsIcon.BackgroundTransparency = 1
    settingsIcon.Image = AssetSystem:Get("Settings")
    settingsIcon.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
    settingsIcon.Parent = settingsButton
    
    settingsButton.MouseEnter:Connect(function()
        settingsIcon.ImageColor3 = theme.Text
    end)
    
    settingsButton.MouseLeave:Connect(function()
        settingsIcon.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
    end)
    
    -- Container de categorias/tabs
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "Tabs"
    tabsContainer.Size = UDim2.new(1, 0, 1, -42)
    tabsContainer.Position = UDim2.fromOffset(0, 38)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.Parent = mainWindow
    
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = tabsContainer
    
    -- Divider
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.Position = UDim2.fromOffset(0, 36)
    topDivider.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
    topDivider.BorderSizePixel = 0
    topDivider.Parent = mainWindow
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🔍 BARRA DE PESQUISA
    -- ═══════════════════════════════════════════════════════════════
    
    local searchBar = Instance.new("Frame")
    searchBar.Name = "SearchBar"
    searchBar.Size = UDim2.fromOffset(220, 38)
    searchBar.Position = UDim2.new(0.5, -110, 0, 12)
    searchBar.BackgroundColor3 = ColorSystem.Dark(theme.Primary, 0.02)
    searchBar.Parent = clickGui
    
    Components.AddBlur(searchBar)
    Components.AddCorner(searchBar)
    
    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.fromOffset(14, 14)
    searchIcon.Position = UDim2.new(1, -24, 0, 12)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = AssetSystem:Get("Search")
    searchIcon.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
    searchIcon.Parent = searchBar
    
    local searchInput = Instance.new("TextBox")
    searchInput.Size = UDim2.new(1, -50, 1, 0)
    searchInput.Position = UDim2.fromOffset(12, 0)
    searchInput.BackgroundTransparency = 1
    searchInput.Text = ""
    searchInput.PlaceholderText = "Search modules..."
    searchInput.TextXAlignment = Enum.TextXAlignment.Left
    searchInput.TextColor3 = theme.Text
    searchInput.PlaceholderColor3 = theme.TextDark
    searchInput.TextSize = 13
    searchInput.FontFace = self.Settings.Fonts.Regular
    searchInput.ClearTextOnFocus = false
    searchInput.Parent = searchBar
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📁 MÉTODOS DA JANELA
    -- ═══════════════════════════════════════════════════════════════
    
    -- Criar tab/categoria
    function windowAPI:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        
        -- Botão na janela principal
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabOptions.Name .. "Tab"
        tabButton.Size = UDim2.new(1, 0, 0, 40)
        tabButton.BackgroundColor3 = theme.Primary
        tabButton.BorderSizePixel = 0
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabsContainer
        
        -- Ícone (suporta emoji ou imagem)
        local iconText
        local iconImage
        
                    if tabOptions.Icon:match("^https?://") or tabOptions.Icon:match("^rbxassetid://") then
                -- É uma imagem
                iconImage = Instance.new("ImageLabel")
                iconImage.Size = tabOptions.IconSize or UDim2.fromOffset(16, 16)
                iconImage.Position = UDim2.fromOffset(12, 12)
                iconImage.BackgroundTransparency = 1
                iconImage.Image = tabOptions.Icon:match("^https?://") and AssetSystem:LoadFromURL(tabOptions.Icon) or tabOptions.Icon
                iconImage.ImageColor3 = ColorSystem.Dark(theme.Text, 0.16)
                iconImage.Parent = tabButton
            else
                -- É um emoji ou texto
                iconText = Instance.new("TextLabel")
                iconText.Size = UDim2.fromOffset(24, 24)
                iconText.Position = UDim2.fromOffset(10, 8)
                iconText.BackgroundTransparency = 1
                iconText.Text = tabOptions.Icon
                iconText.TextSize = 16
                iconText.Parent = tabButton
            end
        end
        
        -- Texto do tab
        local tabText = Instance.new("TextLabel")
        tabText.Size = UDim2.new(1, -80, 1, 0)
        tabText.Position = UDim2.fromOffset(tabOptions.Icon and 40 or 12, 0)
        tabText.BackgroundTransparency = 1
        tabText.Text = tabOptions.Name or "Tab"
        tabText.TextXAlignment = Enum.TextXAlignment.Left
        tabText.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
        tabText.TextSize = 14
        tabText.FontFace = VapeV5.Settings.Fonts.Regular
        tabText.Parent = tabButton
        
        -- Seta
        local tabArrow = Instance.new("ImageLabel")
        tabArrow.Size = UDim2.fromOffset(6, 10)
        tabArrow.Position = UDim2.new(1, -20, 0, 15)
        tabArrow.BackgroundTransparency = 1
        tabArrow.Image = AssetSystem:Get("Arrow")
        tabArrow.ImageColor3 = ColorSystem.Light(theme.Primary, 0.37)
        tabArrow.Parent = tabButton
        
        -- Criar categoria associada
        local category = CreateCategory(clickGui, {
            Name = tabOptions.Name,
            Icon = iconImage and iconImage.Image or "",
            IconSize = tabOptions.IconSize,
            Position = UDim2.fromOffset(240, 60),
        })
        
        self.Categories[tabOptions.Name] = category
        
        local tabAPI = {
            Name = tabOptions.Name,
            Enabled = false,
            Category = category,
        }
        
        function tabAPI:Toggle()
            self.Enabled = not self.Enabled
            category.Object.Visible = self.Enabled
            
            VapeV5.Tween:Create(tabArrow, {
                Position = UDim2.new(1, self.Enabled and -14 or -20, 0, 15)
            }, 0.1)
            
            if self.Enabled then
                tabText.TextColor3 = theme.Accent
                if iconImage then iconImage.ImageColor3 = theme.Accent end
                tabButton.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
            else
                tabText.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
                if iconImage then iconImage.ImageColor3 = ColorSystem.Dark(theme.Text, 0.16) end
                tabButton.BackgroundColor3 = theme.Primary
            end
        end
        
        function tabAPI:CreateModule(moduleOptions)
            return category:CreateModule(moduleOptions)
        end
        
        -- Eventos do botão
        tabButton.MouseEnter:Connect(function()
            if not tabAPI.Enabled then
                tabText.TextColor3 = theme.Text
                if iconImage then iconImage.ImageColor3 = theme.Text end
                tabButton.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
            end
        end)
        
        tabButton.MouseLeave:Connect(function()
            if not tabAPI.Enabled then
                tabText.TextColor3 = ColorSystem.Dark(theme.Text, 0.16)
                if iconImage then iconImage.ImageColor3 = ColorSystem.Dark(theme.Text, 0.16) end
                tabButton.BackgroundColor3 = theme.Primary
            end
        end)
        
        tabButton.MouseButton1Click:Connect(function()
            tabAPI:Toggle()
        end)
        
        tabAPI.Object = tabButton
        return tabAPI
    end
    
    -- Criar divider na lista de tabs
    function windowAPI:CreateDivider(text)
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, 0, 0, text and 28 or 1)
        divider.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.03)
        divider.BackgroundTransparency = text and 1 or 0
        divider.BorderSizePixel = 0
        divider.Parent = tabsContainer
        
        if text then
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.fromOffset(10, 0)
            label.BackgroundTransparency = 1
            label.Text = text:upper()
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextColor3 = ColorSystem.Dark(theme.Text, 0.5)
            label.TextSize = 10
            label.FontFace = VapeV5.Settings.Fonts.Bold
            label.Parent = divider
            
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 1, -1)
            line.BackgroundColor3 = ColorSystem.Light(theme.Primary, 0.05)
            line.BorderSizePixel = 0
            line.Parent = divider
        end
        
        return divider
    end
    
    -- Toggle visibilidade
    function windowAPI:Toggle()
        self.Visible = not self.Visible
        clickGui.Visible = self.Visible
        VapeV5._tooltip.Visible = false
        
        -- Esconder/mostrar categorias baseado no estado dos tabs
        for _, cat in pairs(self.Categories) do
            -- Manter estado anterior das categorias
        end
    end
    
    function windowAPI:Show()
        self.Visible = true
        clickGui.Visible = true
    end
    
    function windowAPI:Hide()
        self.Visible = false
        clickGui.Visible = false
        VapeV5._tooltip.Visible = false
    end
    
    -- Notificação
    function windowAPI:Notify(title, message, duration, type)
        VapeV5.Notify(title, message, duration, type)
    end
    
    -- Salvar configurações
    function windowAPI:Save(profileName)
        profileName = profileName or "default"
        local data = {
            Modules = {},
            Categories = {},
            Settings = VapeV5.Settings,
        }
        
        for name, module in pairs(VapeV5._modules) do
            data.Modules[name] = {
                Enabled = module.Enabled,
                Bind = module.Bind,
                Options = {},
            }
            
            for optName, option in pairs(module.Options) do
                if option.Save then
                    option:Save(data.Modules[name].Options)
                end
            end
        end
        
        for name, category in pairs(self.Categories) do
            data.Categories[name] = {
                Position = {
                    X = category.Object.Position.X.Offset,
                    Y = category.Object.Position.Y.Offset,
                },
                Expanded = category.Expanded,
            }
        end
        
        local success = pcall(function()
            if not isfolder("VapeV5") then makefolder("VapeV5") end
            if not isfolder("VapeV5/profiles") then makefolder("VapeV5/profiles") end
            writefile("VapeV5/profiles/" .. profileName .. "_" .. game.PlaceId .. ".json", 
                Services.HttpService:JSONEncode(data))
        end)
        
        if success then
            self:Notify("Settings Saved", "Profile '" .. profileName .. "' saved successfully!", 2, "Success")
        end
        
        return success
    end
    
    -- Carregar configurações
    function windowAPI:Load(profileName)
        profileName = profileName or "default"
        local path = "VapeV5/profiles/" .. profileName .. "_" .. game.PlaceId .. ".json"
        
        if not Utils.FileExists(path) then
            return false
        end
        
        local data = Utils.LoadJSON(path)
        if not data then return false end
        
        -- Carregar módulos
        for name, moduleData in pairs(data.Modules or {}) do
            local module = VapeV5._modules[name]
            if module then
                if moduleData.Enabled ~= module.Enabled then
                    module:Toggle(true)
                end
                
                if moduleData.Bind then
                    module:SetBind(moduleData.Bind)
                end
                
                for optName, optData in pairs(moduleData.Options or {}) do
                    local option = module.Options[optName]
                    if option and option.Load then
                        option:Load(optData)
                    end
                end
            end
        end
        
        -- Carregar posições das categorias
        for name, catData in pairs(data.Categories or {}) do
            local category = self.Categories[name]
            if category then
                category.Object.Position = UDim2.fromOffset(catData.Position.X, catData.Position.Y)
                if catData.Expanded ~= category.Expanded then
                    category:Expand()
                end
            end
        end
        
        self:Notify("Settings Loaded", "Profile '" .. profileName .. "' loaded!", 2, "Success")
        return true
    end
    
    -- Destruir a UI
    function windowAPI:Destroy()
        -- Salvar antes de destruir
        self:Save()
        
        -- Desativar todos os módulos
        for _, module in pairs(VapeV5._modules) do
            if module.Enabled then
                module:Toggle(true)
            end
        end
        
        -- Limpar conexões
        for _, conn in pairs(VapeV5._connections) do
            if conn.Disconnect then
                conn:Disconnect()
            end
        end
        
        -- Destruir GUI
        gui:Destroy()
        
        -- Limpar tabelas
        table.clear(VapeV5._modules)
        table.clear(VapeV5._windows)
        table.clear(VapeV5._connections)
        
        VapeV5._loaded = false
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- ⌨️ SISTEMA DE KEYBINDS
    -- ═══════════════════════════════════════════════════════════════
    
    local heldKeys = {}
    
    local function checkKeybind(keys, pressedKey)
        if type(keys) ~= "table" or #keys == 0 then return false end
        
        if table.find(keys, pressedKey) then
            for _, key in ipairs(keys) do
                if not table.find(heldKeys, key) then
                    return false
                end
            end
            return true
        end
        
        return false
    end
    
    -- Input handler
    local inputConnection = Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            table.insert(heldKeys, input.KeyCode.Name)
            
            -- Verificar se está bindando
            if VapeV5._bindingTarget then
                VapeV5._bindingTarget:StopListening(input.KeyCode)
                VapeV5._bindingTarget = nil
                return
            end
            
            -- Toggle GUI
            if checkKeybind(VapeV5.Settings.Keybind, input.KeyCode.Name) then
                windowAPI:Toggle()
            end
            
            -- Toggle módulos
            for _, module in pairs(VapeV5._modules) do
                if checkKeybind(module.Bind, input.KeyCode.Name) then
                    module:Toggle()
                    
                    if VapeV5.Settings.General.Notifications then
                        VapeV5.Notify(
                            "Module Toggled",
                            module.Name .. " " .. (module.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>"),
                            1,
                            module.Enabled and "Success" or "Error"
                        )
                    end
                end
            end
        end
    end)
    
    local inputEndConnection = Services.UserInputService.InputEnded:Connect(function(input)
        local idx = table.find(heldKeys, input.KeyCode.Name)
        if idx then
            table.remove(heldKeys, idx)
        end
    end)
    
    table.insert(VapeV5._connections, inputConnection)
    table.insert(VapeV5._connections, inputEndConnection)
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🌈 SISTEMA RAINBOW
    -- ═══════════════════════════════════════════════════════════════
    
    task.spawn(function()
        while VapeV5._loaded ~= nil do
            if VapeV5.Settings.Rainbow.Enabled then
                local hue = (tick() * 0.2 * VapeV5.Settings.Rainbow.Speed) % 1
                
                for _, item in ipairs(VapeV5._rainbowTable) do
                    if item.SetValue then
                        item:SetValue(ColorSystem.GetRainbow(hue))
                    end
                end
            end
            
            task.wait(1 / VapeV5.Settings.Rainbow.UpdateRate)
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- 📐 ATUALIZAR TAMANHO DA JANELA PRINCIPAL
    -- ═══════════════════════════════════════════════════════════════
    
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local contentHeight = tabsLayout.AbsoluteContentSize.Y / scale.Scale
        mainWindow.Size = UDim2.fromOffset(220, 42 + contentHeight)
    end)
    
    -- Pesquisa de módulos
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = searchInput.Text:lower()
        
        if searchText == "" then
            -- Mostrar resultados normais, esconder resultados da pesquisa
            return
        end
        
        -- Filtrar módulos
        for name, module in pairs(VapeV5._modules) do
            if name:lower():find(searchText) then
                -- Destacar módulo encontrado
            end
        end
    end)
    
    -- ═══════════════════════════════════════════════════════════════
    -- 🎯 FINALIZAÇÃO
    -- ═══════════════════════════════════════════════════════════════
    
    VapeV5._loaded = true
    table.insert(VapeV5._windows, windowAPI)
    
    -- Carregar configurações salvas
    task.spawn(function()
        task.wait(0.5)
        windowAPI:Load()
    end)
    
    -- Mostrar notificação de boas-vindas
    if options.ShowWelcome ~= false then
        task.spawn(function()
            task.wait(1)
            VapeV5.Notify(
                options.Title or "Vape V5",
                "Press <font color='#05C46B'>" .. table.concat(VapeV5.Settings.Keybind, " + "):upper() .. "</font> to toggle GUI",
                3,
                "Info"
            )
        end)
    end
    
    windowAPI.GUI = gui
    windowAPI.MainWindow = mainWindow
    
    return windowAPI
end

-- ═══════════════════════════════════════════════════════════════════
-- 🎨 TEMAS PRÉ-DEFINIDOS
-- ═══════════════════════════════════════════════════════════════════

VapeV5.Themes = {
    Dark = {
        Primary = Color3.fromRGB(26, 25, 26),
        Secondary = Color3.fromRGB(35, 34, 35),
        Accent = Color3.fromRGB(5, 134, 105),
        Text = Color3.fromRGB(200, 200, 200),
        TextDark = Color3.fromRGB(140, 140, 140),
    },
    
    Light = {
        Primary = Color3.fromRGB(245, 245, 245),
        Secondary = Color3.fromRGB(235, 235, 235),
        Accent = Color3.fromRGB(5, 134, 105),
        Text = Color3.fromRGB(40, 40, 40),
        TextDark = Color3.fromRGB(100, 100, 100),
    },
    
    Ocean = {
        Primary = Color3.fromRGB(20, 30, 48),
        Secondary = Color3.fromRGB(30, 45, 65),
        Accent = Color3.fromRGB(52, 152, 219),
        Text = Color3.fromRGB(200, 210, 220),
        TextDark = Color3.fromRGB(120, 140, 160),
    },
    
    Purple = {
        Primary = Color3.fromRGB(30, 25, 40),
        Secondary = Color3.fromRGB(45, 38, 58),
        Accent = Color3.fromRGB(155, 89, 182),
        Text = Color3.fromRGB(210, 200, 220),
        TextDark = Color3.fromRGB(140, 130, 150),
    },
    
    Red = {
        Primary = Color3.fromRGB(35, 25, 25),
        Secondary = Color3.fromRGB(50, 35, 35),
        Accent = Color3.fromRGB(231, 76, 60),
        Text = Color3.fromRGB(220, 200, 200),
        TextDark = Color3.fromRGB(160, 130, 130),
    },
    
    Midnight = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(25, 25, 32),
        Accent = Color3.fromRGB(99, 102, 241),
        Text = Color3.fromRGB(200, 200, 210),
        TextDark = Color3.fromRGB(120, 120, 140),
    },
    
    Forest = {
        Primary = Color3.fromRGB(25, 35, 25),
        Secondary = Color3.fromRGB(35, 50, 35),
        Accent = Color3.fromRGB(46, 204, 113),
        Text = Color3.fromRGB(200, 220, 200),
        TextDark = Color3.fromRGB(130, 160, 130),
    },
}

-- Aplicar tema
function VapeV5:SetTheme(themeName)
    local theme = self.Themes[themeName]
    if theme then
        for k, v in pairs(theme) do
            self.Settings.Theme[k] = v
        end
        -- Atualizar UI existente seria necessário aqui
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════════
-- 📚 UTILITÁRIOS EXPORTADOS
-- ═══════════════════════════════════════════════════════════════════

VapeV5.Utils = Utils

-- ═══════════════════════════════════════════════════════════════════
-- 🚀 RETORNAR BIBLIOTECA
-- ═══════════════════════════════════════════════════════════════════

return VapeV5
            