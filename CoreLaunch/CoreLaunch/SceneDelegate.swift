//
//  SceneDelegate.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit
import SwiftUI

// Custom notification name for trait changes
extension NSNotification.Name {
    static let traitCollectionDidChange = NSNotification.Name("traitCollectionDidChange")
}

// Custom window class that posts notifications when trait collection changes
class ThemeAwareWindow: UIWindow {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Post notification about trait collection change
        NotificationCenter.default.post(
            name: .traitCollectionDidChange,
            object: self
        )
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    // MARK: - Custom Transition Coordinator
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Initialize the theme manager to ensure a theme is loaded
        let themeManager = ThemeManager.shared
        
        // Force refresh theme to ensure proper initialization
        themeManager.refreshTheme()
        
        // Use our custom window class that handles trait collection changes
        window = ThemeAwareWindow(windowScene: windowScene)
        let homeViewController = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
        
        // Register for transition events
        if let rootVC = window?.rootViewController {
            rootVC.transitionCoordinator?.animate(alongsideTransition: { context in
                // Ensure UserDefaults is synchronized during transitions
                UserDefaults.standard.synchronize()
            }, completion: { _ in })
        }
        
        // Apply the current theme to the window
        let isDarkMode = windowScene.traitCollection.userInterfaceStyle == .dark
        themeManager.applyTheme(to: window!, isDarkMode: isDarkMode)
        
        // Register for theme change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: NSNotification.Name("ThemeDidChangeNotification"),
            object: nil
        )
        
        window?.makeKeyAndVisible()
    }
    
    // Handle theme changes
    @objc func themeDidChange() {
        guard let window = window, let windowScene = window.windowScene else { return }
        
        // Refresh theme explicitly
        ThemeManager.shared.refreshTheme()
        
        // Get current trait collection to determine if we're in dark mode
        let isDarkMode = windowScene.traitCollection.userInterfaceStyle == .dark
        
        let currentTheme = ThemeManager.shared.currentTheme
        print("SceneDelegate applying theme: \(currentTheme.name), background: \(currentTheme.backgroundColor)")
        
        // Special case for Light and Monochrome themes
        if currentTheme.name == "Light" || currentTheme.name == "Monochrome" {
            window.backgroundColor = .white
            print("Light or Monochrome theme detected in SceneDelegate - forcing white background")
        }
        
        // Apply theme to window and all subviews
        ThemeManager.shared.applyTheme(to: window, isDarkMode: isDarkMode)
        
        // Force UI update
        window.setNeedsLayout()
        window.layoutIfNeeded()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
        // Force refresh theme when app becomes active
        ThemeManager.shared.refreshTheme()
        
        // Apply theme if Light or Monochrome theme is selected
        if ThemeManager.shared.currentTheme.name == "Light" || ThemeManager.shared.currentTheme.name == "Monochrome" {
            window?.backgroundColor = .white
            print("Light or Monochrome theme applied in sceneDidBecomeActive")
        }
        
        // Send notification to refresh all views
        NotificationCenter.default.post(
            name: NSNotification.Name("ThemeDidChangeNotification"),
            object: nil
        )
        
        // Post a custom notification to tell other views the app became active
        NotificationCenter.default.post(
            name: NSNotification.Name("ApplicationDidBecomeActiveNotification"),
            object: nil
        )
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        print("SceneDelegate sceneWillEnterForeground")
        
        // Force UserDefaults synchronization during transition
        UserDefaults.standard.synchronize()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    

    
}

