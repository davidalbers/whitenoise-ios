import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

class ViewController: UIViewController {
    var presenter: MainPresenter?
    var timer: Timer?
    private let themer = Themer()

    @IBOutlet var playButton: UIButton!
    @IBOutlet var timerPicker: UIDatePicker!
    @IBOutlet var timerButton: UIButton!
    @IBOutlet var timerLabel: UILabel!
    @IBOutlet var wavesSwitch: UISwitch!
    @IBOutlet var fadeSwitch: UISwitch!
    @IBOutlet var colorSegmented: UISegmentedControl!
    @IBOutlet var themeButton: UIButton!

    let grey: UIColor = .init(named: "darkGrey") ?? UIColor.yellow
    let pink: UIColor = .init(named: "pink") ?? UIColor.systemPink
    let brown: UIColor = .init(named: "brown") ?? UIColor.brown
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
        setupRemoteCommandCenter()
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

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        guard let presenter, AudioManager.shared.isPlaying else { return }
        let color = presenter.settingsSource.color()
        presenter.currentColor = color
        setColor(color: color)
        presenter.wavesEnabled = presenter.settingsSource.wavesEnabled()
        presenter.fadeEnabled = presenter.settingsSource.fadeEnabled()
        setWavesEnabled(enabled: presenter.wavesEnabled)
        setFadeEnabled(enabled: presenter.fadeEnabled)
    }

    private func syncTimerWithSavedState() {
        guard let presenter, AudioManager.shared.isPlaying else { return }
        let savedSeconds = presenter.settingsSource.timerSeconds()
        if savedSeconds == 0 {
            guard presenter.timerActive else { return }
            presenter.timerActive = false
            presenter.timerDisplayed = false
            presenter.timeLeftSecs = 0
            cancelTimer(timerText: "")
        } else if !presenter.timerActive || savedSeconds != getTimerPickerTime() {
            setTimerPickerTime(seconds: savedSeconds)
            presenter.timerActive = true
            presenter.timerDisplayed = true
            presenter.timeLeftSecs = savedSeconds
            if presenter.fadeEnabled { AudioManager.shared.fadeSeconds = Int(savedSeconds) }
            addTimer(timerText: formatTimerSeconds(savedSeconds))
        }
    }

    private func formatTimerSeconds(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        return hours > 0 ? String(format: "%02i:%02i:%02i", hours, minutes, secs) : String(format: "%02i:%02i", minutes, secs)
    }

    private func syncWithAudioManager() {
        guard let presenter else { return }
        if AudioManager.shared.isPlaying, !presenter.isPlaying {
            presenter.isPlaying = true
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                         target: self,
                                         selector: #selector(update),
                                         userInfo: nil,
                                         repeats: true)
            animateButtonImage(newImageName: "pause", button: playButton)
        } else if !AudioManager.shared.isPlaying, presenter.isPlaying {
            presenter.isPlaying = false
            timer?.invalidate()
            showPlayButtonPlayable()
        }
    }

    @objc func update() {
        presenter?.tick()
    }

    @available(iOS 12.0, *)
    func onReceiveIntent(intent: PlayIntent) {
        presenter?.setIntent(intent: intent)
    }

    @available(iOS 12.0, *)
    func onReceiveIntent(intent _: PauseIntent) {
        presenter?.pause()
    }

    func onReceiveDeeplink(
        params: [URLQueryItem]
    ) {
        presenter?.setDeeplinkParams(params: params)
    }

    func resetPlayer(restart: Bool) {
        AudioManager.shared.reset(color: presenter?.getColor() ?? .white, restart: restart)
    }

    func play() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: MainPresenter.tickInterval,
                                     target: self,
                                     selector: #selector(update),
                                     userInfo: nil,
                                     repeats: true)
        AudioManager.shared.play(
            color: presenter?.getColor() ?? .white,
            waves: presenter?.wavesEnabled ?? false,
            fade: presenter?.fadeEnabled ?? false
        )

        animateButtonImage(newImageName: "pause", button: playButton)
    }

    func setMediaTitle(title: String) {
        if let image = UIImage(named: "darkIcon") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size,
                                             requestHandler: { _ -> UIImage in return image })

            let nowPlayingInfo = [MPMediaItemPropertyTitle: title,
                                  MPMediaItemPropertyArtwork: artwork]
                as [String: Any]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    func pause() {
        timer?.invalidate()
        AudioManager.shared.pause()
        showPlayButtonPlayable()
    }

    private func setupRemoteCommandCenter() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.presenter?.pause()
            return .success
        }
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.presenter?.play()
            return .success
        }
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
                          completion: nil)
        button.tintColor = textColor
    }

    func getTimerPickerTime() -> Double {
        timerPicker.countDownDuration
    }

    func cancelTimer(timerText: String) {
        timerPicker.isEnabled = true
        animateButtonImage(newImageName: "add", button: timerButton)
        animateTimer(
            hidden: true,
            completion: { self.setTimerText(text: timerText) }
        )
    }

    func addTimer(timerText: String) {
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
                          })
    }

    func setTimerText(text: String) {
        var actualText = text
        if !actualText.isEmpty {
            actualText.append("\t")
        }
        timerLabel.text = actualText
    }

    func setColor(color: NoiseColors) {
        switch color {
        case .white:
            colorSegmented.selectedSegmentIndex = 0
            wavesSwitch.onTintColor = grey
            fadeSwitch.onTintColor = grey
        case .pink:
            colorSegmented.selectedSegmentIndex = 1
            wavesSwitch.onTintColor = pink
            fadeSwitch.onTintColor = pink
        case .brown:
            colorSegmented.selectedSegmentIndex = 2
            wavesSwitch.onTintColor = brown
            fadeSwitch.onTintColor = brown
        }
    }

    func setWavesEnabled(enabled: Bool) {
        wavesSwitch.setOn(enabled, animated: false)
    }

    func setFadeEnabled(enabled: Bool) {
        fadeSwitch.setOn(enabled, animated: false)
    }

    func setTimerPickerTime(seconds: Double) {
        timerPicker.countDownDuration = seconds
    }

    @IBAction func playPausePressed(_: UIButton) {
        presenter?.playPause()
    }

    @IBAction func colorChangedAction(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            presenter?.changeColor(color: .white)
        case 1:
            presenter?.changeColor(color: .pink)
        case 2:
            presenter?.changeColor(color: .brown)
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

    @IBAction func timerAddedAction(_: UIButton) {
        presenter?.addDeleteTimer()
    }

    @IBAction func themeButton(_: Any) {
        if #available(iOS 14.0, *) {
            var settingsView = SettingsView(dismissAction: { self.dismiss(animated: true, completion: nil) })
            settingsView.rootVc = self

            let settingsVc = UIHostingController(rootView: settingsView)
            present(settingsVc, animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        themer.getStatusBarStyle()
    }
}
