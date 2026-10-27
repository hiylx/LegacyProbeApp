# Legacy IOKit Probe — iOS App

## Build Instructions

### Prerequisites
- macOS with Xcode 15+
- Apple ID (free developer account works, 7-day cert)
- iPhone 15 Pro on iOS 27.0.1 connected via USB

### Quick Build (Xcode)
```bash
cd /home/harshad/claudecode/newstuff/LegacyProbeApp
# Open in Xcode:
open -a Xcode .
# 1. Select your Apple ID team in Project → Signing & Capabilities
# 2. Connect iPhone 15 Pro via USB
# 3. Select device as run destination
# 4. Cmd+R to build & run
```

### Command Line Build
```bash
cd /home/harshad/claudecode/newstuff/LegacyProbeApp
xcodebuild -project LegacyProbeApp.xcodeproj \
  -scheme LegacyProbeApp \
  -destination 'platform=iOS,name=YOUR_IPHONE_NAME' \
  -configuration Debug \
  CODE_SIGN_IDENTITY="Apple Development" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  build
```

### Sideloadly (Windows/Mac/Linux - No Xcode Project Needed)
1. Build CLI probe first:
   ```bash
   clang -framework IOKit -framework CoreFoundation \
     ../legacy_probe.c -o legacy_probe
   ```
2. Create minimal .ipa wrapper (or use Sideloadly's "Install .app" feature)
3. Drag to Sideloadly → Install with Apple ID

### App Structure
```
LegacyProbeApp/
├── AppDelegate.h/m          # App lifecycle
├── SceneDelegate.h/m        # Scene lifecycle (iOS 13+)
├── ProbeViewController.h/m  # Main UI + probe logic
├── Main.storyboard          # UI: text output + Run/Clear buttons
├── LaunchScreen.storyboard  # Launch screen
├── Info.plist               # Bundle config
└── Assets.xcassets/         # App icon (add your own)
```

### Probe Logic (in ProbeViewController.m)
- Tests all 4 Entry #10 legacy `IOKit` classes:
  1. **IOMachPort** — Mach port wrapper
  2. **IOUserNotification** — User notifications
  3. **IOUserIterator** — Registry iteration
  4. **IOUserClient2022** — Modernized base class
- Tests selectors 0-19 per class via `IOConnectCallScalarMethod`
- Reports any result ≠ `KERN_NO_ACCESS` / `KERN_NOT_SUPPORTED`

### Expected Outputs

| Result | Meaning |
|--------|---------|
| All 4 classes = `KERN_NO_ACCESS` | **Entry #10 blocked** — need GPU process (Calif chain) |
| Any selector ≠ `KERN_NO_ACCESS` | **UAF PATH REACHABLE** — build full exploit for that class |

### After Probe Runs
- If vulnerable selector found → use `gpu_exploit.c` logic adapted for that class
- If all blocked → need WebKit RCE + GPU escape (Calif private chain)

### Troubleshooting
- **Codesign error**: Ensure Apple ID team selected, device registered
- **IOKit link error**: Add `IOKit.framework` in Frameworks & Libraries
- **App crashes on launch**: Check device iOS version (must be 27.0.1)
- **No output**: Open Console.app on Mac → select device → filter "LegacyProbeApp"

### Files to Copy to Your Mac
```
/home/harshad/claudecode/newstuff/
├── legacy_probe.c              # CLI probe (reference)
├── gpu_exploit.c               # Full GPU weaponization source
└── LegacyProbeApp/             # Complete Xcode project
    ├── AppDelegate.h/m
    ├── SceneDelegate.h/m
    ├── ProbeViewController.h/m
    ├── Main.storyboard
    ├── LaunchScreen.storyboard
    ├── Info.plist
    └── Assets.xcassets/        # Create in Xcode, add icon
```

"Copy the LegacyProbeApp folder to your Mac. Open in Xcode. Sign with your Apple ID. Deploy to 15 Pro. Tap Run Probe. Kernel answers."