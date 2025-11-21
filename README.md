# Night - 无冬之夜OL 服务器端

[![编译状态](https://github.com/yanlongyang806-cyber/zr/workflows/编译%20GameServer%20和%20AutoLoadLua/badge.svg)](https://github.com/yanlongyang806-cyber/zr/actions)

## 📋 项目说明

这是无冬之夜OL (Neverwinter Online) 的服务器端项目，包含：

- **GameServer** - 游戏服务器主程序
- **AutoLoadLua** - 自动加载Lua脚本的DLL注入工具
- **PVP系统** - 完整的PVP功能实现
- **决斗系统** - 玩家决斗功能

## 🚀 快速开始

### 编译要求

- **Windows 10/11** 或 **Windows Server 2016+**
- **Visual Studio 2019/2022** (包含 C++ 桌面开发工具)
- **Windows SDK**

### 本地编译

#### 1. 编译 GameServer

```bash
cd src/Night/GameServer
msbuild NNOGameServer.sln /p:Configuration=Release /p:Platform=x64
```

#### 2. 编译 AutoLoadLua.dll

```bash
cd tools/AutoLoadLua
build.bat
```

#### 3. 编译 Injector.exe

```bash
cd tools/AutoLoadLua
build_injector.bat
```

## 📦 GitHub Actions 自动编译

本项目配置了 GitHub Actions 工作流，可以自动编译：

### 工作流说明

1. **build.yml** - 完整编译（GameServer + AutoLoadLua）
2. **build-simple.yml** - 简化版编译（仅 GameServer）
3. **build-autoloadlua.yml** - 仅编译 AutoLoadLua DLL

### 使用方法

1. **推送代码到 GitHub**
   ```bash
   git add .
   git commit -m "更新代码"
   git push origin main
   ```

2. **查看编译状态**
   - 访问：https://github.com/yanlongyang806-cyber/zr/actions
   - 点击最新的工作流运行

3. **下载构建产物**
   - 在工作流运行完成后
   - 点击 "build-artifacts" 或 "GameServer-Build"
   - 下载编译好的文件

### 手动触发编译

1. 访问 GitHub Actions 页面
2. 选择工作流
3. 点击 "Run workflow"
4. 选择分支并运行

## 📁 项目结构

```
.
├── src/                          # 源代码
│   ├── Night/GameServer/         # GameServer 主程序
│   └── Core/TestServer/          # 测试服务器代码
├── tools/                        # 工具
│   ├── AutoLoadLua/              # DLL注入工具
│   └── bin/                      # 编译输出目录
├── data/                         # 游戏数据
│   ├── server/TestServer/scripts/ # Lua脚本
│   └── defs/                     # 游戏定义文件
└── .github/workflows/            # GitHub Actions 工作流
```

## 🔧 功能特性

### PVP系统

- ✅ 全地图PVP支持
- ✅ 阵营系统（FreeForAll, Pvp1, Pvp2等）
- ✅ 决斗系统（/duel, /duelaccept等命令）

### Lua脚本系统

- ✅ 自动加载机制
- ✅ 服务器端脚本支持
- ✅ GM命令注册

### 自动加载

- ✅ DLL注入自动加载
- ✅ ControllerScript自动加载
- ✅ 源码修改自动加载（推荐）

## 📝 使用说明

### 启动服务器

```bash
cd tools/bin
GameServer.exe
```

### 加载Lua脚本

#### 方法1：自动加载（推荐）

修改 `src/Core/TestServer/TestServerLua.c` 的 `TestServer_StartLuaThread` 函数：

```c
// 自动加载 LoadPVP.lua
TestServer_RunScript("data/server/TestServer/scripts/LoadPVP.lua");
```

#### 方法2：DLL注入

```bash
Injector.exe GameServer.exe AutoLoadLua.dll
```

#### 方法3：ControllerScript

在 Controller Scripts 窗口中点击 "RunLoadPVP" 按钮

## 🐛 问题排查

### 编译失败

1. 检查 Visual Studio 是否正确安装
2. 检查 Windows SDK 是否安装
3. 查看编译日志中的错误信息

### GameServer 无法启动

1. 确保 TransactionServer 已启动
2. 检查端口是否被占用
3. 查看日志文件

### Lua脚本未加载

1. 检查脚本路径是否正确
2. 查看 GameServer 日志
3. 使用 DebugView 查看 DLL 日志

## 📚 相关文档

- [📘DLL注入方案-自动加载Lua脚本.md](📘DLL注入方案-自动加载Lua脚本.md)
- [📘推荐方案-修改源码自动加载.md](📘推荐方案-修改源码自动加载.md)
- [📘Lua脚本注册GM命令完整指南.md](📘Lua脚本注册GM命令完整指南.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目仅供学习和研究使用。

## 🔗 相关链接

- GitHub Actions: https://github.com/yanlongyang806-cyber/zr/actions
- 仓库地址: https://github.com/yanlongyang806-cyber/zr
