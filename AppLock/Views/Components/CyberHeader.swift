import SwiftUI

public struct CyberHeader: View {
    let title: String
    let subtitle: String?
    var badgeText: String? = nil
    var badgeColor: Color = AppColors.cyan
    
    public init(
        title: String,
        subtitle: String? = nil,
        badgeText: String? = nil,
        badgeColor: Color = AppColors.cyan
    ) {
        self.title = title
        self.subtitle = subtitle
        self.badgeText = badgeText
        self.badgeColor = badgeColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                if let badgeText = badgeText {
                    NeonBadge(text: badgeText, color: badgeColor)
                }
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }
}

public struct NeonBadge: View {
    let text: String
    var color: Color = AppColors.cyan
    
    public init(text: String, color: Color = AppColors.cyan) {
        self.text = text
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color, radius: 4)
            
            Text(text)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
