import SwiftUI

public struct LockScreenOverlayView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var enteredPin: String = ""
    @State private var selectedPattern: [Int] = []
    @State private var patternState: PatternState = .normal
    @State private var shakeAttempts: CGFloat = 0
    @State private var errorMessage: String? = nil
    @State private var showForgotSheet: Bool = false
    
    // For password recovery
    @State private var recoveryAnswerInput: String = ""
    @State private var recoveryError: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark Cyber Background
            AppColors.background
                .ignoresSafeArea()
            
            // Subtle neon background gradient glow
            RadialGradient(
                colors: [AppColors.cyan.opacity(0.12), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Top Shield or Target App Icon
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cardBackground)
                            .frame(width: 84, height: 84)
                            .overlay(
                                Circle().stroke(AppColors.cyan.opacity(0.4), lineWidth: 2)
                            )
                            .shadow(color: AppColors.cyan.opacity(0.3), radius: 12)
                        
                        Image(systemName: appLockManager.currentLockedAppTarget != nil ? "lock.shield.fill" : "shield.lefthalf.filled.badge.checkmark")
                            .font(.system(size: 38))
                            .foregroundColor(AppColors.cyan)
                    }
                    
                    if let target = appLockManager.currentLockedAppTarget {
                        Text("Đang khóa: \(target)")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text("Được bảo vệ bởi AppLock")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Text(appLockManager.lockType == .pin ? "Nhập mã PIN bảo mật 4 số" : "Vẽ hình mở khóa bảo mật")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.coral)
                            .transition(.opacity)
                    }
                }
                
                // Passcode input area
                if appLockManager.lockType == .pin {
                    PinPadView(
                        enteredPin: $enteredPin,
                        shakeAttempts: shakeAttempts,
                        showBiometricButton: appLockManager.isBiometricEnabled,
                        onBiometricTap: triggerBiometrics,
                        onComplete: verifyPinCode
                    )
                } else {
                    VStack(spacing: 20) {
                        PatternLockView(
                            selectedIndices: $selectedPattern,
                            state: patternState,
                            onComplete: verifyPatternCode
                        )
                        
                        if appLockManager.isBiometricEnabled {
                            Button(action: triggerBiometrics) {
                                HStack(spacing: 8) {
                                    Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                    Text("Mở bằng \(BiometricManager.shared.getAvailableBiometricType().title)")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.cyan)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(AppColors.cyan.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Footer: Switch mode or Forgot Passcode
                HStack(spacing: 32) {
                    // Switch PIN / Pattern
                    Button(action: {
                        withAnimation {
                            appLockManager.lockType = (appLockManager.lockType == .pin ? .pattern : .pin)
                            enteredPin = ""
                            selectedPattern = []
                            errorMessage = nil
                        }
                    }) {
                        Text(appLockManager.lockType == .pin ? "Đổi sang hình vẽ" : "Đổi sang mã PIN")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    // Forgot Passcode
                    Button(action: {
                        showForgotSheet = true
                    }) {
                        Text("Quên mật khẩu?")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            if appLockManager.isBiometricEnabled {
                triggerBiometrics()
            }
        }
        .sheet(isPresented: $showForgotSheet) {
            recoverySheetView
        }
    }
    
    // Recovery sheet
    private var recoverySheetView: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Khôi phục mật khẩu")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("Đóng") {
                        showForgotSheet = false
                    }
                    .foregroundColor(AppColors.cyan)
                }
                .padding(.top, 24)
                
                Text("Trả lời câu hỏi bảo mật của bạn để đặt lại quyền truy cập:")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Câu hỏi:")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        
                        Text(appLockManager.securityQuestion)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Divider().background(AppColors.cardBorder)
                        
                        TextField("Nhập câu trả lời của bạn...", text: $recoveryAnswerInput)
                            .padding(.vertical, 8)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(16)
                }
                
                if let err = recoveryError {
                    Text(err)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.coral)
                }
                
                Button(action: verifyRecoveryAnswer) {
                    Text("Xác thực & Mở khóa")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func verifyRecoveryAnswer() {
        if appLockManager.verifySecurityAnswer(recoveryAnswerInput) {
            recoveryError = nil
            showForgotSheet = false
            appLockManager.handleSuccessfulUnlock()
            dismiss()
        } else {
            recoveryError = "Câu trả lời bảo mật không chính xác!"
            HapticManager.shared.notification(.error)
        }
    }
    
    private func verifyPinCode(_ pin: String) {
        if appLockManager.verifyPIN(pin) {
            errorMessage = nil
            appLockManager.handleSuccessfulUnlock()
            dismiss()
        } else {
            withAnimation(.default) {
                shakeAttempts += 1
            }
            errorMessage = "Mã PIN không chính xác (\(appLockManager.failedAttemptsCount + 1) lần sai)"
            enteredPin = ""
            appLockManager.handleFailedAttempt(targetApp: appLockManager.currentLockedAppTarget ?? "AppLock")
        }
    }
    
    private func verifyPatternCode(_ pattern: [Int]) {
        if appLockManager.verifyPattern(pattern) {
            patternState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appLockManager.handleSuccessfulUnlock()
                selectedPattern = []
                patternState = .normal
                dismiss()
            }
        } else {
            patternState = .error
            appLockManager.handleFailedAttempt(targetApp: appLockManager.currentLockedAppTarget ?? "AppLock")
            errorMessage = "Hình vẽ không chính xác (\(appLockManager.failedAttemptsCount) lần sai)"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                selectedPattern = []
                patternState = .normal
            }
        }
    }
    
    private func triggerBiometrics() {
        Task {
            let result = await BiometricManager.shared.authenticate(reason: "Xác thực để mở khóa AppLock")
            switch result {
            case .success(let success):
                if success {
                    await MainActor.run {
                        appLockManager.handleSuccessfulUnlock()
                        dismiss()
                    }
                }
            case .failure:
                // User can use PIN or Pattern
                break
            }
        }
    }
}
