# UTILITY_TOGGLE // v2.0.0
> Y2K MONOCHROMATIC MACOS MENU BAR AUDIO CONTROLLER & SMART PRESET ROUTER

```
==================================================================
  [+] UTILITY_TOGGLE // SYSTEM_AUDIO_ROUTER            [ ⌥ SPACE ]
==================================================================

  +------------------------+    +------------------------------+
  | OUTPUT VOLUME          |    | MIC INPUT LEVEL              |
  | [85%] ||||||||||||||-- |    | [45%] |||||||-------         |
  +------------------------+    +------------------------------+

  + AUDIO PROFILES & ROUTING:
  +--------------------------------------------------------------+
  | [ GENERAL ]      | [ GAMING ]         | [ STUDIO ]           |
  | (System Default) | (AirPods Wireless) | (CoreAudio DAC)      |
  +--------------------------------------------------------------+

  + LIVE OUTPUT SOUND EQUALIZER SPECTRUM (60 FPS):
  |  |||||  ||||||||  ||||  ||||||  ||||||||  |||||  ||||||||    |

  [ CONFIGURATION ]                                 [ CLOSE ]
==================================================================
```

---

## // OVERVIEW & USE CASES

UTILITY_TOGGLE is a lightweight macOS menu bar utility designed for fast, seamless audio device switching and volume control without opening System Settings.

- **Gaming & Streaming**: Instant one-click switch between desktop speakers and gaming headsets with custom volume levels.
- **Music & Audio Production**: Route input/output audio to external DACs and studio mics with real-time spectrum visualizers.
- **Work & Calls**: Quick mute toggles and mic peak monitoring directly from your menu bar or global hotkey.

---

## // FEATURES

- **AUDIO PROFILES**: Create custom profiles with assigned input/output hardware and volume presets.
- **ONLINE FALLBACK**: Automatic fallback to system default devices if target hardware is offline.
- **LIVE SOUND SPECTRUM**: Real-time 60 FPS output sound equalizer visualizer.
- **MENU BAR VOLUME %**: Live output volume percentage displayed next to status item.
- **COLOR WHEEL THEME ENGINE**: Customize primary accent and secondary background colors via native macOS Color Wheels or Y2K presets.
- **GLOBAL SHORTCUT**: Press `Option + Space` anywhere to toggle the HUD popover.

---

## // LOCAL INSTALLATION & BUILD

### Prerequisites
- macOS 13.0 or later
- Xcode 14.0 or later

### Step 1: Clone Repository
```bash
git clone https://github.com/reachforaryan/UtilityToggle.git
cd UtilityToggle
```

### Step 2: Build App Bundle
```bash
xcodebuild -project UtilityToggle.xcodeproj -scheme UtilityToggle -configuration Debug build
```

### Step 3: Run Executable
```bash
open ~/Library/Developer/Xcode/DerivedData/UtilityToggle-*/Build/Products/Debug/UtilityToggle.app
```

---

## // LICENSE
MIT License. Built for macOS using Swift, SwiftUI, and CoreAudio HAL C-APIs.
