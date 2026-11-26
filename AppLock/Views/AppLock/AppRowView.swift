import SwiftUI

public struct AppRowView: View {
    let app: AppItem
    var onToggle: () -> Void
    var onTestLock: (() -> Void)? = nil
    
    @State private var copiedUrl: Bool = false
    
    public init(app: AppItem, onToggle: @escaping () -> Void, onTestLock: (() -> Void)? = nil) {
        self.app = app
        self.onToggle = onToggle
        self.onTestLock = onTestLock
    }
    
    public var body: some View {
        GlassCard(cornerRadius: 14) {
            HStack(spacing: 14) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(app.isLocked ? AppColors.cyan.opacity(0.15) : AppColors.cardBackground)
                        .frame(width: 46, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(app.isLocked ? AppColors.cyan.opacity(0.4) : AppColors.cardBorder, lineWidth: 1)
                        )
                    
                    Image(systemName: app.iconSymbol)
                        .font(.system(size: 22))
                        .foregroundColor(app.isLocked ? AppColors.cyan : AppColors.textSecondary)
                }
                
                // App Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(app.appName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        if app.isRecommended {
                            Text("Khuyên dùng")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(AppColors.amber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.amber.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(app.category)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Copy shortcut URL button (when locked)
                if app.isLocked {
                    Button(action: {
                        let link = "applock://lock?app=\(app.appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? app.appName)"
                        UIPasteboard.general.string = link
                        copiedUrl = true
                        HapticManager.shared.notification(.success)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copiedUrl = false
                        }
                    }) {
                        Image(systemName: copiedUrl ? "checkmark.circle.fill" : "link.badge.plus")
                            .font(.system(size: 17))
                            .foregroundColor(copiedUrl ? AppColors.emerald : AppColors.cyan.opacity(0.8))
                    }
                    .padding(.trailing, 2)
                }
                
                // Test lock button (preview lock screen)
                if let onTestLock = onTestLock {
                    Button(action: onTestLock) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.cyan.opacity(0.7))
                    }
                    .padding(.trailing, 4)
                }
                
                // Lock toggle switch
                Button(action: onToggle) {
                    ZStack {
                        Capsule()
                            .fill(app.isLocked ? AppColors.cyan : AppColors.cardBorder.opacity(0.5))
                            .frame(width: 50, height: 28)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 22, height: 22)
                            .shadow(radius: 2)
                            .offset(x: app.isLocked ? 11 : -11)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: app.isLocked)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
