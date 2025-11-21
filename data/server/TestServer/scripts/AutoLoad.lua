-- ============================================
-- 自动加载脚本
-- Auto Load Script
-- ============================================
-- 功能：自动加载LoadPVP.lua
-- ============================================

local function log(msg)
    print("[AutoLoad] " .. tostring(msg))
end

-- ============================================
-- 自动加载LoadPVP
-- ============================================
if not _G.tc then
    log("========================================")
    log("AutoLoad.lua: Auto-loading LoadPVP.lua...")
    log("========================================")
    
    local success, err = pcall(function()
        dofile('data/server/TestServer/scripts/LoadPVP.lua')
    end)
    
    if success then
        log("LoadPVP.lua loaded successfully")
    else
        log("ERROR: Failed to load LoadPVP.lua")
        log("Error: " .. tostring(err))
    end
    
    log("========================================")
end

