import SwiftUI
import AVFoundation
import Photos
import LocalAuthentication
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Permission & Protection Activation Screen matching `activity_permission.xml`
public struct PermissionStatusView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var cameraGranted: Bool = false
    @State private var photosGranted: Bool = false
    @State private var showShortcutsGuide: Bool = false
    @State private var showFamilyPicker: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(AppColors.cyan)
                        .padding(.top, 24)
                    
                    Text("Kích Hoạt Bảo Vệ Toàn Diện")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 4)
                    
                    Text("Để AppLock có thể phát hiện và khóa ứng dụng tức thì ngay khi mở, vui lòng cấp các quyền cần thiết bên dưới:")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    
                    // 1. Tự động chặn ứng dụng (Khuyên dùng)
                    permissionCard(
                        title: "1. Tự động khóa ứng dụng (Khuyên dùng)",
                        subtitle: "Khóa Facebook, YouTube, Zalo tức thì 0.01 giây",
                        isGranted: appLockManager.isAutomationVerified
                    ) {
                        showShortcutsGuide = true
                    }
                    
                    // 2. Khiên khóa hệ thống (Screen Time)
                    permissionCard(
                        title: "2. Hiển thị trên ứng dụng khác",
                        subtitle: "Chặn trực tiếp qua Apple Screen Time (iOS 16+)",
                        isGranted: screenTimeManager.isAuthorized
                    ) {
                        Task {
                            let ok = await screenTimeManager.requestAuthorization()
                            if ok {
                                showFamilyPicker = true
                            } else {
                                showShortcutsGuide = true
                            }
                        }
                    }
                    
                    // 3. Quyền máy ảnh (Chụp kẻ gian)
                    permissionCard(
                        title: "3. Quyền máy ảnh (Chụp kẻ gian)",
                        subtitle: "Tự động chụp camera trước khi mở khóa sai",
                        isGranted: cameraGranted
                    ) {
                        Task {
                            let ok = await CameraManager.shared.requestCameraPermission()
                            await MainActor.run { cameraGranted = ok }
                        }
                    }
                    
                    // 4. Quyền Thư viện ảnh (Két riêng tư)
                    permissionCard(
                        title: "4. Quyền truy cập Két riêng tư",
                        subtitle: "Ẩn và khôi phục ảnh, video bí mật an toàn",
                        isGranted: photosGranted
                    ) {
                        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                            DispatchQueue.main.async {
                                photosGranted = (status == .authorized || status == .limited)
                            }
                        }
                    }
                    
                    Button(action: { dismiss() }) {
                        Text("Bắt đầu sử dụng")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Capsule().fill(AppColors.cyan))
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear(perform: refreshStatuses)
        .sheet(isPresented: $showShortcutsGuide) {
            ShortcutsGuideView(initialAppName: "Facebook")
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showFamilyPicker, selection: $screenTimeManager.activitySelection)
        #endif
    }
    
    private func permissionCard(title: String, subtitle: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textMuted)
            }
            
            Spacer()
            
            Button(action: action) {
                Text(isGranted ? "Đã cấp" : "Bật")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isGranted ? AppColors.emerald : AppColors.cyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill((isGranted ? AppColors.emerald : AppColors.cyan).opacity(0.15))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                )
        )
    }
    
    private func refreshStatuses() {
        cameraGranted = (AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
        let pStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photosGranted = (pStatus == .authorized || pStatus == .limited)
        screenTimeManager.checkCurrentStatus()
    }
}
