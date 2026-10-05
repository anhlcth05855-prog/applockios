import Foundation

public enum LockType: String, Codable, CaseIterable {
    case pin = "PIN"
    case pattern = "PATTERN"
    
    public var title: String {
        switch self {
        case .pin: return "Mã PIN 4 số"
        case .pattern: return "Hình vẽ mẫu (Pattern)"
        }
    }
}

public enum RelockPolicy: String, Codable, CaseIterable {
    case immediately = "IMMEDIATELY"
    case screenOff = "SCREEN_OFF"
    case oneMinute = "ONE_MINUTE"
    
    public var title: String {
        switch self {
        case .immediately: return "Khóa ngay khi thoát ứng dụng"
        case .screenOff: return "Khóa khi tắt màn hình"
        case .oneMinute: return "Khóa sau 1 phút"
        }
    }
}
