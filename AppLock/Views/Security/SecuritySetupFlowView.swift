import SwiftUI

public struct SecuritySetupFlowView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    var isChangingPasscode: Bool = false
    var onFinish: () -> Void
    
    enum Step {
        case selectType
        case enterPasscode
        case confirmPasscode
        case securityQuestion
    }
    
    @State private var currentStep: Step = .selectType
    @State private var selectedLockType: LockType = .pin
    @State private var firstPin: String = ""
    @State private var confirmPin: String = ""
    @State private var firstPattern: [Int] = []
    @State private var confirmPattern: [Int] = []
    @State private var questionInput: String = "Tên thú cưng đầu tiên của bạn là gì?"
    @State private var answerInput: String = ""
    @State private var errorMessage: String? = nil
    @State private var shakeAttempts: CGFloat = 0
    
    public init(isChangingPasscode: Bool = false, onFinish: @escaping () -> Void) {
        self.isChangingPasscode = isChangingPasscode
        self.onFinish = onFinish
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                CyberHeader(
                    title: isChangingPasscode ? "Đổi mật khẩu" : "Thiết lập bảo vệ",
                    subtitle: stepSubtitle,
                    badgeText: stepBadge,
                    badgeColor: AppColors.cyan
                )
                
                if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.coral)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Step Content
                switch currentStep {
                case .selectType:
                    selectTypeView
                case .enterPasscode:
                    enterPasscodeView(isConfirm: false)
                case .confirmPasscode:
                    enterPasscodeView(isConfirm: true)
                case .securityQuestion:
                    securityQuestionView
                }
                
                Spacer()
            }
        }
    }
    
    private var stepBadge: String {
        switch currentStep {
        case .selectType: return "Bước 1/4"
        case .enterPasscode: return "Bước 2/4"
        case .confirmPasscode: return "Bước 3/4"
        case .securityQuestion: return "Bước 4/4"
        }
    }
    
    private var stepSubtitle: String {
        switch currentStep {
        case .selectType: return "Chọn phương thức khóa ưa thích của bạn"
        case .enterPasscode: return "Tạo mật mã bảo vệ mới"
        case .confirmPasscode: return "Nhập lại mật mã để xác nhận"
        case .securityQuestion: return "Cài đặt câu hỏi dự phòng khi quên mật khẩu"
        }
    }
    
    // Step 1: Select Type
    private var selectTypeView: some View {
        VStack(spacing: 16) {
            Button(action: {
                selectedLockType = .pin
                currentStep = .enterPasscode
            }) {
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "number.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.cyan)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mã PIN 4 số")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Bàn phím số quen thuộc, nhanh chóng")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(20)
                }
            }
            
            Button(action: {
                selectedLockType = .pattern
                currentStep = .enterPasscode
            }) {
                GlassCard {
                    HStack(spacing: 16) {
                        Image(systemName: "circle.grid.3x3.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.emerald)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hình vẽ mẫu (Pattern)")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Text("Vẽ nối 9 điểm bảo mật trực quan")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(20)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // Step 2 & 3: Enter / Confirm Passcode
    @ViewBuilder
    private func enterPasscodeView(isConfirm: Bool) -> some View {
        if selectedLockType == .pin {
            PinPadView(
                enteredPin: isConfirm ? $confirmPin : $firstPin,
                shakeAttempts: shakeAttempts,
                showBiometricButton: false,
                onComplete: { pin in
                    if !isConfirm {
                        currentStep = .confirmPasscode
                    } else {
                        if confirmPin == firstPin {
                            errorMessage = nil
                            currentStep = .securityQuestion
                        } else {
                            withAnimation { shakeAttempts += 1 }
                            errorMessage = "Mã PIN xác nhận không khớp. Vui lòng nhập lại!"
                            confirmPin = ""
                            HapticManager.shared.notification(.error)
                        }
                    }
                }
            )
        } else {
            PatternLockView(
                selectedIndices: isConfirm ? $confirmPattern : $firstPattern,
                onComplete: { pattern in
                    if !isConfirm {
                        currentStep = .confirmPasscode
                    } else {
                        if confirmPattern == firstPattern {
                            errorMessage = nil
                            currentStep = .securityQuestion
                        } else {
                            errorMessage = "Hình vẽ không khớp. Vui lòng thử lại!"
                            confirmPattern = []
                            HapticManager.shared.notification(.error)
                        }
                    }
                }
            )
        }
    }
    
    // Step 4: Security Question
    private var securityQuestionView: some View {
        VStack(spacing: 20) {
            GlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Câu hỏi bí mật:")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    
                    TextField("Câu hỏi bảo mật", text: $questionInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(10)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(8)
                    
                    Divider().background(AppColors.cardBorder)
                    
                    Text("Câu trả lời của bạn:")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    
                    TextField("Nhập câu trả lời bí mật...", text: $answerInput)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(10)
                        .background(AppColors.backgroundSecondary)
                        .cornerRadius(8)
                }
                .padding(20)
            }
            .padding(.horizontal, 24)
            
            Button(action: finishSetup) {
                Text("Hoàn tất & Kích hoạt")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CyberButtonStyle(primaryColor: AppColors.emerald))
            .padding(.horizontal, 24)
            .disabled(answerInput.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(answerInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
        }
    }
    
    private func finishSetup() {
        appLockManager.lockType = selectedLockType
        if selectedLockType == .pin {
            appLockManager.pin = firstPin
        } else {
            appLockManager.pattern = firstPattern
        }
        appLockManager.securityQuestion = questionInput
        appLockManager.securityAnswer = answerInput
        appLockManager.isFirstLaunch = false
        appLockManager.saveSettings()
        
        HapticManager.shared.notification(.success)
        onFinish()
    }
}
