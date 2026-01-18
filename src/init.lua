--[[
    ██╗   ██╗ █████╗ ██████╗ ███████╗██╗   ██╗██╗
    ██║   ██║██╔══██╗██╔══██╗██╔════╝██║   ██║██║
    ██║   ██║███████║██████╔╝█████╗  ██║   ██║██║
    ╚██╗ ██╔╝██╔══██║██╔═══╝ ██╔══╝  ██║   ██║██║
     ╚████╔╝ ██║  ██║██║     ███████╗╚██████╔╝██║
      ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝
    
    VapeUI v2.0.0 | Professional UI Framework for Roblox
    Inspired by VapeV4 design language
    
    GitHub: https://github.com/username/VapeUI
]]

local VapeUI = {}
VapeUI.__index = VapeUI
VapeUI.Version = "2.0.0"
VapeUI.Flags = {}
VapeUI.Windows = {}

-- ═══════════════════════════════════════════════════════════════════
-- SERVICES & MODULES
-- ═══════════════════════════════════════════════════════════════════

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

-- Core
local Theme = require(script.core.Theme)
local Config = require(script.core.Config)
local Signal = require(script.core.Signal)

-- UI
local Window = require(script.ui.Window)
local TopBar = require(script.ui.TopBar)
local Sidebar = require(script.ui.Sidebar)
local ContentArea = require(script.ui.ContentArea)
local Blur = require(script.ui.Blur)

-- Layout
local PageManager = require(script.layout.PageManager)

-- Components
local Toggle = require(script.components.Toggle)
local Slider = require(script.components.Slider)
local Button = require(script.components.Button)
local Dropdown = require(script.components.Dropdown)
local Keybind = require(script.components.Keybind)
local TextInput = require(script.components.TextInput)
local Label = require(script.components.Label)
local Divider = require(script.components.Divider)

-- Utils
local Create = require(script.utils.Create)
local Tween = require(script.utils.Tween)

-- Expose modules
VapeUI.Theme = Theme
VapeUI.Config = Config
VapeUI.Signal = Signal
VapeUI.Blur = Blur

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
    }
    
    -- Set theme
    Theme:Set(windowInstance.ThemeName)
    
    -- Clean old UI
    if CoreGui:FindFirstChild("VapeUI") then
        CoreGui:FindFirstChild("VapeUI"):Destroy()
    end
    
    -- ScreenGui
    windowInstance.ScreenGui = Create.Instance("ScreenGui", {
        Name = "VapeUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
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
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == windowInstance.ToggleKey then
            windowInstance:Toggle()
        end
    end)
    
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
        
        function tabInstance:CreateLabel(opts)
            if type(opts) == "string" then
                opts = {Text = opts}
            end
            opts = opts or {}
            local label = Label.new(page.Frame, opts)
            table.insert(self.Elements, label)
            return label
        end
        
        function tabInstance:CreateDivider(opts)
            if type(opts) == "string" then
                opts = {Text = opts}
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
        
        for _, tab in ipairs(self.Tabs) do
            for _, element in ipairs(tab.Elements) do
                if element.UpdateTheme then
                    element:UpdateTheme()
                end
            end
        end
    end
    
    function windowInstance:Destroy()
        self.BlurController:Destroy()
        self.ScreenGui:Destroy()
    end
    
    table.insert(VapeUI.Windows, windowInstance)
    return windowInstance
end

return VapeUI