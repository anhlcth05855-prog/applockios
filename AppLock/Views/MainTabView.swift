import SwiftUI

public enum TabItem: Int, CaseIterable {
    case appLock = 0
    case vault = 1
    case intruder = 2
    case settings = 3
    
    var title: String {
        switch self {
        case .appLock: return "Khóa App"
        case .vault: return "Két Riêng"
        case .intruder: return "Xâm Nhập"
        case .settings: return "Cài Đặt"
        }
    }
    
    var iconName: String {
        switch self {
        case .appLock: return "lock.shield.fill"
        case .vault: return "archivebox.fill"
        case .intruder: return "camera.badge.ellipsis"
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
            // Tab Contents
            TabView(selection: $selectedTab) {
                AppLockListView()
                    .tag(TabItem.appLock)
                
                VaultView()
                    .tag(TabItem.vault)
                
                IntruderLogView()
                    .tag(TabItem.intruder)
                
                SettingsView()
                    .tag(TabItem.settings)
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Custom Cyber Floating Bottom Nav Bar
            customBottomBar
        }
        .fullScreenCover(isPresented: $appLockManager.isShowingLockOverlay) {
            if appLockManager.isFirstLaunch {
                SecuritySetupFlowView {
                    appLockManager.isShowingLockOverlay = false
                }
            } else {
                LockScreenOverlayView()
            }
        }
    }
    
    private var customBottomBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                    if appLockManager.isVibrationEnabled {
                        HapticManager.shared.selection()
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if isSelected {
                                Circle()
                                    .fill(AppColors.cyan.opacity(0.18))
                                    .frame(width: 38, height: 38)
                                    .shadow(color: AppColors.cyan.opacity(0.4), radius: 6)
                            }
                            
                            Image(systemName: tab.iconName)
                                .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? AppColors.cyan : AppColors.textSecondary)
                        }
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? AppColors.cyan : AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppColors.backgroundSecondary.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
