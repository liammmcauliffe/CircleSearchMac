<div align="center">

<img src="assets/logo.svg" width="120" alt="CircleSearch">

# CircleSearch

**Circle anything on your Mac screen to reverse image search it.**

[![macOS](https://img.shields.io/badge/macOS-13%2B-black?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5-orange?logo=swift)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

A lightweight macOS menu bar app inspired by Google Pixel's *Circle to Search*. Press a hotkey, draw around what you want to identify, and your browser opens with results from Google Lens, Yandex, Bing — or your own engine.

## Features

- **Global hotkey** — activate the selection overlay from any app
- **Two selection modes** — freeform *lasso* or *rectangle*
- **Live cutout overlay** — your selection stays clear while everything else dims
- **Retina-accurate capture** via `ScreenCaptureKit`
- **Multiple search engines** — Google Lens, Yandex, Bing, plus custom engines via URL templates
- **Customizable shortcut** — record any modifier + key combination
- **Launch at login** — via `SMAppService`
- **Menu bar only** — no Dock icon, stays out of your way
- **No telemetry** — no accounts, no analytics

## Requirements

- macOS 13 Ventura or later
- Accessibility permission (for the global hotkey)
- Screen Recording permission (for the capture)

## Installation

1. Download the latest `CircleSearch.app` from [Releases](https://github.com/liammmauliffe/CircleSearch/releases).
2. Drag it into your **Applications** folder.
3. Open it from Applications.
4. Grant the **Accessibility** and **Screen Recording** permissions when prompted.
5. The magnifying-glass icon appears in your menu bar — you're set.

> [!NOTE]
> The app isn't notarized yet. The first time you open it, right-click the app and choose **Open** to bypass Gatekeeper.

## Usage

Default shortcut: <kbd>⌘</kbd> + <kbd>⌃</kbd> + <kbd>S</kbd>

1. Press the shortcut from any app.
2. The screen dims with a translucent overlay.
3. Draw a lasso or rectangle around what you want to identify.
4. Release the mouse — a brief preview shows the captured area.
5. Your default browser opens with the search results.

Press <kbd>Esc</kbd> at any time to cancel.

Open **Preferences** from the menu bar icon to change the shortcut, selection mode, search engine, or launch-at-login behavior.

## Search engines

Three engines are built in:

| Engine                 | Strengths                                          |
| ---------------------- | -------------------------------------------------- |
| **Google Lens**        | Best general-purpose results, OCR, shopping        |
| **Yandex**             | Best for source images, people, and landmarks      |
| **Bing Visual Search** | Solid all-rounder, good for products               |

### Adding a custom engine

Open **Preferences → Search engine → +** and fill in:

- **Name** — display name for the engine
- **URL template** — search URL with `{url}` where the image URL should appear

Example for [TinEye](https://tineye.com):

```
https://www.tineye.com/search?url={url}
```

## How it works

CircleSearch is a small Swift + AppKit app. The flow is:

1. A global `CGEventTap` listens for the configured hotkey.
2. A borderless, full-screen `NSWindow` at `.screenSaver` level shows the dim overlay and selection view.
3. On release, `ScreenCaptureKit` captures the selected rect at native pixel resolution.
4. The image is uploaded to [uguu.se](https://uguu.se) — a temporary public image host.
5. The returned URL is handed to the selected search engine via `NSWorkspace.shared.open`.

> [!WARNING]
> Captured images are uploaded to [uguu.se](https://uguu.se) (a third-party host) so the search engines can fetch them. Don't circle anything sensitive. Self-hosting is on the roadmap.

## Building from source

```bash
git clone https://github.com/liammmauliffe/CircleSearch.git
cd CircleSearchMac/CircleSearch
open CircleSearch.xcodeproj
```

Then build and run with <kbd>⌘</kbd> + <kbd>R</kbd> in Xcode. There are no external dependencies — no SPM packages, no CocoaPods, just open and go.

## Roadmap

**v1 — shipped**

- [x] Global hotkey + selection overlay
- [x] Lasso and rectangle selection modes
- [x] Cutout overlay with corner brackets
- [x] Three built-in search engines + custom engines
- [x] Customizable shortcut
- [x] Launch at login

**v2 — polish**

- [ ] Loading indicator during upload
- [ ] Crosshair cursor
- [ ] Multi-monitor support (overlay on the cursor's screen)

**v3 — self-hosted**

- [ ] Replace the third-party image host with a self-hosted backend
- [ ] Clipboard-only mode (keep images local)
- [ ] Auto-update support
