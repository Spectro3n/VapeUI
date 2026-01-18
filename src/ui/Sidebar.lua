--[[
    VapeUI Sidebar
    Tab navigation container.
]]

local Create = require("Utils/Create.lua")
local Theme = require("Core/Theme.lua")
local Config = require("Core/Config.lua")
local Tween = require("Utils/Tween.lua")
local Signal = require("Core/Signal.lua")

local TabButton = require("Components/TabButton.lua")

local Sidebar = {}
Sidebar.__index = Sidebar

function Sidebar.new(parent, options)
    local self = setmetatable({}, Sidebar)
    
    options = options or {}
    self.Width = options.Width or Config.Sidebar.Width
    self.Tabs = {}
    self.CurrentTab = nil
    self.Collapsed = false
    
    self.OnTabChanged = Signal.new()
    
    -- Main Frame
    self.Frame = Create.Frame({
        Name = "Sidebar",
        Size = UDim2.new(0, self.Width, 1, -Config.TopBar.Height),
        Position = UDim2.new(0, 0, 0, Config.TopBar.Height),
        BackgroundColor3 = Theme:Get("Sidebar"),
        BorderSizePixel = 0,
        Parent = parent,
    })
    
    -- Divider
    self.Divider = Create.Frame({
        Name = "Divider",
        Size = UDim2.new(0, 1, 1, -20),
        Position = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Theme:Get("Divider"),
        BorderSizePixel = 0,
        Parent = self.Frame,
    })
    
    -- Tab Container
    self.TabContainer = Create.Scroll({
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme:Get("Accent"),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.Frame,
    }, {
        Create.List({
            Padding = UDim.new(0, Config.Sidebar.TabPadding),
        }),
        Create.Padding(8, 10, 8, 10),
    })
    
    return self
end

function Sidebar:AddTab(name, icon)
    local tabButton = TabButton.new(self.TabContainer, {
        Name = name,
        Icon = icon,
        Width = self.Width - 20,
    })
    
    local tabData = {
        Name = name,
        Button = tabButton,
        Page = nil,
    }
    
    tabButton.OnClick:Connect(function()
        self:SelectTab(tabData)
    end)
    
    table.insert(self.Tabs, tabData)
    
    if #self.Tabs == 1 then
        self:SelectTab(tabData)
    end
    
    return tabData
end

function Sidebar:SelectTab(tabData)
    if self.CurrentTab == tabData then return end
    
    if self.CurrentTab then
        self.CurrentTab.Button:SetActive(false)
    end
    
    self.CurrentTab = tabData
    tabData.Button:SetActive(true)
    
    self.OnTabChanged:Fire(tabData)
end

function Sidebar:SetCollapsed(collapsed)
    self.Collapsed = collapsed
    
    local targetWidth = collapsed and Config.Sidebar.CollapsedWidth or self.Width
    
    Tween.Normal(self.Frame, {
        Size = UDim2.new(0, targetWidth, 1, -Config.TopBar.Height)
    })
    
    for _, tab in ipairs(self.Tabs) do
        tab.Button:SetCollapsed(collapsed)
    end
end

function Sidebar:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Sidebar")
    self.Divider.BackgroundColor3 = Theme:Get("Divider")
    
    for _, tab in ipairs(self.Tabs) do
        tab.Button:UpdateTheme()
    end
end

return Sidebar