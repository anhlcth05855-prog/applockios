import SwiftUI

/// Screen Time Permission Prompt matching 00:08 - 00:20 in the reference video
public struct ScreenTimePermissionView: View {
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var onAuthorized: (() -> Void)? = nil
    
    @State private var isRequesting: Bool = false
    @State private var showErrorAlert: Bool = false
    
    public init(onAuthorized: (() -> Void)? = nil) {
        self.onAuthorized = onAuthorized
    }
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.inputBackground))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // Hourglass Icon matching 00:08
                Image(systemName: "hourglass")
                    .font(.system(size: 58, weight: .light))
                    .foregroundColor(AppColors.cyan)
                    .padding(.bottom, 22)
                
                Text("Cho phép \"Khoá App\" truy cập vào \"Thời gian sử dụng\"")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                
                Text("Theo yêu cầu của iOS, bạn phải cho phép truy cập vào \"Thời gian sử dụng\" để sử dụng tính năng khóa ứng dụng.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                
                Button(action: requestPermission) {
                    ZStack {
                        Capsule()
                            .fill(AppColors.cyan)
                            .frame(width: 170, height: 48)
                        
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Cho phép")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isRequesting)
                .padding(.top, 28)
                
                Spacer()
            }
        }
        .alert("Không thể cấp quyền Thời gian sử dụng", isPresented: $showErrorAlert) {
            Button("Thử lại") {
                requestPermission()
            }
            Button("Đóng", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(screenTimeManager.authorizationError ?? "Vui lòng bật Thời gian sử dụng trong Cài đặt iPhone.")
        }
    }
    
    private func requestPermission() {
        isRequesting = true
        Task {
            let approved = await screenTimeManager.requestAuthorization()
            await MainActor.run {
                isRequesting = false
                if approved {
                    if let onAuthorized = onAuthorized {
                        onAuthorized()
                    } else {
                        dismiss()
                    }
                } else {
                    showErrorAlert = true
                }
            }
        }
    }
}
