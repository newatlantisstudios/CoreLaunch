//
//  ColorTheme.swift
//  CoreLaunch
//
//  Created on 4/3/25.
//

import UIKit

struct ColorTheme: Codable {
    var name: String
    var primaryColor: UIColor
    var secondaryColor: UIColor
    var accentColor: UIColor
    var backgroundColor: UIColor
    var textColor: UIColor
    var secondaryTextColor: UIColor
    
    // Custom Codable implementation for UIColor
    enum CodingKeys: String, CodingKey {
        case name
        case primaryColorHex
        case secondaryColorHex
        case accentColorHex
        case backgroundColorHex
        case textColorHex
        case secondaryTextColorHex
    }
    
    init(name: String, 
         primaryColor: UIColor, 
         secondaryColor: UIColor, 
         accentColor: UIColor,
         backgroundColor: UIColor, 
         textColor: UIColor, 
         secondaryTextColor: UIColor) {
        self.name = name
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(primaryColor.toHex, forKey: .primaryColorHex)
        try container.encode(secondaryColor.toHex, forKey: .secondaryColorHex)
        try container.encode(accentColor.toHex, forKey: .accentColorHex)
        try container.encode(backgroundColor.toHex, forKey: .backgroundColorHex)
        try container.encode(textColor.toHex, forKey: .textColorHex)
        try container.encode(secondaryTextColor.toHex, forKey: .secondaryTextColorHex)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        let primaryHex = try container.decode(String.self, forKey: .primaryColorHex)
        primaryColor = UIColor(hex: primaryHex) ?? .systemBlue
        
        let secondaryHex = try container.decode(String.self, forKey: .secondaryColorHex)
        secondaryColor = UIColor(hex: secondaryHex) ?? .systemGreen
        
        let accentHex = try container.decode(String.self, forKey: .accentColorHex)
        accentColor = UIColor(hex: accentHex) ?? .systemOrange
        
        let backgroundHex = try container.decode(String.self, forKey: .backgroundColorHex)
        backgroundColor = UIColor(hex: backgroundHex) ?? .systemBackground
        
        let textHex = try container.decode(String.self, forKey: .textColorHex)
        textColor = UIColor(hex: textHex) ?? .label
        
        let secondaryTextHex = try container.decode(String.self, forKey: .secondaryTextColorHex)
        secondaryTextColor = UIColor(hex: secondaryTextHex) ?? .secondaryLabel
    }
}

// MARK: - Predefined Themes
extension ColorTheme {
    static var defaultTheme: ColorTheme {
        // Check system appearance and return appropriate theme
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        
        return ColorTheme(
            name: "Auto Light and Dark",
            primaryColor: .systemBlue,
            secondaryColor: .systemGreen,
            accentColor: .systemOrange,
            backgroundColor: isDarkMode ? .black : .white,
            textColor: isDarkMode ? .white : .black,
            secondaryTextColor: isDarkMode ? .lightGray : .darkGray
        )
    }
    
    // Observer for interface style changes to support auto theme
    static func setupInterfaceStyleObserver() {
        NotificationCenter.default.addObserver(
            forName: .traitCollectionDidChange,
            object: nil,
            queue: .main
        ) { _ in
            // If current theme is Auto, update UI to reflect system appearance
            if ThemeManager.shared.currentTheme.name == "Auto Light and Dark" {
                // Force theme manager to reload the auto theme with current system appearance
                ThemeManager.shared.refreshTheme()
                
                // Post notification for views to refresh
                NotificationCenter.default.post(
                    name: NSNotification.Name("ThemeDidChangeNotification"),
                    object: nil
                )
            }
        }
    }
    
    static var darkTheme: ColorTheme {
        return ColorTheme(
            name: "Dark",
            primaryColor: .systemBlue,
            secondaryColor: .systemGreen,
            accentColor: .systemOrange,
            backgroundColor: .black,
            textColor: .white,
            secondaryTextColor: .lightGray
        )
    }
    
    static var lightTheme: ColorTheme {
        return ColorTheme(
            name: "Light",
            primaryColor: .systemBlue,
            secondaryColor: .systemGreen,
            accentColor: .systemOrange,
            backgroundColor: .white,
            textColor: .black,
            secondaryTextColor: .darkGray
        )
    }
    
    static var mintTheme: ColorTheme {
        return ColorTheme(
            name: "Mint",
            primaryColor: .systemMint,
            secondaryColor: .systemTeal,
            accentColor: .systemCyan,
            backgroundColor: UIColor(hex: "#F5FFFA") ?? .white,
            textColor: .black,
            secondaryTextColor: .darkGray
        )
    }
    
    static var roseTheme: ColorTheme {
        return ColorTheme(
            name: "Rose",
            primaryColor: .systemPink,
            secondaryColor: .systemPurple,
            accentColor: .systemRed,
            backgroundColor: UIColor(hex: "#FFF0F5") ?? .white,
            textColor: .black,
            secondaryTextColor: .darkGray
        )
    }
    
    static var midnightTheme: ColorTheme {
        return ColorTheme(
            name: "Midnight",
            primaryColor: .systemIndigo,
            secondaryColor: .systemPurple,
            accentColor: .systemCyan,
            backgroundColor: UIColor(hex: "#191970") ?? .black,
            textColor: .white,
            secondaryTextColor: .lightGray
        )
    }
    
    static var natureTheme: ColorTheme {
        return ColorTheme(
            name: "Nature",
            primaryColor: .systemGreen,
            secondaryColor: .systemBrown,
            accentColor: .systemYellow,
            backgroundColor: UIColor(hex: "#F5F5DC") ?? .white,
            textColor: .darkGray,
            secondaryTextColor: .systemBrown
        )
    }
    
    static var monochrome: ColorTheme {
        // Ensure explicitly white background and black text
        return ColorTheme(
            name: "Monochrome",
            primaryColor: .darkGray,
            secondaryColor: .gray,
            accentColor: .black,
            backgroundColor: .white,
            textColor: .black,
            secondaryTextColor: .darkGray
        )
    }
    
    static var oceanTheme: ColorTheme {
        return ColorTheme(
            name: "Ocean",
            primaryColor: .systemBlue,
            secondaryColor: .systemTeal,
            accentColor: UIColor(hex: "#4682B4") ?? .systemBlue, // Steel Blue
            backgroundColor: UIColor(hex: "#E0F7FA") ?? .white, // Light Cyan
            textColor: UIColor(hex: "#01579B") ?? .black, // Dark Blue
            secondaryTextColor: UIColor(hex: "#0277BD") ?? .darkGray // Medium Blue
        )
    }
    
    static var sunsetTheme: ColorTheme {
        return ColorTheme(
            name: "Sunset",
            primaryColor: UIColor(hex: "#FF7043") ?? .systemOrange, // Deep Orange
            secondaryColor: UIColor(hex: "#FFB74D") ?? .systemYellow, // Orange
            accentColor: UIColor(hex: "#FF5722") ?? .systemRed, // Bright Orange
            backgroundColor: UIColor(hex: "#FFF3E0") ?? .white, // Light Orange
            textColor: UIColor(hex: "#3E2723") ?? .black, // Dark Brown
            secondaryTextColor: UIColor(hex: "#5D4037") ?? .darkGray // Brown
        )
    }
    
    static var forestTheme: ColorTheme {
        return ColorTheme(
            name: "Forest",
            primaryColor: UIColor(hex: "#2E7D32") ?? .systemGreen, // Forest Green
            secondaryColor: UIColor(hex: "#558B2F") ?? .systemGreen, // Light Green
            accentColor: UIColor(hex: "#FFA000") ?? .systemYellow, // Amber
            backgroundColor: UIColor(hex: "#F1F8E9") ?? .white, // Light Green
            textColor: UIColor(hex: "#1B5E20") ?? .black, // Dark Green
            secondaryTextColor: UIColor(hex: "#33691E") ?? .darkGray // Medium Green
        )
    }
    
    static var purpleHazeTheme: ColorTheme {
        return ColorTheme(
            name: "Purple Haze",
            primaryColor: UIColor(hex: "#7B1FA2") ?? .systemPurple, // Purple
            secondaryColor: UIColor(hex: "#9C27B0") ?? .systemPurple, // Medium Purple
            accentColor: UIColor(hex: "#E91E63") ?? .systemPink, // Pink
            backgroundColor: UIColor(hex: "#F3E5F5") ?? .white, // Light Purple
            textColor: UIColor(hex: "#4A148C") ?? .black, // Dark Purple
            secondaryTextColor: UIColor(hex: "#6A1B9A") ?? .darkGray // Medium Dark Purple
        )
    }
    
    static var neonTheme: ColorTheme {
        return ColorTheme(
            name: "Neon",
            primaryColor: UIColor(hex: "#00E676") ?? .systemGreen, // Neon Green
            secondaryColor: UIColor(hex: "#00B0FF") ?? .systemBlue, // Bright Blue
            accentColor: UIColor(hex: "#D500F9") ?? .systemPurple, // Neon Purple
            backgroundColor: UIColor(hex: "#212121") ?? .black, // Dark Gray
            textColor: UIColor(hex: "#FFFFFF") ?? .white, // White
            secondaryTextColor: UIColor(hex: "#BDBDBD") ?? .lightGray // Light Gray
        )
    }
    
    static func allThemes() -> [ColorTheme] {
        return [
            defaultTheme,
            darkTheme,
            lightTheme,
            mintTheme,
            roseTheme,
            midnightTheme,
            natureTheme,
            monochrome,
            oceanTheme,
            sunsetTheme,
            forestTheme,
            purpleHazeTheme,
            neonTheme
        ]
    }
}

// MARK: - ThemeManager
class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: ColorTheme {
        get {
            if let savedTheme = loadThemeFromUserDefaults() {
                // If the current theme is Auto Light and Dark, get a fresh instance to respect current system appearance
                if savedTheme.name == "Auto Light and Dark" {
                    return ColorTheme.defaultTheme
                }
                return savedTheme
            }
            return ColorTheme.defaultTheme
        }
        set {
            saveThemeToUserDefaults(newValue)
            // Post notification that theme changed
            NotificationCenter.default.post(name: NSNotification.Name("ThemeDidChangeNotification"), object: nil)
        }
    }
    
    private init() {
        // Set up observer for system appearance changes
        ColorTheme.setupInterfaceStyleObserver()
    }
    
    // Method to refresh the current theme if it's set to Auto
    func refreshTheme() {
        if let savedTheme = loadThemeFromUserDefaults(), savedTheme.name == "Auto Light and Dark" {
            // Force reload the auto theme to respect current system appearance
            let refreshedTheme = ColorTheme.defaultTheme
            // Save without triggering the setter to avoid notification loop
            saveThemeToUserDefaults(refreshedTheme)
        }
    }
    
    private func saveThemeToUserDefaults(_ theme: ColorTheme) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            UserDefaults.standard.set(data, forKey: "selectedTheme")
        } catch {
            print("Failed to save theme: \(error)")
        }
    }
    
    private func loadThemeFromUserDefaults() -> ColorTheme? {
        guard let data = UserDefaults.standard.data(forKey: "selectedTheme") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(ColorTheme.self, from: data)
        } catch {
            print("Failed to load theme: \(error)")
            return nil
        }
    }
    
    func applyTheme(to view: UIView, isDarkMode: Bool) {
        // Apply theme colors without overrides
        view.backgroundColor = currentTheme.backgroundColor
        
        // Debug log for theme application
        print("Applying theme: \(currentTheme.name), background color: \(currentTheme.backgroundColor), isDarkMode: \(isDarkMode)")
        
        // For dark theme, ensure we're using correct text colors for UI components
        if currentTheme.name == "Dark" || 
           (currentTheme.name == "Auto Light and Dark" && isDarkMode) || 
           currentTheme.name == "Midnight" {
            // Find all text elements and ensure text color is set correctly
            applyTextColorRecursively(to: view)
        } else if currentTheme.name == "Light" {
            // Explicitly ensure Light theme has white background
            view.backgroundColor = .white
            applyTextColorRecursively(to: view)
        } else if currentTheme.name == "Monochrome" {
            // Explicitly ensure Monochrome theme has correct colors
            view.backgroundColor = .white
            applyTextColorRecursively(to: view)
        }
        
        // Force UI update to ensure the changes take effect
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // Helper method to ensure text colors are properly set in dark themes
    private func applyTextColorRecursively(to view: UIView) {
        // Handle labels
        if let label = view as? UILabel {
            label.textColor = currentTheme.textColor
        }
        
        // Handle text fields
        if let textField = view as? UITextField {
            textField.textColor = currentTheme.textColor
        }
        
        // Handle text views
        if let textView = view as? UITextView {
            textView.textColor = currentTheme.textColor
        }
        
        // Handle buttons with text
        if let button = view as? UIButton {
            button.setTitleColor(currentTheme.textColor, for: .normal)
        }
        
        // Recursively apply to subviews
        for subview in view.subviews {
            applyTextColorRecursively(to: subview)
        }
    }
    
    func registerCustomTheme(_ theme: ColorTheme) {
        var customThemes = loadCustomThemes()
        
        // Check if theme with this name already exists
        if let index = customThemes.firstIndex(where: { $0.name == theme.name }) {
            customThemes[index] = theme // Update existing theme
        } else {
            customThemes.append(theme) // Add new theme
        }
        
        saveCustomThemes(customThemes)
    }
    
    func deleteCustomTheme(named themeName: String) {
        var customThemes = loadCustomThemes()
        customThemes.removeAll { $0.name == themeName }
        saveCustomThemes(customThemes)
    }
    
    func loadCustomThemes() -> [ColorTheme] {
        guard let data = UserDefaults.standard.data(forKey: "customThemes") else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([ColorTheme].self, from: data)
        } catch {
            print("Failed to load custom themes: \(error)")
            return []
        }
    }
    
    private func saveCustomThemes(_ themes: [ColorTheme]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(themes)
            UserDefaults.standard.set(data, forKey: "customThemes")
        } catch {
            print("Failed to save custom themes: \(error)")
        }
    }
    
    func getAllThemes() -> [ColorTheme] {
        let predefinedThemes = ColorTheme.allThemes()
        let customThemes = loadCustomThemes()
        return predefinedThemes + customThemes
    }
    
    func getTheme(named themeName: String) -> ColorTheme? {
        return getAllThemes().first(where: { $0.name == themeName })
    }
}
