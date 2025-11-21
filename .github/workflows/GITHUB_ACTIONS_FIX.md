# GitHub Actions 编译修复说明

## ✅ 已修复的问题

### 1. `tools/generate_code.bat` 文件不存在

**问题：** PowerShell 脚本尝试调用 `tools/generate_code.bat`，但文件不存在。

**修复：**
- ✅ 创建了 `tools/generate_code.bat` 占位符文件
- ✅ 更新了工作流，使用 `cmd` shell 正确调用批处理文件
- ✅ 添加了文件存在性检查

### 2. PowerShell 路径问题

**问题：** PowerShell 中使用 Unix 风格路径 `tools/generate_code.bat` 无法识别。

**修复：**
- ✅ 使用 `cmd` shell 调用批处理文件（Windows 原生）
- ✅ 使用 Windows 路径分隔符 `tools\generate_code.bat`

### 3. XML 格式问题

**问题：** `.vcxproj` 文件中的 `PreBuildEvent` 可能存在多行 XML 格式问题。

**修复：**
- ✅ 添加了自动修复步骤，在编译前修复 XML 格式
- ✅ 确保所有 `&` 字符正确转义为 `&amp;`

### 4. 工具集版本

**问题：** 项目可能需要指定工具集版本。

**修复：**
- ✅ 在所有 `msbuild` 命令中添加了 `/p:PlatformToolset=v143` 参数

## 📋 工作流步骤

1. **Checkout repository** - 检出代码
2. **Setup MSBuild** - 设置 MSBuild
3. **Run code generation** - 运行代码生成（如果存在）
4. **Fix XML format issues** - 自动修复 XML 格式问题
5. **Restore NuGet packages** - 恢复 NuGet 包（如果存在）
6. **Build GameServerLib** - 编译 GameServerLib
7. **Build CoreGameServer** - 编译 CoreGameServer
8. **Build NNOGameServer** - 编译 NNOGameServer
9. **Upload GameServer.exe** - 上传编译产物

## 🔧 自定义代码生成

如果需要添加实际的代码生成工具，编辑 `tools/generate_code.bat`：

```batch
@echo off
echo Running code generation...

REM 添加你的代码生成命令
python scripts/generate_structs.py
python scripts/generate_remote_funcs.py

exit /b 0
```

## 📝 注意事项

- 所有路径使用 Windows 风格（反斜杠 `\`）
- 批处理文件使用 `cmd` shell 执行
- PowerShell 脚本使用 `powershell` shell 执行
- 工具集版本设置为 `v143` (Visual Studio 2022)






