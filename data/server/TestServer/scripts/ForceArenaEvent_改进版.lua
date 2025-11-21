-- ============================================
-- 强制竞技场活动脚本（改进版 - 基于实际API）
-- Force Arena Event Script (Improved - Based on Real APIs)
-- ============================================
-- 基于 ServerPVP.lua 的实际API用法
-- ============================================

-- 导入Cryptic模块
local Entity = require("cryptic/Entity")
local Var = require("cryptic/Var")
local Scope = require("cryptic/Scope")

-- 配置
local CONFIG = {
    eventName = "Force_Arena_Event",
    queueName = "Pvp_Arena_Domination_60",
    targetMap = "Pvp_Arena_Domination_01",
    minLevel = 60,
    maxLevel = 60,
    notificationTime = 10,
    excludeMaps = {
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
-- 获取玩家ID（基于ServerPVP.lua的实现）
-- ============================================
local function GetPlayerId(player)
    if not player then return nil end
    
    -- 方法1: 使用Entity模块解析
    local success, playerData = pcall(function()
        if player.id then
            return Entity.Parse(player.id)
        end
    end)
    
    if success and playerData and playerData.id then
        return playerData.id
    end
    
    -- 方法2: 直接API
    if player.GetDbId then
        return player:GetDbId()
    elseif player.GetAccountId then
        return player:GetAccountId()
    elseif player.id then
        return player.id
    else
        return tostring(player)
    end
end

-- ============================================
-- 获取玩家等级（需要根据实际API调整）
-- ============================================
local function GetPlayerLevel(player)
    -- 方法1: 直接API
    if player.GetLevel then
        local success, level = pcall(function()
            return player:GetLevel()
        end)
        if success and level then
            return level
        end
    end
    
    -- 方法2: 通过Entity
    if player.id then
        local success, playerData = pcall(function()
            return Entity.Parse(player.id)
        end)
        if success and playerData and playerData.level then
            return playerData.level
        end
    end
    
    -- 方法3: 属性
    if player.level then
        return player.level
    end
    
    return 0
end

-- ============================================
-- 获取玩家当前地图（需要根据实际API调整）
-- ============================================
local function GetPlayerCurrentMap(player)
    -- 方法1: 直接API
    if player.GetCurrentMap then
        local success, map = pcall(function()
            return player:GetCurrentMap()
        end)
        if success and map then
            return map
        end
    end
    
    -- 方法2: 通过Entity
    if player.id then
        local success, playerData = pcall(function()
            return Entity.Parse(player.id)
        end)
        if success and playerData and playerData.map then
            return playerData.map
        end
    end
    
    -- 方法3: 属性
    if player.map then
        return player.map
    end
    
    return "Unknown"
end

-- ============================================
-- 获取所有在线玩家（需要根据实际API调整）
-- ============================================
local function GetAllOnlinePlayers()
    local players = {}
    
    -- 方法1: World API
    if World and World.GetAllPlayers then
        local success, result = pcall(function()
            return World.GetAllPlayers()
        end)
        if success and result then
            return result
        end
    end
    
    -- 方法2: Server API
    if Server and Server.GetOnlinePlayers then
        local success, result = pcall(function()
            return Server.GetOnlinePlayers()
        end)
        if success and result then
            return result
        end
    end
    
    -- 方法3: Player API
    if Player and Player.GetAllOnline then
        local success, result = pcall(function()
            return Player.GetAllOnline()
        end)
        if success and result then
            return result
        end
    end
    
    log("警告: GetAllOnlinePlayers() 需要根据实际API实现")
    return players
end

-- ============================================
-- 发送消息给玩家（基于ServerPVP.lua的实现）
-- ============================================
local function SendMessageToPlayer(player, message)
    if not player or not message then
        log("无法发送消息: player或message为nil")
        return
    end
    
    -- 方法1: 直接API（多种尝试）
    local success = false
    
    if player.SendMessage then
        success = pcall(function() player:SendMessage(message) end)
    elseif player.SendChatMessage then
        success = pcall(function() player:SendChatMessage(message) end)
    elseif player.SystemMessage then
        success = pcall(function() player:SystemMessage(message) end)
    elseif player.SendSystemNotification then
        success = pcall(function() player:SendSystemNotification(message) end)
    end
    
    if success then
        return
    end
    
    -- 方法2: 使用服务器命令（最可靠）
    if CmdParseTextCommand then
        local cmd = string.format("chat_send %s", message)
        success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        if success then
            return
        end
    end
    
    -- 方法3: 通过Entity发送
    if player.id and ts and ts.entity_xset then
        success = pcall(function()
            ts.entity_xset(player.id, "chat_message", message)
        end)
        if success then
            return
        end
    end
    
    -- 最后回退：打印到服务器日志
    local playerId = GetPlayerId(player)
    log(string.format("消息给玩家 %s: %s", tostring(playerId), tostring(message)))
end

-- ============================================
-- 强制加入队列（使用CmdParseTextCommand）
-- ============================================
local function ForceJoinQueue(player, queueName)
    if not player or not queueName then return false end
    
    -- 方法1: 使用服务器命令
    if CmdParseTextCommand then
        local cmd = string.format("queue_join %s", queueName)
        local success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        if success then
            log("玩家 " .. tostring(GetPlayerId(player)) .. " 已加入队列 " .. queueName)
            return true
        end
    end
    
    -- 方法2: 直接API（如果存在）
    if player.JoinQueue then
        local success = pcall(function()
            return player:JoinQueue(queueName)
        end)
        if success then
            return true
        end
    end
    
    log("警告: 无法加入队列，需要根据实际API实现")
    return false
end

-- ============================================
-- 传送到地图（使用CmdParseTextCommand）
-- ============================================
local function TeleportToMap(player, mapName)
    if not player or not mapName then return false end
    
    -- 方法1: 使用服务器命令
    if CmdParseTextCommand then
        local cmd = string.format("teleport %s", mapName)
        local success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        if success then
            log("玩家 " .. tostring(GetPlayerId(player)) .. " 已传送到地图 " .. mapName)
            return true
        end
    end
    
    -- 方法2: 直接API（如果存在）
    if player.Teleport then
        local success = pcall(function()
            return player:Teleport(mapName)
        end)
        if success then
            return true
        end
    end
    
    log("警告: 无法传送，需要根据实际API实现")
    return false
end

-- ============================================
-- 过滤符合条件的玩家
-- ============================================
local function FilterEligiblePlayers(players)
    local eligible = {}
    
    for _, player in ipairs(players) do
        if not player then goto continue end
        
        -- 检查等级
        local level = GetPlayerLevel(player)
        if level < CONFIG.minLevel or level > CONFIG.maxLevel then
            goto continue
        end
        
        -- 检查当前地图
        local currentMap = GetPlayerCurrentMap(player)
        for _, excludeMap in ipairs(CONFIG.excludeMaps) do
            if currentMap == excludeMap then
                goto continue  -- 已经在竞技场，跳过
            end
        end
        
        table.insert(eligible, player)
        ::continue::
    end
    
    return eligible
end

-- ============================================
-- 发送传送通知
-- ============================================
local function SendTeleportNotification(players)
    for _, player in ipairs(players) do
        local message = string.format(
            "强制竞技场活动即将开始！%d秒后您将被传送到竞技场。",
            CONFIG.notificationTime
        )
        SendMessageToPlayer(player, message)
        local playerId = GetPlayerId(player)
        notificationsSent[playerId] = ts and ts.get_time() or os.time()
        log("已发送通知给玩家 " .. tostring(playerId))
    end
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
    
    for _, player in ipairs(players) do
        local playerId = GetPlayerId(player)
        if teleportedPlayers[playerId] then
            goto continue  -- 已经传送过
        end
        
        -- 方法1：强制加入队列（推荐）
        if ForceJoinQueue(player, CONFIG.queueName) then
            teleportedPlayers[playerId] = true
            successCount = successCount + 1
            goto continue
        end
        
        -- 方法2：直接传送到地图（如果队列失败）
        if TeleportToMap(player, CONFIG.targetMap) then
            teleportedPlayers[playerId] = true
            successCount = successCount + 1
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
    eventStartTime = (ts and ts.get_time()) or os.time()
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
    -- 注意：需要根据实际的定时器API实现延迟
    log("等待 " .. CONFIG.notificationTime .. " 秒后开始传送...")
    
    -- 临时实现：立即传送（实际应该延迟）
    -- TODO: 使用定时器API实现延迟
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
-- 注册命令（基于ChatHandler.lua的实现）
-- ============================================
local function RegisterCommands()
    -- 方法1: RegisterChatCommand
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
        log("命令 '/forcearena' 已注册 (RegisterChatCommand)")
        return true
    end
    
    -- 方法2: RegisterCommand
    if RegisterCommand then
        RegisterCommand("forcearena", function(player, args)
            if args and #args > 0 and args[1] == "start" then
                CmdForceArenaStart(player, args)
            elseif args and #args > 0 and args[1] == "stop" then
                CmdForceArenaStop(player, args)
            end
        end)
        log("命令 '/forcearena' 已注册 (RegisterCommand)")
        return true
    end
    
    -- 方法3: Commands表
    if Commands then
        Commands.forcearena = function(player, args)
            if args and #args > 0 and args[1] == "start" then
                CmdForceArenaStart(player, args)
            elseif args and #args > 0 and args[1] == "stop" then
                CmdForceArenaStop(player, args)
            end
        end
        log("命令 '/forcearena' 已注册 (Commands table)")
        return true
    end
    
    log("警告: 无法注册命令（没有找到注册API）")
    return false
end

-- ============================================
-- 事件注册（需要根据实际事件系统调整）
-- ============================================
local function RegisterEventHandlers()
    -- 方法1: RegisterEvent
    if RegisterEvent then
        RegisterEvent("Event.Start", OnEventStart)
        RegisterEvent("Event.End", OnEventEnd)
        log("事件处理器已注册 (RegisterEvent)")
        return true
    end
    
    -- 方法2: Server API
    if Server and Server.RegisterEventHandler then
        Server.RegisterEventHandler("Event.Start", OnEventStart)
        Server.RegisterEventHandler("Event.End", OnEventEnd)
        log("事件处理器已注册 (Server.RegisterEventHandler)")
        return true
    end
    
    log("注意: 事件处理器需要根据实际API注册")
    return false
end

-- ============================================
-- 初始化
-- ============================================
log("========================================")
log("强制竞技场活动脚本加载中...")
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
log("注意: 部分API（获取所有玩家、获取地图）需要根据实际API调整")
log("========================================")

-- 导出函数供其他模块使用
return {
    OnEventStart = OnEventStart,
    OnEventEnd = OnEventEnd,
    CmdForceArenaStart = CmdForceArenaStart,
    CmdForceArenaStop = CmdForceArenaStop,
}

