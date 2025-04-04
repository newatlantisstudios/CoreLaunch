import Foundation
import UIKit

class ProfileManager {
    static let shared = ProfileManager()
    
    private let profilesKey = "userProfiles"
    private let activeProfileKey = "activeProfileIndex"
    
    private(set) var profiles: [Profile] = []
    private(set) var activeProfileIndex: Int = 0
    
    init() {
        loadProfiles()
        
        // Create default profile if none exist
        if profiles.isEmpty {
            createDefaultProfile()
        }
    }
    
    // MARK: - Profile Management
    
    var activeProfile: Profile {
        get {
            if profiles.indices.contains(activeProfileIndex) {
                return profiles[activeProfileIndex]
            } else {
                activeProfileIndex = 0
                return profiles.isEmpty ? createDefaultProfile() : profiles[0]
            }
        }
    }
    
    func createProfile(name: String) -> Profile {
        // Get current settings
        let defaults = UserDefaults.standard
        
        let newProfile = Profile(
            id: UUID(),
            name: name,
            use24HourTime: defaults.bool(forKey: "use24HourTime"),
            showDate: defaults.bool(forKey: "showDate"),
            useMinimalistStyle: defaults.bool(forKey: "useMinimalistStyle"),
            useMonochromeIcons: defaults.bool(forKey: "useMonochromeIcons"),
            showMotivationalMessages: defaults.bool(forKey: "showMotivationalMessages"),
            textSizeMultiplier: defaults.float(forKey: "textSizeMultiplier"),
            fontName: defaults.string(forKey: "fontName") ?? "System",
            themeName: ThemeManager.shared.currentTheme.name
        )
        
        profiles.append(newProfile)
        saveProfiles()
        return newProfile
    }
    
    func deleteProfile(at index: Int) {
        guard profiles.count > 1, profiles.indices.contains(index) else { return }
        
        profiles.remove(at: index)
        
        // Adjust active index if needed
        if activeProfileIndex >= profiles.count {
            activeProfileIndex = profiles.count - 1
        }
        
        saveProfiles()
    }
    
    func switchToProfile(at index: Int) {
        guard profiles.indices.contains(index) else { return }
        
        activeProfileIndex = index
        applyActiveProfile()
        saveProfiles()
    }
    
    func updateActiveProfile() {
        guard profiles.indices.contains(activeProfileIndex) else { return }
        
        // Get current settings
        let defaults = UserDefaults.standard
        var updatedProfile = profiles[activeProfileIndex]
        
        updatedProfile.use24HourTime = defaults.bool(forKey: "use24HourTime")
        updatedProfile.showDate = defaults.bool(forKey: "showDate")
        updatedProfile.useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        updatedProfile.useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
        updatedProfile.showMotivationalMessages = defaults.bool(forKey: "showMotivationalMessages")
        updatedProfile.textSizeMultiplier = defaults.float(forKey: "textSizeMultiplier")
        updatedProfile.fontName = defaults.string(forKey: "fontName") ?? updatedProfile.fontName
        updatedProfile.themeName = ThemeManager.shared.currentTheme.name
        
        profiles[activeProfileIndex] = updatedProfile
        saveProfiles()
    }
    
    // MARK: - Private Methods
    
    private func createDefaultProfile() -> Profile {
        let defaultProfile = Profile(
            id: UUID(),
            name: "Default",
            use24HourTime: false,
            showDate: true,
            useMinimalistStyle: true,
            useMonochromeIcons: false,
            showMotivationalMessages: true,
            textSizeMultiplier: 1.0,
            fontName: "System",
            themeName: "Default"
        )
        
        profiles = [defaultProfile]
        saveProfiles()
        return defaultProfile
    }
    
    private func applyActiveProfile() {
        let profile = activeProfile
        let defaults = UserDefaults.standard
        
        // Apply settings to UserDefaults
        defaults.set(profile.use24HourTime, forKey: "use24HourTime")
        defaults.set(profile.showDate, forKey: "showDate")
        defaults.set(profile.useMinimalistStyle, forKey: "useMinimalistStyle")
        defaults.set(profile.useMonochromeIcons, forKey: "useMonochromeIcons")
        defaults.set(profile.showMotivationalMessages, forKey: "showMotivationalMessages")
        defaults.set(profile.textSizeMultiplier, forKey: "textSizeMultiplier")
        defaults.set(profile.fontName, forKey: "fontName")
        
        // Set theme
        if let theme = ThemeManager.shared.getTheme(named: profile.themeName) {
            ThemeManager.shared.currentTheme = theme
        }
        
        // Notify the system that settings have changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsDidChangeNotification"), object: nil)
    }
    
    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey) {
            if let decoded = try? JSONDecoder().decode([Profile].self, from: data) {
                profiles = decoded
                activeProfileIndex = UserDefaults.standard.integer(forKey: activeProfileKey)
                
                // Ensure the index is valid
                if activeProfileIndex >= profiles.count {
                    activeProfileIndex = 0
                }
            }
        }
    }
    
    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
            UserDefaults.standard.set(activeProfileIndex, forKey: activeProfileKey)
        }
    }
}
