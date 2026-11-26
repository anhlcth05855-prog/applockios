import SwiftUI

public enum AppColors {
    public static let background = Color(hex: "0A0F1D")
    public static let backgroundSecondary = Color(hex: "131B2E")
    public static let cardBackground = Color(hex: "1A243D")
    public static let cardHighlight = Color(hex: "223050")
    public static let inputBackground = Color(hex: "152037")
    public static let cardBorder = Color(hex: "2E3D60")
    public static let keypadNormal = Color(hex: "1D2A48")
    public static let keypadPressed = Color(hex: "2E3F6B")
    
    // Accents
    public static let cyan = Color(hex: "00E5FF")
    public static let emerald = Color(hex: "00E676")
    public static let coral = Color(hex: "FF3B30")
    public static let amber = Color(hex: "FFB300")
    public static let purple = Color(hex: "6C5CE7")
    
    // Text
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textMuted = Color(hex: "64748B")
    public static let textHint = Color(hex: "475569")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
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
