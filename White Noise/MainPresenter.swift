//
//  MainPresenter.swift
//  White Noise
//
//  Created by David Albers on 4/17/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import Foundation

class MainPresenter {
    var isPlaying: Bool = false
    var currentColor: NoiseColors = .White
    var viewController: ViewController
    var volume: Float = 0.2
    let minVolume: Float = 0.2
    var maxVolume: Float = 1.0
    static let tickInterval: Double = 0.03
    var increasing: Bool = false
    let volumeIncrement: Float
    var wavesEnabled: Bool = false
    var fadeEnabled: Bool = false
    var resettingVolume: Bool = false
    var fadeTime: Int = 10
    let resetVolumeIncrement: Float
    var timerDisplayed: Bool = false
    var timeLeftSecs: Double = 0
    var prevTime: Int = 0
    var timerActive: Bool = false
    var settingsSource = SettingsSource()

    init(viewController: ViewController) {
        self.viewController = viewController
        SettingsMigrater().migrate()
        volumeIncrement = Float(MainPresenter.tickInterval / 5)
        resetVolumeIncrement = Float(MainPresenter.tickInterval)
    }
    
    public func changeColor(color: NoiseColors) {
        if (currentColor == color) {
            return
        }
        currentColor = color
        viewController.resetPlayer(restart: isPlaying)
        viewController.setColor(color: color)
        viewController.setMediaTitle(title: getSoundTitle())
    }
    
    public func getColor() -> NoiseColors {
        return currentColor
    }
    
    public func playPause() {
        if (isPlaying) {
            pause()
        } else {
            play()
        }
    }
    
    public func pause() {
        viewController.pause()
        isPlaying = false
    }
    
    public func play() {
        resetVolume()
        createState()
        donateIntent()
        viewController.play()
        viewController.setMediaTitle(title: getSoundTitle())
        isPlaying = true
    }
    
    private func getSoundTitle() -> String {
        var playingTitle = ""
        switch (currentColor) {
        case .Brown:
            playingTitle = "Brown"
            break;
        case .Pink:
            playingTitle = "Pink"
            break;
        default:
            playingTitle = "White"
            break;
        }
        return playingTitle + " Noise"
    }
    
    public func donateIntent() {
        guard #available(iOS 12.0, *) else {
            return
        }
        let intent = PlayIntent()
        intent.noiseModification = createNoiseModificationForIntent()
        intent.minutes = createTimerMinutesForIntent()
        switch currentColor {
        case .White:
            intent.color = Colors.white
        case .Brown:
            intent.color = Colors.brown
        case .Pink:
            intent.color = Colors.pink
        }
        print(intent.color.rawValue)
        ShortcutCreator().resetShortcutsWithNewIntent(intent: intent)
    }
    
    @available(iOS 12.0, *)
    private func createNoiseModificationForIntent() -> Modification {
        if fadeEnabled && wavesEnabled {
            return Modification.both
        }
        if wavesEnabled {
            return Modification.wavy
        }
        if fadeEnabled {
            return Modification.fading
        }
        return Modification.unknown
    }
    
    private func createTimerMinutesForIntent() -> NSNumber? {
        if timerActive {
            return (viewController.getTimerPickerTime() / 60) as NSNumber
        }
        return nil
    }

    private func createState() {
        settingsSource.setColor(currentColor)
        settingsSource.setWaves(wavesEnabled)
        settingsSource.setFade(fadeEnabled)
        var timerSeconds: Double? = nil
        if timerActive {
            timerSeconds = viewController.getTimerPickerTime()
        }
        settingsSource.setTimer(timerSeconds)
    }
    
    @available(iOS 12.0, *)
    public func setIntent(intent: PlayIntent) {
        let intentParser = IntentParser(intent: intent)
        if intentParser.playForIntentIfNeeded() {
            intentToState(intentParser: intentParser)
        } else {
            loadSavedState()
        }
        play()
    }
    
    @available(iOS 12.0, *)
    func intentToState(intentParser: IntentParser) {
        settingsSource.setColor(intentParser.mapColor())
        settingsSource.setTimer(intentParser.getMinutesFromIntent())
        settingsSource.setWaves(intentParser.getWavesEnabledFromIntent())
        settingsSource.setFade(intentParser.getFadingEnabledFromIntent())
        loadSavedState()
    }
    
    public func setDeeplinkParams(
        params: [URLQueryItem]
    ) {
    }
    
    private let userDefaultsSuite = "group.com.dalbers.WhiteNoise"

    public func loadSavedState() {
        changeColor(color: settingsSource.color())
        wavesEnabled = settingsSource.wavesEnabled()
        fadeEnabled = settingsSource.fadeEnabled()
        viewController.setWavesEnabled(enabled: wavesEnabled)
        viewController.setFadeEnabled(enabled: fadeEnabled)
        
        timerDisplayed = false
        timerActive = false
        let savedTimerSeconds = settingsSource.timerSeconds()
        if savedTimerSeconds > 0 {
            viewController.setTimerPickerTime(seconds: savedTimerSeconds)
            addDeleteTimer()
        } else {
            timeLeftSecs = 0
            viewController.setTimerPickerTime(seconds: timeLeftSecs)
            viewController.cancelTimer(timerText: "")
        }
    }
    
    public func enableWavyVolume(enabled: Bool) {
        wavesEnabled = enabled
        if (wavesEnabled) {
            resettingVolume = false;
        } else {
            resetVolume()
        }
    }
    
    public func enableFadeVolume(enabled: Bool) {
        fadeEnabled = enabled
        if (fadeEnabled) {
            resettingVolume = false;
            fadeTime = Int(timeLeftSecs)
            if (fadeTime == 0) {
                fadeTime = 10
            }
        } else {
            resetVolume()
        }
    }
    
    public func tick() {
        decrementTimerTime()
    
        if (fadeEnabled) {
            applyFadeVolume()
        }
        if (wavesEnabled) {
            applyWavyVolume()
        }
        if (resettingVolume) {
            applyResetVolume()
        }
        viewController.setVolume(volume: volume)
    }
    
    private func decrementTimerTime() {
        if (!timerActive) {
            return
        }
        
        if (Int(timeLeftSecs) != 0) {
            timeLeftSecs -= Double(MainPresenter.tickInterval)
            
            if (Int(timeLeftSecs) != prevTime) {
                prevTime = Int(timeLeftSecs)
                viewController.setTimerText(text: getTimerText())
            }
        } else {
            viewController.pause()
            timerDisplayed = false
            viewController.cancelTimer(timerText: getTimerText())
            timerActive = false
            isPlaying = false
            fadeTime = 10
        }
    }
    
    public func resetVolume() {
        maxVolume = 1.0
        volume = 0.2
        viewController.setVolume(volume: volume)
        resettingVolume = true
        increasing = false
    }
    
    public func applyWavyVolume() {
        if (increasing) {
            volume += volumeIncrement
        } else {
            volume -= volumeIncrement
        }
        if (volume <= minVolume) {
            volume = minVolume
            increasing = true
        } else if (volume >= maxVolume) {
            increasing = false
            volume = maxVolume
        }
    }
    
    public func applyFadeVolume() {
        let volumeDelta = (1.0 - minVolume) /
            (Float(fadeTime) * 1.0 / Float(MainPresenter.tickInterval))
        if (maxVolume > minVolume) {
            maxVolume -= volumeDelta
            if (volume > maxVolume) {
                volume -= volumeDelta
            }
        }
    }
    
    public func applyResetVolume() {
        if (volume < maxVolume) {
            volume += resetVolumeIncrement
        }
        if (volume >= maxVolume) {
            volume = maxVolume
            resettingVolume = false
        }
    }
    
    public func addDeleteTimer() {
        timerDisplayed = !timerDisplayed
        if (timerDisplayed) {
            timerActive = true
            timeLeftSecs = viewController.getTimerPickerTime()
            if (fadeEnabled) {
                fadeTime = Int(timeLeftSecs)
            }
            viewController.addTimer(timerText: getTimerText())
        } else {
            timerActive = false
            timeLeftSecs = 0
            viewController.cancelTimer(timerText: getTimerText())
        }
    }
    
    private func getTimerText() -> String {
        if (timerDisplayed) {
            return secondsToFormattedTime(time: timeLeftSecs)
        } else {
            return ""
        }
    }
    
    private func secondsToFormattedTime(time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if (hours != 0) {
            return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format:"%02i:%02i", minutes, seconds)
        }
    }
    
}
