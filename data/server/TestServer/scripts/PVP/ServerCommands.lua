-- ============================================
-- 服务端PVP命令系统
-- Server-Side PVP Command System
-- ============================================
-- 功能：注册和处理PVP相关命令
-- ============================================

local ServerPVP = require("PVP.ServerPVP")

-- 导出CmdPVP供ChatHandler使用
local CmdPVP = nil

-- ============================================
-- 命令处理器
-- ============================================

-- /pvp - 主命令
CmdPVP = function(player, args)
    if not player then return end
    
    -- 无参数 - 切换PVP
    if not args or #args == 0 then
        local success, msg = ServerPVP.TogglePVP(player)
        if not success then
            ServerPVP.SendMessage(player, "错误: " .. tostring(msg))
        end
        return
    end
    
    local subcmd = args[1]:lower()
    
    -- /pvp on [faction]
    if subcmd == "on" or subcmd == "enable" then
        local faction = args[2] or ServerPVP.CONFIG.DEFAULT_PVP_FACTION
        local success, msg = ServerPVP.EnablePVP(player, faction)
        if not success then
            ServerPVP.SendMessage(player, "错误: " .. tostring(msg))
        end
        return
    end
    
    -- /pvp off
    if subcmd == "off" or subcmd == "disable" then
        local success, msg = ServerPVP.DisablePVP(player)
        if not success then
            ServerPVP.SendMessage(player, "错误: " .. tostring(msg))
        end
        return
    end
    
    -- /pvp toggle [faction]
    if subcmd == "toggle" then
        local faction = args[2]
        local success, msg = ServerPVP.TogglePVP(player, faction)
        if not success then
            ServerPVP.SendMessage(player, "错误: " .. tostring(msg))
        end
        return
    end
    
    -- /pvp status
    if subcmd == "status" or subcmd == "check" then
        local status = ServerPVP.GetPVPStatus(player)
        if status then
            if status.enabled then
                ServerPVP.SendMessage(player, string.format("【PVP状态】已启用 - 阵营: %s", status.faction))
            else
                ServerPVP.SendMessage(player, "【PVP状态】未启用 - 阵营: " .. status.faction)
            end
        else
            ServerPVP.SendMessage(player, "无法获取PVP状态")
        end
        return
    end
    
    -- /pvp help
    if subcmd == "help" or subcmd == "?" then
        ShowPVPHelp(player)
        return
    end
    
    -- 未知子命令
    ServerPVP.SendMessage(player, "未知命令！输入 /pvp help 查看帮助")
end

-- ============================================
-- 显示帮助
-- ============================================
function ShowPVPHelp(player)
    ServerPVP.SendMessage(player, "========== PVP命令帮助 ==========")
    ServerPVP.SendMessage(player, "/pvp              - 切换PVP状态")
    ServerPVP.SendMessage(player, "/pvp on [faction] - 启用PVP")
    ServerPVP.SendMessage(player, "/pvp off          - 禁用PVP")
    ServerPVP.SendMessage(player, "/pvp toggle       - 切换PVP状态")
    ServerPVP.SendMessage(player, "/pvp status       - 查看当前状态")
    ServerPVP.SendMessage(player, "/pvp help         - 显示此帮助")
    ServerPVP.SendMessage(player, "")
    ServerPVP.SendMessage(player, "可用阵营:")
    for _, faction in ipairs(ServerPVP.CONFIG.PVP_FACTIONS) do
        ServerPVP.SendMessage(player, "  - " .. faction)
    end
    ServerPVP.SendMessage(player, "================================")
end

-- ============================================
-- 注册命令
-- ============================================
local function RegisterCommands()
    -- 根据服务器API调整
    if RegisterChatCommand then
        RegisterChatCommand("pvp", CmdPVP)
        print("[ServerPVP] Command '/pvp' registered via RegisterChatCommand")
    elseif RegisterCommand then
        RegisterCommand("pvp", CmdPVP)
        print("[ServerPVP] Command '/pvp' registered via RegisterCommand")
    elseif Commands then
        Commands.pvp = CmdPVP
        print("[ServerPVP] Command '/pvp' registered via Commands table")
    else
        print("[ServerPVP] WARNING: No command registration API found!")
        print("[ServerPVP] Please check doc.pdf for the correct API")
    end
end

-- ============================================
-- 初始化
-- ============================================
print("========================================")
print("ServerPVP Command System Loading...")
print("========================================")

RegisterCommands()

print("========================================")
print("ServerPVP Command System Loaded!")
print("========================================")

-- 导出CmdPVP供其他模块使用
return {
    CmdPVP = CmdPVP,
    ShowPVPHelp = ShowPVPHelp,
    RegisterCommands = RegisterCommands
}

