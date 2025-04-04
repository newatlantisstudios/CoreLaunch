import Foundation
import SwiftUI

struct Profile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var use24HourTime: Bool
    var showDate: Bool
    var useMinimalistStyle: Bool
    var useMonochromeIcons: Bool
    var showMotivationalMessages: Bool
    var textSizeMultiplier: Float
    var fontName: String
    var themeName: String
    
    static func == (lhs: Profile, rhs: Profile) -> Bool {
        return lhs.id == rhs.id
    }
}
