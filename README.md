# Bilibili Audiobook Manager
### 哔哩哔哩听书进度管理 & 一键跳转工具

<details open>
<summary><b>中文</b></summary>

一个 SwiftUI iOS 应用：记录你的 B 站听书 / 视频播放进度，一键跳回上次听到的位置。

### 功能

- 保存听书条目：标题、BV 号、分 P、播放进度（秒）
- 每行一个醒目的 **Play（播放）** 按钮：通过 `bilibili://video/{bvId}?p={page}&t={seconds}` 在哔哩哔哩 App 中直达保存的分 P 和时间点；如果手机没装 B 站 App，会自动用网页播放器打开同一位置
- 编辑条目、左滑删除
- 进度保存在本地（JSON 序列化的 `Codable` 模型），按最近更新排序，关掉 App 也不会丢

### 半自动化：尽量少手动输入

iOS 的沙盒机制决定了第三方 App 读不到哔哩哔哩的播放记录，所以做不到"全自动同步进度"。但下面三个功能可以把手动操作降到最少：

1. **分享扩展**：在 B 站视频页点 分享 → **保存到听书**，BV 号自动存好，回到 App 直接补标题和秒数。不用手抄 BV 号。
2. **剪贴板识别**：复制 B 站链接后打开 App，自动弹窗问你要不要添加（已在库中的不会重复提示）。
3. **回来时推算进度**：点 Play 跳去 B 站听，回来时 App 按你离开的时长提示更新进度，例如"离开了 25 分钟，是否把进度从 1:30 更新为 26:30？"

### 在 iOS 上运行指南

#### 准备工作

- 一台 Mac，安装 **Xcode 15** 或更高版本
- iPhone（iOS 17 及以上），或直接用 Xcode 自带的模拟器（无需真机、无需签名）

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
   - 选中 `BilibiliAudiobookManager` target → **Signing & Capabilities** → **Team** 选择你的 Apple ID（免费的个人 Team 也可以）
   - 如果提示 Bundle Identifier 冲突，把 `com.example.BilibiliAudiobookManager` 改成唯一的
   - 在 iPhone 上进入 设置 → 通用 → VPN 与设备管理，信任你的开发者证书
5. 点击左上角 ▶（或按 ⌘R）运行。

#### 启用分享扩展（需要付费开发者账号）

分享扩展通过 **App Group**（`group.com.example.BilibiliAudiobookManager`）在扩展和主 App 之间传数据，两个 target 的 entitlements 文件已经配好。App Group 能力需要 **Apple Developer Program（付费）** 账号：

1. 在 Xcode 里分别选中 `BilibiliAudiobookManager` 和 `ShareExtension` target → **Signing & Capabilities**，确认 **App Groups** 已勾选 `group.com.example.BilibiliAudiobookManager`（Xcode 会自动在开发者后台注册）。
2. 真机运行后，在哔哩哔哩 App 里打开任意视频 → 分享 → 找到 **保存到听书**。

**没有付费账号？** 删掉 `ShareExtension` target（或把两处 `CODE_SIGN_ENTITLEMENTS` 留空），主 App 照常编译运行，剪贴板识别和回来推算进度不受影响。

#### 使用指南

1. 添加听书（四种方式）：
   - 点右上角 **+** 手动输入：标题（如"三体 第二章"）、BV 号（必须以 BV 开头，如 `BV1xx411c7mD`）、分 P（默认 1）、秒数（如 90 表示 1:30）
   - B 站分享菜单 → **保存到听书** → 回 App 补全
   - 复制 B 站链接 → 打开 App → 弹窗确认添加
   - 填错了会有红字提示，按提示改就行
2. 列表每行显示标题、BV 号、分 P 和当前进度，点 **Play** 立刻跳转。
3. 左滑删除；右滑或长按可编辑（比如更新进度秒数）。
4. 新建 / 修改过的条目会自动排到最前面。

#### 常见问题

- **点了 Play 却打开了网页版？** → 说明没检测到 B 站 App。请确认手机装了哔哩哔哩 App；本项目 `Info.plist` 已声明 `LSApplicationQueriesSchemes` 包含 `bilibili`（iOS 9+ 的硬性要求，缺了它 `canOpenURL` 永远返回 false）。
- **分享菜单里没有"保存到听书"？** → 确认按上面步骤启用了 App Group 且用了付费 Team 签名；也可以在分享菜单底部点"编辑"把它加到常用。
- **真机安装失败？** → 检查三件事：Team 是否已选、Bundle Identifier 是否唯一、iPhone 是否信任了开发者证书。
- **数据会丢吗？** → 不会，存在本地；只有卸载 App 才会清空。

</details>

<details>
<summary><b>English</b></summary>

A SwiftUI iOS app that tracks your Bilibili audiobook / video playback progress and jumps you straight back in via Bilibili deep links.

### Features

- Save audiobooks with title, BV ID, page number, and playback position (seconds)
- One-tap **Play / Resume** — opens `bilibili://video/{bvId}?p={page}&t={seconds}` in the Bilibili app, or falls back to the web player (`https://www.bilibili.com/...`) if the app isn't installed
- Edit entries, swipe-to-delete
- Progress persists locally (JSON-encoded `Codable` models), most-recently-updated first

### Semi-automation: minimal manual input

iOS sandboxing means no third-party app can read Bilibili's playback history, so fully automatic progress sync is impossible. These three features cut manual work to a minimum:

1. **Share extension**: in the Bilibili app, Share → **保存到听书** ("Save to Audiobooks"); the BV id is captured automatically — just fill in the title and seconds back in the app.
2. **Clipboard detection**: copy a Bilibili link, open the app, and get prompted to add it (already-saved ids are skipped).
3. **Return-time progress estimation**: tap Play, listen in Bilibili, come back — the app offers to advance the saved progress by the time you were away (e.g. "Away for 25 min — update progress from 1:30 to 26:30?").

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

### Enabling the Share extension (paid developer account required)

The extension passes data to the main app through an **App Group** (`group.com.example.BilibiliAudiobookManager`); both targets' entitlements are already configured. App Groups require an **Apple Developer Program (paid)** membership:

1. In Xcode, select the `BilibiliAudiobookManager` and `ShareExtension` targets → **Signing & Capabilities**, and confirm **App Groups** includes `group.com.example.BilibiliAudiobookManager` (Xcode registers it in your developer account automatically).
2. Run on a real device, then in the Bilibili app open any video → Share → **保存到听书**.

**No paid account?** Delete the `ShareExtension` target (or clear both `CODE_SIGN_ENTITLEMENTS` settings); the main app still builds and runs, and clipboard detection plus return-time estimation keep working.

### Notes

- `Info.plist` declares `bilibili` under `LSApplicationQueriesSchemes` — this is **required** for `canOpenURL` to detect the Bilibili app (iOS 9+). Without it, the app silently falls back to the web player every time.
- No third-party dependencies — `Foundation`, `SwiftUI`, and `UIKit` only.

</details>
