-- ============================================
-- PVP聊天命令处理器
-- PVP Chat Command Handler
-- ============================================
-- 功能：拦截聊天消息，处理/pvp命令
-- ============================================

local ServerPVP = require("PVP.ServerPVP")

-- ============================================
-- 命令解析
-- ============================================
local function ParseCommand(cmdLine)
    if not cmdLine or cmdLine == "" then
        return nil, {}
    end
    
    -- 移除前导斜杠
    cmdLine = cmdLine:gsub("^/", "")
    
    -- 分割命令和参数
    local parts = {}
    for part in cmdLine:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    if #parts == 0 then
        return nil, {}
    end
    
    local cmd = parts[1]:lower()
    local args = {}
    for i = 2, #parts do
        table.insert(args, parts[i])
    end
    
    return cmd, args
end

-- ============================================
-- 聊天消息处理函数
-- ============================================
local function OnChatMessage(player, message, channel)
    if not player or not message then
        return false
    end
    
    -- 检查是否为命令（以/开头）
    if message:sub(1, 1) ~= "/" then
        return false
    end
    
    local cmd, args = ParseCommand(message)
    
    -- 处理/pvp命令
    if cmd == "pvp" then
        local CmdPVP = require("PVP.ServerCommands").CmdPVP
        if CmdPVP then
            CmdPVP(player, args)
            return true  -- 阻止消息继续传播
        end
    end
    
    return false
end

-- ============================================
-- 注册聊天事件
-- ============================================
local function RegisterChatHandler()
    -- 方法1: RegisterChatEvent
    if RegisterChatEvent then
        RegisterChatEvent(OnChatMessage)
        print("[ChatHandler] Registered via RegisterChatEvent")
        return true
    end
    
    -- 方法2: RegisterEvent
    if RegisterEvent then
        RegisterEvent("OnChatMessage", OnChatMessage)
        print("[ChatHandler] Registered via RegisterEvent('OnChatMessage')")
        return true
    end
    
    -- 方法3: OnChatMessage全局函数
    if _G.OnChatMessage == nil then
        _G.OnChatMessage = OnChatMessage
        print("[ChatHandler] Registered via global OnChatMessage")
        return true
    end
    
    print("[ChatHandler] WARNING: No chat event registration API found!")
    return false
end

-- ============================================
-- 初始化
-- ============================================
print("========================================")
print("PVP ChatHandler Loading...")
print("========================================")

RegisterChatHandler()

print("========================================")
print("PVP ChatHandler Loaded!")
print("========================================")

-- 导出函数供其他模块使用
return {
    OnChatMessage = OnChatMessage,
    ParseCommand = ParseCommand,
    RegisterChatHandler = RegisterChatHandler
}

