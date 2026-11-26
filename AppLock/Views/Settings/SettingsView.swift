import SwiftUI
import AVFoundation
#if canImport(FamilyControls)
import FamilyControls
#endif

public struct SettingsView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var showingChangePasscode = false
    @State private var showingShortcutsGuide = false
    @State private var showingFamilyPicker = false
    @State private var cameraAuthorized = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. Phương thức khóa (matching 00:19 in video)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phương thức khóa")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        
                        VStack(spacing: 14) {
                            Button(action: {
                                appLockManager.lockType = (appLockManager.lockType == .pin ? .pattern : .pin)
                                appLockManager.saveSettings()
                                appLockManager.showToast("Đã chuyển sang \(appLockManager.lockType == .pin ? "Mã PIN" : "Hình vẽ mẫu")")
                            }) {
                                HStack {
                                    Text("Loại khóa hiện tại")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(appLockManager.lockType == .pin ? "Mã PIN" : "Hình vẽ mẫu")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(AppColors.cyan)
                                }
                            }
                            
                            Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                            
                            HStack {
                                Text("Mở khóa bằng vân tay / khuôn mặt")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Toggle("", isOn: $appLockManager.isBiometricEnabled)
                                    .labelsHidden()
                                    .tint(AppColors.cyan)
                                    .onChange(of: appLockManager.isBiometricEnabled) { _ in
                                        appLockManager.saveSettings()
                                    }
                            }
                            
                            Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                            
                            Button(action: {
                                showingChangePasscode = true
                            }) {
                                Text(appLockManager.lockType == .pin ? "Đổi mã PIN" : "Đổi hình vẽ")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.cyan)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        Capsule()
                                            .stroke(AppColors.cardBorder, lineWidth: 1.5)
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
                    
                    // 2. Quyền hệ thống (Interactive rows matching 00:19)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quyền hệ thống")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        
                        VStack(spacing: 14) {
                            Button(action: { showingShortcutsGuide = true }) {
                                HStack {
                                    Text("Tự động chặn ứng dụng (Khuyên dùng)")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(appLockManager.isAutomationVerified ? "Đã cấp quyền" : "Cấp quyền")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(appLockManager.isAutomationVerified ? AppColors.emerald : AppColors.amber)
                                }
                            }
                            
                            Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                            
                            Button(action: {
                                Task {
                                    let ok = await screenTimeManager.requestAuthorization()
                                    if ok {
                                        showingFamilyPicker = true
                                    } else {
                                        showingShortcutsGuide = true
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Hiển thị khiên khóa (Screen Time)")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(screenTimeManager.isAuthorized ? "Đã cấp quyền" : "Thiết lập")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(screenTimeManager.isAuthorized ? AppColors.emerald : AppColors.cyan)
                                }
                            }
                            
                            Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                            
                            Button(action: {
                                Task {
                                    let granted = await CameraManager.shared.requestCameraPermission()
                                    await MainActor.run {
                                        cameraAuthorized = granted
                                        if !granted, let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                }
                            }) {
                                HStack {
                                    Text("Quyền máy ảnh (Chụp kẻ gian)")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Text(cameraAuthorized ? "Đã cấp quyền" : "Cấp quyền")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(cameraAuthorized ? AppColors.emerald : AppColors.amber)
                                }
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
                    
                    // 3. Thời gian khóa lại (Radio buttons matching 00:19)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Thời gian khóa lại")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            radioRow(policy: .screenOff, label: "Khóa khi tắt màn hình")
                            radioRow(policy: .immediately, label: "Khóa ngay khi thoát ứng dụng")
                            radioRow(policy: .oneMinute, label: "Sau 1 phút")
                            
                            Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                            
                            HStack {
                                Text("Phiên mở khóa ứng dụng ngoài:")
                                    .font(.system(size: 13.5))
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Picker("", selection: $appLockManager.unlockGraceSeconds) {
                                    Text("30 giây").tag(30)
                                    Text("1 phút").tag(60)
                                    Text("2 phút").tag(120)
                                    Text("5 phút").tag(300)
                                }
                                .pickerStyle(.menu)
                                .tint(AppColors.cyan)
                                .onChange(of: appLockManager.unlockGraceSeconds) { _ in
                                    appLockManager.saveSettings()
                                }
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
                    
                    // 4. Rung khi bấm phím
                    HStack {
                        Text("Rung khi bấm phím")
                            .font(.system(size: 15))
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
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    )
                    
                    // 5. About Card
                    VStack(spacing: 5) {
                        Text("AppLock - Lock & Guard Private")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Phiên bản 1.3.0 Pro Guard")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                        
                        Text("Phát triển theo chuẩn bảo mật riêng tư cao cấp")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
        }
        .onAppear {
            cameraAuthorized = (AVCaptureDevice.authorizationStatus(for: .video) == .authorized)
        }
        .fullScreenCover(isPresented: $showingChangePasscode) {
            SecuritySetupFlowView(isChangingPasscode: true) {
                showingChangePasscode = false
            }
        }
        .sheet(isPresented: $showingShortcutsGuide) {
            ShortcutsGuideView(initialAppName: "Facebook")
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showingFamilyPicker, selection: $screenTimeManager.activitySelection)
        #endif
    }
    
    private func radioRow(policy: RelockPolicy, label: String) -> some View {
        let selected = appLockManager.relockPolicy == policy
        return Button(action: {
            appLockManager.relockPolicy = policy
            appLockManager.saveSettings()
            if appLockManager.isVibrationEnabled {
                HapticManager.shared.selection()
            }
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
