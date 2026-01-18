--[[
    VapeUI Services
    Cached game services for performance.
]]

local Services = {}

-- Cache interno
local _cache = {
    TweenService = game:GetService("TweenService"),
    UserInputService = game:GetService("UserInputService"),
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Lighting = game:GetService("Lighting"),
    CoreGui = game:GetService("CoreGui"),
    TextService = game:GetService("TextService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),  -- ⬅️ ADICIONADO
}

-- Método Get() que faltava
function Services:Get(name)
    if not _cache[name] then
        _cache[name] = game:GetService(name)
    end
    return _cache[name]
end

-- Acesso direto também funciona
setmetatable(Services, {
    __index = function(_, key)
        return Services:Get(key)
    end
})

-- Player reference
Services.LocalPlayer = _cache.Players.LocalPlayer
Services.Mouse = Services.LocalPlayer:GetMouse()

-- Camera reference
Services.Camera = workspace.CurrentCamera

return Services