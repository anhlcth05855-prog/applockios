import SwiftUI

@main
struct AppLockApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLockManager = AppLockManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    init() {
        // Configure standard navigation and tab bar appearance
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appLockManager)
                .environmentObject(screenTimeManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    appLockManager.handleDeepLink(url: url)
                }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background:
                        appLockManager.appMovedToBackground()
                    case .active:
                        appLockManager.appBecameActive()
                    default:
                        break
                    }
                }
        }
    }
    
    private func configureAppearance() {
        // Navigation bar dark tint
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppColors.background)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Hide default UITabBar background since custom floating bar is used
        UITabBar.appearance().isHidden = true
    }
}
