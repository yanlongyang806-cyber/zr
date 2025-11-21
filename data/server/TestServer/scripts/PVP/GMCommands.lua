-- ============================================
-- 红名PVP系统 - GM命令
-- Red Name PVP System - GM Commands
-- ============================================

-- 导入PVP模块
local PvPModule = require("PvPToggle")

-- ============================================
-- GM命令注册
-- ============================================

-- /pvp - 切换PVP状态
RegisterCommand("pvp", function(player, args)
    if not player then return end
    
    -- 无参数 - 切换PVP
    if not args or #args == 0 then
        local success, msg = PvPModule.TogglePVP(player)
        return
    end
    
    -- /pvp status - 查看状态
    if args[1] == "status" or args[1] == "check" then
        PvPModule.CheckPVPStatus(player)
        return
    end
    
    -- /pvp on - 强制开启（需要GM权限）
    if args[1] == "on" then
        if IsGM(player) then
            PvPModule.ForcePVPOn(player)
        else
            SendMessage(player, "权限不足！")
        end
        return
    end
    
    -- /pvp off - 强制关闭（需要GM权限）
    if args[1] == "off" then
        if IsGM(player) then
            PvPModule.ForcePVPOff(player)
        else
            SendMessage(player, "权限不足！")
        end
        return
    end
    
    -- /pvp help - 帮助
    if args[1] == "help" or args[1] == "?" then
        ShowHelp(player)
        return
    end
    
    -- 未知命令
    SendMessage(player, "未知命令！输入 /pvp help 查看帮助")
end)

-- ============================================
-- 显示帮助信息
-- ============================================
function ShowHelp(player)
    SendMessage(player, "========== PVP命令帮助 ==========")
    SendMessage(player, "/pvp          - 切换PVP状态")
    SendMessage(player, "/pvp status   - 查看当前状态")
    SendMessage(player, "/pvp on       - 强制开启PVP (GM)")
    SendMessage(player, "/pvp off      - 强制关闭PVP (GM)")
    SendMessage(player, "/pvp help     - 显示此帮助")
    SendMessage(player, "================================")
end

-- ============================================
-- 辅助函数
-- ============================================

-- 检查是否为GM
function IsGM(player)
    -- 根据你的服务器API修改
    if player.IsGM then
        return player:IsGM()
    elseif player.isGM then
        return player.isGM
    elseif player.gmLevel then
        return player.gmLevel > 0
    end
    return false
end

-- 发送消息
function SendMessage(player, message)
    if player.SendMessage then
        player:SendMessage(message)
    elseif player.SendChatMessage then
        player:SendChatMessage(message)
    end
end

-- 注册命令（需要根据服务器API修改）
function RegisterCommand(cmd, handler)
    -- 根据你的服务器API修改
    if RegisterChatCommand then
        RegisterChatCommand(cmd, handler)
    elseif Commands then
        Commands[cmd] = handler
    end
end

