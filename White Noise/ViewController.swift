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

class ViewController: UIViewController {
    lazy var player: AVAudioPlayer? = self.makePlayer()
    var presenter: MainPresenter?
    var timer: Timer?
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timerPicker: UIDatePicker!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var wavesSwitch: UISwitch!
    @IBOutlet weak var fadeSwitch: UISwitch!
    @IBOutlet weak var colorSegmented: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(
            AVAudioSessionCategoryPlayAndRecord,
            with: [
                .defaultToSpeaker,
                .allowBluetooth,
                .allowAirPlay,
                .allowBluetoothA2DP])
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
        presenter = MainPresenter(viewController: self)
        wavesSwitch.onTintColor = UIColor.brown
        fadeSwitch.onTintColor = UIColor.brown
        presenter?.loadSaved()
    }
    
    func update() {
        presenter?.tick()
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
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(self.update),
                                     userInfo: nil,
                                     repeats: true)
        player?.play()
        playButton.setTitle("Pause", for: .normal)
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
        presenter?.saveState()
    }

    public func pause() {
        timer?.invalidate()
        player?.pause()
        playButton.setTitle("Play", for: .normal)
    }
    
    public func setVolume(volume: Float) {
        print(volume)
        player?.setVolume(volume, fadeDuration: 0)
    }
    
    public func getTimerPickerTime() -> Double {
       return timerPicker.countDownDuration
    }
    
    public func cancelTimer(timerText: String) {
        timerPicker.isEnabled = true
        timerButton.setTitle("Set", for: .normal)
        setTimerText(text: timerText)
    }
    
    public func addTimer(timerText: String) {
        timerPicker.isEnabled = false
        timerButton.setTitle("Clear", for: .normal)
        setTimerText(text: timerText)
    }
    
    public func setTimerText(text: String) {
        timerLabel.text = text
    }
    
    public func setColor(color : MainPresenter.NoiseColors) {
        switch color {
        case .White:
            colorSegmented.selectedSegmentIndex = 0
            break;
        case .Pink:
            colorSegmented.selectedSegmentIndex = 1
            break;
        case .Brown:
            colorSegmented.selectedSegmentIndex = 2
            break;
        }
    }
    
    public func setWavesEnabled(enabled : Bool) {
        wavesSwitch.setOn(enabled, animated: false)
    }
    
    public func setFadeEnabled(enabled : Bool) {
        fadeSwitch.setOn(enabled, animated: false)
    }
    
    public func setTimerPickerTime(time : Double) {
        timerPicker.countDownDuration = time
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
}

