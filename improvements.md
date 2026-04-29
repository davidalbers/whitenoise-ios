# Proposed Improvements

## Bugs
1. Fix accumulating `MPRemoteCommandCenter` handlers — new handlers are added on every `play()` call with no cleanup, so they pile up
2. Remove `NotificationCenter` observer — `appWillEnterForeground` is registered but never removed
3. Fix deprecated `AVAudioSession` API — `AVAudioSessionCategoryPlayback` should be `.playback`

## Code Quality
4. Fix the `setTimerText` tab character hack — `actualText.append("\t")` is a fragile layout trick that should be real layout
5. Add error handling in `AudioManager` — `catch {}` silently swallows audio failures
6. Fix brittle segmented control mapping — `colorChangedAction` maps raw integers to colors; if the UI order ever changes it breaks silently

## SwiftLint
7. Rename `White_NoiseTests` and `White_NoiseUITests` classes — removes the last relaxed SwiftLint rule (`type_name.allowed_symbols`)

## UX
8. Haptic feedback — play/pause, color change, and timer add/cancel
9. Local notification when sleep timer ends — currently audio stops silently with no feedback if the screen is off

## Architecture
10. Migrate main screen to SwiftUI + replace `MainPresenter` with an `@Observable` ViewModel
11. Add tests for the ViewModel

## Features
12. More sounds — grey noise and fan noise are the most-requested alternatives; same implementation, just new audio files
13. Live Activity for the sleep timer — show a countdown on the lock screen so users don't need to open the app to check time remaining
14. Scheduled start — "start playing at 10:30pm" as an alternative to the countdown timer, good for consistent bedtime routines
15. Presets — save current settings (color + waves + fade + timer) as a named preset for one-tap restore
16. Crossfade between noise colors — short crossfade when switching colors instead of the current abrupt cut
