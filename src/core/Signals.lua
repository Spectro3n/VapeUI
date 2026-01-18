--[[
    VapeUI Signal System
    Lightweight event system for component communication.
]]

local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal)
    self._connections = {}
    self._fired = false
    self._lastArgs = nil
    return self
end

function Signal:Connect(callback)
    local connection = {
        Callback = callback,
        Connected = true,
    }
    
    function connection:Disconnect()
        self.Connected = false
    end
    
    table.insert(self._connections, connection)
    return connection
end

function Signal:Once(callback)
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        callback(...)
    end)
    return connection
end

function Signal:Fire(...)
    self._fired = true
    self._lastArgs = {...}
    
    for i = #self._connections, 1, -1 do
        local connection = self._connections[i]
        if connection.Connected then
            task.spawn(connection.Callback, ...)
        else
            table.remove(self._connections, i)
        end
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect()
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:DisconnectAll()
    for _, connection in ipairs(self._connections) do
        connection.Connected = false
    end
    self._connections = {}
end

function Signal:Destroy()
    self:DisconnectAll()
    setmetatable(self, nil)
end

return Signal