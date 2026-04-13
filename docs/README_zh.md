# CatLock

[English](../README.md) | **中文** | [Deutsch](README_de.md)

一款轻量级 macOS 菜单栏应用，锁定键盘和鼠标，防止猫咪、小孩或清洁时的误触。

按下自定义快捷键（默认：`Cmd+Shift+L`），即可在任意应用中锁定全部键盘和鼠标输入。屏幕会显示全屏遮罩和解锁按钮。再次按下快捷键或点击按钮即可解锁。就这么简单。

## 功能

- **全局快捷键** — 在任何应用中都能使用，即使 CatLock 在后台运行
- **自定义快捷键** — 在设置中录制任意按键组合
- **隐私模式** — 可选全黑遮罩，隐藏屏幕内容
- **菜单栏应用** — 常驻菜单栏，不占空间
- **25 种语言** — 自动检测系统语言
- **防止休眠** — 锁定期间保持 Mac 唤醒，避免中断长时间运行的任务

## 为什么选择 CatLock？

猫咪踩键盘、小孩乱按键、擦键盘时误触快捷键——CatLock 在系统层面拦截所有输入事件，锁定后没有任何事件会到达应用程序。

## 工作原理

CatLock 使用 macOS CGEvent tap 在事件到达任何应用之前拦截键盘和鼠标输入。一个轻量级的监听 tap 始终运行以检测快捷键。锁定后，第二个 tap 拦截所有输入（解锁快捷键除外）。这需要辅助功能权限，CatLock 会在首次使用时提示授权。

## 安装

1. 从 [Releases](../../releases) 下载最新的 `.dmg` 文件
2. 打开 `.dmg`，将 CatLock 拖到"应用程序"文件夹
3. 打开 CatLock，macOS 会弹出警告 — 点击 **完成**（不要点"移到废纸篓"）
4. 前往 **系统设置 → 隐私与安全性**，向下滚动，点击 **仍然打开**
5. CatLock 会请求辅助功能权限 — 点击按钮前往系统设置授权

> **为什么会有警告？** CatLock 是开源免费软件。警告出现是因为应用未使用付费的 Apple 开发者证书（$99/年）签名。源代码完全公开，可在本仓库中查看。

## 从源码构建

```
git clone https://github.com/hou-physics/CatLock.git
cd CatLock
xcodebuild -scheme CatLock -configuration Release build
```

构建的应用位于 `~/Library/Developer/Xcode/DerivedData/CatLock-*/Build/Products/Release/CatLock.app`。

## 系统要求

- macOS 14.0 或更高版本
- 辅助功能权限（首次使用时提示）

## 许可证

GPL-3.0
