import SwiftUI

public struct AppRowView: View {
    let app: AppItem
    var onToggle: () -> Void
    var onTestLock: (() -> Void)? = nil
    var onOpenGuide: (() -> Void)? = nil
    
    public init(
        app: AppItem,
        onToggle: @escaping () -> Void,
        onTestLock: (() -> Void)? = nil,
        onOpenGuide: (() -> Void)? = nil
    ) {
        self.app = app
        self.onToggle = onToggle
        self.onTestLock = onTestLock
        self.onOpenGuide = onOpenGuide
    }
    
    public var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                // Colorful realistic brand icon (44x44)
                AppBrandIconView(app: app, size: 44)
                
                // App Name + "Bảo mật cao" badge + package/bundle identifier
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.appName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if app.isRecommended {
                            Text("Bảo mật cao")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppColors.background)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(AppColors.cyan)
                                )
                        }
                        
                        Text(app.bundleId)
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                            .lineLimit(1)
                    }
                }
                
                Spacer(minLength: 8)
                
                // Padlock Icon matching video (Cyan closed padlock when locked, muted open padlock when unlocked)
                Image(systemName: app.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(app.isLocked ? AppColors.cyan : AppColors.textMuted)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(app.isLocked ? AppColors.cyan.opacity(0.35) : AppColors.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onTestLock = onTestLock {
                Button(action: onTestLock) {
                    Label("Xem thử màn hình khóa \(app.appName)", systemImage: "lock.shield")
                }
            }
            if let onOpenGuide = onOpenGuide {
                Button(action: onOpenGuide) {
                    Label("Hướng dẫn chặn tự động \(app.appName)", systemImage: "bolt.fill")
                }
            }
            Button(action: onToggle) {
                Label(app.isLocked ? "Mở khóa \(app.appName)" : "Khóa \(app.appName)", systemImage: app.isLocked ? "lock.open" : "lock.fill")
            }
        }
    }
}
