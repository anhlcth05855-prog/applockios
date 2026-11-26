import ManagedSettings
import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {
    private let appGroupId = "group.com.guardio.applock"
    
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldButton(action: action, completionHandler: completionHandler)
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldButton(action: action, completionHandler: completionHandler)
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        handleShieldButton(action: action, completionHandler: completionHandler)
    }
    
    private func handleShieldButton(action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            let sharedDefaults = UserDefaults(suiteName: appGroupId)
            sharedDefaults?.set(true, forKey: "applock_pending_shield_unlock")
            sharedDefaults?.synchronize()
            
            scheduleUnlockNotification()
            completionHandler(.defer)
            
        case .secondaryButtonPressed:
            completionHandler(.close)
            
        @unknown default:
            completionHandler(.close)
        }
    }
    
    private func scheduleUnlockNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Mở khóa ứng dụng"
        content.body = "Nhấn vào đây để nhập mật khẩu mở khóa trong Khoá App."
        content.sound = .default
        content.userInfo = ["action": "unlock_shield"]
        
        let request = UNNotificationRequest(
            identifier: "applock.shield.unlock.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
