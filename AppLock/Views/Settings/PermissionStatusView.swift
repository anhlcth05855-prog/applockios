import SwiftUI
import AVFoundation
import Photos
import LocalAuthentication

public struct PermissionStatusView: View {
    @State private var cameraStatus: String = "Kiểm tra..."
    @State private var photosStatus: String = "Kiểm tra..."
    @State private var biometricsStatus: String = "Kiểm tra..."
    
    public init() {}
    
    public var body: some View {
        GlassCard {
            VStack(spacing: 12) {
                permissionRow(
                    icon: "faceid",
                    title: "Face ID / Touch ID",
                    statusText: biometricsStatus,
                    isGranted: biometricsStatus == "Sẵn sàng"
                )
                
                Divider().background(AppColors.cardBorder)
                
                permissionRow(
                    icon: "camera.fill",
                    title: "Máy ảnh (Bắt kẻ xâm nhập)",
                    statusText: cameraStatus,
                    isGranted: cameraStatus == "Đã cấp"
                )
                
                Divider().background(AppColors.cardBorder)
                
                permissionRow(
                    icon: "photo.stack.fill",
                    title: "Thư viện ảnh (Két an toàn)",
                    statusText: photosStatus,
                    isGranted: photosStatus == "Đã cấp"
                )
            }
            .padding(16)
        }
        .onAppear {
            checkPermissions()
        }
    }
    
    @ViewBuilder
    private func permissionRow(icon: String, title: String, statusText: String, isGranted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isGranted ? AppColors.emerald : AppColors.textSecondary)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Text(statusText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isGranted ? AppColors.emerald : AppColors.amber)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (isGranted ? AppColors.emerald : AppColors.amber).opacity(0.12)
                )
                .cornerRadius(6)
        }
    }
    
    private func checkPermissions() {
        // Biometrics
        let bioType = BiometricManager.shared.getAvailableBiometricType()
        biometricsStatus = bioType == .none ? "Chưa kích hoạt" : "Sẵn sàng"
        
        // Camera
        let cam = AVCaptureDevice.authorizationStatus(for: .video)
        cameraStatus = (cam == .authorized) ? "Đã cấp" : "Chưa cấp"
        
        // Photos
        let photo = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photosStatus = (photo == .authorized || photo == .limited) ? "Đã cấp" : "Chưa cấp"
    }
}
