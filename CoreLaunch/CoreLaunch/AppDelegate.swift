//
//  AppDelegate.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit
import NotificationCenter
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up default settings if they don't exist
        let defaults = UserDefaults.standard
        
        if !defaults.bool(forKey: "defaultsInitialized") {
            defaults.set(false, forKey: "use24HourTime")
            defaults.set(true, forKey: "showDate")
            defaults.set(true, forKey: "useMinimalistStyle")
            defaults.set(false, forKey: "useMonochromeIcons")
            defaults.set(true, forKey: "showMotivationalMessages")
            defaults.set(true, forKey: "defaultsInitialized")
        }
        
        // Initialize usage tracker
        _ = UsageTracker.shared
        
        // Initialize focus mode manager
        _ = FocusModeManager.shared
        
        // Register for app lifecycle notifications to track usage
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Set up daily usage alerts
        setupUsageLimitNotifications()
        
        return true
    }
    
    // MARK: - App Lifecycle Tracking
    
    @objc func appWillResignActive() {
        // No longer recording CoreLaunch usage
        // Just keep the notification center functionality
    }
    
    @objc func appDidBecomeActive() {
        // No longer recording CoreLaunch usage
        
        // Post a notification that can be observed by the HomeViewController
        NotificationCenter.default.post(name: NSNotification.Name("ApplicationDidBecomeActiveNotification"), object: nil)
        
        // Check if we need to show usage limit notifications
        checkUsageLimits()
        
        // Check if any app is being launched during focus mode
        checkFocusModeRestrictions()
    }
    
    // MARK: - Usage Alerts
    
    private func setupUsageLimitNotifications() {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Register notification categories for focus mode
        registerFocusModeNotificationCategory()
    }
    
    private func checkUsageLimits() {
        // Check if user has exceeded their daily usage limit
        if UsageTracker.shared.hasExceededDailyLimit() {
            showUsageLimitExceededNotification()
        }
    }
    
    private func showUsageLimitExceededNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Usage Limit Exceeded"
        content.body = "You've exceeded your daily screen time goal. Take a break!"
        content.sound = .default
        
        // Create a notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with the trigger and content
        let request = UNNotificationRequest(
            identifier: "usageLimitExceeded",
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Focus Mode
    
    private func registerFocusModeNotificationCategory() {
        // Create actions
        let endAction = UNNotificationAction(identifier: "END_FOCUS", title: "End Focus Session", options: .destructive)
        let continueAction = UNNotificationAction(identifier: "CONTINUE_FOCUS", title: "Stay Focused", options: .foreground)
        
        // Create category
        let category = UNNotificationCategory(
            identifier: "FOCUS_MODE_ALERT",
            actions: [continueAction, endAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register category
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func checkFocusModeRestrictions() {
        // Get currently active app if possible
        guard let currentApp = getCurrentAppName() else { return }
        
        // Check if app is blocked by focus mode
        if FocusModeManager.shared.isAppBlocked(currentApp) {
            showFocusModeBlockedAlert(appName: currentApp)
        }
    }
    
    private func getCurrentAppName() -> String? {
        // In a real implementation, this would get the name of the app being launched
        // For our prototype, we'll return the name from a UserDefaults key set by the launcher
        return UserDefaults.standard.string(forKey: "lastLaunchedApp")
    }
    
    private func showFocusModeBlockedAlert(appName: String) {
        // In a full implementation, this would show the alert before the app fully launches
        // For our prototype, we'll show a notification
        
        let content = UNMutableNotificationContent()
        content.title = "Focus Mode Active"
        content.body = "\(appName) is blocked during your focus session."
        content.sound = .default
        content.categoryIdentifier = "FOCUS_MODE_ALERT"
        
        // Create a notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with the trigger and content
        let request = UNNotificationRequest(
            identifier: "focusModeBlocked",
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
