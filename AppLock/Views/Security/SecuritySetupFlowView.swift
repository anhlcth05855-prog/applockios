import SwiftUI

/// Single-page Passcode & Pattern Setup matching 00:20 - 00:36 in the reference video
public struct SecuritySetupFlowView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    var isChangingPasscode: Bool = false
    var onFinish: () -> Void
    
    private let securityQuestions = [
        "Tên thú cưng đầu tiên của bạn?",
        "Tên trường tiểu học đầu tiên của bạn?",
        "Thành phố nơi mẹ bạn sinh ra?",
        "Bộ phim yêu thích nhất của bạn?",
        "Món ăn yêu thích nhất của bạn?"
    ]
    
    @State private var selectedLockType: LockType = .pin
    @State private var pin1: String = ""
    @State private var pin2: String = ""
    @State private var patternIndices: [Int] = []
    @State private var recordedPattern: [Int] = []
    @State private var patternState: PatternState = .normal
    @State private var selectedQuestion: String = "Tên thú cưng đầu tiên của bạn?"
    @State private var answerInput: String = ""
    @State private var localToast: String? = nil
    
    public init(isChangingPasscode: Bool = false, onFinish: @escaping () -> Void) {
        self.isChangingPasscode = isChangingPasscode
        self.onFinish = onFinish
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isChangingPasscode {
                    HStack {
                        Spacer()
                        Button("Đóng") {
                            onFinish()
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.cyan)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top Shield Icon (64x64)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundColor(AppColors.cyan)
                            .padding(.top, isChangingPasscode ? 8 : 28)
                        
                        Text("Thiết Lập Mật Khẩu Khóa")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, 14)
                        
                        Text("Chọn phương thức bảo mật chính cho AppLock")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 6)
                        
                        // Segmented PIN vs Pattern Selector (matching 00:20 & 00:28)
                        HStack(spacing: 0) {
                            Button(action: {
                                selectedLockType = .pin
                                HapticManager.shared.selection()
                            }) {
                                Text("Mã PIN 4 số")
                                    .font(.system(size: 14, weight: selectedLockType == .pin ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        Capsule().fill(selectedLockType == .pin ? AppColors.cyan : Color.clear)
                                    )
                                    .foregroundColor(selectedLockType == .pin ? AppColors.background : AppColors.textSecondary)
                            }
                            
                            Button(action: {
                                selectedLockType = .pattern
                                HapticManager.shared.selection()
                            }) {
                                Text("Hình vẽ mẫu")
                                    .font(.system(size: 14, weight: selectedLockType == .pattern ? .bold : .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 40)
                                    .background(
                                        Capsule().fill(selectedLockType == .pattern ? AppColors.cyan : Color.clear)
                                    )
                                    .foregroundColor(selectedLockType == .pattern ? AppColors.background : AppColors.textSecondary)
                            }
                        }
                        .padding(4)
                        .background(
                            Capsule()
                                .fill(AppColors.cardBackground)
                                .overlay(Capsule().stroke(AppColors.cardBorder, lineWidth: 1))
                        )
                        .padding(.top, 24)
                        
                        // PIN or Pattern Input Area
                        if selectedLockType == .pin {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Nhập mã PIN gồm 4 chữ số:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.cyan)
                                    .padding(.top, 20)
                                
                                SecureField("• • • •", text: $pin1)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppColors.inputBackground)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                                    )
                                    .onChange(of: pin1) { val in
                                        let filtered = val.filter { $0.isNumber }
                                        pin1 = String(filtered.prefix(4))
                                    }
                                
                                Text("Xác nhận lại mã PIN 4 chữ số:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.cyan)
                                    .padding(.top, 8)
                                
                                SecureField("• • • •", text: $pin2)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppColors.inputBackground)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                                    )
                                    .onChange(of: pin2) { val in
                                        let filtered = val.filter { $0.isNumber }
                                        pin2 = String(filtered.prefix(4))
                                    }
                            }
                        } else {
                            VStack(spacing: 12) {
                                Text("Vẽ hình mẫu của bạn (nối ít nhất 4 điểm):")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.cyan)
                                    .padding(.top, 20)
                                
                                PatternLockView(
                                    selectedIndices: $patternIndices,
                                    state: patternState,
                                    onComplete: { drawn in
                                        if drawn.count >= 4 {
                                            recordedPattern = drawn
                                            patternState = .success
                                            showLocalToast("Đã ghi nhận hình vẽ mẫu!")
                                        } else {
                                            patternState = .error
                                            showLocalToast("Vui lòng nối ít nhất 4 điểm!")
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                patternIndices = []
                                                patternState = .normal
                                            }
                                        }
                                    }
                                )
                            }
                        }
                        
                        // Security Question Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Câu hỏi bảo mật (Dùng khi quên mật khẩu):")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.top, 26)
                            
                            Menu {
                                ForEach(securityQuestions, id: \.self) { q in
                                    Button(q) { selectedQuestion = q }
                                }
                            } label: {
                                HStack {
                                    Text(selectedQuestion)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "arrowtriangle.down.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.inputBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                                )
                            }
                            
                            TextField("Nhập câu trả lời của bạn...", text: $answerInput)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColors.inputBackground)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.cardBorder, lineWidth: 1))
                                )
                        }
                        
                        // Confirm & Save Button matching video (00:36)
                        Button(action: saveSetup) {
                            Text("Xác Nhận & Lưu Thiết Lập")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppColors.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    Capsule()
                                        .fill(AppColors.cyan)
                                )
                        }
                        .padding(.top, 28)
                        .padding(.bottom, 36)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            if let toast = localToast {
                ToastBannerView(message: toast)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            selectedLockType = appLockManager.lockType
            if isChangingPasscode {
                answerInput = appLockManager.securityAnswer
                if securityQuestions.contains(appLockManager.securityQuestion) {
                    selectedQuestion = appLockManager.securityQuestion
                }
            }
        }
    }
    
    private func showLocalToast(_ msg: String) {
        withAnimation { localToast = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { localToast = nil }
        }
    }
    
    private func saveSetup() {
        let trimmedAnswer = answerInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAnswer.isEmpty else {
            HapticManager.shared.notification(.error)
            showLocalToast("Vui lòng nhập câu trả lời bảo mật!")
            return
        }
        
        if selectedLockType == .pin {
            guard pin1.count == 4 else {
                HapticManager.shared.notification(.error)
                showLocalToast("Mã PIN phải đủ 4 chữ số!")
                return
            }
            guard pin1 == pin2 else {
                HapticManager.shared.notification(.error)
                showLocalToast("Hai mã PIN không trùng khớp!")
                return
            }
            appLockManager.lockType = .pin
            appLockManager.pin = pin1
        } else {
            guard recordedPattern.count >= 4 else {
                HapticManager.shared.notification(.error)
                showLocalToast("Vui lòng vẽ hình mẫu khóa (ít nhất 4 điểm)!")
                return
            }
            appLockManager.lockType = .pattern
            appLockManager.pattern = recordedPattern
        }
        
        appLockManager.securityQuestion = selectedQuestion
        appLockManager.securityAnswer = trimmedAnswer
        appLockManager.isFirstLaunch = false
        appLockManager.isAppUnlocked = true
        appLockManager.saveSettings()
        
        HapticManager.shared.notification(.success)
        appLockManager.showToast("Thiết lập bảo mật thành công!")
        onFinish()
    }
}
