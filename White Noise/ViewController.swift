//
//  ViewController.swift
//  White Noise
//
//  Created by David Albers on 4/9/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    lazy var player: AVAudioPlayer? = self.makePlayer()
    var presenter: MainPresenter?
    var timer: Timer?
    
    @IBOutlet weak var playButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(
            AVAudioSessionCategoryPlayAndRecord,
            with: .defaultToSpeaker)
        } catch {
            print("Failed to set audio session category.  Error: \(error)")
        }
        presenter = MainPresenter(viewController: self)
    }
    
    func update() {
        presenter?.tick()
    }
    
  
    private func makePlayer() -> AVAudioPlayer? {
        let url = Bundle.main.url(forResource: presenter?.getColor().rawValue, withExtension: "mp3")!
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
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        playButton.isSelected = true
        player?.play()
        playButton.setTitle("Pause", for: .normal)
    }
    
    public func pause() {
        timer?.invalidate()
        playButton.isSelected = false
        player?.pause()
        playButton.setTitle("Play", for: .normal)
    }
    
    public func setVolume(volume: Float) {
        player?.setVolume(volume, fadeDuration: 10)
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
    }
}

