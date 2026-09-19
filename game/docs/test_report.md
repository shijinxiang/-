# 测试记录

日期：2026-09-19
环境：Windows 10 x64，Godot 4.3 stable（项目内 `tools/Godot_v4.3-stable_win64_console.exe`）

## 已执行

| 测试 | 命令 | 结果 |
|---|---|---|
| 工程与脚本解析 | `Godot_v4.3-stable_win64_console.exe --headless --path game --editor --quit` | 通过 |
| 主菜单启动 | `Godot_v4.3-stable_win64_console.exe --headless --path game --quit-after 2` | 通过 |
| 移动场景启动 | `Godot_v4.3-stable_win64_console.exe --headless --path game res://scenes/arena.tscn --quit-after 2` | 通过 |
| 场景文件检查 | 检查 `scenes/menu.tscn`、`scenes/arena.tscn` | 通过 |

## 界面流程

- 主菜单显示开始、设置 / 人物招式和退出入口。
- 设置页显示两名角色的移动与跳跃按键，按 Esc 可关闭。
- 移动场景显示背景、两名角色和纯色按键提示。
- 移动场景按 Esc 后可继续、查看人物招式或返回菜单。

## 当前范围

本轮只验证菜单、场景载入、左右移动、跳跃和暂停返回流程。后续内容暂不纳入本轮验收。

## 尚未覆盖

- 实机导出包启动验证
- 长时间运行性能采样
- 不同窗口尺寸下的视觉回归截图
