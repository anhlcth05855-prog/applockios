// Theme definition for AppLock iOS
import SwiftUI

public enum AppColors {
    public static let background = Color(hex: "0A0F1D")
    public static let backgroundSecondary = Color(hex: "131B2E")
    public static let cardBackground = Color(hex: "1A233A")
    public static let cardBorder = Color(hex: "2A3655")
    
    // Accents
    public static let cyan = Color(hex: "00E5FF")
    public static let emerald = Color(hex: "00E676")
    public static let coral = Color(hex: "FF5252")
    public static let amber = Color(hex: "FFD600")
    public static let purple = Color(hex: "7C4DFF")
    
    // Text
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textMuted = Color(hex: "64748B")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
