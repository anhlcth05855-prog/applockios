import SwiftUI
import AVFoundation

public struct SettingsView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var showingChangePasscode = false
    @State private var showingScreenTimeSheet = false
    @State private var cameraAuthorized = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Cài đặt")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 8)
                    
                    // 1. Bảo mật & Mật khẩu
                    sectionHeader("Bảo mật & Mật khẩu")
                    VStack(spacing: 14) {
                        Button(action: { showingChangePasscode = true }) {
                            HStack {
                                Image(systemName: "key.fill")
                                    .foregroundColor(AppColors.cyan)
                                Text("Đổi mật khẩu 6 số")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textMuted)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                .foregroundColor(AppColors.cyan)
                            Text("Mở khóa bằng \(BiometricManager.shared.getAvailableBiometricType().title)")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $appLockManager.isBiometricEnabled)
                                .labelsHidden()
                                .tint(AppColors.cyan)
                                .onChange(of: appLockManager.isBiometricEnabled) { _ in
                                    appLockManager.saveSettings()
                                }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    
                    // 2. Quyền hệ thống iOS
                    sectionHeader("Quyền hệ thống iOS")
                    VStack(spacing: 14) {
                        Button(action: { showingScreenTimeSheet = true }) {
                            HStack {
                                Image(systemName: "hourglass")
                                    .foregroundColor(AppColors.cyan)
                                Text("Thời gian sử dụng (Screen Time)")
                                    .font(.system(size: 14.5, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(screenTimeManager.isAuthorized ? "Đã cấp quyền" : "Cấp quyền")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(screenTimeManager.isAuthorized ? AppColors.emerald : AppColors.amber)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                let ok = await CameraManager.shared.requestCameraPermission()
                                await MainActor.run {
                                    cameraAuthorized = ok
                                    if !ok, let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(AppColors.cyan)
                                Text("Máy ảnh (Chụp kẻ xâm nhập)")
                                    .font(.system(size: 14.5, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(cameraAuthorized ? "Đã cấp quyền" : "Cấp quyền")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(cameraAuthorized ? AppColors.emerald : AppColors.amber)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            Task {
                                await screenTimeManager.requestNotificationPermission()
                                await MainActor.run {
                                    appLockManager.showToast("Đã bật thông báo mở khóa nhanh!")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(AppColors.cyan)
                                Text("Thông báo Mở khóa")
                                    .font(.system(size: 14.5, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text("Cho phép")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(AppColors.cyan)
                            }
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    
                    // 3. Thời gian khóa lại AppLock
                    sectionHeader("Thời gian khóa lại")
                    VStack(alignment: .leading, spacing: 14) {
                        radioRow(policy: .immediately, label: "Khóa ngay khi thoát ứng dụng")
                        radioRow(policy: .screenOff, label: "Khóa khi tắt màn hình")
                        radioRow(policy: .oneMinute, label: "Sau 1 phút")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    
                    // 4. Rung phản hồi
                    HStack {
                        Text("Rung khi bấm phím")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Toggle("", isOn: $appLockManager.isVibrationEnabled)
                            .labelsHidden()
                            .tint(AppColors.cyan)
                            .onChange(of: appLockManager.isVibrationEnabled) { _ in
                                appLockManager.saveSettings()
                            }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    
                    // 5. About
                    VStack(spacing: 4) {
                        Text("Khoá App - Guard Private Protection")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Phiên bản 2.0.0 • Native Screen Time API")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 16)
            }
        }
        .onChange(of: appLockManager.modalDismissToken) { _ in
            showingChangePasscode = false
            showingScreenTimeSheet = false
        }
        .onAppear {
            cameraAuthorized = (AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
            screenTimeManager.checkCurrentStatus()
        }
        .fullScreenCover(isPresented: $showingChangePasscode) {
            SecuritySetupFlowView(isChangingPasscode: true) {
                showingChangePasscode = false
            }
        }
        .sheet(isPresented: $showingScreenTimeSheet) {
            ScreenTimePermissionView()
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppColors.textSecondary)
            .padding(.leading, 4)
    }
    
    private func radioRow(policy: RelockPolicy, label: String) -> some View {
        let selected = appLockManager.relockPolicy == policy
        return Button(action: {
            appLockManager.relockPolicy = policy
            appLockManager.saveSettings()
            HapticManager.shared.selection()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(selected ? AppColors.cyan : AppColors.textMuted, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if selected {
                        Circle()
                            .fill(AppColors.cyan)
                            .frame(width: 10, height: 10)
                    }
                }
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
