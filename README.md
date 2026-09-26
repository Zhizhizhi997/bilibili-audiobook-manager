# Bilibili Audiobook Manager

A SwiftUI iOS app that tracks your Bilibili audiobook / video playback progress and jumps you straight back in via Bilibili deep links.

## Features

- Save audiobooks with title, BV ID, page number, and playback position (seconds)
- One-tap **Play / Resume** — opens `bilibili://video/{bvId}?p={page}&t={seconds}` in the Bilibili app, or falls back to the web player (`https://www.bilibili.com/...`) if the app isn't installed
- Edit entries, swipe-to-delete
- Progress persists in `UserDefaults` (JSON-encoded `Codable` models), most-recently-updated first

## Requirements

- Xcode 15+
- iOS 17+

## Setup

1. Open `BilibiliAudiobookManager.xcodeproj` in Xcode.
2. Select the `BilibiliAudiobookManager` target → **Signing & Capabilities** → choose your **Team** (required for running on a real device; the Simulator works without it).
3. Optionally change the **Bundle Identifier** (default `com.example.BilibiliAudiobookManager`).
4. Build & run (⌘R).

## Notes

- `Info.plist` declares `bilibili` under `LSApplicationQueriesSchemes` — this is **required** for `canOpenURL` to detect the Bilibili app (iOS 9+). Without it, the app silently falls back to the web player every time.
- No third-party dependencies — `Foundation`, `SwiftUI`, and `UIKit` only.
