import Foundation
import LocalAuthentication

public final class BiometricManager {
    public static let shared = BiometricManager()
    
    private init() {}
    
    public enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        public var title: String {
            switch self {
            case .none: return "Không khả dụng"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        public var iconName: String {
            switch self {
            case .none: return "lock.fill"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "eye.circle.fill"
            }
        }
    }
    
    public func getAvailableBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .faceID
        }
    }
    
    public func authenticate(reason: String = "Xác thực sinh trắc học để mở khóa AppLock") async -> Result<Bool, Error> {
        let context = LAContext()
        context.localizedCancelTitle = "Dùng mật khẩu"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(error ?? NSError(domain: "BiometricError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sinh trắc học chưa sẵn sàng"]))
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return .success(success)
        } catch {
            return .failure(error)
        }
    }
}
