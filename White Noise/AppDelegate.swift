//
//  AppDelegate.swift
//  White Noise
//
//  Created by David Albers on 4/9/17.
//  Copyright © 2017 David Albers. All rights reserved.
//

import UIKit
import AppIntents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        StartPlayingIntent.playHandler = { colorRaw, waves, fade in
            let color = NoiseColors(rawValue: colorRaw) ?? .White
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if #available(iOS 12.0, *),
           let viewController = self.window?.rootViewController as? ViewController,
           let intent = userActivity.interaction?.intent {

            switch intent {
            case is PlayIntent:
                viewController.onReceiveIntent(intent: intent as! PlayIntent)
            case is PauseIntent:
                viewController.onReceiveIntent(intent: intent as! PauseIntent)
            default:
                return false
            }
            return true
        }
        return false
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:] ) -> Bool {
        if let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let params = components.queryItems,
            let viewController = self.window?.rootViewController as? ViewController {
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
                "Play \(\.$color) noise with \(.applicationName)"
            ],
            shortTitle: "Play White Noise",
            systemImageName: "speaker.wave.3"
        )
    }
}
