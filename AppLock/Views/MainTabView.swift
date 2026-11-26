import SwiftUI

public enum TabItem: Int, CaseIterable {
    case appLock = 0
    case vault = 1
    case intruder = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .appLock: return "Khóa ứng dụng"
        case .vault: return "Két riêng tư"
        case .intruder: return "Kẻ xâm nhập"
        case .settings: return "Cài đặt"
        }
    }
    
    var iconName: String {
        switch self {
        case .appLock: return "square.grid.2x2.fill"
        case .vault: return "camera.viewfinder"
        case .intruder: return "person.crop.circle"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @State private var selectedTab: TabItem = .appLock
    @State private var showPermissionGuideSheet: Bool = false
    
    public init() {}
    
    private var lockedCount: Int {
        appLockManager.apps.filter { $0.isLocked }.count
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Persistent Top App Bar matching video (AppLock / Guard Private Protection / X ĐÃ KHÓA)
                topAppBar
                
                // Main Content Area
                ZStack {
                    switch selectedTab {
                    case .appLock:
                        AppLockListView()
                    case .vault:
                        VaultView()
                    case .intruder:
                        IntruderLogView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Solid Bottom Navigation Bar matching video
                bottomNavBar
            }
            
            // Floating Toast Pill above bottom nav
            if let toast = appLockManager.toastMessage {
                ToastBannerView(message: toast)
                    .padding(.bottom, 78)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .sheet(isPresented: $showPermissionGuideSheet) {
            PermissionStatusView()
        }
        .fullScreenCover(isPresented: $appLockManager.isShowingLockOverlay) {
            if appLockManager.isFirstLaunch {
                SecuritySetupFlowView {
                    appLockManager.isShowingLockOverlay = false
                    if !appLockManager.isAutomationVerified {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showPermissionGuideSheet = true
                        }
                    }
                }
            } else {
                LockScreenOverlayView()
            }
        }
    }
    
    private var topAppBar: some View {
        HStack(spacing: 12) {
            // Cyan Shield Checkmark Icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(AppColors.cyan)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AppLock")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Guard Private Protection")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.cyan)
            }
            
            Spacer()
            
            // Cyan Capsule Status Badge ("3 ĐÃ KHÓA")
            Button(action: {
                showPermissionGuideSheet = true
            }) {
                Text("\(lockedCount) ĐÃ KHÓA")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AppColors.cyan)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(AppColors.backgroundSecondary)
    }
    
    private var bottomNavBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.cardBorder.opacity(0.6))
                .frame(height: 1)
            
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    let isSelected = selectedTab == tab
                    
                    Button(action: {
                        selectedTab = tab
                        if appLockManager.isVibrationEnabled {
                            HapticManager.shared.selection()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? AppColors.cyan : AppColors.textMuted)
                            
                            Text(tab.title)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? AppColors.cyan : AppColors.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(AppColors.backgroundSecondary)
        }
        .background(AppColors.backgroundSecondary.ignoresSafeArea(edges: .bottom))
    }
}
