import SwiftUI

public enum AppColors {
    // Light modern palette matching reference video
    public static let background = Color(hex: "F8FAFC")
    public static let backgroundSecondary = Color(hex: "FFFFFF")
    public static let cardBackground = Color(hex: "FFFFFF")
    public static let cardHighlight = Color(hex: "EEF2FF")
    public static let inputBackground = Color(hex: "F1F5F9")
    public static let cardBorder = Color(hex: "E2E8F0")
    public static let keypadNormal = Color(hex: "F1F5F9")
    public static let keypadPressed = Color(hex: "4B5563")
    
    // Brand Accents
    public static let cyan = Color(hex: "1D6FF2")       // Primary Blue (#1D6FF2)
    public static let purple = Color(hex: "7C3AED")     // Purple gradient accent
    public static let pink = Color(hex: "EC4899")
    public static let yellowCard = Color(hex: "FFE100") // "Chế độ riêng tư" highlight
    public static let emerald = Color(hex: "10B981")
    public static let coral = Color(hex: "EF4444")
    public static let amber = Color(hex: "F59E0B")
    
    // Text
    public static let textPrimary = Color(hex: "0F172A")
    public static let textSecondary = Color(hex: "64748B")
    public static let textMuted = Color(hex: "94A3B8")
    public static let textHint = Color(hex: "CBD5E1")
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
