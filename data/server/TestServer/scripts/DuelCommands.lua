-- ============================================
-- 决斗命令系统
-- Duel Command System
-- ============================================
-- 功能：注册决斗相关的聊天命令
-- ============================================

-- ============================================
-- 辅助函数：发送消息给玩家
-- ============================================
local function SendMessage(player, message)
    if not player then return end
    
    if player.SendMessage then
        player:SendMessage(message)
    elseif CmdParseTextCommand then
        pcall(function()
            CmdParseTextCommand("chat_send " .. message, player)
        end)
    else
        print("消息给玩家: " .. tostring(message))
    end
end

-- ============================================
-- 命令处理器：/duel
-- ============================================
local function CmdDuel(player, args)
    if not player then return end
    
    -- 检查参数
    if not args or #args == 0 then
        SendMessage(player, "用法: /duel <玩家名称>")
        SendMessage(player, "示例: /duel PlayerName")
        return
    end
    
    local targetName = args[1]
    
    -- 使用服务器命令发起决斗
    if CmdParseTextCommand then
        local cmd = string.format("duel %s", targetName)
        local success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        
        if success then
            SendMessage(player, string.format("已向 %s 发起决斗请求", targetName))
        else
            SendMessage(player, "决斗请求失败，请检查玩家名称是否正确")
        end
    else
        SendMessage(player, "错误: 决斗系统不可用")
    end
end

-- ============================================
-- 命令处理器：/duelaccept
-- ============================================
local function CmdDuelAccept(player, args)
    if not player then return end
    
    -- 使用服务器命令接受决斗
    if CmdParseTextCommand then
        local success = pcall(function()
            CmdParseTextCommand("duelaccept", player)
        end)
        
        if success then
            SendMessage(player, "已接受决斗请求")
        else
            SendMessage(player, "接受决斗失败")
        end
    else
        SendMessage(player, "错误: 决斗系统不可用")
    end
end

-- ============================================
-- 命令处理器：/dueldecline
-- ============================================
local function CmdDuelDecline(player, args)
    if not player then return end
    
    -- 使用服务器命令拒绝决斗
    if CmdParseTextCommand then
        local success = pcall(function()
            CmdParseTextCommand("dueldecline", player)
        end)
        
        if success then
            SendMessage(player, "已拒绝决斗请求")
        else
            SendMessage(player, "拒绝决斗失败")
        end
    else
        SendMessage(player, "错误: 决斗系统不可用")
    end
end

-- ============================================
-- 命令处理器：/whitelist_duels
-- ============================================
local function CmdWhitelistDuels(player, args)
    if not player then return end
    
    -- 检查参数
    if not args or #args == 0 then
        SendMessage(player, "用法: /whitelist_duels <0/1>")
        SendMessage(player, "  0 = 关闭决斗白名单（接受所有人的决斗）")
        SendMessage(player, "  1 = 开启决斗白名单（只接受白名单玩家的决斗）")
        return
    end
    
    local enabled = tonumber(args[1])
    if enabled == nil or (enabled ~= 0 and enabled ~= 1) then
        SendMessage(player, "错误: 参数必须是 0 或 1")
        return
    end
    
    -- 使用服务器命令设置白名单
    if CmdParseTextCommand then
        local cmd = string.format("Whitelist_Duels %d", enabled)
        local success = pcall(function()
            CmdParseTextCommand(cmd, player)
        end)
        
        if success then
            if enabled == 1 then
                SendMessage(player, "决斗白名单已开启")
            else
                SendMessage(player, "决斗白名单已关闭")
            end
        else
            SendMessage(player, "设置决斗白名单失败")
        end
    else
        SendMessage(player, "错误: 决斗系统不可用")
    end
end

-- ============================================
-- 注册命令
-- ============================================
local function RegisterCommands()
    -- 方法1: RegisterChatCommand（推荐）
    if RegisterChatCommand then
        RegisterChatCommand("duel", CmdDuel)
        RegisterChatCommand("duelaccept", CmdDuelAccept)
        RegisterChatCommand("dueldecline", CmdDuelDecline)
        RegisterChatCommand("whitelist_duels", CmdWhitelistDuels)
        print("[DuelCommands] Commands registered via RegisterChatCommand")
        print("[DuelCommands]   - /duel <玩家名称>")
        print("[DuelCommands]   - /duelaccept")
        print("[DuelCommands]   - /dueldecline")
        print("[DuelCommands]   - /whitelist_duels <0/1>")
        return true
    end
    
    -- 方法2: RegisterCommand
    if RegisterCommand then
        RegisterCommand("duel", CmdDuel)
        RegisterCommand("duelaccept", CmdDuelAccept)
        RegisterCommand("dueldecline", CmdDuelDecline)
        RegisterCommand("whitelist_duels", CmdWhitelistDuels)
        print("[DuelCommands] Commands registered via RegisterCommand")
        return true
    end
    
    -- 方法3: Commands表
    if Commands then
        Commands.duel = CmdDuel
        Commands.duelaccept = CmdDuelAccept
        Commands.dueldecline = CmdDuelDecline
        Commands.whitelist_duels = CmdWhitelistDuels
        print("[DuelCommands] Commands registered via Commands table")
        return true
    end
    
    print("[DuelCommands] WARNING: No command registration API found!")
    return false
end

-- ============================================
-- 初始化函数
-- ============================================
local function Initialize()
    print("========================================")
    print("Duel Command System Loading...")
    print("========================================")
    
    local ok, err = pcall(RegisterCommands)
    if not ok then
        print("[DuelCommands] ERROR during registration:")
        print(tostring(err))
        print("========================================")
        return false
    end
    
    print("========================================")
    print("Duel Command System Loaded!")
    print("========================================")
    return true
end

-- ============================================
-- 默认在服务器/独立 Lua 环境下立即加载
-- ============================================
-- ⭐ 关键：如果不是TestClient环境，立即执行初始化
-- 当通过 -scriptName 参数加载时，_G.tc 为 nil，会立即执行
if not _G.tc then
    print("========================================")
    print("DuelCommands.lua: Auto-loading Duel Commands...")
    print("========================================")
    local ok, err = pcall(Initialize)
    if not ok then
        print("[DuelCommands] ERROR during auto-load:")
        print(tostring(err))
        print("========================================")
    end
end

-- 导出函数供其他模块使用
return {
    CmdDuel = CmdDuel,
    CmdDuelAccept = CmdDuelAccept,
    CmdDuelDecline = CmdDuelDecline,
    CmdWhitelistDuels = CmdWhitelistDuels,
    RegisterCommands = RegisterCommands,
    Initialize = Initialize
}

