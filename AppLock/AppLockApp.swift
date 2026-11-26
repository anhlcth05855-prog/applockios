import SwiftUI
import UserNotifications

final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            AppLockManager.shared.triggerUnlockFromNotification()
        }
        completionHandler()
    }
}

@main
struct AppLockApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var appLockManager = AppLockManager.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    init() {
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appLockManager)
                .environmentObject(screenTimeManager)
                .preferredColorScheme(.light)
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
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.white
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UITabBar.appearance().isHidden = true
    }
}
