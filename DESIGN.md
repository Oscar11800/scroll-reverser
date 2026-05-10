# ScrollReverser - Design Document

## Overview

A macOS menu bar utility that allows per-mouse scroll settings independent of trackpad settings.

## Design Decisions

| Decision | Choice |
|----------|--------|
| App type | Standard window, close hides to background |
| Menu bar | Icon (`arrow.up.arrow.down`) with dropdown (Open Settings, Global Toggle, Quit) |
| Launch at login | Yes, with toggle in settings, defaults to on |
| Settings persist | UserDefaults, remembered across sessions |
| Per-mouse settings | Reverse vertical scroll (toggle), scroll speed (slider 0.25x-5.0x, default 1.0x) |
| Device list | Shows product name + optional custom label, hides disconnected mice |
| Permissions | Dialog + button to open Accessibility settings on first launch |
| Language | Swift, SwiftUI for UI |
| Build system | SPM + manual shell script to assemble .app bundle |
| Min macOS | 13+ |
| App name | ScrollReverser |

## Architecture

- **Event Tap (CGEventTap):** Intercepts scroll events, identifies source device, applies per-device modifications
- **Device Manager (IOKit):** Enumerates connected HID devices (mice), provides unique IDs and product names
- **Settings UI (SwiftUI):** List of connected mice with per-device toggle (reverse scroll) and slider (speed)
- **Menu Bar:** SF Symbol `arrow.up.arrow.down`, dropdown with Open Settings / Enable toggle / Quit
- **Persistence (UserDefaults):** Stores per-device settings keyed by device unique ID

## Scope (v1)

- Reverse vertical scroll per mouse
- Scroll speed multiplier per mouse (0.25x - 5.0x, default 1.0x)

## Out of Scope (future)

- Reverse horizontal scroll
- Smooth scrolling
- Disable scroll acceleration
