-- PVP系统加载脚本
-- 若在服务器环境运行：直接加载 PVP 模块
-- 若在 Test Client 环境运行：满足 OnPreSpawn/OnSpawn 规范，可复用同一份脚本
-- ============================================

local modulesLoaded = false

local function logLine(msg)
    if _G.tc and tc.log then
        tc.log(msg)
    else
        print(msg)
    end
end

local function loadPvpModules()
    if modulesLoaded then
        logLine("[LoadPVP] modules already loaded, skip")
        return true
    end

    logLine("[LoadPVP] start")
    logLine("========================================")
    logLine("Loading PVP System...")
    logLine("========================================")

    -- 加载决斗命令系统
    local success0, err0 = pcall(function()
        dofile('data/server/TestServer/scripts/DuelCommands.lua')
        logLine("[OK] Duel Commands loaded")
    end)
    if not success0 then
        logLine("[WARNING] Failed to load Duel Commands:")
        logLine(tostring(err0))
        logLine("(Duel commands may not be available)")
    end

    local success1, err1 = pcall(function()
        require("PVP.ServerPVP")
        logLine("[OK] ServerPVP core module loaded")
    end)
    
    if not success1 then
        logLine("[ERROR] Failed to load ServerPVP core:")
        logLine(tostring(err1))
        return false
    end
    
    local success2, err2 = pcall(function()
        require("PVP.ServerCommands")
        logLine("[OK] ServerPVP Commands loaded")
    end)
    
    if not success2 then
        logLine("[ERROR] Failed to load ServerPVP Commands:")
        logLine(tostring(err2))
        return false
    end
    
    -- 加载聊天处理器
    local success5, err5 = pcall(function()
        require("PVP.ChatHandler")
        logLine("[OK] PVP ChatHandler loaded")
    end)
    
    if not success5 then
        logLine("[WARNING] Failed to load PVP ChatHandler:")
        logLine(tostring(err5))
        logLine("(Commands may need to be registered manually)")
    end
    
    -- 兼容旧版本（可选）
    local success3, err3 = pcall(function()
        require("PVP.GMCommands")
        logLine("[OK] Legacy GMCommands loaded (optional)")
    end)
    
    if not success3 then
        logLine("[INFO] Legacy GMCommands not loaded (optional, can ignore)")
    end

    -- 地图自动PVP（可选）
    local success4, err4 = pcall(function()
        require("PVP.MapAutoPVP")
        logLine("[OK] Map Auto PVP loaded")
    end)

    if not success4 then
        logLine("[WARNING] Failed to load Map Auto PVP:")
        logLine(tostring(err4))
        logLine("(This is optional, you can ignore this if not needed)")
    end

    logLine("========================================")
    logLine("PVP System loaded successfully!")
    logLine("========================================")

    modulesLoaded = true
    return true
end

-- ============================
-- Test Client 兼容入口
-- ============================

function OnPreSpawn()
    if tc and tc.log then
        tc.log("[LoadPVP] OnPreSpawn - preparing test client")
    end
end

function OnSpawn()
    if tc and tc.log then
        tc.log("[LoadPVP] OnSpawn - attempting to load modules")
    end
    local ok, err = pcall(loadPvpModules)
    if not ok then
        logLine("[LoadPVP] OnSpawn error: " .. tostring(err))
    end
end

-- 默认在服务器/独立 Lua 环境下立即加载
if not _G.tc then
    logLine("========================================")
    logLine("LoadPVP.lua: Auto-loading PVP modules...")
    logLine("========================================")
    local ok, err = pcall(loadPvpModules)
    if not ok then
        logLine("[LoadPVP] ERROR during auto-load:")
        logLine(tostring(err))
        logLine("========================================")
    end
end

