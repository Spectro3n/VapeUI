--[[
    ██╗   ██╗ █████╗ ██████╗ ███████╗██╗   ██╗██╗
    ██║   ██║██╔══██╗██╔══██╗██╔════╝██║   ██║██║
    ██║   ██║███████║██████╔╝█████╗  ██║   ██║██║
    ╚██╗ ██╔╝██╔══██║██╔═══╝ ██╔══╝  ██║   ██║██║
     ╚████╔╝ ██║  ██║██║     ███████╗╚██████╔╝██║
      ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝
    
    VapeUI v2.0.0 | Professional UI Framework for Roblox
    Inspired by VapeV4 design language
]]

local VapeUI = {}
VapeUI.__index = VapeUI
VapeUI.Version = "2.0.0"
VapeUI.Flags = {}
VapeUI.Windows = {}

-- ═══════════════════════════════════════════════════════════════════
-- LOAD MODULES
-- ═══════════════════════════════════════════════════════════════════

-- Core
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Signal = require("Core/Signal.lua")

-- Utils
local Services = require("Utils/Services.lua")
local Create = require("Utils/Create.lua")
local Tween = require("Utils/Tween.lua")
local Drag = require("Utils/Drag.lua")
local Scale = require("Utils/Scale.lua")

-- UI
local Window = require("UI/Window.lua")
local TopBar = require("UI/TopBar.lua")
local Sidebar = require("UI/Sidebar.lua")
local ContentArea = require("UI/ContentArea.lua")
local Blur = require("UI/Blur.lua")

-- Layout
local PageManager = require("Layout/PageManager.lua")

-- Components
local Card = require("Components/Card.lua")
local Toggle = require("Components/Toggle.lua")
local Slider = require("Components/Slider.lua")
local Button = require("Components/Button.lua")
local Dropdown = require("Components/Dropdown.lua")
local Keybind = require("Components/Keybind.lua")
local TextInput = require("Components/TextInput.lua")
local Label = require("Components/Label.lua")
local Divider = require("Components/Divider.lua")
local ColorPicker = require("Components/ColorPicker.lua")
local TabButton = require("Components/TabButton.lua")
local Notification = require("Components/Notification.lua")
local Tooltip = require("Components/Tooltip.lua")
local Paragraph = require("Components/Paragraph.lua")

-- Services
local CoreGui = Services:Get("CoreGui")
local UserInputService = Services:Get("UserInputService")

-- ═══════════════════════════════════════════════════════════════════
-- EXPOSE MODULES
-- ═══════════════════════════════════════════════════════════════════

VapeUI.Theme = Theme
VapeUI.Config = Config
VapeUI.Signal = Signal
VapeUI.Services = Services
VapeUI.Create = Create
VapeUI.Tween = Tween
VapeUI.Scale = Scale

-- ═══════════════════════════════════════════════════════════════════
-- WINDOW CREATION
-- ═══════════════════════════════════════════════════════════════════

function VapeUI:CreateWindow(options)
    options = options or {}
    
    local windowInstance = {
        Title = options.Title or "VapeUI",
        Size = options.Size or Config.Window.DefaultSize,
        ThemeName = options.Theme or "Dark",
        ToggleKey = options.ToggleKey or Config.Keybinds.ToggleUI,
        Visible = true,
        Tabs = {},
        Flags = VapeUI.Flags,
        _connections = {},
    }
    
    -- Set theme
    Theme:Set(windowInstance.ThemeName)
    
    -- Clean old UI
    local oldUI = CoreGui:FindFirstChild("VapeUI")
    if oldUI then
        oldUI:Destroy()
    end
    
    -- ScreenGui
    windowInstance.ScreenGui = Create.Instance("ScreenGui", {
        Name = "VapeUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = false,
        Parent = CoreGui,
    })
    
    -- Initialize Blur
    windowInstance.BlurController = Blur.new()
    if Config.Misc.BlurEnabled then
        windowInstance.BlurController:Enable()
    end
    
    -- Create Window
    windowInstance.Window = Window.new(windowInstance.ScreenGui, {
        Title = windowInstance.Title,
        Size = windowInstance.Size,
    })
    
    -- Create TopBar
    windowInstance.TopBar = TopBar.new(windowInstance.Window.Container, {
        Title = windowInstance.Title,
        DragTarget = windowInstance.Window.Frame,
    })
    
    -- Create Sidebar
    windowInstance.Sidebar = Sidebar.new(windowInstance.Window.Container)
    
    -- Create Content Area
    windowInstance.ContentArea = ContentArea.new(windowInstance.Window.Container)
    
    -- Create Page Manager
    windowInstance.PageManager = PageManager.new(windowInstance.ContentArea.PageContainer)
    
    -- Connect sidebar to page manager
    windowInstance.Sidebar.OnTabChanged:Connect(function(tabData)
        if tabData.Page then
            windowInstance.PageManager:JumpTo(tabData.Page.Name)
        end
    end)
    
    -- TopBar events
    windowInstance.TopBar.OnClose:Connect(function()
        windowInstance:Destroy()
    end)
    
    windowInstance.TopBar.OnMinimize:Connect(function()
        windowInstance.Window:Toggle()
    end)
    
    -- Toggle keybind
    table.insert(windowInstance._connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == windowInstance.ToggleKey then
            windowInstance:Toggle()
        end
    end))
    
    -- ═══════════════════════════════════════════════════════════════════
    -- TAB CREATION
    -- ═══════════════════════════════════════════════════════════════════
    
    function windowInstance:CreateTab(tabOptions)
        tabOptions = tabOptions or {}
        
        local tabData = self.Sidebar:AddTab(
            tabOptions.Name or "Tab",
            tabOptions.Icon
        )
        
        -- Create page for this tab
        local page = self.PageManager:CreatePage(tabData.Name)
        tabData.Page = page
        
        -- Tab instance with component methods
        local tabInstance = {
            Name = tabData.Name,
            Page = page,
            Elements = {},
        }
        
        -- ═══════════════════════════════════════════════════════════════════
        -- COMPONENT METHODS
        -- ═══════════════════════════════════════════════════════════════════
        
        function tabInstance:CreateToggle(opts)
            opts = opts or {}
            local toggle = Toggle.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = toggle.Value end
            toggle.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, toggle)
            return toggle
        end
        
        function tabInstance:CreateSlider(opts)
            opts = opts or {}
            local slider = Slider.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = slider.Value end
            slider.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, slider)
            return slider
        end
        
        function tabInstance:CreateButton(opts)
            opts = opts or {}
            local button = Button.new(page.Frame, opts)
            table.insert(self.Elements, button)
            return button
        end
        
        function tabInstance:CreateDropdown(opts)
            opts = opts or {}
            local dropdown = Dropdown.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = dropdown.Value end
            dropdown.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, dropdown)
            return dropdown
        end
        
        function tabInstance:CreateKeybind(opts)
            opts = opts or {}
            local keybind = Keybind.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = keybind.Value end
            keybind.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, keybind)
            return keybind
        end
        
        function tabInstance:CreateInput(opts)
            opts = opts or {}
            local input = TextInput.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = input.Value end
            input.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, input)
            return input
        end
        
        function tabInstance:CreateColorPicker(opts)
            opts = opts or {}
            local colorPicker = ColorPicker.new(page.Frame, opts)
            if opts.Flag then VapeUI.Flags[opts.Flag] = colorPicker.Value end
            colorPicker.OnChanged:Connect(function(value)
                if opts.Flag then VapeUI.Flags[opts.Flag] = value end
            end)
            table.insert(self.Elements, colorPicker)
            return colorPicker
        end
        
        function tabInstance:CreateLabel(opts)
            if type(opts) == "string" then
                opts = { Text = opts }
            end
            opts = opts or {}
            local label = Label.new(page.Frame, opts)
            table.insert(self.Elements, label)
            return label
        end
        
        function tabInstance:CreateParagraph(opts)
            opts = opts or {}
            local paragraph = Paragraph.new(page.Frame, opts)
            table.insert(self.Elements, paragraph)
            return paragraph
        end
        
        function tabInstance:CreateDivider(opts)
            if type(opts) == "string" then
                opts = { Text = opts }
            end
            opts = opts or {}
            local divider = Divider.new(page.Frame, opts)
            table.insert(self.Elements, divider)
            return divider
        end
        
        table.insert(self.Tabs, tabInstance)
        return tabInstance
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- NOTIFICATION
    -- ═══════════════════════════════════════════════════════════════════
    
    function windowInstance:Notify(options)
        return Notification.new(self.ScreenGui, options)
    end
    
    -- ═══════════════════════════════════════════════════════════════════
    -- WINDOW METHODS
    -- ═══════════════════════════════════════════════════════════════════
    
    function windowInstance:Toggle()
        if self.Visible then
            self:Hide()
        else
            self:Show()
        end
    end
    
    function windowInstance:Show()
        self.Visible = true
        self.Window:SetVisible(true)
        if Config.Misc.BlurEnabled then
            self.BlurController:Enable()
        end
    end
    
    function windowInstance:Hide()
        self.Visible = false
        self.Window:SetVisible(false)
        self.BlurController:Disable()
        Tooltip.Hide()
    end
    
    function windowInstance:SetTheme(themeName)
        if Theme:Set(themeName) then
            self.ThemeName = themeName
            self:UpdateTheme()
        end
    end
    
    function windowInstance:UpdateTheme()
        self.Window:UpdateTheme()
        self.TopBar:UpdateTheme()
        self.Sidebar:UpdateTheme()
        self.ContentArea:UpdateTheme()
        Tooltip.UpdateTheme()
        
        for _, tab in ipairs(self.Tabs) do
            for _, element in ipairs(tab.Elements) do
                if element.UpdateTheme then
                    element:UpdateTheme()
                end
            end
        end
    end
    
    function windowInstance:Destroy()
        -- Disconnect all connections
        for _, connection in ipairs(self._connections) do
            connection:Disconnect()
        end
        self._connections = {}
        
        -- Destroy components
        for _, tab in ipairs(self.Tabs) do
            for _, element in ipairs(tab.Elements) do
                if element.Destroy then
                    element:Destroy()
                end
            end
        end
        
        self.BlurController:Destroy()
        self.ScreenGui:Destroy()
        
        -- Remove from windows list
        for i, win in ipairs(VapeUI.Windows) do
            if win == self then
                table.remove(VapeUI.Windows, i)
                break
            end
        end
    end
    
    table.insert(VapeUI.Windows, windowInstance)
    return windowInstance
end

-- ═══════════════════════════════════════════════════════════════════
-- GLOBAL METHODS
-- ═══════════════════════════════════════════════════════════════════

function VapeUI:GetFlag(flag)
    return self.Flags[flag]
end

function VapeUI:SetFlag(flag, value)
    self.Flags[flag] = value
end

function VapeUI:DestroyAll()
    for _, window in ipairs(self.Windows) do
        window:Destroy()
    end
    self.Windows = {}
    self.Flags = {}
end

-- ═══════════════════════════════════════════════════════════════════
-- RETURN
-- ═══════════════════════════════════════════════════════════════════

print("✅ VapeUI v" .. VapeUI.Version .. " loaded successfully!")

return VapeUI