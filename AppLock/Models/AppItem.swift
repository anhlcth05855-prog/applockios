import Foundation
import SwiftUI

public struct AppItem: Identifiable, Codable, Hashable {
    public let id: String
    public let bundleId: String
    public let appName: String
    public var isLocked: Bool
    public let isSystemApp: Bool
    public let isRecommended: Bool
    public let iconSymbol: String
    public let category: String
    public var urlSchemes: [String]
    
    public init(
        id: String = UUID().uuidString,
        bundleId: String,
        appName: String,
        isLocked: Bool = false,
        isSystemApp: Bool = false,
        isRecommended: Bool = false,
        iconSymbol: String = "app.fill",
        category: String = "Tiện ích",
        urlSchemes: [String] = []
    ) {
        self.id = id
        self.bundleId = bundleId
        self.appName = appName
        self.isLocked = isLocked
        self.isSystemApp = isSystemApp
        self.isRecommended = isRecommended
        self.iconSymbol = iconSymbol
        self.category = category
        self.urlSchemes = urlSchemes
    }
    
    enum CodingKeys: String, CodingKey {
        case id, bundleId, appName, isLocked, isSystemApp, isRecommended, iconSymbol, category, urlSchemes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        bundleId = try container.decode(String.self, forKey: .bundleId)
        appName = try container.decode(String.self, forKey: .appName)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        isSystemApp = try container.decode(Bool.self, forKey: .isSystemApp)
        isRecommended = try container.decode(Bool.self, forKey: .isRecommended)
        iconSymbol = try container.decode(String.self, forKey: .iconSymbol)
        category = try container.decode(String.self, forKey: .category)
        if let schemes = try container.decodeIfPresent([String].self, forKey: .urlSchemes), !schemes.isEmpty {
            urlSchemes = schemes
        } else {
            urlSchemes = AppItem.knownSchemes(for: appName)
        }
    }
}

public extension AppItem {
    static func knownSchemes(for name: String) -> [String] {
        let lower = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.contains("facebook") || lower == "fb" {
            return ["fb://"]
        } else if lower.contains("messenger") {
            return ["fb-messenger://"]
        } else if lower.contains("zalo") {
            return ["zalo://"]
        } else if lower.contains("tiktok") || lower.contains("tik tok") {
            return ["snssdk1180://", "snssdk1233://", "tiktok://"]
        } else if lower.contains("instagram") || lower == "ig" {
            return ["instagram://"]
        } else if lower.contains("youtube") {
            return ["youtube://"]
        } else if lower.contains("discord") {
            return ["discord://"]
        } else if lower.contains("shopee") {
            return ["shopeevn://", "shopee://"]
        } else if lower.contains("telegram") {
            return ["tg://"]
        } else if lower.contains("gmail") {
            return ["googlegmail://"]
        } else if lower.contains("chrome") {
            return ["googlechrome://"]
        } else if lower.contains("locket") {
            return ["locket://"]
        } else if lower.contains("free fire") || lower.contains("freefire") {
            return ["freefire://"]
        } else if lower.contains("momo") {
            return ["momo://"]
        } else if lower.contains("ảnh") || lower.contains("photo") {
            return ["photos-redirect://"]
        } else if lower.contains("safari") {
            return ["x-web-search://"]
        } else if lower.contains("mail") {
            return ["message://"]
        } else if lower.contains("tin nhắn") || lower.contains("messages") || lower == "sms" {
            return ["sms://"]
        } else if lower.contains("ghi chú") || lower.contains("notes") {
            return ["mobilenotes://"]
        } else if lower.contains("tệp") || lower.contains("files") {
            return ["shareddocuments://"]
        }
        return []
    }
    
    static let defaultApps: [AppItem] = [
        // Mạng xã hội & Nhắn tin phổ biến
        AppItem(bundleId: "com.facebook.Facebook", appName: "Facebook", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "f.circle.fill", category: "Mạng xã hội", urlSchemes: ["fb://"]),
        AppItem(bundleId: "com.facebook.Messenger", appName: "Messenger", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "message.fill", category: "Nhắn tin", urlSchemes: ["fb-messenger://"]),
        AppItem(bundleId: "com.zing.zalo", appName: "Zalo", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "bubble.left.and.bubble.right.fill", category: "Nhắn tin", urlSchemes: ["zalo://"]),
        AppItem(bundleId: "com.burbn.instagram", appName: "Instagram", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "camera.fill", category: "Mạng xã hội", urlSchemes: ["instagram://"]),
        AppItem(bundleId: "com.ss.iphone.ugc.Ame", appName: "TikTok", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "music.note", category: "Mạng xã hội", urlSchemes: ["snssdk1180://", "snssdk1233://", "tiktok://"]),
        AppItem(bundleId: "com.hammerandchisel.discord", appName: "Discord", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "gamecontroller.fill", category: "Nhắn tin", urlSchemes: ["discord://"]),
        AppItem(bundleId: "ph.telegra.Telegraph", appName: "Telegram", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "paperplane.fill", category: "Nhắn tin", urlSchemes: ["tg://"]),
        AppItem(bundleId: "com.locket.Locket", appName: "Locket", isLocked: false, isSystemApp: false, isRecommended: false, iconSymbol: "heart.rectangle.fill", category: "Mạng xã hội", urlSchemes: ["locket://"]),
        
        // Đa phương tiện & Mua sắm & Giải trí
        AppItem(bundleId: "com.apple.mobileslideshow", appName: "Ảnh (Photos)", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "photo.stack.fill", category: "Đa phương tiện", urlSchemes: ["photos-redirect://"]),
        AppItem(bundleId: "com.google.ios.youtube", appName: "YouTube", isLocked: false, isSystemApp: false, isRecommended: false, iconSymbol: "play.rectangle.fill", category: "Đa phương tiện", urlSchemes: ["youtube://"]),
        AppItem(bundleId: "com.beeasy.shopee.vn", appName: "Shopee", isLocked: false, isSystemApp: false, isRecommended: false, iconSymbol: "bag.fill", category: "Mua sắm", urlSchemes: ["shopeevn://", "shopee://"]),
        AppItem(bundleId: "com.dts.freefireth", appName: "Free Fire", isLocked: false, isSystemApp: false, isRecommended: false, iconSymbol: "flame.fill", category: "Trò chơi", urlSchemes: ["freefire://"]),
        
        // Ngân hàng & Tài chính
        AppItem(bundleId: "com.mservice.momopay", appName: "MoMo", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "wallet.pass.fill", category: "Ví điện tử", urlSchemes: ["momo://"]),
        AppItem(bundleId: "vn.vcb.digibank", appName: "VCB Digibank", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "banknote.fill", category: "Ngân hàng"),
        AppItem(bundleId: "com.mbmobile", appName: "MB Bank", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "creditcard.fill", category: "Ngân hàng"),
        AppItem(bundleId: "com.techcombank.mobile", appName: "Techcombank Mobile", isLocked: true, isSystemApp: false, isRecommended: true, iconSymbol: "dollarsign.circle.fill", category: "Ngân hàng"),
        
        // Trình duyệt & Hệ thống
        AppItem(bundleId: "com.apple.mobilesafari", appName: "Safari", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "safari.fill", category: "Trình duyệt", urlSchemes: ["x-web-search://"]),
        AppItem(bundleId: "com.google.chrome.ios", appName: "Chrome", isLocked: false, isSystemApp: false, isRecommended: false, iconSymbol: "globe", category: "Trình duyệt", urlSchemes: ["googlechrome://"]),
        AppItem(bundleId: "com.google.Gmail", appName: "Gmail", isLocked: false, isSystemApp: false, isRecommended: true, iconSymbol: "envelope.badge.fill", category: "Email", urlSchemes: ["googlegmail://"]),
        AppItem(bundleId: "com.apple.MobileSMS", appName: "Tin nhắn (Messages)", isLocked: true, isSystemApp: true, isRecommended: true, iconSymbol: "ellipsis.message.fill", category: "Hệ thống", urlSchemes: ["sms://"]),
        AppItem(bundleId: "com.apple.Preferences", appName: "Cài đặt (Settings)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "gearshape.fill", category: "Hệ thống"),
        AppItem(bundleId: "com.apple.mobilemail", appName: "Mail", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "envelope.fill", category: "Hệ thống", urlSchemes: ["message://"]),
        AppItem(bundleId: "com.apple.mobilenotes", appName: "Ghi chú (Notes)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "note.text", category: "Hệ thống", urlSchemes: ["mobilenotes://"]),
        AppItem(bundleId: "com.apple.DocumentsApp", appName: "Tệp (Files)", isLocked: false, isSystemApp: true, isRecommended: false, iconSymbol: "folder.fill", category: "Hệ thống", urlSchemes: ["shareddocuments://"])
    ]
}
