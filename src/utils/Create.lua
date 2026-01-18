--[[
    VapeUI Instance Creator
    Clean instance creation with property assignment.
]]

local Create = {}

function Create.Instance(className, properties, children)
    local instance = Instance.new(className)
    
    -- Apply properties
    for property, value in pairs(properties or {}) do
        if property ~= "Parent" then
            instance[property] = value
        end
    end
    
    -- Apply children
    for _, child in ipairs(children or {}) do
        child.Parent = instance
    end
    
    -- Set parent last
    if properties and properties.Parent then
        instance.Parent = properties.Parent
    end
    
    return instance
end

-- Shorthand creators
function Create.Frame(props, children)
    return Create.Instance("Frame", props, children)
end

function Create.Text(props)
    return Create.Instance("TextLabel", props)
end

function Create.Button(props, children)
    return Create.Instance("TextButton", props, children)
end

function Create.Image(props)
    return Create.Instance("ImageLabel", props)
end

function Create.ImageButton(props, children)
    return Create.Instance("ImageButton", props, children)
end

function Create.Input(props)
    return Create.Instance("TextBox", props)
end

function Create.Scroll(props, children)
    return Create.Instance("ScrollingFrame", props, children)
end

function Create.Corner(radius)
    return Create.Instance("UICorner", {
        CornerRadius = typeof(radius) == "number" and UDim.new(0, radius) or radius
    })
end

function Create.Stroke(props)
    return Create.Instance("UIStroke", props)
end

function Create.Padding(top, right, bottom, left)
    return Create.Instance("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft = UDim.new(0, left or right or top or 0),
    })
end

function Create.List(props)
    local default = {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
    }
    for k, v in pairs(props or {}) do
        default[k] = v
    end
    return Create.Instance("UIListLayout", default)
end

function Create.Grid(props)
    local default = {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = UDim2.new(0, 6, 0, 6),
    }
    for k, v in pairs(props or {}) do
        default[k] = v
    end
    return Create.Instance("UIGridLayout", default)
end

return Create