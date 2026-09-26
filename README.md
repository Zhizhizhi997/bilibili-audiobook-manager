# Bilibili Audiobook Manager
### 哔哩哔哩听书进度管理 & 一键跳转工具

[中文说明](#中文说明) | [English](#english)

---

## 中文说明

一个 SwiftUI iOS 应用：记录你的 B 站听书 / 视频播放进度，一键跳回上次听到的位置。

### 功能

- 保存听书条目：标题、BV 号、分 P、播放进度（秒）
- 每行一个醒目的 **Play（播放）** 按钮：通过 `bilibili://video/{bvId}?p={page}&t={seconds}` 在哔哩哔哩 App 中直达保存的分 P 和时间点；如果手机没装 B 站 App，会自动用网页播放器打开同一位置
- 编辑条目、左滑删除
- 进度保存在本地 `UserDefaults`（JSON 序列化的 `Codable` 模型），按最近更新排序，关掉 App 也不会丢

### 在 iOS 上运行指南

#### 准备工作

- 一台 Mac，安装 **Xcode 15** 或更高版本
- 真机二选一：
  - iPhone（iOS 17 及以上），或
  - 直接用 Xcode 自带的模拟器（无需真机、无需签名）

#### 运行步骤

1. 把仓库 clone 到 Mac：
   ```bash
   git clone https://github.com/Zhizhizhi997/bilibili-audiobook-manager.git
   ```
2. 双击打开 `BilibiliAudiobookManager.xcodeproj`。
3. 在 Xcode 顶部工具栏选择运行目标：
   - 只想快速试用 → 选任意 iPhone 模拟器（如 iPhone 15），跳到第 5 步
   - 要装到真机 → 用数据线连接 iPhone，并在顶部选择你的 iPhone
4. 真机首次运行需要配置签名（模拟器跳过）：
   - 左侧选中 `BilibiliAudiobookManager` target → **Signing & Capabilities**
   - **Team** 选择你的 Apple ID（免费的个人 Team 也可以，不需要付费开发者账号）
   - 如果提示 Bundle Identifier 冲突，把 `com.example.BilibiliAudiobookManager` 改成唯一的（如 `com.你的名字.BilibiliAudiobookManager`）
   - 在 iPhone 上进入 设置 → 通用 → VPN 与设备管理，信任你的开发者证书
5. 点击左上角 ▶（或按 ⌘R）运行。

#### 使用指南

1. 点右上角 **+** 添加一本听书：
   - **Title**：标题，例如“三体 第二章”
   - **BV ID**：视频的 BV 号，例如 `BV1xx411c7mD`（必须以 BV 开头）
   - **Page**：分 P 编号，默认 1
   - **Seconds**：上次听到第几秒，例如 90 表示 1:30
   - 填错了会有红字提示，按提示改就行
2. 列表里每行显示标题、BV 号、分 P 和当前进度，点 **Play** 立刻跳转。
3. 左滑删除某条；右滑或长按可编辑（比如更新进度秒数）。
4. 新建 / 修改过的条目会自动排到最前面。

#### 常见问题

- **点了 Play 却打开了网页版？** → 说明没检测到 B 站 App。请确认手机装了哔哩哔哩 App；本项目 `Info.plist` 已声明 `LSApplicationQueriesSchemes` 包含 `bilibili`（iOS 9+ 的硬性要求，缺了它 `canOpenURL` 永远返回 false）。
- **真机安装失败？** → 检查三件事：Team 是否已选、Bundle Identifier 是否唯一、iPhone 是否信任了开发者证书。
- **数据会丢吗？** → 不会，存在本地 `UserDefaults`；只有卸载 App 才会清空。

---

## English

A SwiftUI iOS app that tracks your Bilibili audiobook / video playback progress and jumps you straight back in via Bilibili deep links.

### Features

- Save audiobooks with title, BV ID, page number, and playback position (seconds)
- One-tap **Play / Resume** — opens `bilibili://video/{bvId}?p={page}&t={seconds}` in the Bilibili app, or falls back to the web player (`https://www.bilibili.com/...`) if the app isn't installed
- Edit entries, swipe-to-delete
- Progress persists in `UserDefaults` (JSON-encoded `Codable` models), most-recently-updated first

### Requirements

- Xcode 15+
- iOS 17+

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/Zhizhizhi997/bilibili-audiobook-manager.git
   ```
2. Open `BilibiliAudiobookManager.xcodeproj` in Xcode.
3. Pick a run destination: any iPhone simulator for a quick try, or your iPhone for on-device.
4. For a real device (first time only): select the `BilibiliAudiobookManager` target → **Signing & Capabilities** → choose your **Team** (a free personal team works), make the **Bundle Identifier** unique if prompted, and trust your developer certificate under iPhone Settings → General → VPN & Device Management.
5. Hit ▶ (or ⌘R) to build & run.

### Notes

- `Info.plist` declares `bilibili` under `LSApplicationQueriesSchemes` — this is **required** for `canOpenURL` to detect the Bilibili app (iOS 9+). Without it, the app silently falls back to the web player every time.
- No third-party dependencies — `Foundation`, `SwiftUI`, and `UIKit` only.
