import SwiftUI

public struct ShortcutsGuideView: View {
    @Environment(\.presentationMode) var presentationMode
    
    struct GuideStep: Identifiable {
        let id: Int
        let title: String
        let description: String
        let iconName: String
        let color: Color
    }
    
    let steps: [GuideStep] = [
        GuideStep(
            id: 1,
            title: "Mở ứng dụng Phím Tắt (Shortcuts)",
            description: "Tìm và mở app 'Phím tắt' (Shortcuts) có sẵn trên iPhone của bạn.",
            iconName: "square.stack.3d.up.fill",
            color: AppColors.cyan
        ),
        GuideStep(
            id: 2,
            title: "Tạo Tự Động Hóa Mới (Automation)",
            description: "Chuyển sang tab 'Tự động hóa' ở thanh dưới cùng và nhấn nút (+) hoặc 'Tạo mục tự động hóa cá nhân'.",
            iconName: "plus.circle.fill",
            color: AppColors.emerald
        ),
        GuideStep(
            id: 3,
            title: "Chọn điều kiện: Ứng Dụng (App)",
            description: "Cuộn xuống chọn 'Ứng dụng' -> Chọn danh sách app bạn muốn khóa (Safari, Messenger, Ảnh, Zalo...) -> Tích chọn 'Khi được mở'.",
            iconName: "app.badge.checkmark.fill",
            color: AppColors.amber
        ),
        GuideStep(
            id: 4,
            title: "Đặt 'Chạy ngay lập tức' (Run Immediately)",
            description: "Chọn tùy chọn 'Chạy ngay lập tức' và tắt 'Thông báo khi chạy' để màn hình khóa kích hoạt mượt mà nhất.",
            iconName: "bolt.fill",
            color: AppColors.purple
        ),
        GuideStep(
            id: 5,
            title: "Thêm tác vụ: Mở ứng dụng AppLock",
            description: "Nhấn 'Tiếp' -> Chọn hành động 'Mở ứng dụng' -> Chọn 'AppLock'. Hoàn tất!",
            iconName: "shield.lefthalf.filled",
            color: AppColors.cyan
        )
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hướng dẫn khóa tức thì")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Tự động hóa với Apple Shortcuts")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Notice card
                        GlassCard {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.amber)
                                
                                Text("Khóa ứng dụng tức thì bằng tính năng Phím Tắt của Apple giúp AppLock hoạt động trên mọi phiên bản iOS mà không cần Jailbreak hay cài đặt phức tạp.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                            .padding(14)
                        }
                        
                        // Steps list
                        ForEach(steps) { step in
                            GlassCard {
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(step.color.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: step.iconName)
                                            .font(.system(size: 18))
                                            .foregroundColor(step.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Bước \(step.id): \(step.title)")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Text(step.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                            }
                        }
                        
                        // Quick open shortcuts button
                        Button(action: {
                            if let url = URL(string: "shortcuts://") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.right.square.fill")
                                Text("Mở ứng dụng Phím Tắt ngay")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}
