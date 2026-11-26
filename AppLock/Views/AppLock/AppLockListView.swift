import SwiftUI

/// Home Modes Screen matching 00:01 - 00:02 in the reference video
public struct AppLockListView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var selectedModeId: String? = nil
    @State private var showSetupSheet: Bool = false
    @State private var showPermissionSheet: Bool = false
    
    public init() {}
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Return to unlocked app banner (matching 00:35)
                if screenTimeManager.showReturnToAppBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Nhấn vào góc trên bên trái để quay lại ứng dụng đã mở khóa")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Khóa lại") {
                            screenTimeManager.relockShieldsNow()
                            appLockManager.showToast("Đã bật lại khiên khóa!")
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(AppColors.yellowCard)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0F172A"))
                }
                
                // Top Header ("Khoá App" + +PLUS badge) matching 00:01
                HStack(spacing: 8) {
                    Text("Khoá App")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("+PLUS")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "4F6DF5"), Color(hex: "A855F7")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    
                    Spacer()
                    
                    Button(action: {
                        showPermissionSheet = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
                            Image(systemName: screenTimeManager.isAuthorized ? "checkmark.shield.fill" : "book.fill")
                                .font(.system(size: 15))
                                .foregroundColor(screenTimeManager.isAuthorized ? AppColors.emerald : AppColors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero Illustration Card matching 00:01
                        VStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "EEF2FF"), Color(hex: "F5F3FF")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 96)
                                
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 46))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.cyan, AppColors.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .padding(.top, 6)
                            
                            Text("Chọn chế độ")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(screenTimeManager.totalProtectedAppsCount > 0
                                 ? "Đang khóa bảo vệ \(screenTimeManager.totalProtectedAppsCount) mục qua Thời gian sử dụng"
                                 : "Bắt đầu khóa ứng dụng!")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.bottom, 4)
                        
                        // Tooltip Callout matching 00:01
                        if appLockManager.isFirstLaunch || !screenTimeManager.isAuthorized {
                            Text("Nhấp để bắt đầu khóa ứng dụng")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 3)
                                )
                        }
                        
                        // 2x2 Modes Grid matching 00:01 - 00:02
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(screenTimeManager.modes) { mode in
                                modeCard(mode)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .onChange(of: appLockManager.modalDismissToken) { _ in
            showSetupSheet = false
            showPermissionSheet = false
        }
        .fullScreenCover(isPresented: $showSetupSheet) {
            SecuritySetupFlowView {
                showSetupSheet = false
                selectedModeId = "privacy"
            }
        }
        .sheet(isPresented: $showPermissionSheet) {
            ScreenTimePermissionView()
        }
        .fullScreenCover(item: Binding(
            get: { selectedModeId.map { ModeNavTarget(id: $0) } },
            set: { selectedModeId = $0?.id }
        )) { target in
            ModeDetailView(modeId: target.id)
        }
    }
    
    @ViewBuilder
    private func modeCard(_ mode: LockModeItem) -> some View {
        let isYellow = mode.isHighlighted
        let bgColor: Color = {
            if isYellow { return AppColors.yellowCard }
            switch mode.id {
            case "work": return Color(hex: "F1F5F9")
            case "teen": return Color(hex: "EDE9FE")
            default: return Color(hex: "FFFFFF")
            }
        }()
        
        Button(action: {
            if appLockManager.isFirstLaunch {
                showSetupSheet = true
            } else if !screenTimeManager.isAuthorized {
                showPermissionSheet = true
            } else {
                selectedModeId = mode.id
            }
        }) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isYellow ? Color.white.opacity(0.65) : Color.white)
                            .frame(width: 36, height: 36)
                        Image(systemName: mode.iconName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isYellow ? AppColors.textPrimary : AppColors.cyan)
                    }
                    Spacer()
                }
                
                Text(mode.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer(minLength: 4)
                
                HStack {
                    Spacer()
                    // Pill Switch inside card
                    Button(action: {
                        if appLockManager.isFirstLaunch {
                            showSetupSheet = true
                        } else if !screenTimeManager.isAuthorized {
                            showPermissionSheet = true
                        } else {
                            var updated = mode
                            updated.isEnabled.toggle()
                            screenTimeManager.updateMode(updated)
                            HapticManager.shared.selection()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if mode.isEnabled {
                                Text("ON")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundColor(.white)
                                Circle().fill(Color.white).frame(width: 18, height: 18)
                            } else {
                                Circle().fill(Color.white).frame(width: 18, height: 18)
                                Text("OFF")
                                    .font(.system(size: 10.5, weight: .heavy))
                                    .foregroundColor(isYellow ? AppColors.textSecondary : .white)
                            }
                        }
                        .padding(.horizontal, 4)
                        .frame(width: 56, height: 26)
                        .background(
                            Capsule()
                                .fill(mode.isEnabled ? AppColors.cyan : (isYellow ? Color.white.opacity(0.85) : Color(hex: "CBD5E1")))
                        )
                    }
                }
            }
            .padding(16)
            .frame(height: 168)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(bgColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isYellow ? Color(hex: "FACC15") : AppColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ModeNavTarget: Identifiable {
    let id: String
}
