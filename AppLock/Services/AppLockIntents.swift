import Foundation
import AppIntents

@available(iOS 16.0, *)
struct CheckAppLockIntent: AppIntent {
    static var title: LocalizedStringResource = "Kiểm tra cần khóa ứng dụng"
    static var description = IntentDescription("Kiểm tra xem ứng dụng đang mở (VD: Facebook, Zalo) có cần hiện màn hình khóa AppLock hay không. Trả về Đúng nếu cần khóa, trả về Sai nếu vừa mở khóa hợp lệ.")
    
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Tên ứng dụng (VD: Facebook)", default: "Facebook")
    var appName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Kiểm tra cần khóa \(\.$appName)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let shouldLock = AppLockManager.shared.evaluateShortcutIntercept(appName: appName)
        return .result(value: shouldLock)
    }
}

@available(iOS 16.0, *)
struct LockAppImmediatelyIntent: AppIntent {
    static var title: LocalizedStringResource = "Bật khóa bảo vệ AppLock ngay"
    static var description = IntentDescription("Mở ngay màn hình khóa bảo vệ của AppLock cho ứng dụng chỉ định.")
    
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Tên ứng dụng (VD: Facebook)", default: "Facebook")
    var appName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Khóa ngay \(\.$appName) bằng AppLock")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        _ = AppLockManager.shared.forceInterceptLock(appName: appName)
        return .result()
    }
}

@available(iOS 16.0, *)
struct AppLockShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckAppLockIntent(),
            phrases: [
                "Kiểm tra khóa ứng dụng bằng \(.applicationName)",
                "Bảo vệ ứng dụng với \(.applicationName)"
            ],
            shortTitle: "Kiểm tra Khóa App",
            systemImageName: "checkmark.shield.fill"
        )
    }
}
