import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    var borderColor: Color = AppColors.cardBorder
    var backgroundColor: Color = AppColors.cardBackground.opacity(0.7)
    
    public init(
        cornerRadius: CGFloat = 16,
        borderColor: Color = AppColors.cardBorder,
        backgroundColor: Color = AppColors.cardBackground.opacity(0.7),
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    public var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            )
    }
}

public struct CyberButtonStyle: ButtonStyle {
    var primaryColor: Color = AppColors.cyan
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [primaryColor.opacity(0.9), primaryColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: primaryColor.opacity(configuration.isPressed ? 0.2 : 0.4), radius: 8, x: 0, y: 3)
            )
            .foregroundColor(.black)
            .font(.system(size: 15, weight: .bold))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
