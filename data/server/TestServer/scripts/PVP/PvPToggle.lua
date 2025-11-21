-- ============================================
-- 红名PVP系统 - 阵营切换脚本
-- Red Name PVP System - Faction Toggle
-- ============================================
-- 功能：玩家输入命令切换PVP状态
-- 红名玩家可以互相攻击
-- ============================================

-- 配置项
local CONFIG = {
    -- 友好阵营（绿名）
    FRIENDLY_FACTION = "UnalignedFriendlies",
    
    -- PVP阵营（红名）
    PVP_FACTION = "FreeForAll",
    
    -- 消息提示
    MSG_PVP_ON = "【PVP已开启】你现在是红名，其他红名玩家可以攻击你！",
    MSG_PVP_OFF = "【PVP已关闭】你现在是友好状态，其他玩家无法攻击你。",
    MSG_ALREADY_ON = "你已经处于PVP状态！",
    MSG_ALREADY_OFF = "你已经处于非PVP状态！",
    MSG_IN_COMBAT = "战斗中无法切换PVP状态！",
    MSG_COOLDOWN = "切换冷却中，请稍后再试...",
    
    -- 冷却时间（秒）
    COOLDOWN_TIME = 5,
}

-- 玩家PVP冷却记录
local pvpCooldowns = {}

-- ============================================
-- 核心函数：切换PVP状态
-- ============================================
function TogglePVP(player)
    if not player then
        return false, "玩家对象无效"
    end
    
    -- 检查是否在战斗中
    if IsInCombat(player) then
        return false, CONFIG.MSG_IN_COMBAT
    end
    
    -- 检查冷却时间
    local playerId = GetPlayerId(player)
    local currentTime = os.time()
    
    if pvpCooldowns[playerId] then
        local timeSince = currentTime - pvpCooldowns[playerId]
        if timeSince < CONFIG.COOLDOWN_TIME then
            local remaining = CONFIG.COOLDOWN_TIME - timeSince
            return false, string.format(CONFIG.MSG_COOLDOWN .. " (%d秒)", remaining)
        end
    end
    
    -- 获取当前阵营
    local currentFaction = GetPlayerFaction(player)
    
    -- 切换阵营
    if currentFaction == CONFIG.FRIENDLY_FACTION then
        -- 开启PVP
        SetPlayerFaction(player, CONFIG.PVP_FACTION)
        SendMessage(player, CONFIG.MSG_PVP_ON)
        pvpCooldowns[playerId] = currentTime
        return true, "PVP已开启"
    elseif currentFaction == CONFIG.PVP_FACTION then
        -- 关闭PVP
        SetPlayerFaction(player, CONFIG.FRIENDLY_FACTION)
        SendMessage(player, CONFIG.MSG_PVP_OFF)
        pvpCooldowns[playerId] = currentTime
        return true, "PVP已关闭"
    else
        -- 未知阵营，设置为友好
        SetPlayerFaction(player, CONFIG.FRIENDLY_FACTION)
        SendMessage(player, "已重置为友好状态")
        return true, "已重置"
    end
end

-- ============================================
-- 强制开启PVP（GM命令）
-- ============================================
function ForcePVPOn(player)
    if not player then return false end
    SetPlayerFaction(player, CONFIG.PVP_FACTION)
    SendMessage(player, "【强制】" .. CONFIG.MSG_PVP_ON)
    return true
end

-- ============================================
-- 强制关闭PVP（GM命令）
-- ============================================
function ForcePVPOff(player)
    if not player then return false end
    SetPlayerFaction(player, CONFIG.FRIENDLY_FACTION)
    SendMessage(player, "【强制】" .. CONFIG.MSG_PVP_OFF)
    return true
end

-- ============================================
-- 检查PVP状态
-- ============================================
function CheckPVPStatus(player)
    if not player then return false end
    
    local faction = GetPlayerFaction(player)
    
    if faction == CONFIG.PVP_FACTION then
        SendMessage(player, "【PVP状态】红名（可以被攻击）")
    elseif faction == CONFIG.FRIENDLY_FACTION then
        SendMessage(player, "【PVP状态】友好（无法被攻击）")
    else
        SendMessage(player, "【PVP状态】未知阵营: " .. tostring(faction))
    end
    
    return true
end

-- ============================================
-- 辅助函数（需要根据服务器API调整）
-- ============================================

-- 获取玩家ID
function GetPlayerId(player)
    -- 根据你的服务器API修改
    return player:GetDbId() or player:GetAccountId() or tostring(player)
end

-- 获取玩家阵营
function GetPlayerFaction(player)
    -- 根据你的服务器API修改
    return player:GetFaction() or player.faction or CONFIG.FRIENDLY_FACTION
end

-- 设置玩家阵营
function SetPlayerFaction(player, faction)
    -- 根据你的服务器API修改
    if player.SetFaction then
        player:SetFaction(faction)
    elseif player.faction then
        player.faction = faction
    end
end

-- 检查是否在战斗中
function IsInCombat(player)
    -- 根据你的服务器API修改
    if player.IsInCombat then
        return player:IsInCombat()
    elseif player.inCombat then
        return player.inCombat
    end
    return false
end

-- 发送消息给玩家
function SendMessage(player, message)
    -- 根据你的服务器API修改
    if player.SendMessage then
        player:SendMessage(message)
    elseif player.SendChatMessage then
        player:SendChatMessage(message)
    elseif player.SystemMessage then
        player:SystemMessage(message)
    end
end

-- ============================================
-- 返回模块
-- ============================================
return {
    TogglePVP = TogglePVP,
    ForcePVPOn = ForcePVPOn,
    ForcePVPOff = ForcePVPOff,
    CheckPVPStatus = CheckPVPStatus,
    CONFIG = CONFIG
}

