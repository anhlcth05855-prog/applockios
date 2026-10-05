import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    @State private var showingChangePasscode = false
    @State private var showingSecurityQuestion = false
    @State private var newQuestion = ""
    @State private var newAnswer = ""
    @State private var showingResetAlert = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CyberHeader(
                    title: "Cài Đặt & Bảo Mật",
                    subtitle: "Tùy chỉnh phương thức xác thực và quyền riêng tư",
                    badgeText: "Bản Pro 1.0",
                    badgeColor: AppColors.cyan
                )
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Security & Passcode
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PHƯƠNG THỨC KHÓA")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard {
                                VStack(spacing: 14) {
                                    // Lock Type Selection
                                    HStack {
                                        Text("Kiểu khóa chính:")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Picker("", selection: $appLockManager.lockType) {
                                            Text("Mã PIN").tag(LockType.pin)
                                            Text("Hình vẽ").tag(LockType.pattern)
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 160)
                                        .onChange(of: appLockManager.lockType) { _ in
                                            appLockManager.saveSettings()
                                        }
                                    }
                                    
                                    Divider().background(AppColors.cardBorder)
                                    
                                    // Change Passcode Button
                                    Button(action: {
                                        showingChangePasscode = true
                                    }) {
                                        HStack {
                                            Image(systemName: "key.fill")
                                                .foregroundColor(AppColors.cyan)
                                            Text(appLockManager.lockType == .pin ? "Đổi mã PIN 4 số" : "Đổi hình vẽ mẫu (Pattern)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                    
                                    Divider().background(AppColors.cardBorder)
                                    
                                    // Face ID / Biometrics toggle
                                    HStack {
                                        Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                            .foregroundColor(AppColors.emerald)
                                        Text("Mở khóa bằng \(BiometricManager.shared.getAvailableBiometricType().title)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Toggle("", isOn: $appLockManager.isBiometricEnabled)
                                            .labelsHidden()
                                            .tint(AppColors.cyan)
                                            .onChange(of: appLockManager.isBiometricEnabled) { _ in
                                                appLockManager.saveSettings()
                                            }
                                    }
                                    
                                    Divider().background(AppColors.cardBorder)
                                    
                                    // Security Question
                                    Button(action: {
                                        newQuestion = appLockManager.securityQuestion
                                        newAnswer = appLockManager.securityAnswer
                                        showingSecurityQuestion = true
                                    }) {
                                        HStack {
                                            Image(systemName: "questionmark.shield.fill")
                                                .foregroundColor(AppColors.amber)
                                            Text("Câu hỏi bảo mật (Khôi phục)")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppColors.textPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Section 2: Re-lock Policy & Haptics
                        VStack(alignment: .leading, spacing: 10) {
                            Text("QUY TẮC KHÓA LẠI & PHẢN HỒI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard {
                                VStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Thời gian khóa lại:")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Picker("", selection: $appLockManager.relockPolicy) {
                                            ForEach(RelockPolicy.allCases, id: \.self) { policy in
                                                Text(policy.title).tag(policy)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .padding(.vertical, 4)
                                        .onChange(of: appLockManager.relockPolicy) { _ in
                                            appLockManager.saveSettings()
                                        }
                                    }
                                    
                                    Divider().background(AppColors.cardBorder)
                                    
                                    HStack {
                                        Image(systemName: "iphone.radiowaves.left.and.right")
                                            .foregroundColor(AppColors.cyan)
                                        Text("Rung xúc giác (Haptic Feedback)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Toggle("", isOn: $appLockManager.isVibrationEnabled)
                                            .labelsHidden()
                                            .tint(AppColors.cyan)
                                            .onChange(of: appLockManager.isVibrationEnabled) { _ in
                                                appLockManager.saveSettings()
                                            }
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Section 3: Permission Status Dashboard
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TRẠNG THÁI QUYỀN HỆ THỐNG")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 24)
                            
                            PermissionStatusView()
                                .padding(.horizontal, 20)
                        }
                        
                        // Section 4: App Info & Credits
                        VStack(alignment: .leading, spacing: 10) {
                            Text("THÔNG TIN")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 24)
                            
                            GlassCard {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Phiên bản")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("1.0.0 Pro Guard (iOS)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppColors.cyan)
                                    }
                                    
                                    Divider().background(AppColors.cardBorder)
                                    
                                    HStack {
                                        Text("Bảo mật dữ liệu")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                        Spacer()
                                        Text("100% Offline Sandbox")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(AppColors.emerald)
                                    }
                                }
                                .padding(16)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(isPresented: $showingChangePasscode) {
            SecuritySetupFlowView(isChangingPasscode: true) {
                showingChangePasscode = false
            }
        }
        .sheet(isPresented: $showingSecurityQuestion) {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack {
                        Text("Đổi câu hỏi bảo mật")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Button("Đóng") {
                            showingSecurityQuestion = false
                        }
                        .foregroundColor(AppColors.cyan)
                    }
                    .padding(.top, 24)
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Câu hỏi:")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.cyan)
                            TextField("Nhập câu hỏi...", text: $newQuestion)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(10)
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                            
                            Divider().background(AppColors.cardBorder)
                            
                            Text("Câu trả lời bí mật:")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.cyan)
                            TextField("Nhập câu trả lời...", text: $newAnswer)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(10)
                                .background(AppColors.backgroundSecondary)
                                .cornerRadius(8)
                        }
                        .padding(16)
                    }
                    
                    Button("Lưu câu hỏi mới") {
                        appLockManager.securityQuestion = newQuestion
                        appLockManager.securityAnswer = newAnswer
                        appLockManager.saveSettings()
                        HapticManager.shared.notification(.success)
                        showingSecurityQuestion = false
                    }
                    .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                    .disabled(newAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
