//
//  FocusMode.swift
//  CoreLaunch
//
//  Created on 4/2/25.
//

import Foundation
import UserNotifications

enum FocusModeState {
    case inactive
    case active
    case scheduled
}

struct FocusSession: Codable {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval // In seconds
    var endTime: Date { startTime.addingTimeInterval(duration) }
    var blockedApps: [String]
    var isCompleted: Bool
    var actualEndTime: Date?
    
    init(startTime: Date = Date(), duration: TimeInterval, blockedApps: [String]) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.blockedApps = blockedApps
        self.isCompleted = false
        self.actualEndTime = nil
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime && !isCompleted
    }
    
    var remainingTime: TimeInterval {
        if isCompleted || Date() > endTime {
            return 0
        }
        return endTime.timeIntervalSince(Date())
    }
    
    var formattedRemainingTime: String {
        let remainingSeconds = Int(remainingTime)
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var percentComplete: Double {
        let totalDuration = duration
        let elapsed = duration - remainingTime
        return min(1.0, max(0.0, elapsed / totalDuration))
    }
}

class FocusModeManager: Codable {
    // Define coding keys for Codable conformance
    private enum CodingKeys: String, CodingKey {
        case distractingApps
        case focusSessions
        case activeFocusSession
        case scheduledFocusSession
    }
    // Singleton instance
    static let shared = FocusModeManager()
    
    // Keys for UserDefaults
    private let distractingAppsKey = "distractingApps"
    private let focusSessionsKey = "focusSessions"
    private let activeFocusSessionKey = "activeFocusSession"
    private let scheduledFocusSessionKey = "scheduledFocusSession"
    
    // Properties
    private(set) var distractingApps: [String] = []
    private(set) var focusSessions: [FocusSession] = []
    private(set) var activeFocusSession: FocusSession?
    private(set) var scheduledFocusSession: FocusSession?
    
    private var userDefaults = UserDefaults.standard
    private var focusSessionTimer: Timer?
    
    // MARK: - Initialization
    private init() {
        loadData()
        checkForActiveSessions()
    }
    
    // Required initializer for Decodable conformance
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode properties from the container
        distractingApps = try container.decode([String].self, forKey: .distractingApps)
        focusSessions = try container.decode([FocusSession].self, forKey: .focusSessions)
        activeFocusSession = try container.decodeIfPresent(FocusSession.self, forKey: .activeFocusSession)
        scheduledFocusSession = try container.decodeIfPresent(FocusSession.self, forKey: .scheduledFocusSession)
        
        // Initialize properties that shouldn't be decoded
        userDefaults = UserDefaults.standard
        focusSessionTimer = nil
    }
    
    // Custom encoding method for Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(distractingApps, forKey: .distractingApps)
        try container.encode(focusSessions, forKey: .focusSessions)
        try container.encode(activeFocusSession, forKey: .activeFocusSession)
        try container.encode(scheduledFocusSession, forKey: .scheduledFocusSession)
    }
    
    // MARK: - Public Methods
    
    /// Add an app to the distracting apps list
    func addDistractingApp(_ appName: String) {
        if !distractingApps.contains(appName) {
            distractingApps.append(appName)
            saveDistractingApps()
        }
    }
    
    /// Remove an app from the distracting apps list
    func removeDistractingApp(_ appName: String) {
        if let index = distractingApps.firstIndex(of: appName) {
            distractingApps.remove(at: index)
            saveDistractingApps()
        }
    }
    
    /// Set distracting apps list
    func setDistractingApps(_ apps: [String]) {
        distractingApps = apps
        saveDistractingApps()
    }
    
    /// Get all distracting apps
    func getDistractingApps() -> [String] {
        return distractingApps
    }
    
    /// Start a focus session immediately
    func startFocusSession(duration: TimeInterval, blockedApps: [String]? = nil) -> FocusSession {
        // Schedule notifications for session start, halfway point, and near-end
        scheduleNotifications(for: duration)
        // If there's an active session, end it first
        if let activeSession = activeFocusSession {
            endFocusSession(completed: false)
        }
        
        // Create a new session
        let appsToBlock = blockedApps ?? distractingApps
        let session = FocusSession(startTime: Date(), duration: duration, blockedApps: appsToBlock)
        
        // Set it as the active session
        activeFocusSession = session
        
        // Add to history and save
        focusSessions.append(session)
        saveData()
        
        // Set up a timer to end the session
        setupFocusSessionTimer()
        
        // Post notification that focus mode started
        NotificationCenter.default.post(name: NSNotification.Name("FocusModeStateChanged"), object: nil)
        
        // Update widget
        updateWidget()
        
        return session
    }
    
    /// Schedule a focus session for later
    func scheduleFocusSession(startTime: Date, duration: TimeInterval, blockedApps: [String]? = nil) -> FocusSession {
        // Schedule notification to remind user of upcoming focus session
        scheduleReminderNotification(for: startTime, duration: duration)
        let appsToBlock = blockedApps ?? distractingApps
        let session = FocusSession(startTime: startTime, duration: duration, blockedApps: appsToBlock)
        
        // Set as scheduled session
        scheduledFocusSession = session
        
        // Save
        saveData()
        
        // Post notification that focus mode was scheduled
        NotificationCenter.default.post(name: NSNotification.Name("FocusModeStateChanged"), object: nil)
        
        // Update widget
        updateWidget()
        
        return session
    }
    
    /// End the current focus session
    func endFocusSession(completed: Bool = true) {
        // Remove any scheduled notifications for this session
        removeSessionNotifications()
        guard let session = activeFocusSession else { return }
        
        // Update the session
        var updatedSession = session
        updatedSession.isCompleted = true
        updatedSession.actualEndTime = Date()
        
        // Update in history
        if let index = focusSessions.firstIndex(where: { $0.id == session.id }) {
            focusSessions[index] = updatedSession
        }
        
        // Clear active session
        activeFocusSession = nil
        
        // Stop the timer
        focusSessionTimer?.invalidate()
        focusSessionTimer = nil
        
        // Save changes
        saveData()
        
        // Post notification that focus mode ended
        NotificationCenter.default.post(name: NSNotification.Name("FocusModeStateChanged"), object: nil)
        
        // Update widget
        updateWidget()
    }
    
    /// Cancel scheduled focus session
    func cancelScheduledFocusSession() {
        scheduledFocusSession = nil
        saveData()
        
        // Post notification that focus mode schedule changed
        NotificationCenter.default.post(name: NSNotification.Name("FocusModeStateChanged"), object: nil)
        
        // Update widget
        updateWidget()
    }
    
    /// Check if an app is currently blocked by focus mode
    func isAppBlocked(_ appName: String) -> Bool {
        guard let session = activeFocusSession, session.isActive else {
            return false
        }
        
        return session.blockedApps.contains(appName)
    }
    
    /// Get the current focus mode state
    func getCurrentState() -> FocusModeState {
        if activeFocusSession != nil && activeFocusSession!.isActive {
            return .active
        } else if scheduledFocusSession != nil {
            return .scheduled
        } else {
            return .inactive
        }
    }
    
    /// Get the active focus session if one exists and is active
    func getActiveFocusSession() -> FocusSession? {
        return activeFocusSession?.isActive == true ? activeFocusSession : nil
    }
    
    /// Get focus session history
    func getFocusSessionHistory() -> [FocusSession] {
        return focusSessions
    }
    
    /// Get recently completed focus sessions (last 7 days)
    func getRecentFocusSessions(days: Int = 7) -> [FocusSession] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        return focusSessions.filter { session in
            session.isCompleted && session.startTime >= startDate
        }
    }
    
    // MARK: - Notification Methods
    
    private func scheduleNotifications(for duration: TimeInterval) {
        // Remove any existing notifications first
        removeSessionNotifications()
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        // 1. Start notification
        let startContent = UNMutableNotificationContent()
        startContent.title = "Focus Session Started"
        startContent.body = "Your focus session has started. Stay focused!"
        startContent.sound = .default
        
        let startTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let startRequest = UNNotificationRequest(identifier: "focusStart", content: startContent, trigger: startTrigger)
        
        // 2. Halfway notification
        let halfwayContent = UNMutableNotificationContent()
        halfwayContent.title = "Focus Session Halfway"
        halfwayContent.body = "You're halfway through your focus session. Keep going!"
        halfwayContent.sound = .default
        
        let halfwayTrigger = UNTimeIntervalNotificationTrigger(timeInterval: duration / 2, repeats: false)
        let halfwayRequest = UNNotificationRequest(identifier: "focusHalfway", content: halfwayContent, trigger: halfwayTrigger)
        
        // 3. Almost done notification (1 minute before end)
        let almostDoneContent = UNMutableNotificationContent()
        almostDoneContent.title = "Focus Session Almost Complete"
        almostDoneContent.body = "Just one more minute in your focus session!"
        almostDoneContent.sound = .default
        
        let almostDoneTrigger = UNTimeIntervalNotificationTrigger(timeInterval: duration - 60, repeats: false)
        let almostDoneRequest = UNNotificationRequest(identifier: "focusAlmostDone", content: almostDoneContent, trigger: almostDoneTrigger)
        
        // 4. Complete notification
        let completeContent = UNMutableNotificationContent()
        completeContent.title = "Focus Session Complete"
        completeContent.body = "Great job! You've completed your focus session."
        completeContent.sound = .default
        
        let completeTrigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)
        let completeRequest = UNNotificationRequest(identifier: "focusComplete", content: completeContent, trigger: completeTrigger)
        
        // Add all notifications (only add almost done if duration > 120 seconds)
        notificationCenter.add(startRequest)
        notificationCenter.add(halfwayRequest)
        
        if duration > 120 {
            notificationCenter.add(almostDoneRequest)
        }
        
        notificationCenter.add(completeRequest)
    }
    
    private func scheduleReminderNotification(for startTime: Date, duration: TimeInterval) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Create content for reminder notification
        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "Focus Session Reminder"
        reminderContent.body = "Your scheduled focus session is about to start."
        reminderContent.sound = .default
        
        // Schedule notification 5 minutes before session starts
        let fiveMinutesBefore = startTime.addingTimeInterval(-300)
        let now = Date()
        
        // Only schedule if it's in the future and more than 5 minutes away
        if fiveMinutesBefore > now {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fiveMinutesBefore)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "focusReminder", content: reminderContent, trigger: trigger)
            
            notificationCenter.add(request)
        }
        
        // Also schedule notification right at session start time
        let startContent = UNMutableNotificationContent()
        startContent.title = "Focus Session Started"
        startContent.body = "Your scheduled focus session has started. Stay focused!"
        startContent.sound = .default
        
        let startComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startTime)
        let startTrigger = UNCalendarNotificationTrigger(dateMatching: startComponents, repeats: false)
        let startRequest = UNNotificationRequest(identifier: "scheduledFocusStart", content: startContent, trigger: startTrigger)
        
        notificationCenter.add(startRequest)
    }
    
    private func removeSessionNotifications() {
        // Remove all focus-related notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "focusStart",
            "focusHalfway",
            "focusAlmostDone",
            "focusComplete",
            "focusReminder",
            "scheduledFocusStart"
        ])
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        // Load distracting apps
        if let apps = userDefaults.stringArray(forKey: distractingAppsKey) {
            distractingApps = apps
        }
        
        // Load focus sessions
        if let data = userDefaults.data(forKey: focusSessionsKey),
           let sessions = try? JSONDecoder().decode([FocusSession].self, from: data) {
            focusSessions = sessions
        }
        
        // Load active session
        if let data = userDefaults.data(forKey: activeFocusSessionKey),
           let session = try? JSONDecoder().decode(FocusSession.self, from: data) {
            activeFocusSession = session
        }
        
        // Load scheduled session
        if let data = userDefaults.data(forKey: scheduledFocusSessionKey),
           let session = try? JSONDecoder().decode(FocusSession.self, from: data) {
            scheduledFocusSession = session
        }
    }
    
    private func saveData() {
        // Save focus sessions
        if let data = try? JSONEncoder().encode(focusSessions) {
            userDefaults.set(data, forKey: focusSessionsKey)
        }
        
        // Save active session
        if let session = activeFocusSession, let data = try? JSONEncoder().encode(session) {
            userDefaults.set(data, forKey: activeFocusSessionKey)
        } else {
            userDefaults.removeObject(forKey: activeFocusSessionKey)
        }
        
        // Save scheduled session
        if let session = scheduledFocusSession, let data = try? JSONEncoder().encode(session) {
            userDefaults.set(data, forKey: scheduledFocusSessionKey)
        } else {
            userDefaults.removeObject(forKey: scheduledFocusSessionKey)
        }
    }
    
    private func saveDistractingApps() {
        userDefaults.set(distractingApps, forKey: distractingAppsKey)
    }
    
    private func updateWidget() {
        // Widget functionality removed
    }
    
    private func checkForActiveSessions() {
        // Check if the active session is still valid
        if let session = activeFocusSession {
            if !session.isActive {
                // Session has expired, mark as complete
                endFocusSession(completed: true)
            } else {
                // Session is still active, set up the timer
                setupFocusSessionTimer()
            }
        }
        
        // Check if a scheduled session should start
        if let scheduled = scheduledFocusSession {
            let now = Date()
            if now >= scheduled.startTime && now <= scheduled.endTime {
                // Time to start this session
                activeFocusSession = scheduled
                scheduledFocusSession = nil
                setupFocusSessionTimer()
                
                // Post notification that focus mode started
                NotificationCenter.default.post(name: NSNotification.Name("FocusModeStateChanged"), object: nil)
            } else if now > scheduled.endTime {
                // Scheduled session has passed without being activated
                scheduledFocusSession = nil
                saveData()
            }
        }
    }
    
    private func setupFocusSessionTimer() {
        // Cancel any existing timer
        focusSessionTimer?.invalidate()
        
        guard let session = activeFocusSession, session.isActive else { return }
        
        // Create a timer that fires every second to update the session status
        focusSessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let activeSession = self.activeFocusSession else { return }
            
            if !activeSession.isActive {
                // Session has ended, complete it
                self.endFocusSession(completed: true)
            } else {
                // Post notification to update any UI showing the timer
                NotificationCenter.default.post(name: NSNotification.Name("FocusModeTimerUpdated"), object: nil)
                
                // Update widget every 15 seconds to keep timer current
                if Int(activeSession.remainingTime) % 15 == 0 {
                    updateWidget()
                }
            }
        }
    }
}
