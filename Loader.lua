--[[
    ██╗   ██╗ █████╗ ██████╗ ███████╗██╗   ██╗██╗
    ██║   ██║██╔══██╗██╔══██╗██╔════╝██║   ██║██║
    ██║   ██║███████║██████╔╝█████╗  ██║   ██║██║
    ╚██╗ ██╔╝██╔══██║██╔═══╝ ██╔══╝  ██║   ██║██║
     ╚████╔╝ ██║  ██║██║     ███████╗╚██████╔╝██║
      ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝
    
    VapeUI v2.0.0 | Professional UI Framework for Roblox
    
    Usage:
    local VapeUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/VapeUI/main/Loader.lua"))()
]]

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════

local REPO_BASE = "https://raw.githubusercontent.com/Spectro3n/VapeUI/main/src/"
local VERSION = "2.0.0"
local DEBUG_MODE = false

-- ═══════════════════════════════════════════════════════════════════
-- MODULE CACHE
-- ═══════════════════════════════════════════════════════════════════

local VapeUICache = {}
local LoadedModules = {}
local LoadingModules = {}

-- ═══════════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════

local function Log(level, message)
    if DEBUG_MODE or level == "ERROR" or level == "SUCCESS" then
        local prefix = ({
            INFO = "📦",
            SUCCESS = "✅",
            ERROR = "❌",
            WARN = "⚠️",
            LOADING = "⏳"
        })[level] or "📝"
        
        print(string.format("[VapeUI] %s %s", prefix, message))
    end
end

local function NormalizePath(path)
    path = path:gsub("\\", "/")
    path = path:gsub("^%./", "")
    path = path:gsub("//+", "/")
    
    if not path:match("%.lua$") then
        path = path .. ".lua"
    end
    
    return path
end

local function FetchModule(url, retries)
    retries = retries or 3
    local lastError = "Unknown error"
    
    for attempt = 1, retries do
        local success, result = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if success and type(result) == "string" and #result > 0 then
            if not result:match("^404") and not result:match("Not Found") then
                return result, nil
            end
        end
        
        lastError = tostring(result)
        
        if attempt < retries then
            task.wait(0.2 * attempt)
        end
    end
    
    return nil, lastError
end

-- ═══════════════════════════════════════════════════════════════════
-- MODULE LOADER
-- ═══════════════════════════════════════════════════════════════════

local function VapeRequire(path)
    path = NormalizePath(path)
    
    -- Already loaded
    if LoadedModules[path] then
        return LoadedModules[path]
    end
    
    -- Circular dependency protection
    if LoadingModules[path] then
        Log("WARN", "Circular dependency detected: " .. path)
        return LoadingModules[path]
    end
    
    -- Mark as loading
    LoadingModules[path] = {}
    
    local url = REPO_BASE .. path
    Log("LOADING", "Loading: " .. path)
    
    local code, fetchError = FetchModule(url)
    
    if not code then
        LoadingModules[path] = nil
        Log("ERROR", "Failed to fetch " .. path .. ": " .. tostring(fetchError))
        error("[VapeUI] Failed to load module: " .. path)
    end
    
    -- Compile module
    local moduleFunc, compileError = loadstring(code, "@VapeUI/" .. path)
    
    if not moduleFunc then
        LoadingModules[path] = nil
        Log("ERROR", "Compile error in " .. path .. ": " .. tostring(compileError))
        error("[VapeUI] Compile error: " .. path)
    end
    
    -- Create module environment
    local moduleEnv = setmetatable({
        require = VapeRequire,
        script = {
            Parent = { Parent = {} }
        },
        _VERSION = VERSION,
    }, { __index = getfenv(0) })
    
    setfenv(moduleFunc, moduleEnv)
    
    -- Execute module
    local success, result = pcall(moduleFunc)
    
    if not success then
        LoadingModules[path] = nil
        Log("ERROR", "Runtime error in " .. path .. ": " .. tostring(result))
        error("[VapeUI] Runtime error: " .. path)
    end
    
    -- Store result
    local moduleExports = result or LoadingModules[path]
    LoadedModules[path] = moduleExports
    LoadingModules[path] = nil
    
    Log("SUCCESS", "Loaded: " .. path)
    
    return moduleExports
end

-- ═══════════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════

print([[
██╗   ██╗ █████╗ ██████╗ ███████╗██╗   ██╗██╗
██║   ██║██╔══██╗██╔══██╗██╔════╝██║   ██║██║
██║   ██║███████║██████╔╝█████╗  ██║   ██║██║
╚██╗ ██╔╝██╔══██║██╔═══╝ ██╔══╝  ██║   ██║██║
 ╚████╔╝ ██║  ██║██║     ███████╗╚██████╔╝██║
  ╚═══╝  ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝
]])
print("[VapeUI] Version " .. VERSION)
print("[VapeUI] Loading framework...")

-- Load main module
local VapeUI = VapeRequire("Init.lua")

-- Expose loader
VapeUI._Require = VapeRequire
VapeUI._LoadedModules = LoadedModules
VapeUI._Version = VERSION

print("[VapeUI] ✅ Framework loaded successfully!")

return VapeUI