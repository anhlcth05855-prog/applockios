import SwiftUI

/// Lock Screen matching 00:43 - 00:52 & 01:06 - 01:09 in the reference video
public struct LockScreenOverlayView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    @State private var enteredPin: String = ""
    @State private var selectedPattern: [Int] = []
    @State private var patternState: PatternState = .normal
    @State private var shakeAttempts: CGFloat = 0
    @State private var errorToast: String? = nil
    @State private var showForgotSheet: Bool = false
    
    @State private var recoveryAnswerInput: String = ""
    @State private var recoveryError: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 44)
                
                // Top Target App Icon + Title + Prompt matching video (00:43 - 00:52)
                VStack(spacing: 10) {
                    if let target = appLockManager.currentLockedAppTarget, !target.isEmpty {
                        AppBrandIconView(appName: target, size: 68)
                        
                        Text(target)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, 2)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 62, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                        
                        Text("Được bảo vệ bởi AppLock")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, 2)
                    }
                    
                    Text(appLockManager.lockType == .pin ? "Nhập mã PIN bảo mật" : "Vẽ hình mở khóa")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // PIN Keypad or Pattern Matrix
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
                                    Text("Mở khóa nhanh bằng \(BiometricManager.shared.getAvailableBiometricType().title)")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.cyan)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom "Quên mật khẩu?" link matching video (00:50)
                Button(action: {
                    showForgotSheet = true
                }) {
                    Text("Quên mật khẩu?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.cyan)
                }
                .padding(.bottom, 28)
            }
            
            // Toast Pill near bottom on wrong attempt ("Mã PIN không chính xác (1 lần sai)")
            if let toast = errorToast {
                ToastBannerView(message: toast)
                    .padding(.bottom, 58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            enteredPin = ""
            selectedPattern = []
            patternState = .normal
            errorToast = nil
            if appLockManager.isBiometricEnabled {
                triggerBiometrics()
            }
        }
        .sheet(isPresented: $showForgotSheet) {
            recoverySheetView
        }
    }
    
    private func showErrorToast(_ text: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            errorToast = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                if errorToast == text {
                    errorToast = nil
                }
            }
        }
    }
    
    private var recoverySheetView: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Text("Khôi phục mật khẩu")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("Đóng") { showForgotSheet = false }
                        .foregroundColor(AppColors.cyan)
                }
                .padding(.top, 24)
                
                Text("Trả lời câu hỏi bảo mật để mở khóa ngay:")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(appLockManager.securityQuestion)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                        
                        Rectangle().fill(AppColors.cardBorder).frame(height: 1)
                        
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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(AppColors.cyan))
                }
                
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
        } else {
            recoveryError = "Câu trả lời bảo mật không chính xác!"
            HapticManager.shared.notification(.error)
        }
    }
    
    private func verifyPinCode(_ pin: String) {
        if appLockManager.verifyPIN(pin) {
            errorToast = nil
            enteredPin = ""
            appLockManager.handleSuccessfulUnlock()
        } else {
            withAnimation(.default) {
                shakeAttempts += 1
            }
            enteredPin = ""
            let target = appLockManager.currentLockedAppTarget ?? "AppLock"
            appLockManager.handleFailedAttempt(targetApp: target)
            showErrorToast("Mã PIN không chính xác (\(appLockManager.failedAttemptsCount) lần sai)")
        }
    }
    
    private func verifyPatternCode(_ pattern: [Int]) {
        if appLockManager.verifyPattern(pattern) {
            patternState = .success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                appLockManager.handleSuccessfulUnlock()
                selectedPattern = []
                patternState = .normal
            }
        } else {
            patternState = .error
            let target = appLockManager.currentLockedAppTarget ?? "AppLock"
            appLockManager.handleFailedAttempt(targetApp: target)
            showErrorToast("Hình vẽ không chính xác (\(appLockManager.failedAttemptsCount) lần sai)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                selectedPattern = []
                patternState = .normal
            }
        }
    }
    
    private func triggerBiometrics() {
        let targetText = appLockManager.currentLockedAppTarget.map { "Đang khóa: \($0)" } ?? "Xác thực để mở khóa AppLock"
        Task {
            let result = await BiometricManager.shared.authenticate(reason: targetText)
            if case .success(true) = result {
                await MainActor.run {
                    appLockManager.handleSuccessfulUnlock()
                }
            }
        }
    }
}
