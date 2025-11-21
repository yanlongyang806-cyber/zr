-- ============================================
-- 地图自动PVP脚本
-- ============================================
-- 此脚本让玩家进入特定地图时自动切换为PVP模式
-- 离开时恢复正常模式
-- ============================================

-- 配置：哪些地图启用自动PVP
local PVP_MAPS = {
    -- 自由混战地图
    ["Az_Ch_Blacklake_District"] = "ffa",  -- 黑湖区 - 自由混战
    ["Az_Hh_Helm_Hold"] = "ffa",           -- 赫姆要塞 - 自由混战
    
    -- 红蓝对抗地图
    ["Az_Mh_Mount_Hotenow"] = "redblue",   -- 烈焰火山 - 红蓝对抗
    ["Az_Ve_Vellosk"] = "redblue",         -- 维洛斯克 - 红蓝对抗
}

-- 配置：PVP区域的警告消息
local PVP_MESSAGES = {
    enter_ffa = "⚔️ 你已进入PVP区域！所有玩家互相敌对！",
    enter_red = "⚔️ 你已加入红队！攻击蓝队玩家！",
    enter_blue = "⚔️ 你已加入蓝队！攻击红队玩家！",
    leave = "✓ 你已离开PVP区域",
}

-- 存储玩家的原始阵营
local playerOriginalFactions = {}

-- ============================================
-- 玩家进入地图事件
-- ============================================

function OnPlayerEnterMap(player, mapName)
    local pvpMode = PVP_MAPS[mapName]
    
    if not pvpMode then
        -- 不是PVP地图，恢复正常阵营
        RestorePlayerFaction(player)
        return
    end
    
    -- 保存玩家原始阵营
    if not playerOriginalFactions[player:GetID()] then
        playerOriginalFactions[player:GetID()] = player:GetFaction()
    end
    
    -- 根据模式设置阵营
    if pvpMode == "ffa" then
        -- 自由混战模式
        player:SetFaction("FreeForAll")
        player:SendMessage(PVP_MESSAGES.enter_ffa)
        
    elseif pvpMode == "redblue" then
        -- 红蓝对抗模式 - 随机或平衡分配
        local team = AssignPlayerToTeam(player, mapName)
        if team == "red" then
            player:SetFaction("OpenPvp_Red")
            player:SendMessage(PVP_MESSAGES.enter_red)
        else
            player:SetFaction("OpenPvp_Blue")
            player:SendMessage(PVP_MESSAGES.enter_blue)
        end
    end
    
    -- 显示PVP提示UI（可选）
    ShowPVPWarning(player)
end

-- ============================================
-- 玩家离开地图事件
-- ============================================

function OnPlayerLeaveMap(player, mapName)
    local pvpMode = PVP_MAPS[mapName]
    
    if pvpMode then
        -- 离开PVP地图，恢复原始阵营
        RestorePlayerFaction(player)
        player:SendMessage(PVP_MESSAGES.leave)
    end
end

-- ============================================
-- 辅助函数
-- ============================================

-- 恢复玩家原始阵营
function RestorePlayerFaction(player)
    local playerID = player:GetID()
    local originalFaction = playerOriginalFactions[playerID]
    
    if originalFaction then
        player:SetFaction(originalFaction)
        playerOriginalFactions[playerID] = nil
    else
        -- 默认恢复为友好阵营
        player:SetFaction("UnalignedFriendlies")
    end
end

-- 分配玩家到红队或蓝队（平衡分配）
function AssignPlayerToTeam(player, mapName)
    -- 统计当前地图的红队和蓝队人数
    local redCount = 0
    local blueCount = 0
    
    local playersInMap = GetPlayersInZone(mapName)
    for _, p in pairs(playersInMap) do
        local faction = p:GetFaction()
        if faction == "OpenPvp_Red" then
            redCount = redCount + 1
        elseif faction == "OpenPvp_Blue" then
            blueCount = blueCount + 1
        end
    end
    
    -- 分配到人数较少的队伍
    if redCount <= blueCount then
        return "red"
    else
        return "blue"
    end
end

-- 显示PVP警告UI
function ShowPVPWarning(player)
    -- 显示屏幕中央的警告消息
    player:ShowFloatingText("PVP区域", 3.0, "red")
    -- 可以添加更多UI元素
end

-- ============================================
-- 事件注册
-- ============================================

-- 注册地图进入事件
RegisterEvent("OnPlayerEnterZone", OnPlayerEnterMap)

-- 注册地图离开事件  
RegisterEvent("OnPlayerLeaveZone", OnPlayerLeaveMap)

-- 玩家登出时清理数据
RegisterEvent("OnPlayerLogout", function(player)
    playerOriginalFactions[player:GetID()] = nil
end)

-- ============================================
-- 使用说明：
-- 1. 将此文件放在 data/server/TestServer/scripts/ 目录
-- 2. 修改 PVP_MAPS 表，配置哪些地图启用PVP
-- 3. 重启服务器后，玩家进入配置的地图会自动开启PVP
-- 4. 离开地图会自动恢复正常模式
-- ============================================

-- ============================================
-- 自定义配置示例：
-- ============================================

-- 方案1：所有冒险区域都是自由混战
--[[
local PVP_MAPS = {
    ["Az_Ch_Blacklake_District"] = "ffa",
    ["Az_Hh_Helm_Hold"] = "ffa",
    ["Az_Mh_Mount_Hotenow"] = "ffa",
    ["Az_Ve_Vellosk"] = "ffa",
    ["Az_Sha_Sharandar"] = "ffa",
    -- ... 添加更多地图
}
]]

-- 方案2：特定地图红蓝对抗，其他自由混战
--[[
local PVP_MAPS = {
    -- 大型对抗地图
    ["Az_Mh_Mount_Hotenow"] = "redblue",
    ["Az_Ve_Vellosk"] = "redblue",
    
    -- 小型混战地图
    ["Az_Ch_Blacklake_District"] = "ffa",
    ["Az_Hh_Helm_Hold"] = "ffa",
}
]]

-- 方案3：全地图PVP（谨慎使用！）
--[[
function OnPlayerEnterMap(player, mapName)
    -- 所有地图都设为自由混战
    player:SetFaction("FreeForAll")
    player:SendMessage("⚔️ 全地图PVP已启用！")
end
]]

