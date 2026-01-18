--[[
    VapeUI Page Manager
    Handles page creation and navigation with UIPageLayout.
]]

local Create = require(script.Parent.Parent.utils.Create)
local Config = require(script.Parent.Parent.core.Config)

local PageManager = {}
PageManager.__index = PageManager

function PageManager.new(container)
    local self = setmetatable({}, PageManager)
    
    self.Container = container
    self.Pages = {}
    self.CurrentPage = nil
    
    -- UIPageLayout for smooth transitions
    self.PageLayout = Create.Instance("UIPageLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        EasingDirection = Enum.EasingDirection.Out,
        EasingStyle = Enum.EasingStyle.Quad,
        TweenTime = Config.Animation.Slow,
        FillDirection = Enum.FillDirection.Horizontal,
        Circular = false,
        Parent = container,
    })
    
    return self
end

function PageManager:CreatePage(name)
    local page = Create.Scroll({
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.Container,
    }, {
        Create.List({
            Padding = UDim.new(0, Config.Card.Spacing),
        }),
        Create.Padding(10, 10, 15, 5),
    })
    
    local pageData = {
        Name = name,
        Frame = page,
    }
    
    self.Pages[name] = pageData
    
    -- Select first page
    if not self.CurrentPage then
        self:JumpTo(name)
    end
    
    return pageData
end

function PageManager:JumpTo(pageName)
    local page = self.Pages[pageName]
    if not page then return end
    
    self.CurrentPage = page
    self.PageLayout:JumpTo(page.Frame)
end

function PageManager:GetPage(pageName)
    return self.Pages[pageName]
end

return PageManager