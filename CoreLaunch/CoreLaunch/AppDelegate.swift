//
//  AppDelegate.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit
import NotificationCenter

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
            defaults.set(true, forKey: "defaultsInitialized")
        }
        
        // Initialize usage tracker
        _ = UsageTracker.shared
        
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

