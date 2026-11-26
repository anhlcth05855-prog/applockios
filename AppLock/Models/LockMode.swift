import Foundation

public struct LockModeItem: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var subtitle: String
    public var iconName: String
    public var isHighlighted: Bool
    public var isEnabled: Bool
    public var isScheduleEnabled: Bool
    
    // Extra Restrictions ("Thêm" tab matching video)
    public var autoRelockMinutes: Int
    public var unlockNotificationEnabled: Bool
    public var denyInAppPurchases: Bool
    public var denyAppRemoval: Bool
    public var denyAppInstallation: Bool
    
    public init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        isHighlighted: Bool = false,
        isEnabled: Bool = false,
        isScheduleEnabled: Bool = true,
        autoRelockMinutes: Int = 5,
        unlockNotificationEnabled: Bool = true,
        denyInAppPurchases: Bool = false,
        denyAppRemoval: Bool = false,
        denyAppInstallation: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.isHighlighted = isHighlighted
        self.isEnabled = isEnabled
        self.isScheduleEnabled = isScheduleEnabled
        self.autoRelockMinutes = autoRelockMinutes
        self.unlockNotificationEnabled = unlockNotificationEnabled
        self.denyInAppPurchases = denyInAppPurchases
        self.denyAppRemoval = denyAppRemoval
        self.denyAppInstallation = denyAppInstallation
    }
    
    public static let defaultModes: [LockModeItem] = [
        LockModeItem(
            id: "work",
            title: "Chế độ\nlàm việc",
            subtitle: "Mỗi ngày",
            iconName: "briefcase.fill",
            isHighlighted: false
        ),
        LockModeItem(
            id: "teen",
            title: "Chế độ\nthiếu niên",
            subtitle: "Mỗi ngày",
            iconName: "sparkles",
            isHighlighted: false
        ),
        LockModeItem(
            id: "privacy",
            title: "Chế độ\nriêng tư",
            subtitle: "Mỗi ngày",
            iconName: "hand.raised.fill",
            isHighlighted: true
        ),
        LockModeItem(
            id: "focus",
            title: "Chế độ\nTập trung",
            subtitle: "Mỗi ngày",
            iconName: "target",
            isHighlighted: false
        )
    ]
}
