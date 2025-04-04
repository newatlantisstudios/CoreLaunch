//
//  BreathingRoomSettings.swift
//  CoreLaunch
//
//  Created on 4/4/25.
//

import Foundation

/// Model for tracking which apps have breathing room enabled and their delay durations
struct BreathingRoomAppSetting: Codable, Equatable {
    let appName: String
    var isEnabled: Bool
    var delayDuration: TimeInterval // in seconds
    
    init(appName: String, isEnabled: Bool = true, delayDuration: TimeInterval = 5.0) {
        self.appName = appName
        self.isEnabled = isEnabled
        self.delayDuration = delayDuration
    }
}

/// Manager class for breathing room settings
class BreathingRoomManager: Codable {
    // Coding keys for Codable conformance
    private enum CodingKeys: String, CodingKey {
        case isEnabled, appSettings, defaultDelay, reflectionPrompts
    }
    // Singleton instance
    static let shared = BreathingRoomManager()
    
    // Keys for UserDefaults
    private let enabledKey = "breathingRoomEnabled"
    private let appSettingsKey = "breathingRoomAppSettings"
    private let defaultDelayKey = "breathingRoomDefaultDelay"
    private let reflectionPromptsKey = "breathingRoomReflectionPrompts"
    
    // Properties
    private(set) var isEnabled: Bool = true
    private(set) var appSettings: [BreathingRoomAppSetting] = []
    private(set) var defaultDelay: TimeInterval = 5.0 // Default 5 seconds
    private(set) var reflectionPrompts: [String] = []
    
    private var userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    private init() {
        loadData()
        setupDefaultPromptsIfNeeded()
    }
    
    // MARK: - Codable Conformance
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        appSettings = try container.decode([BreathingRoomAppSetting].self, forKey: .appSettings)
        defaultDelay = try container.decode(TimeInterval.self, forKey: .defaultDelay)
        reflectionPrompts = try container.decode([String].self, forKey: .reflectionPrompts)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(appSettings, forKey: .appSettings)
        try container.encode(defaultDelay, forKey: .defaultDelay)
        try container.encode(reflectionPrompts, forKey: .reflectionPrompts)
    }
    
    // MARK: - Public Methods
    
    /// Enable or disable breathing room feature globally
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        saveSettings()
    }
    
    /// Set the default delay duration for new apps
    func setDefaultDelay(_ delay: TimeInterval) {
        defaultDelay = max(1.0, min(delay, 60.0)) // Cap between 1-60 seconds
        saveSettings()
    }
    
    /// Add or update app settings
    func setAppSetting(appName: String, isEnabled: Bool, delayDuration: TimeInterval) {
        // Check if the app already has settings
        if let index = appSettings.firstIndex(where: { $0.appName == appName }) {
            // Update existing settings
            var updatedSetting = appSettings[index]
            updatedSetting.isEnabled = isEnabled
            updatedSetting.delayDuration = max(1.0, min(delayDuration, 60.0)) // Cap between 1-60 seconds
            appSettings[index] = updatedSetting
        } else {
            // Create new settings
            let setting = BreathingRoomAppSetting(
                appName: appName,
                isEnabled: isEnabled,
                delayDuration: max(1.0, min(delayDuration, 60.0)) // Cap between 1-60 seconds
            )
            appSettings.append(setting)
        }
        
        saveSettings()
    }
    
    /// Remove app settings
    func removeAppSetting(for appName: String) {
        appSettings.removeAll { $0.appName == appName }
        saveSettings()
    }
    
    /// Get settings for a specific app
    func getAppSetting(for appName: String) -> BreathingRoomAppSetting? {
        return appSettings.first { $0.appName == appName }
    }
    
    /// Check if an app should have breathing room delay
    func shouldDelayApp(_ appName: String) -> Bool {
        // If breathing room is globally disabled, no delay
        guard isEnabled else { return false }
        
        // Check if this app has specific settings
        if let setting = getAppSetting(for: appName) {
            return setting.isEnabled
        }
        
        // No specific settings, assume no delay
        return false
    }
    
    /// Get the delay duration for an app
    func getDelayDuration(for appName: String) -> TimeInterval {
        // If breathing room is globally disabled, no delay
        guard isEnabled else { return 0 }
        
        // Check if this app has specific settings
        if let setting = getAppSetting(for: appName), setting.isEnabled {
            return setting.delayDuration
        }
        
        // No specific settings or disabled, use zero
        return 0
    }
    
    /// Get a random reflection prompt
    func getRandomReflectionPrompt() -> String {
        guard !reflectionPrompts.isEmpty else {
            return "Take a moment to breathe and reflect."
        }
        
        return reflectionPrompts[Int.random(in: 0..<reflectionPrompts.count)]
    }
    
    /// Add a custom reflection prompt
    func addReflectionPrompt(_ prompt: String) {
        if !reflectionPrompts.contains(prompt) {
            reflectionPrompts.append(prompt)
            saveSettings()
        }
    }
    
    /// Remove a reflection prompt
    func removeReflectionPrompt(at index: Int) {
        guard index >= 0 && index < reflectionPrompts.count else { return }
        reflectionPrompts.remove(at: index)
        saveSettings()
    }
    
    /// Reset reflection prompts to defaults
    func resetReflectionPromptsToDefault() {
        reflectionPrompts = getDefaultReflectionPrompts()
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func loadData() {
        isEnabled = userDefaults.bool(forKey: enabledKey)
        
        // Load default delay (use 5 seconds if not set)
        defaultDelay = userDefaults.double(forKey: defaultDelayKey)
        if defaultDelay < 1.0 {
            defaultDelay = 5.0
        }
        
        // Load app settings
        if let data = userDefaults.data(forKey: appSettingsKey),
           let settings = try? JSONDecoder().decode([BreathingRoomAppSetting].self, from: data) {
            appSettings = settings
        }
        
        // Load reflection prompts
        if let prompts = userDefaults.stringArray(forKey: reflectionPromptsKey) {
            reflectionPrompts = prompts
        }
    }
    
    private func saveSettings() {
        userDefaults.set(isEnabled, forKey: enabledKey)
        userDefaults.set(defaultDelay, forKey: defaultDelayKey)
        
        // Save app settings
        if let data = try? JSONEncoder().encode(appSettings) {
            userDefaults.set(data, forKey: appSettingsKey)
        }
        
        // Save reflection prompts
        userDefaults.set(reflectionPrompts, forKey: reflectionPromptsKey)
    }
    
    private func setupDefaultPromptsIfNeeded() {
        if reflectionPrompts.isEmpty {
            reflectionPrompts = getDefaultReflectionPrompts()
            saveSettings()
        }
    }
    
    private func getDefaultReflectionPrompts() -> [String] {
        return [
            "Is this app worth your attention right now?",
            "Take a deep breath. Is there something more important you could be doing?",
            "How will you feel after using this app for 30 minutes?",
            "What are you hoping to gain from opening this app?",
            "Is this a conscious choice or a habitual reaction?",
            "Will this app enhance or detract from your day?",
            "Consider your screen time goals. Is this aligned with them?",
            "Could you do something more meaningful with this time?",
            "What would happen if you didn't open this app right now?",
            "Is this a productive use of your attention?",
            "How will future you feel about this decision?",
            "Are you opening this app with intention or out of boredom?",
            "What else could you do with these few minutes?",
            "Is this app serving you, or are you serving it?",
            "Would doing something else bring you more joy?"
        ]
    }
}
