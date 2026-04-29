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
    static let tickInterval: Double = 0.03
    var wavesEnabled: Bool = false
    var fadeEnabled: Bool = false
    var timerDisplayed: Bool = false
    var timeLeftSecs: Double = 0
    var prevTime: Int = 0
    var timerActive: Bool = false
    var settingsSource = SettingsSource()

    init(viewController: ViewController) {
        self.viewController = viewController
    }

    public func changeColor(color: NoiseColors) {
        if currentColor == color { return }
        currentColor = color
        viewController.resetPlayer(restart: isPlaying)
        viewController.setColor(color: color)
        viewController.setMediaTitle(title: getSoundTitle())
    }

    public func getColor() -> NoiseColors { currentColor }

    public func playPause() {
        if isPlaying { pause() } else { play() }
    }

    public func pause() {
        viewController.pause()
        isPlaying = false
    }

    public func play() {
        createState()
        viewController.play()
        viewController.setMediaTitle(title: getSoundTitle())
        isPlaying = true
    }

    private func getSoundTitle() -> String {
        switch currentColor {
        case .Brown: return "Brown Noise"
        case .Pink:  return "Pink Noise"
        default:     return "White Noise"
        }
    }

    private func createState() {
        settingsSource.setColor(currentColor)
        settingsSource.setWaves(wavesEnabled)
        settingsSource.setFade(fadeEnabled)
        var timerSeconds: Double? = nil
        if timerActive { timerSeconds = viewController.getTimerPickerTime() }
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

    public func setDeeplinkParams(params: [URLQueryItem]) {}

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
        AudioManager.shared.setWaves(enabled)
    }

    public func enableFadeVolume(enabled: Bool) {
        fadeEnabled = enabled
        let seconds = timerActive && timeLeftSecs > 0 ? Int(timeLeftSecs) : 600
        AudioManager.shared.setFade(enabled, seconds: seconds)
    }

    public func tick() {
        decrementTimerTime()
    }

    private func decrementTimerTime() {
        guard timerActive else { return }
        if Int(timeLeftSecs) != 0 {
            timeLeftSecs -= Double(MainPresenter.tickInterval)
            if Int(timeLeftSecs) != prevTime {
                prevTime = Int(timeLeftSecs)
                viewController.setTimerText(text: getTimerText())
            }
        } else {
            viewController.pause()
            timerDisplayed = false
            viewController.cancelTimer(timerText: getTimerText())
            timerActive = false
            isPlaying = false
        }
    }

    public func addDeleteTimer() {
        timerDisplayed = !timerDisplayed
        if timerDisplayed {
            timerActive = true
            timeLeftSecs = viewController.getTimerPickerTime()
            if fadeEnabled {
                AudioManager.shared.fadeSeconds = Int(timeLeftSecs)
            }
            viewController.addTimer(timerText: getTimerText())
        } else {
            timerActive = false
            timeLeftSecs = 0
            viewController.cancelTimer(timerText: getTimerText())
        }
    }

    private func getTimerText() -> String {
        timerDisplayed ? secondsToFormattedTime(time: timeLeftSecs) : ""
    }

    private func secondsToFormattedTime(time: Double) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        if hours != 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
