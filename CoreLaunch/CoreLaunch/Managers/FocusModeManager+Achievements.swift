//
//  FocusModeManager+Achievements.swift
//  CoreLaunch
//
//  Created for Positive Reinforcement System
//

import Foundation

extension FocusModeManager {
    // MARK: - Properties
    
    // Add property to track the last completed session
    private(set) var lastCompletedSession: FocusSession? {
        get {
            if let data = UserDefaults.standard.data(forKey: "lastCompletedFocusSession"),
               let session = try? JSONDecoder().decode(FocusSession.self, from: data) {
                return session
            }
            return nil
        }
        set {
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "lastCompletedFocusSession")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastCompletedFocusSession")
            }
        }
    }
    
    // MARK: - Enhanced Methods
    
    /// Enhanced version of endFocusSession that checks for achievements
    func endFocusSessionWithAchievement(completed: Bool = true) {
        // Store the session before ending it
        let sessionToCheck = activeFocusSession
        
        // End the session using the original method
        endFocusSession(completed: completed)
        
        // Check for achievements if the session was completed
        if completed, let session = sessionToCheck {
            // Store the last completed session
            lastCompletedSession = session
            
            // Check for focus session achievements
            UsageTracker.shared.checkFocusSessionAchievements(
                completed: true,
                duration: session.duration
            )
        }
    }
}
