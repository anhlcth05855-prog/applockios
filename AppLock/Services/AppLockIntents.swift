import Foundation
import AppIntents

@available(iOS 16.0, *)
struct CheckAppLockIntent: AppIntent {
    static var title: LocalizedStringResource = "Kiểm tra cần khóa ứng dụng"
    static var description = IntentDescription("Kiểm tra xem ứng dụng đang mở (VD: Facebook, Zalo) có cần hiện màn hình khóa AppLock hay không. Trả về tên ứng dụng nếu cần khóa, hoặc trả về trống (nil) nếu vừa mở khóa hợp lệ để không bị lặp vô hạn.")
    
    // Chạy ngầm hoàn toàn, chỉ mở AppLock qua khối 'Nếu' (If) khi trả về giá trị khác trống
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Tên ứng dụng (VD: Facebook)", default: "Facebook")
    var appName: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Kiểm tra cần khóa \(\.$appName)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String?> {
        let targetToLock = AppLockManager.shared.evaluateShortcutIntercept(appName: appName)
        return .result(value: targetToLock)
    }
}
