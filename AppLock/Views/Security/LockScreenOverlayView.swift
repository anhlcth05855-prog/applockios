import SwiftUI

/// Unlock screen matching 00:34 in the reference video ("Mở khóa bằng mã")
public struct LockScreenOverlayView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    @State private var enteredPin: String = ""
    @State private var shakeAttempts: CGFloat = 0
    @State private var errorMessage: String? = nil
    @State private var showForgotSheet: Bool = false
    @State private var recoveryAnswerInput: String = ""
    @State private var recoveryError: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        showForgotSheet = true
                    }) {
                        Text("Quên mật khẩu?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
                
                Spacer().frame(height: 28)
                
                // App / Shield icon matching 00:34
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "4F6DF5"), Color(hex: "8B5CF6")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: AppColors.cyan.opacity(0.25), radius: 8, y: 4)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Mở khóa bằng mã")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.top, 16)
                
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.coral)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                PinPadView(
                    enteredPin: $enteredPin,
                    maxDigits: 6,
                    shakeAttempts: shakeAttempts,
                    showBiometricButton: appLockManager.isBiometricEnabled,
                    onBiometricTap: triggerBiometrics,
                    onComplete: verifyPinCode
                )
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.emerald)
                    Text("Bảo vệ bởi Thời gian sử dụng iOS")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.bottom, 22)
            }
        }
        .onAppear {
            enteredPin = ""
            errorMessage = nil
            if appLockManager.isBiometricEnabled {
                triggerBiometrics()
            }
        }
        .sheet(isPresented: $showForgotSheet) {
            recoverySheetView
        }
    }
    
    private var recoverySheetView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Trả lời câu hỏi bảo mật để đặt lại quyền truy cập:")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(appLockManager.securityQuestion)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    
                    TextField("Nhập câu trả lời của bạn...", text: $recoveryAnswerInput)
                        .padding(12)
                        .background(AppColors.inputBackground)
                        .cornerRadius(10)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColors.cardBorder, lineWidth: 1))
                )
                
                if let err = recoveryError {
                    Text(err)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.coral)
                }
                
                Button(action: verifyRecoveryAnswer) {
                    Text("Xác thực & Mở khóa")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Capsule().fill(AppColors.cyan))
                }
                
                Spacer()
            }
            .padding(20)
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Khôi phục mật khẩu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { showForgotSheet = false }
                }
            }
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
    
    private func verifyPinCode(_ code: String) {
        if appLockManager.verifyPIN(code) {
            errorMessage = nil
            enteredPin = ""
            appLockManager.handleSuccessfulUnlock()
        } else {
            withAnimation(.default) {
                shakeAttempts += 1
            }
            enteredPin = ""
            appLockManager.handleFailedAttempt()
            errorMessage = "Mã PIN không chính xác (\(appLockManager.failedAttemptsCount) lần sai)"
        }
    }
    
    private func triggerBiometrics() {
        Task {
            let result = await BiometricManager.shared.authenticate(reason: "Mở khóa ứng dụng bảo vệ")
            if case .success(true) = result {
                await MainActor.run {
                    appLockManager.handleSuccessfulUnlock()
                }
            }
        }
    }
}
