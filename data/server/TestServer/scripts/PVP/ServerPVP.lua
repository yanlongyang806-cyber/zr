-- ============================================
-- 服务端PVP系统 - 完整实现（集成Cryptic模块）
-- Server-Side PVP System - Complete Implementation (with Cryptic Modules)
-- ============================================
-- 功能：
-- - 命令注册和处理
-- - 玩家阵营管理
-- - PVP状态跟踪（持久化）
-- - 事件处理
-- ============================================

-- 导入Cryptic模块
local Entity = require("cryptic/Entity")
local Var = require("cryptic/Var")
local Scope = require("cryptic/Scope")

local ServerPVP = {}

-- ============================================
-- 配置
-- ============================================
ServerPVP.CONFIG = {
    -- 友好阵营（默认）
    FRIENDLY_FACTION = "UnalignedFriendlies",
    
    -- PVP阵营选项
    PVP_FACTIONS = {
        "PlayerFullPvP",    -- 全地图PVP（推荐）
        "FreeForAll",       -- 自由混战
        "OpenPvp_Red",      -- 红队
        "OpenPvp_Blue",     -- 蓝队
        "PlayerPvP",        -- 标准PVP
    },
    
    -- 默认PVP阵营
    DEFAULT_PVP_FACTION = "PlayerFullPvP",
    
    -- 冷却时间（秒）
    COOLDOWN_TIME = 5,
    
    -- 消息
    MSG_PVP_ON = "【PVP已开启】阵营: %s",
    MSG_PVP_OFF = "【PVP已关闭】已恢复友好状态",
    MSG_ALREADY_ON = "你已经处于PVP状态！",
    MSG_ALREADY_OFF = "你已经处于非PVP状态！",
    MSG_IN_COMBAT = "战斗中无法切换PVP状态！",
    MSG_COOLDOWN = "切换冷却中，请稍后再试... (%d秒)",
    MSG_INVALID_FACTION = "无效的阵营名称！可用阵营: %s",
}

-- ============================================
-- 数据存储（使用Var模块持久化）
-- ============================================
-- 注意：playerStates和cooldowns现在通过Var模块持久化存储
-- 作用域格式：PlayerPVP_[playerId]

-- ============================================
-- 核心函数：启用PVP
-- ============================================
function ServerPVP.EnablePVP(player, faction)
    if not player then
        return false, "玩家对象无效"
    end
    
    local playerId = ServerPVP.GetPlayerId(player)
    faction = faction or ServerPVP.CONFIG.DEFAULT_PVP_FACTION
    
    -- 验证阵营
    local validFaction = false
    for _, f in ipairs(ServerPVP.CONFIG.PVP_FACTIONS) do
        if f == faction then
            validFaction = true
            break
        end
    end
    
    if not validFaction then
        local factionsList = table.concat(ServerPVP.CONFIG.PVP_FACTIONS, ", ")
        return false, string.format(ServerPVP.CONFIG.MSG_INVALID_FACTION, factionsList)
    end
    
    -- 检查冷却
    if ServerPVP.IsOnCooldown(playerId) then
        local remaining = ServerPVP.GetCooldownRemaining(playerId)
        return false, string.format(ServerPVP.CONFIG.MSG_COOLDOWN, remaining)
    end
    
    -- 检查战斗状态
    if ServerPVP.IsInCombat(player) then
        return false, ServerPVP.CONFIG.MSG_IN_COMBAT
    end
    
    -- 设置阵营
    local success = ServerPVP.SetPlayerFaction(player, faction)
    if success then
        ServerPVP.SetCooldown(playerId)
        
        ServerPVP.SendMessage(player, string.format(ServerPVP.CONFIG.MSG_PVP_ON, faction))
        return true, "PVP已启用"
    else
        return false, "设置阵营失败"
    end
end

-- ============================================
-- 核心函数：禁用PVP
-- ============================================
function ServerPVP.DisablePVP(player)
    if not player then
        return false, "玩家对象无效"
    end
    
    local playerId = ServerPVP.GetPlayerId(player)
    
    -- 检查冷却
    if ServerPVP.IsOnCooldown(playerId) then
        local remaining = ServerPVP.GetCooldownRemaining(playerId)
        return false, string.format(ServerPVP.CONFIG.MSG_COOLDOWN, remaining)
    end
    
    -- 检查战斗状态
    if ServerPVP.IsInCombat(player) then
        return false, ServerPVP.CONFIG.MSG_IN_COMBAT
    end
    
    -- 设置阵营
    local success = ServerPVP.SetPlayerFaction(player, ServerPVP.CONFIG.FRIENDLY_FACTION)
    if success then
        ServerPVP.SetCooldown(playerId)
        
        ServerPVP.SendMessage(player, ServerPVP.CONFIG.MSG_PVP_OFF)
        return true, "PVP已禁用"
    else
        return false, "设置阵营失败"
    end
end

-- ============================================
-- 核心函数：切换PVP
-- ============================================
function ServerPVP.TogglePVP(player, faction)
    if not player then
        return false, "玩家对象无效"
    end
    
    local currentFaction = ServerPVP.GetPlayerFaction(player)
    
    -- 如果当前是PVP阵营，则禁用
    local isPVP = false
    for _, f in ipairs(ServerPVP.CONFIG.PVP_FACTIONS) do
        if currentFaction == f then
            isPVP = true
            break
        end
    end
    
    if isPVP then
        return ServerPVP.DisablePVP(player)
    else
        return ServerPVP.EnablePVP(player, faction)
    end
end

-- ============================================
-- 获取PVP状态
-- ============================================
function ServerPVP.GetPVPStatus(player)
    if not player then
        return nil
    end
    
    local playerId = ServerPVP.GetPlayerId(player)
    local currentFaction = ServerPVP.GetPlayerFaction(player)
    
    local isPVP = false
    for _, f in ipairs(ServerPVP.CONFIG.PVP_FACTIONS) do
        if currentFaction == f then
            isPVP = true
            break
        end
    end
    
    return {
        enabled = isPVP,
        faction = currentFaction,
        playerId = playerId
    }
end

-- ============================================
-- 辅助函数：获取玩家ID
-- ============================================
function ServerPVP.GetPlayerId(player)
    if not player then
        return nil
    end
    
    -- 尝试使用Entity模块解析
    local success, playerData = pcall(function()
        if player.id then
            return Entity.Parse(player.id)
        end
    end)
    
    if success and playerData and playerData.id then
        return playerData.id
    end
    
    -- 回退到直接API
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
-- 辅助函数：获取玩家阵营
-- ============================================
function ServerPVP.GetPlayerFaction(player)
    if not player then
        return ServerPVP.CONFIG.FRIENDLY_FACTION
    end
    
    -- 尝试使用Entity模块解析
    local success, playerData = pcall(function()
        if player.id then
            return Entity.Parse(player.id)
        end
    end)
    
    if success and playerData and playerData.faction then
        return playerData.faction
    end
    
    -- 尝试从持久化存储读取
    local playerId = ServerPVP.GetPlayerId(player)
    if playerId then
        local playerScope = "PlayerPVP_" .. playerId
        local savedFaction = Var.Get(playerScope, "pvp_faction")
        if savedFaction then
            return savedFaction
        end
    end
    
    -- 回退到直接API
    if player.GetFaction then
        return player:GetFaction()
    elseif player.faction then
        return player.faction
    else
        return ServerPVP.CONFIG.FRIENDLY_FACTION
    end
end

-- ============================================
-- 辅助函数：设置玩家阵营
-- ============================================
function ServerPVP.SetPlayerFaction(player, faction)
    if not player or not faction then
        return false
    end
    
    local playerId = ServerPVP.GetPlayerId(player)
    
    -- 方法1: 尝试直接API
    if player.SetFaction then
        local success = pcall(function() player:SetFaction(faction) end)
        if success then
            ServerPVP.SavePlayerState(playerId, faction)
            return true
        end
    elseif player.SetCritterFaction then
        local success = pcall(function() player:SetCritterFaction(faction) end)
        if success then
            ServerPVP.SavePlayerState(playerId, faction)
            return true
        end
    elseif player.faction then
        player.faction = faction
        ServerPVP.SavePlayerState(playerId, faction)
        return true
    end
    
    -- 方法2: 使用服务器命令（最可靠的方法）
    if CmdParseTextCommand then
        local cmd = string.format("setfaction %s", faction)
        local success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        if success then
            ServerPVP.SavePlayerState(playerId, faction)
            return true
        end
    end
    
    -- 方法3: 尝试通过Entity设置（如果API存在）
    if player.id and ts and ts.entity_xset then
        local success = pcall(function()
            -- 尝试通过实体设置
            ts.entity_xset(player.id, "faction", faction)
        end)
        if success then
            ServerPVP.SavePlayerState(playerId, faction)
            return true
        end
    end
    
    print("[ServerPVP] WARNING: Failed to set faction for player " .. tostring(playerId))
    return false
end

-- ============================================
-- 辅助函数：保存玩家状态（使用Var模块持久化）
-- ============================================
function ServerPVP.SavePlayerState(playerId, faction)
    if not playerId then return end
    
    local playerScope = "PlayerPVP_" .. playerId
    Scope.Set(playerScope)
    
    -- 保存到Var模块（持久化）
    Scope.Var.Set("pvp_faction", faction)
    Scope.Var.Set("last_change_time", ts.get_time())
    Scope.Var.Persist("pvp_faction", true)
    Scope.Var.Persist("last_change_time", true)
    
    -- 同时更新内存缓存
    ServerPVP.playerStates[playerId] = {
        faction = faction,
        enabled = ServerPVP.IsPVPFaction(faction),
        lastChange = os.time()
    }
end

-- ============================================
-- 辅助函数：加载玩家状态（从Var模块）
-- ============================================
function ServerPVP.LoadPlayerState(playerId)
    if not playerId then return nil end
    
    local playerScope = "PlayerPVP_" .. playerId
    local faction = Var.Get(playerScope, "pvp_faction")
    
    if faction then
        return {
            faction = faction,
            enabled = ServerPVP.IsPVPFaction(faction),
            lastChange = Var.Get(playerScope, "last_change_time") or 0
        }
    end
    
    return nil
end

-- ============================================
-- 辅助函数：检查是否为PVP阵营
-- ============================================
function ServerPVP.IsPVPFaction(faction)
    if not faction then return false end
    
    for _, pvpFaction in ipairs(ServerPVP.CONFIG.PVP_FACTIONS) do
        if faction == pvpFaction then
            return true
        end
    end
    
    return false
end

-- ============================================
-- 辅助函数：检查冷却（使用Var模块持久化）
-- ============================================
function ServerPVP.IsOnCooldown(playerId)
    if not playerId then return false end
    
    local playerScope = "PlayerPVP_" .. playerId
    
    -- 从Var模块读取
    local lastToggleTime = Var.Get(playerScope, "last_toggle_time")
    if not lastToggleTime then
        return false
    end
    
    local timeSince = ts.get_time() - lastToggleTime
    return timeSince < ServerPVP.CONFIG.COOLDOWN_TIME
end

function ServerPVP.GetCooldownRemaining(playerId)
    if not playerId then return 0 end
    
    local playerScope = "PlayerPVP_" .. playerId
    local lastToggleTime = Var.Get(playerScope, "last_toggle_time")
    
    if not lastToggleTime then
        return 0
    end
    
    local timeSince = ts.get_time() - lastToggleTime
    local remaining = ServerPVP.CONFIG.COOLDOWN_TIME - timeSince
    return math.max(0, remaining)
end

function ServerPVP.SetCooldown(playerId)
    if not playerId then return end
    
    local playerScope = "PlayerPVP_" .. playerId
    Scope.Set(playerScope)
    Scope.Var.Set("last_toggle_time", ts.get_time())
    Scope.Var.Persist("last_toggle_time", true)
    
    -- 同时更新内存缓存
    ServerPVP.cooldowns[playerId] = os.time()
end

-- ============================================
-- 辅助函数：检查战斗状态
-- ============================================
function ServerPVP.IsInCombat(player)
    -- 根据服务器API调整
    if player.IsInCombat then
        return player:IsInCombat()
    elseif player.inCombat then
        return player.inCombat
    else
        return false
    end
end

-- ============================================
-- 辅助函数：发送消息
-- ============================================
function ServerPVP.SendMessage(player, message)
    if not player or not message then
        print("[ServerPVP] Cannot send message: player or message is nil")
        return
    end
    
    -- 方法1: 尝试直接API
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
    
    -- 方法2: 使用服务器命令
    if CmdParseTextCommand then
        local cmd = string.format("chat_send %s", message)
        success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        if success then
            return
        end
    end
    
    -- 方法3: 尝试通过Entity发送（如果API存在）
    if player.id and ts and ts.entity_xset then
        success = pcall(function()
            -- 尝试通过实体发送消息
            ts.entity_xset(player.id, "chat_message", message)
        end)
        if success then
            return
        end
    end
    
    -- 最后回退：打印到服务器日志
    local playerId = ServerPVP.GetPlayerId(player)
    print(string.format("[ServerPVP] Message to player %s: %s", tostring(playerId), tostring(message)))
end

-- ============================================
-- 返回模块
-- ============================================
return ServerPVP

