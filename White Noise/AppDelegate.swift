import AppIntents
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        StartPlayingIntent.playHandler = { colorRaw, waves, fade in
            let color = NoiseColors(rawValue: colorRaw) ?? .white
            if fade {
                let timerSeconds = UserDefaults(suiteName: "group.com.dalbers.WhiteNoise")?.double(forKey: "timerKey") ?? 0
                if timerSeconds > 0 { AudioManager.shared.fadeSeconds = Int(timerSeconds) }
            }
            AudioManager.shared.play(color: color, waves: waves, fade: fade)
        }
        StopPlayingIntent.stopHandler = {
            AudioManager.shared.pause()
        }
        if #available(iOS 16.0, *) {
            WhiteNoiseShortcuts.updateAppShortcutParameters()
        }
        return true
    }

    func applicationWillResignActive(_: UIApplication) {}

    func applicationDidEnterBackground(_: UIApplication) {}

    func applicationWillEnterForeground(_: UIApplication) {}

    func applicationDidBecomeActive(_: UIApplication) {}

    func applicationWillTerminate(_: UIApplication) {}

    func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([Any]?) -> Void) -> Bool {
        if #available(iOS 12.0, *),
           let viewController = window?.rootViewController as? ViewController,
           let intent = userActivity.interaction?.intent
        {
            switch intent {
            case let playIntent as PlayIntent:
                viewController.onReceiveIntent(intent: playIntent)
            case let pauseIntent as PauseIntent:
                viewController.onReceiveIntent(intent: pauseIntent)
            default:
                return false
            }
            return true
        }
        return false
    }

    func application(_: UIApplication,
                     open url: URL,
                     options _: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool
    {
        if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
           let params = components.queryItems,
           let viewController = window?.rootViewController as? ViewController
        {
            viewController.onReceiveDeeplink(params: params)
            return true
        } else {
            return false
        }
    }
}

@available(iOS 16.0, *)
struct WhiteNoiseShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartPlayingIntent(),
            phrases: [
                "Play \(.applicationName)",
                "Start \(.applicationName)",
                "Play \(\.$color) noise with \(.applicationName)",
            ],
            shortTitle: "Play White Noise",
            systemImageName: "speaker.wave.3"
        )
    }
}
