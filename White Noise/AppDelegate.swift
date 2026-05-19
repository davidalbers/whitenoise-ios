import AppIntents
import SwiftUI
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var mainViewModel: MainViewModel!
    var entitlementsManager: EntitlementsManager!
    var purchaseManager: PurchaseManager!

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        mainViewModel = MainViewModel()
        entitlementsManager = EntitlementsManager()
        purchaseManager = PurchaseManager(entitlements: entitlementsManager)

        StartPlayingIntent.playHandler = { [weak self] colorRaw, wavesIntensity, fade in
            self?.mainViewModel.handleStartIntent(colorRaw: colorRaw, wavesIntensity: wavesIntensity, fade: fade)
        }
        StopPlayingIntent.stopHandler = { [weak self] in
            self?.mainViewModel.pause()
        }
        WhiteNoiseShortcuts.updateAppShortcutParameters()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIHostingController(
            rootView: MainView(viewModel: mainViewModel)
                .environment(entitlementsManager)
                .environment(purchaseManager)
        )
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillResignActive(_: UIApplication) {}

    func applicationDidEnterBackground(_: UIApplication) {}

    func applicationWillEnterForeground(_: UIApplication) {}

    func applicationDidBecomeActive(_: UIApplication) {}

    func applicationWillTerminate(_: UIApplication) {}

    func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([Any]?) -> Void) -> Bool {
        guard let intent = userActivity.interaction?.intent else { return false }
        switch intent {
        case let playIntent as PlayIntent:
            mainViewModel.setIntent(intent: playIntent)
        case _ as PauseIntent:
            mainViewModel.handlePauseIntent()
        default:
            return false
        }
        return true
    }

    func application(_: UIApplication,
                     open url: URL,
                     options _: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool
    {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              components.queryItems != nil else { return false }
        return true
    }
}

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
