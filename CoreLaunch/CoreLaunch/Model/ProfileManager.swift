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
        
        // Force synchronize to ensure we get the most current values
        defaults.synchronize()
        
        // Read the current settings from UserDefaults
        let use24HourTime = defaults.bool(forKey: "use24HourTime")
        let showDate = defaults.bool(forKey: "showDate")
        let useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
        let useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
        let showMotivationalMessages = defaults.bool(forKey: "showMotivationalMessages")
        let textSizeMultiplier = defaults.float(forKey: "textSizeMultiplier")
        let fontName = defaults.string(forKey: "fontName") ?? "System"
        
        // Get current theme directly from ThemeManager
        let currentTheme = ThemeManager.shared.currentTheme
        let currentThemeName = currentTheme.name
        
        print("Creating profile with settings:")
        print("  - Name: \(name)")
        print("  - Monochrome Icons: \(useMonochromeIcons)")
        print("  - Show Motivational: \(showMotivationalMessages)")
        print("  - Theme: \(currentThemeName)")
        
        let newProfile = Profile(
            id: UUID(),
            name: name,
            use24HourTime: use24HourTime,
            showDate: showDate,
            useMinimalistStyle: useMinimalistStyle,
            useMonochromeIcons: useMonochromeIcons,
            showMotivationalMessages: showMotivationalMessages,
            textSizeMultiplier: textSizeMultiplier,
            fontName: fontName,
            themeName: currentThemeName
        )
        
        // Save current theme explicitly to UserDefaults for this profile
        defaults.set(currentThemeName, forKey: "selectedThemeName_\(name)")
        
        // Also save the theme directly to the main key
        if let themeData = try? JSONEncoder().encode(currentTheme) {
            defaults.set(themeData, forKey: "selectedTheme")
        }
        
        // Make sure both theme keys are saved
        defaults.set(currentThemeName, forKey: "selectedThemeName")
        defaults.synchronize()
        
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
        
        // First, save the current profile to ensure no settings are lost
        updateActiveProfile()
        
        // Switch to the new profile
        activeProfileIndex = index
        
        // Force load the theme before applying other settings
        let profile = profiles[index]
        if let theme = ThemeManager.shared.getTheme(named: profile.themeName) {
            print("Found theme before applying: \(theme.name) - directly setting it")
            ThemeManager.shared.currentTheme = theme
        }
        
        // Apply the profile settings
        applyActiveProfile()
        
        // Save the updated profiles
        saveProfiles()
        
        // Post theme notification explicitly
        NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChangeNotification"), object: nil)
        
        print("Switched to profile: \(profiles[index].name)")
        print("  - Monochrome Icons: \(profiles[index].useMonochromeIcons)")
        print("  - Show Motivational: \(profiles[index].showMotivationalMessages)")
        print("  - Theme: \(profiles[index].themeName)")
        print("  - Current Theme: \(ThemeManager.shared.currentTheme.name)")
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
        
        // Ensure we capture the current theme
        updatedProfile.themeName = ThemeManager.shared.currentTheme.name
        print("Updating profile \(updatedProfile.name) with theme: \(updatedProfile.themeName)")
        
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
        
        // Print the profile we're applying for debugging
        print("Applying profile: \(profile.name) with theme: \(profile.themeName)")
        
        // Apply settings to UserDefaults
        defaults.set(profile.use24HourTime, forKey: "use24HourTime")
        defaults.set(profile.showDate, forKey: "showDate")
        defaults.set(profile.useMinimalistStyle, forKey: "useMinimalistStyle")
        defaults.set(profile.useMonochromeIcons, forKey: "useMonochromeIcons")
        defaults.set(profile.showMotivationalMessages, forKey: "showMotivationalMessages")
        defaults.set(profile.textSizeMultiplier, forKey: "textSizeMultiplier")
        defaults.set(profile.fontName, forKey: "fontName")
        
        // Set theme - list available themes for debugging
        let allThemes = ThemeManager.shared.getAllThemes()
        print("Available themes: \(allThemes.map { $0.name })")
        
        // Make sure we apply theme immediately, before checking for saved variants
        // This ensures we at least have a theme applied from the profile
        if let profileTheme = ThemeManager.shared.getTheme(named: profile.themeName) {
            print("Applying profile theme: \(profileTheme.name)")
            ThemeManager.shared.currentTheme = profileTheme
        }
        
        // Then check if we have a saved theme for this profile (in case it was customized)
        if let savedThemeName = defaults.string(forKey: "selectedThemeName_\(profile.name)") {
            print("Found saved theme name for profile: \(savedThemeName)")
            
            if let theme = ThemeManager.shared.getTheme(named: savedThemeName) {
                print("Found saved theme: \(theme.name) - applying it")
                ThemeManager.shared.currentTheme = theme
            }
        }
        // Fallback to default if nothing works
        else if ThemeManager.shared.currentTheme.name != profile.themeName {
            // If theme not found, use default theme
            print("Theme '\(profile.themeName)' not found, using default")
            ThemeManager.shared.currentTheme = ColorTheme.defaultTheme
        }
        
        // Save theme name to profile-specific key
        let themeName = ThemeManager.shared.currentTheme.name
        defaults.set(themeName, forKey: "selectedThemeName_\(profile.name)")
        
        // Also save to the main theme key
        defaults.set(themeName, forKey: "selectedThemeName")
        
        // Save as binary data too for complete serialization
        if let themeData = try? JSONEncoder().encode(ThemeManager.shared.currentTheme) {
            defaults.set(themeData, forKey: "selectedTheme")
            // Also save a profile-specific copy of the theme data
            defaults.set(themeData, forKey: "selectedTheme_\(profile.name)")
        }
        
        // Force save to UserDefaults and print current theme for debugging
        defaults.synchronize()
        print("Current theme after applying profile: \(ThemeManager.shared.currentTheme.name)")
        
        // Notify the system that settings have changed
        NotificationCenter.default.post(name: NSNotification.Name("SettingsDidChangeNotification"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChangeNotification"), object: nil)
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
                
                // Apply the active profile settings
                if !profiles.isEmpty {
                    applyActiveProfile()
                }
            }
        }
    }
    
    private func saveProfiles() {
        // Ensure the current theme is included in the active profile before saving
        if profiles.indices.contains(activeProfileIndex) {
            let currentThemeName = ThemeManager.shared.currentTheme.name
            profiles[activeProfileIndex].themeName = currentThemeName
            
            // Get updated profile settings from UserDefaults
            let defaults = UserDefaults.standard
            profiles[activeProfileIndex].use24HourTime = defaults.bool(forKey: "use24HourTime")
            profiles[activeProfileIndex].showDate = defaults.bool(forKey: "showDate")
            profiles[activeProfileIndex].useMinimalistStyle = defaults.bool(forKey: "useMinimalistStyle")
            profiles[activeProfileIndex].useMonochromeIcons = defaults.bool(forKey: "useMonochromeIcons")
            profiles[activeProfileIndex].showMotivationalMessages = defaults.bool(forKey: "showMotivationalMessages")
            profiles[activeProfileIndex].textSizeMultiplier = defaults.float(forKey: "textSizeMultiplier")
            profiles[activeProfileIndex].fontName = defaults.string(forKey: "fontName") ?? profiles[activeProfileIndex].fontName
            
            // Save current theme to profile-specific key in UserDefaults
            let profileName = profiles[activeProfileIndex].name
            defaults.set(currentThemeName, forKey: "selectedThemeName_\(profileName)")
            
            print("Saving profile \(profileName) with theme: \(currentThemeName)")
        }
        
        // Encode and save all profiles
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
            UserDefaults.standard.set(activeProfileIndex, forKey: activeProfileKey)
            
            // Also save active profile name for easier theme lookup
            if profiles.indices.contains(activeProfileIndex) {
                UserDefaults.standard.set(profiles[activeProfileIndex].name, forKey: "activeProfileName")
            }
            
            UserDefaults.standard.synchronize() // Ensure immediate save
        }
    }
}
