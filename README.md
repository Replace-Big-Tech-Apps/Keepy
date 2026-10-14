# Keepy

A tiny native macOS reminders app (Swift + SwiftUI). Type what to remember, pick a time,
and a small notification lands on your Mac right then — even if Keepy is closed.
Styled after [ORBIS](https://github.com/999Gabriel/ORBIS) like LBrowser: white canvas, black ink,
hairlines, one amber accent, Zen Dots labels and Alumni Sans Pinstripe numerals.

## Build from source

```bash
./build.sh            # -> build/Keepy.app
./build.sh --install  # also copies to /Applications
./build.sh --universal --dmg  # -> build/Keepy-1.0.dmg (Apple Silicon + Intel)
```

Requires macOS 15 or later and Xcode (the SwiftUI macros aren't in the Command Line Tools).
The app is ad-hoc signed and is not notarized. On first launch, allow notifications when macOS asks;
if you declined, Keepy shows a notice linking to **System Settings → Notifications**.

## Use

- Type a reminder, pick a time (or tap **+5 min**, **+15 min**, **+1 hr**, **9:00 tmrw**), press Return.
- Each reminder is scheduled as a system notification, so it fires on time without Keepy running.
- Hover a reminder and click × to cancel it. Delivered ones move to **Sent**; **Clear** removes them.
- Appearance (system / light / dark) is in Settings (⌘,).

Reminders are stored in `~/Library/Application Support/Keepy/reminders.json`.
Design tokens live in `Sources/Keepy/Theme.swift`.
Fonts in `Fonts/` are under the SIL Open Font License (see the OFL files there).
