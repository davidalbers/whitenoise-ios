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
    
    let grey : UIColor = UIColor(red: 201, green: 201, blue: 201)
    let pink : UIColor = UIColor(red: 255, green: 207, blue: 203)
    let brown : UIColor = UIColor(red: 161, green: 136, blue: 127)

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
        timerLabel.text = ""
        timerPicker.setValue(UIColor.white, forKey: "textColor")
        presenter = MainPresenter(viewController: self)
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
        
        let btnImage = UIImage(named: "pause")
        playButton.setImage(btnImage, for: UIControlState.normal)
    }

    public func pause() {
        timer?.invalidate()
        player?.pause()
        
        let btnImage = UIImage(named: "play")
        playButton.setImage(btnImage, for: UIControlState.normal)
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
        timerButton.setImage(UIImage(named: "add"), for: .normal)
        setTimerText(text: timerText)
    }
    
    public func addTimer(timerText: String) {
        timerPicker.isEnabled = false
        timerButton.setImage(UIImage(named: "delete"), for: .normal)
        setTimerText(text: timerText)
    }
    
    public func setTimerText(text: String) {
        timerLabel.text = text
    }
    
    public func setColor(color : MainPresenter.NoiseColors) {
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

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

