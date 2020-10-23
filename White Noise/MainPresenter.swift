//
//  MainPresenter.swift
//  White Noise
//
//  Created by David Albers on 4/17/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import Foundation
import WidgetKit

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
    static let colorKey : String = "colorKey"
    private let wavesKey : String = "wavesKey"
    private let fadeKey : String = "fadeKey"
    private let timerKey : String = "timerKey"

    init(viewController: ViewController) {
        self.viewController = viewController
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
        saveState()
        donateIntent()
        updateWidgets()
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
    
    private func saveState() {
        UserDefaults(suiteName: userDefaultsSuite)!.setValuesForKeys(createState())
    }

    private func createState() -> Dictionary<String, Any> {
        var state = Dictionary<String, Any>()
        state.updateValue(currentColor.rawValue, forKey: MainPresenter.colorKey)
        state.updateValue(wavesEnabled, forKey: wavesKey)
        state.updateValue(fadeEnabled, forKey: fadeKey)
        var timerSeconds: Double? = nil
        if timerActive {
            timerSeconds = viewController.getTimerPickerTime()
        }
        state.updateValue(timerSeconds as Any, forKey: timerKey)
        return state
    }
    
    @available(iOS 12.0, *)
    public func setIntent(intent: PlayIntent) {
        let intentParser = IntentParser(intent: intent)
        if intentParser.playForIntentIfNeeded() {
            loadSavedState(state: intentToState(intentParser: intentParser))
        } else {
            loadStateFromDefaults()
        }
        play()
    }
    
    @available(iOS 12.0, *)
    func intentToState(intentParser: IntentParser) -> [String: Any] {
        var state = [String: Any]()
        state[MainPresenter.colorKey] = intentParser.mapColor().rawValue
        state[timerKey] = intentParser.getMinutesFromIntent()
        state[wavesKey] = intentParser.getWavesEnabledFromIntent()
        state[fadeKey] = intentParser.getFadingEnabledFromIntent()
        return state
    }
    
    public func updateWidgets() {
        if #available(iOS 14.0, *) {
            print("updating widgets")
        WidgetCenter.shared.getCurrentConfigurations { result in
            guard case .success(let widgets) = result else { return }
            if let widget = widgets.first(
                where: { widget in
                    if let intent = widget.configuration as? PlayIntent {
                        let intentParser = IntentParser(intent: intent)
                        if intentParser.playForIntentIfNeeded() {
                            return false
                        }
                        return true
                    }
                    return false
                }
            ) {
                WidgetCenter.shared.reloadTimelines(ofKind: widget.kind)
            }
        }
        }
    }
    
    public func setDeeplinkParams(
        params: [URLQueryItem]
    ) {
        var state = [String: Any]()
        state[MainPresenter.colorKey] = params.first(where: { $0.name == "color" })?.value
        if let minutesParam = params.first(where: { $0.name == "minutes" })?.value {
            state[timerKey] = (Double(minutesParam) ?? 0.0) * 60
        }
        state[wavesKey] = Bool(params.first(where: { $0.name == "wavy" })?.value ?? "false")
        state[fadeKey] = Bool(params.first(where: { $0.name == "fading" })?.value ?? "false")
        loadSavedState(state: state)
        play()
    }
    
    private let userDefaultsSuite = "group.com.dalbers.WhiteNoise"

    public func loadStateFromDefaults() {
        loadSavedState(state:
            UserDefaults(suiteName: userDefaultsSuite)!.dictionaryRepresentation()
        )
    }

    private func loadSavedState(state: Dictionary<String, Any>) {
        if let savedColor = (state[MainPresenter.colorKey] as? String) {
            changeColor(color: NoiseColors(rawValue: savedColor) ?? .White)
        }
        wavesEnabled = state[wavesKey] as? Bool ?? false
        fadeEnabled = state[fadeKey] as? Bool ?? false
        viewController.setWavesEnabled(enabled: wavesEnabled)
        viewController.setFadeEnabled(enabled: fadeEnabled)
        
        timerDisplayed = false
        timerActive = false
        let savedTimerSeconds = state[timerKey] as? Double ?? 0.0
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
