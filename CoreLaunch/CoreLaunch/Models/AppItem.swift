//
//  AppItem.swift
//  CoreLaunch
//
//  Created by x on 4/2/25.
//

import UIKit

// MARK: - Model
struct AppItem: Codable {
    let name: String
    var color: UIColor
    var isSelected: Bool = true
    
    // Custom Codable implementation for UIColor
    enum CodingKeys: String, CodingKey {
        case name, isSelected, colorName
    }
    
    init(name: String, color: UIColor, isSelected: Bool = true) {
        self.name = name
        self.color = color
        self.isSelected = isSelected
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(isSelected, forKey: .isSelected)
        
        // Store color name as a string
        let colorName = getColorName(for: color)
        try container.encode(colorName, forKey: .colorName)
        
        print("DEBUG: Encoding app \(name) with colorName \(colorName)")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        
        // Decode color from name
        let colorName = try container.decode(String.self, forKey: .colorName)
        print("DEBUG: Decoding app \(name) with colorName \(colorName)")
        
        // Initialize color first before using self in getColor
        color = UIColor.systemGray
        // Then update it with the correct color
        color = getColor(from: colorName)
        print("DEBUG: App \(name) color set to \(color)")
    }
    
    // Color name to UIColor conversion
    private func getColor(from name: String) -> UIColor {
        print("DEBUG: Getting color for name: \(name)")
        
        // Handle standard system colors
        switch name {
        case "systemBlue": return .systemBlue
        case "systemGreen": return .systemGreen
        case "systemIndigo": return .systemIndigo
        case "systemOrange": return .systemOrange
        case "systemYellow": return .systemYellow
        case "systemRed": return .systemRed
        case "systemPurple": return .systemPurple
        case "systemGray": return .systemGray
        default: break
        }
        
        // Check if it's a custom color
        if name.hasPrefix("custom_") {
            print("DEBUG: Detected custom color name")
            // Parse RGB values from the name
            let components = name.dropFirst("custom_".count).split(separator: "_")
            if components.count >= 3,
               let red = Double(components[0]),
               let green = Double(components[1]),
               let blue = Double(components[2]) {
                print("DEBUG: Creating color with RGB: \(red), \(green), \(blue)")
                return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
            }
        }
        
        print("DEBUG: Unknown color name: \(name), defaulting to systemGray")
        return .systemGray
    }
    
    private func getColorName(for color: UIColor) -> String {
        if color == .systemBlue { return "systemBlue" }
        if color == .systemGreen { return "systemGreen" }
        if color == .systemIndigo { return "systemIndigo" }
        if color == .systemOrange { return "systemOrange" }
        if color == .systemYellow { return "systemYellow" }
        if color == .systemRed { return "systemRed" }
        if color == .systemPurple { return "systemPurple" }
        if color == .systemGray { return "systemGray" }
        
        // Debug for custom colors
        print("DEBUG: Custom color detected - not matching any standard colors")
        
        // Store RGB values for custom colors
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            let colorString = "custom_\(red)_\(green)_\(blue)"
            print("DEBUG: Creating custom color name: \(colorString)")
            return colorString
        }
        
        return "systemGray"
    }
    
    func getIconColor(useMonochrome: Bool, isDarkMode: Bool) -> UIColor {
        if useMonochrome {
            return isDarkMode ? .white : .black
        } else {
            return color
        }
    }
}
