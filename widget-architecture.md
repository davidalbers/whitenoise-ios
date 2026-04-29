# Widget Architecture

`AudioManager` singleton owns the `AVAudioPlayer` and all sound "state". When a widget intent fires, the app is launched in the background and `playHandler`/`stopHandler` call `AudioManager`. If the app opened after that, it attempts to "sync" it's UI to the state from `AudioManager` in `ViewController.syncWithAudioManager()`. `UserDefaults` in `SettingsSource` are a fallback to this if the app isn't in memory. Both the app and widget load the user's last chosen state in that case.

```mermaid
sequenceDiagram
    participant W as Widget
    participant SI as StartPlayingIntent
    participant SS as SettingsSource
    participant AM as AudioManager
    participant WC as WidgetCenter
    participant VC as ViewController
    participant MP as MainPresenter

    rect rgb(220, 235, 255)
        Note over W,WC: Widget play button tapped
        W->>SI: perform()
        SI->>SS: color/waves/fade (mirror mode)
        SI->>AM: playHandler(color, waves, fade)
        WC->>W: re-render with pause button
    end

    rect rgb(255, 235, 220)
        Note over VC,AM: App foregrounds after widget interaction
        VC->>SS: syncSettingsWithSavedState()
        VC->>SS: syncTimerWithSavedState()
        VC->>AM: syncWithAudioManager()
    end

    rect rgb(220, 255, 225)
        Note over MP,WC: In-app play
        MP->>SS: createState()
        MP->>AM: AudioManager.play()
        WC->>W: re-render with pause button
    end
```
