import SwiftUI

/// Renders realistic colorful iOS/Android brand icons matching the reference video
public struct AppBrandIconView: View {
    let appName: String
    let fallbackSymbol: String
    var size: CGFloat = 44
    
    public init(appName: String, fallbackSymbol: String = "app.fill", size: CGFloat = 44) {
        self.appName = appName
        self.fallbackSymbol = fallbackSymbol
        self.size = size
    }
    
    public init(app: AppItem, size: CGFloat = 44) {
        self.appName = app.appName
        self.fallbackSymbol = app.iconSymbol
        self.size = size
    }
    
    public var body: some View {
        let lower = appName.lowercased()
        let corner = size * 0.24
        
        ZStack {
            if lower.contains("youtube") {
                // White rounded card + Red YouTube play badge
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: size * 0.14)
                    .fill(Color(hex: "FF0000"))
                    .frame(width: size * 0.72, height: size * 0.50)
                Image(systemName: "play.fill")
                    .font(.system(size: size * 0.24, weight: .bold))
                    .foregroundColor(.white)
            } else if lower.contains("facebook") || lower == "fb" {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "1877F2"))
                Text("f")
                    .font(.system(size: size * 0.72, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .offset(x: size * 0.03, y: size * 0.08)
            } else if lower.contains("zalo") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color.white)
                Circle()
                    .fill(Color(hex: "0068FF"))
                    .frame(width: size * 0.78, height: size * 0.78)
                Text("Zalo")
                    .font(.system(size: size * 0.26, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            } else if lower.contains("messenger") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "00B2FF"), Color(hex: "006AFF"), Color(hex: "A033FF"), Color(hex: "FF5280")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                Image(systemName: "bolt.horizontal.fill")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundColor(.white)
            } else if lower.contains("telegram") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "37AEE2"), Color(hex: "1E96C8")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Image(systemName: "paperplane.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(.white)
                    .offset(x: -size * 0.02, y: size * 0.02)
            } else if lower.contains("instagram") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FEDA75"), Color(hex: "FA7E1E"), Color(hex: "D62976"), Color(hex: "962FBF"), Color(hex: "4F5BD5")],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                Image(systemName: "camera")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundColor(.white)
            } else if lower.contains("tiktok") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "080808"))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.48, weight: .heavy))
                    .foregroundColor(Color(hex: "FE2C55"))
                    .offset(x: 1.5, y: 1.5)
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.48, weight: .heavy))
                    .foregroundColor(Color(hex: "25F4EE"))
                    .offset(x: -1.5, y: -1.5)
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.48, weight: .heavy))
                    .foregroundColor(.white)
            } else if lower.contains("chrome") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color.white)
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [Color(hex: "EA4335"), Color(hex: "FBBC05"), Color(hex: "34A853"), Color(hex: "EA4335")],
                            center: .center
                        ),
                        lineWidth: size * 0.18
                    )
                    .frame(width: size * 0.72, height: size * 0.72)
                Circle()
                    .fill(Color(hex: "4285F4"))
                    .frame(width: size * 0.30, height: size * 0.30)
            } else if lower.contains("gmail") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color.white)
                Text("M")
                    .font(.system(size: size * 0.54, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "4285F4"), Color(hex: "EA4335"), Color(hex: "FBBC05"), Color(hex: "34A853")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else if lower.contains("ảnh") || lower.contains("album") || lower.contains("photo") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF9A9E"), Color(hex: "FAD0C4"), Color(hex: "A1C4FD")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .font(.system(size: size * 0.44))
                    .foregroundColor(Color(hex: "1E3A8A"))
            } else if lower.contains("1.1.1.1") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "F72585"), Color(hex: "7209B7")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("1.1.1.1")
                    .font(.system(size: size * 0.24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            } else if lower.contains("cài đặt") || lower.contains("settings") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "8E9AAF"), Color(hex: "4A5568")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.52))
                    .foregroundColor(.white)
            } else if lower.contains("máy ảnh") || lower.contains("camera") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "2D3748"))
                Circle()
                    .stroke(Color(hex: "00E5FF"), lineWidth: 2)
                    .frame(width: size * 0.56, height: size * 0.56)
                Image(systemName: "camera.fill")
                    .font(.system(size: size * 0.36))
                    .foregroundColor(.white)
            } else if lower.contains("momo") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "A50064"))
                Text("mo\nmo")
                    .font(.system(size: size * 0.24, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(-2)
                    .foregroundColor(.white)
            } else if lower.contains("shopee") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "EE4D2D"))
                Image(systemName: "bag.fill")
                    .font(.system(size: size * 0.48))
                    .foregroundColor(.white)
            } else if lower.contains("discord") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "5865F2"))
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: size * 0.46))
                    .foregroundColor(.white)
            } else if lower.contains("safari") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "1FA2FF"), Color(hex: "12D8FA"), Color(hex: "0072FF")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Image(systemName: "safari.fill")
                    .font(.system(size: size * 0.54))
                    .foregroundColor(.white)
            } else if lower.contains("tin nhắn") || lower.contains("messages") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color(hex: "34C759"))
                Image(systemName: "message.fill")
                    .font(.system(size: size * 0.48))
                    .foregroundColor(.white)
            } else if lower.contains("vcb") || lower.contains("mb") || lower.contains("techcombank") {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "0F766E"), Color(hex: "047857")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundColor(.white)
            } else {
                RoundedRectangle(cornerRadius: corner)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2563EB"), Color(hex: "7C3AED")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: fallbackSymbol)
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 2)
    }
}

/// Floating pill toast matching the exact style shown in the video
public struct ToastBannerView: View {
    let message: String
    
    public init(message: String) {
        self.message = message
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppColors.background)
                    .frame(width: 22, height: 22)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.cyan)
            }
            
            Text(message)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(Color(hex: "1E293B"))
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            Capsule()
                .fill(Color(hex: "F1F5F9").opacity(0.96))
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
    }
}
