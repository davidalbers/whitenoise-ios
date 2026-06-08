This is an iOS app that plays white, pink, and brown noise.

Most white noise apps lack features that I would like to have, so I made my own. Those features are:
* Sleep timer
* Wavy volume
* Fading volume
* Control Center/bluetooth/lock-screen controls

Additionally most of the existing apps are ugly/outdated, so I'm attempting to use a simple design.

The app store page is [here](https://itunes.apple.com/us/app/white-noise-plus/id1281372285?mt=8).

There is a nearly identical Android version [here](https://github.com/davidalbers/whitenoise).

---

<img src="White NoiseTests/__Snapshots__/MainViewSnapshotTests/testMainView_playing_withTimer_themes.auto.png" width="250"> <img src="White NoiseTests/__Snapshots__/SettingsViewSnapshotTests/testSettingsView.1.png" width="250">


---

## Documentation

Markdown files attempt to explain design decisions in this app:

- [architecture.md](architecture.md) — MVVM architecture and how the widgets interact with the main app
- [theme.md](theme.md) — How the six themes work
- [snapshot-testing.md](snapshot-testing.md) — Snapshot tests using swift-snapshot-testing
- [code-quality.md](code-quality.md) — How to keep the code consistent with lint and formatting
