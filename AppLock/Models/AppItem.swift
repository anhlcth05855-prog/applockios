import Foundation
import SwiftUI

public struct AppItem: Identifiable, Codable, Hashable {
    public let id: String
    public let bundleId: String
    public let appName: String
    public var isLocked: BooleanLiteralType
    public let isSystemApp: Bool
    public let isRecommended: Bool
    public let iconSymbol: String
    public let category: String
    
    public init(
        id: String = UUID().uuidString,
        bundleId: String,
        appName: String,
        isLocked: Bool = false,
        isSystemApp: Bool = false,
        isRecommended: Bool = false,
        iconSymbol: String = "app.fill",
        category: String = "Tiện ích"
    ) {
        self.id = id
        self.bundleId = bundleId
        self.appName = appName
        self.isLocked = isLocked
        self.isSystemApp = isSystemApp
        self.isRecommended = isRecommended
        self.iconSymbol = iconSymbol
        self.category = category
    }
}

public extension AppItem {
    static let defaultApps: [AppItem] = [
        // Recommended / Sensitive
        AppItem(bundleId: "com.apple.mobilesafari", appName: "Safari", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "safari.fill", category: "Trình duyệt"),
        AppItem(bundleId: "com.apple.mobileslideshow", appName: "Ảnh (Photos)", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "photo.stack.fill", category: "Đa phương tiện"),
        AppItem(bundleId: "com.facebook.Facebook", appName: "Facebook", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "f.circle.fill", category: "Mạng xã hội"),
        AppItem(bundleId: "com.facebook.Messenger", appName: "Messenger", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "message.fill", category: "Nhắn tin"),
        AppItem(bundleId: "com.zing.zalo", appName: "Zalo", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "bubble.left.and.bubble.right.fill", category: "Nhắn tin"),
        AppItem(bundleId: "com.zhiliaoapp.musically", appName: "TikTok", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "music.note", category: "Mạng xã hội"),
        AppItem(bundleId: "com.burbn.instagram", appName: "Instagram", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "camera.fill", category: "Mạng xã hội"),
        AppItem(bundleId: "com.google.ios.youtube", appName: "YouTube", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "play.rectangle.fill", category: "Đa phương tiện"),
        
        // Banking & Finance
        AppItem(bundleId: "vn.vcb.digibank", appName: "VCB Digibank", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "banknote.fill", category: "Ngân hàng"),
        AppItem(bundleId: "com.mbmobile", appName: "MB Bank", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "creditcard.fill", category: "Ngân hàng"),
        AppItem(bundleId: "com.techcombank.mobile", appName: "Techcombank Mobile", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "dollarsign.circle.fill", category: "Ngân hàng"),
        AppItem(bundleId: "com.mservice.momopay", appName: "MoMo", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "wallet.pass.fill", category: "Ví điện tử"),
        
        // System Apps
        AppItem(bundleId: "com.apple.Preferences", appName: "Cài đặt (Settings)", isLocked: false, isSystemApp: true, isRecommended: true, iconSymbol: "gearshape.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.mobilemail", appName: "Mail", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "envelope.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.MobileSMS", appName: "Tin nhắn (Messages)", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "ellipsis.message.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.camera", appName: "Máy ảnh (Camera)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "camera.viewfinder", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.AppStore", appName: "App Store", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "cart.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.mobilenotes", appName: "Ghi chú (Notes)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "note.text", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.mobilephone", appName: "Điện thoại (Phone)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "phone.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.DocumentsApp", appName: "Tệp (Files)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "folder.fill", category: "Hệ thống")
    ]
}
