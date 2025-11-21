-- ============================================
-- 强制竞技场活动脚本
-- Force Arena Event Script
-- ============================================
-- 功能：
-- - 监听活动开始事件
-- - 强制将所有符合条件的玩家传送到竞技场
-- - 自动加入PVP队列
-- ============================================

-- 配置
local CONFIG = {
    eventName = "Force_Arena_Event",  -- 事件名称（与Events文件中的名称对应）
    queueName = "Pvp_Arena_Domination_60",  -- 队列名称
    targetMap = "Pvp_Arena_Domination_01",  -- 目标地图
    minLevel = 60,  -- 最低等级
    maxLevel = 60,  -- 最高等级
    notificationTime = 10,  -- 通知时间（秒）
    excludeMaps = {  -- 排除的地图
        "Pvp_Arena_Domination_01",
        "Pvp_Arena_Domination_03",
    }
}

-- 状态
local eventActive = false
local eventStartTime = 0
local teleportedPlayers = {}  -- 已传送的玩家ID集合
local notificationsSent = {}  -- 已发送通知的玩家

-- 日志函数
local function log(msg)
    print("[ForceArenaEvent] " .. tostring(msg))
end

-- ============================================
-- 获取所有在线玩家
-- ============================================
local function GetAllOnlinePlayers()
    -- 注意：需要根据实际的服务器API调整
    -- 这里提供几种可能的实现方式
    
    -- 方法1：通过World API（需要确认）
    -- local players = World.GetAllPlayers()
    -- return players or {}
    
    -- 方法2：通过Server API（需要确认）
    -- local players = Server.GetOnlinePlayers()
    -- return players or {}
    
    -- 方法3：通过Player API（需要确认）
    -- local players = Player.GetAllOnline()
    -- return players or {}
    
    -- 临时实现：返回空表（需要根据实际API调整）
    log("警告: GetAllOnlinePlayers() 需要根据实际API实现")
    return {}
end

-- ============================================
-- 获取玩家当前地图
-- ============================================
local function GetPlayerCurrentMap(playerId)
    -- 注意：需要根据实际的服务器API调整
    
    -- 方法1：通过World API
    -- return World.GetMapName(playerId)
    
    -- 方法2：通过Player API
    -- return Player.GetCurrentMap(playerId)
    
    -- 方法3：通过Entity API
    -- local Entity = require("cryptic/Entity")
    -- return Entity.GetMap(playerId)
    
    -- 临时实现
    log("警告: GetPlayerCurrentMap() 需要根据实际API实现")
    return "Unknown"
end

-- ============================================
-- 检查玩家是否处于排除状态
-- ============================================
local function IsPlayerInExcludedState(playerId)
    -- 检查是否在副本中
    -- if World.IsInDungeon(playerId) then return true end
    
    -- 检查是否在过场动画中
    -- if Player.IsInCutscene(playerId) then return true end
    
    -- 检查是否在对话中
    -- if Player.IsInDialog(playerId) then return true end
    
    return false
end

-- ============================================
-- 过滤符合条件的玩家
-- ============================================
local function FilterEligiblePlayers(players)
    local eligible = {}
    
    for _, playerId in ipairs(players) do
        -- 检查等级
        local level = Player.GetLevel(playerId) or 0
        if level < CONFIG.minLevel or level > CONFIG.maxLevel then
            goto continue
        end
        
        -- 检查当前地图
        local currentMap = GetPlayerCurrentMap(playerId)
        for _, excludeMap in ipairs(CONFIG.excludeMaps) do
            if currentMap == excludeMap then
                goto continue  -- 已经在竞技场，跳过
            end
        end
        
        -- 检查玩家状态
        if IsPlayerInExcludedState(playerId) then
            goto continue
        end
        
        table.insert(eligible, playerId)
        ::continue::
    end
    
    return eligible
end

-- ============================================
-- 发送消息给玩家
-- ============================================
local function SendMessageToPlayer(playerId, message)
    -- 注意：需要根据实际的服务器API调整
    
    -- 方法1：通过Chat API
    -- Chat.SendToPlayer(playerId, message)
    
    -- 方法2：通过Player API
    -- Player.SendMessage(playerId, message)
    
    -- 方法3：通过GM命令
    -- CmdParseTextCommand("chat_send " .. playerId .. " " .. message)
    
    log("消息给玩家 " .. tostring(playerId) .. ": " .. message)
end

-- ============================================
-- 发送传送通知
-- ============================================
local function SendTeleportNotification(players)
    for _, playerId in ipairs(players) do
        local message = string.format(
            "强制竞技场活动即将开始！%d秒后您将被传送到竞技场。",
            CONFIG.notificationTime
        )
        SendMessageToPlayer(playerId, message)
        notificationsSent[playerId] = os.time()
        log("已发送通知给玩家 " .. tostring(playerId))
    end
end

-- ============================================
-- 强制加入队列
-- ============================================
local function ForceJoinQueue(playerId)
    -- 注意：需要根据实际的服务器API调整
    
    -- 方法1：通过Queue API
    -- return Queue.JoinQueue(playerId, CONFIG.queueName)
    
    -- 方法2：通过Player API
    -- return Player.JoinQueue(playerId, CONFIG.queueName)
    
    -- 方法3：通过GM命令
    -- CmdParseTextCommand("queue_join " .. CONFIG.queueName)
    
    log("尝试将玩家 " .. tostring(playerId) .. " 加入队列 " .. CONFIG.queueName)
    return true  -- 临时返回成功
end

-- ============================================
-- 传送到地图
-- ============================================
local function TeleportToMap(playerId)
    -- 注意：需要根据实际的服务器API调整
    
    -- 方法1：通过World API
    -- return World.TeleportPlayer(playerId, CONFIG.targetMap)
    
    -- 方法2：通过Player API
    -- return Player.Teleport(playerId, CONFIG.targetMap)
    
    -- 方法3：通过GM命令
    -- CmdParseTextCommand("teleport " .. CONFIG.targetMap)
    
    log("尝试将玩家 " .. tostring(playerId) .. " 传送到地图 " .. CONFIG.targetMap)
    return true  -- 临时返回成功
end

-- ============================================
-- 传送玩家到竞技场
-- ============================================
local function TeleportPlayersToArena(players)
    log("========================================")
    log("开始传送玩家到竞技场...")
    log("========================================")
    
    local successCount = 0
    local failCount = 0
    
    for _, playerId in ipairs(players) do
        if teleportedPlayers[playerId] then
            goto continue  -- 已经传送过
        end
        
        -- 方法1：强制加入队列（推荐）
        if ForceJoinQueue(playerId) then
            teleportedPlayers[playerId] = true
            successCount = successCount + 1
            log("玩家 " .. tostring(playerId) .. " 已加入队列")
            goto continue
        end
        
        -- 方法2：直接传送到地图（如果队列失败）
        if TeleportToMap(playerId) then
            teleportedPlayers[playerId] = true
            successCount = successCount + 1
            log("玩家 " .. tostring(playerId) .. " 已传送到竞技场")
        else
            failCount = failCount + 1
            log("传送玩家 " .. tostring(playerId) .. " 失败")
        end
        
        ::continue::
    end
    
    log("========================================")
    log(string.format("传送完成: 成功 %d, 失败 %d", successCount, failCount))
    log("========================================")
end

-- ============================================
-- 活动开始事件处理
-- ============================================
local function OnEventStart(eventName)
    if eventName ~= CONFIG.eventName then
        return
    end
    
    log("========================================")
    log("强制竞技场活动开始: " .. eventName)
    log("========================================")
    
    eventActive = true
    eventStartTime = os.time()
    teleportedPlayers = {}
    notificationsSent = {}
    
    -- 获取所有在线玩家
    local allPlayers = GetAllOnlinePlayers()
    
    -- 过滤符合条件的玩家
    local eligiblePlayers = FilterEligiblePlayers(allPlayers)
    
    log("找到 " .. #eligiblePlayers .. " 个符合条件的玩家")
    
    if #eligiblePlayers == 0 then
        log("没有符合条件的玩家")
        return
    end
    
    -- 发送通知
    SendTeleportNotification(eligiblePlayers)
    
    -- 延迟传送（给玩家时间准备）
    -- 注意：需要根据实际的定时器API调整
    -- 这里使用简单的延迟（实际应该使用定时器）
    log("等待 " .. CONFIG.notificationTime .. " 秒后开始传送...")
    
    -- 临时实现：立即传送（实际应该延迟）
    -- 需要根据实际的定时器API实现延迟
    TeleportPlayersToArena(eligiblePlayers)
end

-- ============================================
-- 活动结束事件处理
-- ============================================
local function OnEventEnd(eventName)
    if eventName ~= CONFIG.eventName then
        return
    end
    
    log("========================================")
    log("强制竞技场活动结束: " .. eventName)
    log("========================================")
    
    eventActive = false
    teleportedPlayers = {}
    notificationsSent = {}
end

-- ============================================
-- GM命令支持
-- ============================================
local function CmdForceArenaStart(player, args)
    log("手动触发强制竞技场活动")
    OnEventStart(CONFIG.eventName)
    return true
end

local function CmdForceArenaStop(player, args)
    log("手动停止强制竞技场活动")
    OnEventEnd(CONFIG.eventName)
    return true
end

-- ============================================
-- 注册命令（如果API可用）
-- ============================================
local function RegisterCommands()
    -- 根据服务器API调整
    if RegisterChatCommand then
        RegisterChatCommand("forcearena", function(player, args)
            if args and #args > 0 and args[1] == "start" then
                CmdForceArenaStart(player, args)
            elseif args and #args > 0 and args[1] == "stop" then
                CmdForceArenaStop(player, args)
            else
                SendMessageToPlayer(player, "用法: /forcearena start|stop")
            end
        end)
        log("命令 '/forcearena' 已注册")
    else
        log("警告: 无法注册命令（RegisterChatCommand 不可用）")
    end
end

-- ============================================
-- 事件注册（需要根据实际事件系统调整）
-- ============================================
local function RegisterEventHandlers()
    -- 注意：需要根据实际的事件系统API调整
    
    -- 方法1：通过Events API
    -- Events.Register("Event.Start", OnEventStart)
    -- Events.Register("Event.End", OnEventEnd)
    
    -- 方法2：通过Server API
    -- Server.RegisterEventHandler("Event.Start", OnEventStart)
    -- Server.RegisterEventHandler("Event.End", OnEventEnd)
    
    log("注意: 事件处理器需要根据实际API注册")
end

-- ============================================
-- 初始化函数
-- ============================================
local function Initialize()
    log("========================================")
    log("强制竞技场活动脚本初始化中...")
    log("========================================")
    
    -- 注册命令
    RegisterCommands()
    
    -- 注册事件处理器
    RegisterEventHandlers()
    
    log("========================================")
    log("强制竞技场活动脚本已加载")
    log("========================================")
    log("")
    log("使用方法:")
    log("1. 自动触发: 当 Force_Arena_Event 活动开始时自动执行")
    log("2. 手动触发: /forcearena start")
    log("3. 手动停止: /forcearena stop")
    log("")
    log("注意: 部分API需要根据实际服务器API调整")
    log("========================================")
end

-- ============================================
-- Test Client 兼容入口
-- ============================================
function OnPreSpawn()
    if tc and tc.log then
        tc.log("[ForceArenaEvent] OnPreSpawn - preparing test client")
    end
end

function OnSpawn()
    if tc and tc.log then
        tc.log("[ForceArenaEvent] OnSpawn - attempting to initialize")
    end
    local ok, err = pcall(Initialize)
    if not ok then
        log("[ForceArenaEvent] OnSpawn error: " .. tostring(err))
    end
end

-- ============================================
-- 自动执行（服务器环境）
-- ============================================
-- ⭐ 关键：如果不是TestClient环境，立即执行初始化
-- 当通过 -scriptName 参数加载时，_G.tc 为 nil，会立即执行
if not _G.tc then
    log("========================================")
    log("ForceArenaEvent.lua: Auto-loading...")
    log("========================================")
    local ok, err = pcall(Initialize)
    if not ok then
        log("[ForceArenaEvent] ERROR during auto-load:")
        log(tostring(err))
        log("========================================")
    end
end

-- ============================================
-- 自动加载决斗命令系统
-- ============================================
if not _G.tc then
    log("========================================")
    log("ForceArenaEvent: Auto-loading Duel Commands...")
    log("========================================")
    local success, err = pcall(function()
        dofile('data/server/TestServer/scripts/DuelCommands.lua')
    end)
    if success then
        log("[ForceArenaEvent] Duel Commands loaded successfully")
    else
        log("[ForceArenaEvent] WARNING: Failed to load Duel Commands")
        log("[ForceArenaEvent] Error: " .. tostring(err))
    end
end

-- 导出函数供其他模块使用
return {
    OnEventStart = OnEventStart,
    OnEventEnd = OnEventEnd,
    CmdForceArenaStart = CmdForceArenaStart,
    CmdForceArenaStop = CmdForceArenaStop,
    Initialize = Initialize,
}
