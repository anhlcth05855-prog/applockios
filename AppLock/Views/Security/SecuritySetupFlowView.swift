import SwiftUI

/// 6-digit PIN setup + Screen Time authorization flow matching 00:03 - 00:20 in the video
public struct SecuritySetupFlowView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    
    var isChangingPasscode: Bool = false
    var onFinish: () -> Void
    
    enum Step {
        case enterPin
        case confirmPin
        case screenTimePermission
    }
    
    @State private var currentStep: Step = .enterPin
    @State private var firstPin: String = ""
    @State private var confirmPin: String = ""
    @State private var errorMessage: String? = nil
    @State private var shakeAttempts: CGFloat = 0
    
    public init(isChangingPasscode: Bool = false, onFinish: @escaping () -> Void) {
        self.isChangingPasscode = isChangingPasscode
        self.onFinish = onFinish
    }
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if currentStep == .screenTimePermission {
                ScreenTimePermissionView {
                    onFinish()
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            if currentStep == .confirmPin {
                                currentStep = .enterPin
                                confirmPin = ""
                                firstPin = ""
                                errorMessage = nil
                            } else {
                                onFinish()
                            }
                        }) {
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
                    
                    Spacer().frame(height: 24)
                    
                    // Blue Lock Icon matching 00:03
                    Image(systemName: "lock.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    
                    Text(currentStep == .enterPin ? "Thiết lập mật khẩu" : "Xác nhận mật khẩu")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.top, 16)
                    
                    Text("Mật khẩu này bảo vệ các ứng dụng riêng tư của bạn\nvà cũng dùng để mở khóa \"Khoá App\".")
                        .font(.system(size: 13.5))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 8)
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.coral)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    if currentStep == .enterPin {
                        PinPadView(
                            enteredPin: $firstPin,
                            maxDigits: 6,
                            shakeAttempts: shakeAttempts,
                            showBiometricButton: false
                        ) { code in
                            firstPin = code
                            errorMessage = nil
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentStep = .confirmPin
                            }
                        }
                    } else {
                        PinPadView(
                            enteredPin: $confirmPin,
                            maxDigits: 6,
                            shakeAttempts: shakeAttempts,
                            showBiometricButton: false
                        ) { code in
                            if code == firstPin {
                                savePasscode(code)
                            } else {
                                withAnimation(.default) { shakeAttempts += 1 }
                                HapticManager.shared.notification(.error)
                                errorMessage = "Mật khẩu xác nhận không khớp, hãy nhập lại!"
                                confirmPin = ""
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom local storage badge matching 00:03
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.emerald)
                        Text("Mật khẩu chỉ lưu trên thiết bị của bạn")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.bottom, 22)
                }
            }
        }
    }
    
    private func savePasscode(_ code: String) {
        appLockManager.lockType = .pin
        appLockManager.pin = code
        appLockManager.isFirstLaunch = false
        appLockManager.isAppUnlocked = true
        appLockManager.saveSettings()
        HapticManager.shared.notification(.success)
        
        if !isChangingPasscode && !screenTimeManager.isAuthorized {
            currentStep = .screenTimePermission
        } else {
            appLockManager.showToast("Đã lưu mật khẩu thành công!")
            onFinish()
        }
    }
}
