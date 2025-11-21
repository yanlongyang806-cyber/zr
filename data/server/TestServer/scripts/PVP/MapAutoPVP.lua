-- ============================================
-- 红名PVP系统 - 地图自动PVP
-- Red Name PVP System - Auto PVP by Map
-- ============================================
-- 功能：玩家进入特定地图自动开启PVP
-- 离开时恢复原状态
-- ============================================

-- 导入PVP模块
local PvPModule = require("PvPToggle")

-- ============================================
-- 配置：自动PVP的地图列表
-- ============================================
local AUTO_PVP_MAPS = {
    -- 添加需要自动PVP的地图名称
    -- 格式："地图名称"
    
    -- 示例：
    -- "Pvp_Arena_Domination_01",
    -- "OpenWorld_PvP_Zone",
    -- "WildArea_North",
}

-- 玩家原始状态记录
local playerOriginalFactions = {}

-- ============================================
-- 玩家进入地图事件
-- ============================================
function OnPlayerEnterMap(player, mapName)
    if not player or not mapName then return end
    
    -- 检查是否为自动PVP地图
    if IsAutoPVPMap(mapName) then
        -- 保存玩家原始阵营
        local playerId = GetPlayerId(player)
        local currentFaction = GetPlayerFaction(player)
        
        if currentFaction ~= PvPModule.CONFIG.PVP_FACTION then
            playerOriginalFactions[playerId] = currentFaction
            
            -- 强制开启PVP
            PvPModule.ForcePVPOn(player)
            SendMessage(player, "【自动PVP】进入PVP区域，已自动开启PVP！")
        end
    end
end

-- ============================================
-- 玩家离开地图事件
-- ============================================
function OnPlayerLeaveMap(player, mapName)
    if not player or not mapName then return end
    
    -- 检查是否为自动PVP地图
    if IsAutoPVPMap(mapName) then
        local playerId = GetPlayerId(player)
        
        -- 恢复玩家原始阵营
        if playerOriginalFactions[playerId] then
            local originalFaction = playerOriginalFactions[playerId]
            SetPlayerFaction(player, originalFaction)
            playerOriginalFactions[playerId] = nil
            
            SendMessage(player, "【自动PVP】离开PVP区域，已恢复原状态。")
        end
    end
end

-- ============================================
-- 检查是否为自动PVP地图
-- ============================================
function IsAutoPVPMap(mapName)
    for _, pvpMap in ipairs(AUTO_PVP_MAPS) do
        if mapName == pvpMap or string.find(mapName, pvpMap) then
            return true
        end
    end
    return false
end

-- ============================================
-- 辅助函数
-- ============================================

function GetPlayerId(player)
    return player:GetDbId() or player:GetAccountId() or tostring(player)
end

function GetPlayerFaction(player)
    return player:GetFaction() or player.faction or PvPModule.CONFIG.FRIENDLY_FACTION
end

function SetPlayerFaction(player, faction)
    if player.SetFaction then
        player:SetFaction(faction)
    elseif player.faction then
        player.faction = faction
    end
end

function SendMessage(player, message)
    if player.SendMessage then
        player:SendMessage(message)
    elseif player.SendChatMessage then
        player:SendChatMessage(message)
    end
end

-- ============================================
-- 注册事件
-- ============================================

-- 根据你的服务器API注册事件
if RegisterPlayerEvent then
    RegisterPlayerEvent("OnEnterMap", OnPlayerEnterMap)
    RegisterPlayerEvent("OnLeaveMap", OnPlayerLeaveMap)
end

