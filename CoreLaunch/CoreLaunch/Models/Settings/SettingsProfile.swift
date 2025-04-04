//
//  SettingsProfile.swift
//  CoreLaunch
//
//  Created on 4/4/25.
//

import UIKit

struct SettingsProfile: Codable {
    var name: String
    var isActive: Bool
    
    // Time display settings
    var use24HourTime: Bool
    var showDate: Bool
    
    // Appearance settings
    var useMinimalistStyle: Bool
    
    // Icon settings
    var useMonochromeIcons: Bool
    
    // Wellness settings
    var showMotivationalMessages: Bool
    
    // Text settings
    var textSizeMultiplier: Float
    var fontName: String
    
    // Theme
    var themeName: String
    
    init(name: String, 
         isActive: Bool = false,
         use24HourTime: Bool = false,
         showDate: Bool = true,
         useMinimalistStyle: Bool = true,
         useMonochromeIcons: Bool = false,
         showMotivationalMessages: Bool = true,
         textSizeMultiplier: Float = 1.0,
         fontName: String = "System",
         themeName: String = "Auto Light and Dark") {
        
        self.name = name
        self.isActive = isActive
        self.use24HourTime = use24HourTime
        self.showDate = showDate
        self.useMinimalistStyle = useMinimalistStyle
        self.useMonochromeIcons = useMonochromeIcons
        self.showMotivationalMessages = showMotivationalMessages
        self.textSizeMultiplier = textSizeMultiplier
        self.fontName = fontName
        self.themeName = themeName
    }
    
    static func getCurrentSettings() -> SettingsProfile {
        let defaults = UserDefaults.standard
        
        // Create a profile with current settings
        let profile = SettingsProfile(
            name: "Current Settings",
            isActive: true,
            use24HourTime: defaults.bool(forKey: "use24HourTime"),
            showDate: defaults.bool(forKey: "showDate"),
            useMinimalistStyle: defaults.bool(forKey: "useMinimalistStyle"),
            useMonochromeIcons: defaults.bool(forKey: "useMonochromeIcons"),
            showMotivationalMessages: defaults.bool(forKey: "showMotivationalMessages"),
            textSizeMultiplier: defaults.float(forKey: "textSizeMultiplier"),
            fontName: defaults.string(forKey: "fontName") ?? "System",
            themeName: ThemeManager.shared.currentTheme.name
        )
        
        return profile
    }
    
    // Apply this profile's settings to the app
    func apply() {
        let defaults = UserDefaults.standard
        
        // Apply time settings
        defaults.set(use24HourTime, forKey: "use24HourTime")
        defaults.set(showDate, forKey: "showDate")
        
        // Apply appearance settings
        defaults.set(useMinimalistStyle, forKey: "useMinimalistStyle")
        
        // Apply icon settings
        defaults.set(useMonochromeIcons, forKey: "useMonochromeIcons")
        
        // Apply wellness settings
        defaults.set(showMotivationalMessages, forKey: "showMotivationalMessages")
        
        // Apply text settings
        defaults.set(textSizeMultiplier, forKey: "textSizeMultiplier")
        defaults.set(fontName, forKey: "fontName")
        
        // Apply theme
        if let theme = ThemeManager.shared.getAllThemes().first(where: { $0.name == themeName }) {
            ThemeManager.shared.currentTheme = theme
        }
        
        // Post notification that settings changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsDidChangeNotification"), object: nil)
    }
}

// MARK: - SettingsProfileManager
class SettingsProfileManager {
    static let shared = SettingsProfileManager()
    
    private let profilesKey = "settingsProfiles"
    private let activeProfileKey = "activeProfileName"
    
    private init() {}
    
    // Get all saved profiles
    func getAllProfiles() -> [SettingsProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            var profiles = try decoder.decode([SettingsProfile].self, from: data)
            
            // Ensure active status is correctly set
            if let activeProfileName = UserDefaults.standard.string(forKey: activeProfileKey) {
                for i in 0..<profiles.count {
                    profiles[i].isActive = (profiles[i].name == activeProfileName)
                }
            }
            
            return profiles
        } catch {
            print("Failed to load profiles: \(error)")
            return []
        }
    }
    
    // Save all profiles
    func saveProfiles(_ profiles: [SettingsProfile]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profiles)
            UserDefaults.standard.set(data, forKey: profilesKey)
        } catch {
            print("Failed to save profiles: \(error)")
        }
    }
    
    // Get active profile name
    func getActiveProfileName() -> String? {
        return UserDefaults.standard.string(forKey: activeProfileKey)
    }
    
    // Set active profile
    func setActiveProfile(_ profile: SettingsProfile) {
        UserDefaults.standard.set(profile.name, forKey: activeProfileKey)
        
        // Update active status in saved profiles
        var profiles = getAllProfiles()
        for i in 0..<profiles.count {
            profiles[i].isActive = (profiles[i].name == profile.name)
        }
        saveProfiles(profiles)
        
        // Apply the profile settings
        profile.apply()
    }
    
    // Save a new profile or update existing
    func saveProfile(_ profile: SettingsProfile) {
        var profiles = getAllProfiles()
        
        // Check if profile with this name already exists
        if let index = profiles.firstIndex(where: { $0.name == profile.name }) {
            profiles[index] = profile // Update existing profile
        } else {
            profiles.append(profile) // Add new profile
        }
        
        saveProfiles(profiles)
        
        // If this is active profile, update active profile key
        if profile.isActive {
            UserDefaults.standard.set(profile.name, forKey: activeProfileKey)
        }
    }
    
    // Delete a profile
    func deleteProfile(_ profileName: String) {
        var profiles = getAllProfiles()
        
        // Don't delete the active profile
        guard profiles.first(where: { $0.name == profileName })?.isActive != true else {
            return
        }
        
        profiles.removeAll { $0.name == profileName }
        saveProfiles(profiles)
    }
}
