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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        isSelected = try container.decode(Bool.self, forKey: .isSelected)
        
        // Decode color from name
        let colorName = try container.decode(String.self, forKey: .colorName)
        // Initialize color first before using self in getColor
        color = UIColor.systemGray
        // Then update it with the correct color
        color = getColor(from: colorName)
    }
    
    // Color name to UIColor conversion
    private func getColor(from name: String) -> UIColor {
        switch name {
        case "systemBlue": return .systemBlue
        case "systemGreen": return .systemGreen
        case "systemIndigo": return .systemIndigo
        case "systemOrange": return .systemOrange
        case "systemYellow": return .systemYellow
        case "systemRed": return .systemRed
        case "systemPurple": return .systemPurple
        case "systemGray": return .systemGray
        default: return .systemGray
        }
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
