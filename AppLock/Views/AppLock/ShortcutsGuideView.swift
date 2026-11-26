import SwiftUI

public struct ShortcutsGuideView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAppName: String
    @State private var useFallbackUrlMode: Bool = false
    @State private var copiedUrl: Bool = false
    
    private let quickApps = ["Facebook", "YouTube", "Zalo", "Messenger", "Instagram", "Ảnh"]
    
    public init(initialAppName: String = "Facebook") {
        let cleaned = initialAppName.trimmingCharacters(in: .whitespacesAndNewlines)
        _selectedAppName = State(initialValue: cleaned.isEmpty ? "Facebook" : cleaned)
    }
    
    private var deepLinkString: String {
        let encoded = selectedAppName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? selectedAppName
        return "applock://lock?app=\(encoded)"
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bật Chặn Thực Tế Cho \(selectedAppName)")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Bắt buộc trên iPhone (thay cho quyền Tiếp cận của Android)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.amber)
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
                        // App chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(quickApps, id: \.self) { app in
                                    let active = selectedAppName == app
                                    Button(action: {
                                        selectedAppName = app
                                        HapticManager.shared.selection()
                                    }) {
                                        HStack(spacing: 6) {
                                            AppBrandIconView(appName: app, size: 18)
                                            Text(app)
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(active ? AppColors.cyan : AppColors.cardBackground)
                                        .foregroundColor(active ? AppColors.background : AppColors.textPrimary)
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        // Mode Switcher (Standard vs Cato/Sideload URL Fallback)
                        HStack(spacing: 0) {
                            Button(action: { useFallbackUrlMode = false }) {
                                Text("Cách 1: Tác vụ AppLock")
                                    .font(.system(size: 12.5, weight: !useFallbackUrlMode ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Capsule().fill(!useFallbackUrlMode ? AppColors.cyan : Color.clear))
                                    .foregroundColor(!useFallbackUrlMode ? AppColors.background : AppColors.textSecondary)
                            }
                            Button(action: { useFallbackUrlMode = true }) {
                                Text("Cách 2: Dành cho Cato / Sideload")
                                    .font(.system(size: 12.5, weight: useFallbackUrlMode ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Capsule().fill(useFallbackUrlMode ? AppColors.cyan : Color.clear))
                                    .foregroundColor(useFallbackUrlMode ? AppColors.background : AppColors.textSecondary)
                            }
                        }
                        .padding(4)
                        .background(Capsule().fill(AppColors.cardBackground).overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1)))
                        
                        if !useFallbackUrlMode {
                            standardAppIntentGuide
                        } else {
                            catoUrlFallbackGuide
                        }
                        
                        // Open Shortcuts App Button
                        Button(action: {
                            UIPasteboard.general.string = deepLinkString
                            if let url = URL(string: "shortcuts://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("Mở ứng dụng Phím Tắt (Shortcuts) ngay")
                            }
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Capsule().fill(AppColors.cyan))
                        }
                        .padding(.top, 4)
                        
                        // Confirm Done Button
                        Button(action: {
                            appLockManager.isAutomationVerified = true
                            appLockManager.saveSettings()
                            appLockManager.showToast("Đã kích hoạt trạng thái chặn ứng dụng!")
                            dismiss()
                        }) {
                            Text("Tôi đã tạo xong Tự động hóa trong Phím Tắt")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(AppColors.emerald)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    Capsule()
                                        .fill(AppColors.emerald.opacity(0.14))
                                        .overlay(Capsule().stroke(AppColors.emerald.opacity(0.5), lineWidth: 1))
                                )
                        }
                        .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var standardAppIntentGuide: some View {
        VStack(spacing: 12) {
            stepCard(
                step: 1,
                title: "Mở app Phím Tắt -> Tab Tự động hóa (+)",
                desc: "Vào ứng dụng 'Phím tắt' có sẵn trên iPhone -> chọn tab 'Tự động hóa' ở thanh dưới cùng -> bấm dấu (+) góc trên phải.",
                color: AppColors.cyan
            )
            stepCard(
                step: 2,
                title: "Chọn Ứng dụng: \(selectedAppName) -> Chạy ngay lập tức",
                desc: "Chọn 'Ứng dụng' -> Bấm 'Chọn' và tích '\(selectedAppName)' -> Tích 'Được mở' và BẮT BUỘC chọn 'Chạy ngay lập tức' (Run Immediately) -> Bấm 'Tiếp' -> Chọn 'Tác vụ trống mới'.",
                color: AppColors.amber
            )
            stepCard(
                step: 3,
                title: "Thêm: Kiểm tra cần khóa -> Nếu -> Mở AppLock",
                desc: "1. Tìm 'AppLock' -> chọn 'Kiểm tra cần khóa ứng dụng' (điền '\(selectedAppName)').\n2. Tìm lệnh 'Nếu' (If).\n3. Tìm 'Mở ứng dụng' -> chọn 'AppLock' và kéo nằm giữa dòng 'Nếu' và 'Kết thúc Nếu' -> Bấm Xong!\n(Nếu tìm không thấy 'Kiểm tra cần khóa' do cài qua Cato, hãy bấm sang tab Cách 2 ở trên!)",
                color: AppColors.emerald
            )
        }
    }
    
    private var catoUrlFallbackGuide: some View {
        VStack(spacing: 12) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Link khóa dành riêng cho \(selectedAppName):")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    
                    HStack {
                        Text(deepLinkString)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = deepLinkString
                            copiedUrl = true
                            HapticManager.shared.notification(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedUrl = false }
                        }) {
                            Text(copiedUrl ? "Đã chép!" : "Sao chép")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.background)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(copiedUrl ? AppColors.emerald : AppColors.cyan))
                        }
                    }
                    .padding(10)
                    .background(AppColors.inputBackground)
                    .cornerRadius(10)
                }
                .padding(14)
            }
            
            stepCard(
                step: 1,
                title: "Mở Phím Tắt -> Tự động hóa (+) -> Ứng dụng",
                desc: "Chọn '\(selectedAppName)' -> tích 'Được mở' -> tích 'Chạy ngay lập tức' (Run Immediately) -> Tiếp -> 'Tác vụ trống mới'.",
                color: AppColors.cyan
            )
            stepCard(
                step: 2,
                title: "Kiểm tra phiên mở khóa (Chống lặp vô hạn)",
                desc: "1. Thêm tác vụ 'Lấy tệp từ thư mục' -> chọn thư mục 'Trên iPhone của tôi / AppLock', ô đường dẫn gõ: unlocked_pass.txt -> Bấm mũi tên mở rộng TẮT 'Báo lỗi nếu không tìm thấy'.\n2. Thêm lệnh 'Nếu' -> bấm vào điều kiện chọn 'không có giá trị bất kỳ'.",
                color: AppColors.amber
            )
            stepCard(
                step: 3,
                title: "Thêm 'Mở URL' bên trong 'Nếu'",
                desc: "Tìm tác vụ 'Mở URL' (Open URLs), dán link '\(deepLinkString)' vào, rồi kéo dòng 'Mở URL' nằm giữa 'Nếu' và 'Kết thúc Nếu' -> Bấm Xong! Từ giờ bấm vào \(selectedAppName) sẽ hiện ngay màn hình nhập mã PIN!",
                color: AppColors.emerald
            )
        }
    }
    
    private func stepCard(step: Int, title: String, desc: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 30, height: 30)
                Text("\(step)")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
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
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppColors.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.cardBorder, lineWidth: 1))
        )
    }
}
