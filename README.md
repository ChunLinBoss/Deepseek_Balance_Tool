# DeepSeek Balance

轻量级 Windows 桌面悬浮窗，实时显示 DeepSeek API 账户余额。

## 功能

| 功能 | 说明 |
|------|------|
| 💰 余额显示 | 自动查询 DeepSeek 账户余额，支持 CNY / USD / EUR |
| 📌 桌面悬浮 | 无边框毛玻璃圆角窗口，可切换始终置顶 |
| 🖱 拖动移动 | 鼠标按住窗口任意位置拖动 |
| ⏱ 定时刷新 | 1 / 5 / 10 / 30 分钟自动查询 |
| 🔔 系统托盘 | 右键菜单：显示/隐藏/设置/刷新/退出 |
| ⚙ 独立设置 | 点击齿轮按钮弹出设置窗口 |
| 🚀 开机自启 | 可选开机自动启动 |
| 👻 任务栏隐藏 | 仅托盘图标，不占任务栏 |

## 托盘菜单

右键点击右下角蓝色托盘图标：

```
显示窗口      — 恢复悬浮窗
隐藏窗口      — 最小化到托盘
设置          — 打开设置（含置顶开关）
刷新          — 立即查询余额
──────────
退出          — 完全退出
```

## 设置项

| 设置 | 说明 |
|------|------|
| API Key | DeepSeek 平台 API Key（sk-...） |
| 查询间隔 | 1 / 5 / 10 / 30 分钟 |
| 开机自动启动 | 勾选后开机自动运行 |
| 窗口始终置顶 | 勾选后悬浮窗保持在最前 |

## 运行

环境要求：Windows 10/11 + 开发者模式已启用

```powershell
flutter pub get
flutter build windows --release
```

输出：`build\windows\x64\runner\Release\deepseek_balance.exe`

## 配置文件

路径：`%APPDATA%\deepseek_balance\config.json`

## 技术栈

Flutter 3.41 · window_manager · tray_manager · win32_registry
