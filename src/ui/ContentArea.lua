--[[
    VapeUI Content Area
    Container for page content.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Theme = require(script.Parent.Parent.core.Theme)
local Config = require(script.Parent.Parent.core.Config)

local ContentArea = {}
ContentArea.__index = ContentArea

function ContentArea.new(parent, options)
    local self = setmetatable({}, ContentArea)
    
    options = options or {}
    self.SidebarWidth = options.SidebarWidth or Config.Sidebar.Width
    
    -- Main frame
    self.Frame = Create.Frame({
        Name = "ContentArea",
        Size = UDim2.new(1, -self.SidebarWidth, 1, -Config.TopBar.Height),
        Position = UDim2.new(0, self.SidebarWidth, 0, Config.TopBar.Height),
        BackgroundColor3 = Theme:Get("Content"),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent,
    })
    
    -- Page container (for UIPageLayout)
    self.PageContainer = Create.Frame({
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self.Frame,
    })
    
    return self
end

function ContentArea:UpdateTheme()
    self.Frame.BackgroundColor3 = Theme:Get("Content")
end

return ContentArea