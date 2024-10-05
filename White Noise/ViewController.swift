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
    lazy var player: AVAudioPlayer? = self.makePlayer()
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
        presenter = MainPresenter(viewController: self)
        presenter?.loadSavedState()
        if #available(iOS 14.0, *) {
            overrideUserInterfaceStyle = themer.getUIUserInterfaceStyle()
            themeButton.imageView?.tintColor = textColor
            themeButton.isHidden = false
        } else {
            themeButton.isHidden = true
        }
        showPlayButtonPlayable()
    }
    
    @objc func update() {
        presenter?.tick()
    }
    
    public func makeActiveAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
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
    
    private func makePlayer() -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: presenter?.getColor().rawValue,
                                  withExtension: "mp3")!
        let player = try? AVAudioPlayer(contentsOf: url)

        player?.numberOfLoops = -1
        return player
    }
    
    public func resetPlayer(restart: Bool) {
        player?.pause()
        player = makePlayer()
        if (restart) {
            player?.play()
        }
    }
    
    public func play() {
        makeActiveAudioSession()
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(self.update),
                                     userInfo: nil,
                                     repeats: true)
        player?.play()
        
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
        
        playButton.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate), for: UIControlState.normal)
        playButton.imageView?.tintColor = textColor
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
        player?.pause()
        
        showPlayButtonPlayable()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error setting audio session active=false")
        }
    }
    
    private func showPlayButtonPlayable() {
        let btnImage = UIImage(named: "play")?.withRenderingMode(.alwaysTemplate)
        playButton.setImage(btnImage, for: UIControlState.normal)
        playButton.tintColor = textColor
    }
    
    public func setVolume(volume: Float) {
        player?.setVolume(volume, fadeDuration: 0)
    }
    
    public func getTimerPickerTime() -> Double {
       return timerPicker.countDownDuration
    }
    
    public func cancelTimer(timerText: String) {
        timerPicker.isEnabled = true
        timerButton.setImage(UIImage(named: "add")?.withRenderingMode(.alwaysTemplate), for: .normal)
        timerButton.imageView?.tintColor = textColor
        setTimerText(text: timerText)
    }
    
    public func addTimer(timerText: String) {
        timerPicker.isEnabled = false
        timerButton.setImage(UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate), for: .normal)
        timerButton.imageView?.tintColor = textColor
        setTimerText(text: timerText)
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
