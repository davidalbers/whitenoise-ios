//
//  ViewController.swift
//  White Noise
//
//  Created by David Albers on 4/9/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import SwiftUI

class ViewController: UIViewController {
    var presenter: MainPresenter?
    var timer: Timer?
    private let themer = Themer()
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var wavesSwitch: UISwitch!
    @IBOutlet weak var fadeSwitch: UISwitch!
    @IBOutlet weak var colorSegmented: UISegmentedControl!
    @IBOutlet weak var themeButton: UIButton!
    
    let grey : UIColor = UIColor(named: "darkGrey") ?? UIColor.yellow
    let pink : UIColor = UIColor(named: "pink") ?? UIColor.systemPink
    let brown : UIColor = UIColor(named: "brown") ?? UIColor.brown
    let textColor = UIColor(named: "text")
    override func viewDidLoad() {
        super.viewDidLoad()

        timerLabel.text = ""
        timerPicker.setValue(textColor, forKey: "textColor")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
        presenter = MainPresenter(viewController: self)
        if AudioManager.shared.isPlaying {
            presenter?.isPlaying = true
        }
        presenter?.loadSavedState()
        if #available(iOS 14.0, *) {
            overrideUserInterfaceStyle = themer.getUIUserInterfaceStyle()
            themeButton.imageView?.tintColor = textColor
            themeButton.isHidden = false
        } else {
            themeButton.isHidden = true
        }
        if AudioManager.shared.isPlaying {
            presenter?.play()
        } else {
            showPlayButtonPlayable()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncWithAudioManager()
    }

    @objc private func appWillEnterForeground() {
        syncSettingsWithSavedState()
        syncTimerWithSavedState()
        syncWithAudioManager()
    }

    private func syncSettingsWithSavedState() {
        guard let p = presenter, AudioManager.shared.isPlaying else { return }
        let color = p.settingsSource.color()
        p.currentColor = color
        setColor(color: color)
        p.wavesEnabled = p.settingsSource.wavesEnabled()
        p.fadeEnabled = p.settingsSource.fadeEnabled()
        setWavesEnabled(enabled: p.wavesEnabled)
        setFadeEnabled(enabled: p.fadeEnabled)
    }

    private func syncTimerWithSavedState() {
        guard let p = presenter, AudioManager.shared.isPlaying else { return }
        let savedSeconds = p.settingsSource.timerSeconds()
        if savedSeconds == 0 {
            guard p.timerActive else { return }
            p.timerActive = false
            p.timerDisplayed = false
            p.timeLeftSecs = 0
            cancelTimer(timerText: "")
        } else if !p.timerActive || savedSeconds != getTimerPickerTime() {
            setTimerPickerTime(seconds: savedSeconds)
            p.timerActive = true
            p.timerDisplayed = true
            p.timeLeftSecs = savedSeconds
            if p.fadeEnabled { AudioManager.shared.fadeSeconds = Int(savedSeconds) }
            addTimer(timerText: formatTimerSeconds(savedSeconds))
        }
    }

    private func formatTimerSeconds(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = Int(seconds) / 60 % 60
        let s = Int(seconds) % 60
        return h > 0 ? String(format: "%02i:%02i:%02i", h, m, s) : String(format: "%02i:%02i", m, s)
    }

    private func syncWithAudioManager() {
        guard let p = presenter else { return }
        if AudioManager.shared.isPlaying && !p.isPlaying {
            p.isPlaying = true
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                         target: self,
                                         selector: #selector(self.update),
                                         userInfo: nil,
                                         repeats: true)
            animateButtonImage(newImageName: "pause", button: playButton)
        } else if !AudioManager.shared.isPlaying && p.isPlaying {
            p.isPlaying = false
            timer?.invalidate()
            showPlayButtonPlayable()
        }
    }
    
    @objc func update() {
        presenter?.tick()
    }
    
    @available(iOS 12.0, *)
    public func onReceiveIntent(intent: PlayIntent) {
        presenter?.setIntent(intent: intent)
    }

    @available(iOS 12.0, *)
    public func onReceiveIntent(intent: PauseIntent) {
        presenter?.pause()
    }

    public func onReceiveDeeplink(
        params: [URLQueryItem]
    ) {
        presenter?.setDeeplinkParams(params: params)
    }
    
    public func resetPlayer(restart: Bool) {
        AudioManager.shared.reset(color: presenter?.getColor() ?? .White, restart: restart)
    }

    public func play() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(self.update),
                                     userInfo: nil,
                                     repeats: true)
        AudioManager.shared.play(
            color: presenter?.getColor() ?? .White,
            waves: presenter?.wavesEnabled ?? false,
            fade: presenter?.fadeEnabled ?? false
        )

        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        weak var weakSelf = self
        commandCenter.pauseCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            weakSelf?.presenter?.pause()
            return .success
        }

        commandCenter.playCommand.addTarget { (event) -> MPRemoteCommandHandlerStatus in
            weakSelf?.presenter?.play()
            return .success
        }

        animateButtonImage(newImageName: "pause", button: playButton)
    }

    
    public func setMediaTitle(title: String) {
        if let image = UIImage(named: "darkIcon") {
            let artwork = MPMediaItemArtwork
                .init(boundsSize: image.size,
                      requestHandler: { (size) -> UIImage in return image})
            
            let nowPlayingInfo = [MPMediaItemPropertyTitle : title,
                                  MPMediaItemPropertyArtwork : artwork]
                                        as [String : Any]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    public func pause() {
        timer?.invalidate()
        AudioManager.shared.pause()
        showPlayButtonPlayable()
    }
    
    private func showPlayButtonPlayable() {
        animateButtonImage(newImageName: "play", button: playButton)
    }

    private func animateButtonImage(newImageName: String, button: UIButton) {
        let btnImage = UIImage(named: newImageName)?.withRenderingMode(.alwaysTemplate)
        UIView.transition(with: button,
          duration: 0.3,
          options: .transitionFlipFromBottom,
          animations: {
            button.setImage(btnImage, for: UIControlState.normal)
          },
          completion: nil
        )
        button.tintColor = textColor
    }

    public func getTimerPickerTime() -> Double {
       return timerPicker.countDownDuration
    }
    
    public func cancelTimer(timerText: String) {
        timerPicker.isEnabled = true
        animateButtonImage(newImageName: "add", button: timerButton)
        animateTimer(
            hidden: true,
            completion: { self.setTimerText(text: timerText) }
        )
    }
    
    public func addTimer(timerText: String) {
        timerPicker.isEnabled = false
        animateButtonImage(newImageName: "delete", button: timerButton)

        setTimerText(text: timerText)
        animateTimer(hidden: false)
    }

    func animateTimer(hidden: Bool, completion: @escaping () -> Void = {}) {
        UIView.transition(with: timerLabel,
            duration: 0.3,
            options: .transitionFlipFromBottom,
            animations: {
                self.timerLabel.isHidden = hidden
            },
            completion: { _ in
                completion()
            }
        )
    }

    public func setTimerText(text: String) {
        var actualText = text
        if !actualText.isEmpty {
            actualText.append("\t")
        }
        timerLabel.text = actualText
    }
    
    public func setColor(color : NoiseColors) {
        switch color {
        case .White:
            colorSegmented.selectedSegmentIndex = 0
            wavesSwitch.onTintColor = grey
            fadeSwitch.onTintColor = grey
            break;
        case .Pink:
            colorSegmented.selectedSegmentIndex = 1
            wavesSwitch.onTintColor = pink
            fadeSwitch.onTintColor = pink
            break;
        case .Brown:
            colorSegmented.selectedSegmentIndex = 2
            wavesSwitch.onTintColor = brown
            fadeSwitch.onTintColor = brown
            break;
        }
    }
    
    public func setWavesEnabled(enabled : Bool) {
        wavesSwitch.setOn(enabled, animated: false)
    }
    
    public func setFadeEnabled(enabled : Bool) {
        fadeSwitch.setOn(enabled, animated: false)
    }
    
    public func setTimerPickerTime(seconds : Double) {
        timerPicker.countDownDuration = seconds
    }
    
    @IBAction func playPausePressed(_ sender: UIButton) {
        presenter?.playPause()
    }

    @IBAction func colorChangedAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            presenter?.changeColor(color: .White)
            break
        case 1:
            presenter?.changeColor(color: .Pink)
            break
        case 2:
            presenter?.changeColor(color: .Brown)
            break
        default:
            break
        }
    }
    
    
    @IBAction func wavesEnabledAction(_ sender: UISwitch) {
        presenter?.enableWavyVolume(enabled: sender.isOn)
    }
    
    @IBAction func fadeEnabledAction(_ sender: UISwitch) {
        presenter?.enableFadeVolume(enabled: sender.isOn)
    }
    
    @IBAction func timerAddedAction(_ sender: UIButton) {
        presenter?.addDeleteTimer()
    }
    
    @IBAction func themeButton(_ sender: Any) {
        if #available(iOS 14.0, *) {
            var settingsView = SettingsView(dismissAction: {self.dismiss( animated: true, completion: nil )})
            settingsView.rootVc = self
            
            let settingsVc = UIHostingController(rootView: settingsView)
            self.present(settingsVc, animated: true, completion: nil)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return themer.getStatusBarStyle()
    }
}
