//
//  MainPresenter.swift
//  White Noise
//
//  Created by David Albers on 4/17/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import Foundation
class MainPresenter {
    //MARK: vars
    public enum NoiseColors: String {
        case White = "white"
        case Pink = "pink"
        case Brown = "brown"
    }
    
    var isPlaying: Bool = false
    var currentColor: NoiseColors = .White
    var viewController: ViewController
    var volume: Float = 0.0
    var increasing: Bool = false
    let minVolume: Float = 0.2
    var maxVolume: Float = 1.0
    let volumeIncrement: Float = 0.025
    var wavesEnabled: Bool = false
    var fadeEnabled: Bool = false
    var resettingVolume: Bool = false
    var fadeTime: Int = 10
    var tickInterval: Float = 0.1
    let resetVolumeIncrement: Float = 0.1
    var timerDisplayed: Bool = false

    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    public func changeColor(color: NoiseColors) {
        if (currentColor == color) {
            return
        }
        currentColor = color
        viewController.resetPlayer(restart: isPlaying)
    }
    
    public func getColor() -> NoiseColors {
        return currentColor
    }
    
    public func playPause() {
        if (isPlaying) {
            viewController.pause()
        } else {
            resetVolume()
            viewController.play()
        }
        isPlaying = !isPlaying
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
        } else {
            resetVolume()
        }
    }
    
    public func tick() {
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
    
    public func resetVolume() {
        maxVolume = 1.0
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
        let volumeDelta = (1.0 - minVolume) / (Float(fadeTime) * 1.0 / tickInterval)
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
        print("Resetting volume to \(volume)")
        if (volume >= maxVolume) {
            volume = maxVolume
            resettingVolume = false
        }
    }
    
}
