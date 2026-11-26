import SwiftUI

public struct ShortcutsGuideView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAppName: String
    @State private var copiedName: Bool = false
    
    private let quickApps = ["Facebook", "Messenger", "Zalo", "Instagram", "TikTok", "Ảnh (Photos)"]
    
    public init(initialAppName: String = "Facebook") {
        let cleaned = initialAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        _selectedAppName = State(initialValue: cleaned.isEmpty ? "Facebook" : cleaned)
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kích hoạt Khóa Thực Tế iOS")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Chặn tức thì • Mở khóa tự vào thẳng \(selectedAppName)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.cyan)
                    }
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ScrollView {
                    VStack(spacing: 14) {
                        // Quick select target app
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CHỌN ỨNG DỤNG BẠN MUỐN KHÓA:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickApps, id: \.self) { app in
                                        let active = selectedAppName == app
                                        Button(action: {
                                            selectedAppName = app
                                            HapticManager.shared.selection()
                                        }) {
                                            Text(app)
                                                .font(.system(size: 13, weight: .bold))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 7)
                                                .background(active ? AppColors.cyan : AppColors.cardBackground)
                                                .foregroundColor(active ? .black : AppColors.textPrimary)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Visual Formula Preview Card
                        GlassCard(
                            cornerRadius: 14,
                            borderColor: AppColors.cyan.opacity(0.45),
                            backgroundColor: AppColors.backgroundSecondary
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "cpu.fill")
                                        .foregroundColor(AppColors.cyan)
                                    Text("CÔNG THỨC CHỐNG LẶP VÔ HẠN (CHỈ 3 DÒNG):")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(AppColors.cyan)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    codeLine(num: "1", text: "Kiểm tra cần khóa \"\(selectedAppName)\"", highlight: AppColors.cyan)
                                    codeLine(num: "2", text: "Nếu [Kết quả Kiểm tra]", highlight: AppColors.amber)
                                    codeLine(num: "3", text: "    ↳ Mở ứng dụng [AppLock]", highlight: AppColors.emerald)
                                    codeLine(num: "4", text: "Kết thúc Nếu", highlight: AppColors.textSecondary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.background)
                                .cornerRadius(10)
                                
                                Text("• Khi bấm vào \(selectedAppName) -> Hiện khóa AppLock ngay lập tức.\n• Khi nhập đúng PIN / Face ID -> Tự động mở thẳng vào \(selectedAppName) mà không bị khóa lặp lại!\n• Khi bạn tắt công tắc \(selectedAppName) trong AppLock -> Tự động cho qua không hỏi mật khẩu!")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(14)
                        }
                        
                        // 4 Clear Steps
                        stepCard(
                            step: 1,
                            title: "Mở tab Tự động hóa (Automation)",
                            desc: "Bấm nút 'Mở ứng dụng Phím Tắt' bên dưới -> Chọn tab 'Tự động hóa' ở thanh dưới cùng -> Bấm dấu (+) góc trên bên phải.",
                            icon: "plus.circle.fill",
                            color: AppColors.cyan
                        )
                        
                        stepCard(
                            step: 2,
                            title: "Chọn điều kiện mở \(selectedAppName)",
                            desc: "Tìm chọn mục 'Ứng dụng' -> Bấm 'Chọn' và tích '\(selectedAppName)' -> Đảm bảo chọn 'Được mở' và TÍCH CHỌN 'Chạy ngay lập tức' (Run Immediately) -> Bấm 'Tiếp' -> Chọn 'Tác vụ trống mới' (New Blank Automation).",
                            icon: "bolt.fill",
                            color: AppColors.amber
                        )
                        
                        stepCard(
                            step: 3,
                            title: "Thêm 'Kiểm tra cần khóa ứng dụng'",
                            desc: "Bấm 'Thêm tác vụ' -> Gõ tìm 'AppLock' -> Chọn hành động 'Kiểm tra cần khóa ứng dụng' -> Chạm vào chữ Facebook màu xanh và điền '\(selectedAppName)'.",
                            icon: "shield.checkered",
                            color: AppColors.purple
                        )
                        
                        stepCard(
                            step: 4,
                            title: "Thêm lệnh 'Nếu' -> 'Mở AppLock'",
                            desc: "Gõ tìm lệnh 'Nếu' (If) vào ngay bên dưới -> Gõ tìm tiếp 'Mở ứng dụng', chọn 'AppLock', rồi giữ kéo dòng 'Mở AppLock' đặt NẰM GIỮA dòng 'Nếu' và 'Kết thúc Nếu' -> Bấm 'Xong'!",
                            icon: "checkmark.seal.fill",
                            color: AppColors.emerald
                        )
                        
                        // Copy App Name helper
                        Button(action: {
                            UIPasteboard.general.string = selectedAppName
                            copiedName = true
                            HapticManager.shared.notification(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                copiedName = false
                            }
                        }) {
                            HStack {
                                Image(systemName: copiedName ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                Text(copiedName ? "Đã sao chép tên '\(selectedAppName)'" : "Sao chép nhanh tên '\(selectedAppName)'")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBackground)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.cyan.opacity(0.35), lineWidth: 1)
                            )
                        }
                        
                        // Open Shortcuts App Button
                        Button(action: {
                            if let url = URL(string: "shortcuts://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("Mở ứng dụng Phím Tắt (Shortcuts) ngay")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                        .padding(.top, 4)
                        
                        // Confirm Done Button
                        Button(action: {
                            appLockManager.isAutomationVerified = true
                            appLockManager.saveSettings()
                            HapticManager.shared.notification(.success)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Tôi đã cài đặt xong — Bật trạng thái Bảo vệ")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.emerald)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColors.emerald.opacity(0.14))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppColors.emerald.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func codeLine(num: String, text: String, highlight: Color) -> some View {
        HStack(spacing: 8) {
            Text(num)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.textMuted)
            Text(text)
                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                .foregroundColor(highlight)
        }
    }
    
    private func stepCard(step: Int, title: String, desc: String, icon: String, color: Color) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bước \(step): \(title)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(desc)
                        .font(.system(size: 12.5))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}
