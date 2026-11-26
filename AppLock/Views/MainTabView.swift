import SwiftUI

public enum TabItem: Int, CaseIterable {
    case appLock = 0
    case vault = 1
    case intruder = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .appLock: return "Khoá App"
        case .vault: return "Két riêng tư"
        case .intruder: return "Kẻ xâm nhập"
        case .settings: return "Cài đặt"
        }
    }
    
    var iconName: String {
        switch self {
        case .appLock: return "lock.shield.fill"
        case .vault: return "photo.on.rectangle.angled"
        case .intruder: return "person.crop.circle"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainTabView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @State private var selectedTab: TabItem = .appLock
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                
                // Bottom Navigation Bar matching video
                bottomNavBar
            }
            
            if let toast = appLockManager.toastMessage {
                ToastBannerView(message: toast)
                    .padding(.bottom, 76)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
            
            // Root Passcode Lock Overlay
            if appLockManager.isShowingLockOverlay && !appLockManager.isFirstLaunch {
                LockScreenOverlayView()
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
    }
    
    private var bottomNavBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.cardBorder)
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
            .background(Color.white)
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
    }
}
