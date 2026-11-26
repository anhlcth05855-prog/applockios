import SwiftUI

public struct PinPadView: View {
    @Binding var enteredPin: String
    var maxDigits: Int = 4
    var onComplete: (String) -> Void
    var onBiometricTap: (() -> Void)? = nil
    var showBiometricButton: Bool = true
    var shakeAttempts: CGFloat = 0
    
    public init(
        enteredPin: Binding<String>,
        maxDigits: Int = 4,
        shakeAttempts: CGFloat = 0,
        showBiometricButton: Bool = true,
        onBiometricTap: (() -> Void)? = nil,
        onComplete: @escaping (String) -> Void
    ) {
        self._enteredPin = enteredPin
        self.maxDigits = maxDigits
        self.shakeAttempts = shakeAttempts
        self.showBiometricButton = showBiometricButton
        self.onBiometricTap = onBiometricTap
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            // 4 PIN Dots matching video (00:49 - 00:52)
            HStack(spacing: 18) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    let filled = index < enteredPin.count
                    Circle()
                        .fill(filled ? AppColors.cyan : AppColors.keypadNormal)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(filled ? AppColors.cyan : AppColors.cardBorder, lineWidth: 1.5)
                        )
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAttempts))
            
            // 3x4 Circular Keypad Grid (72x72 buttons in #1D2A48)
            VStack(spacing: 18) {
                ForEach(0..<3) { row in
                    HStack(spacing: 22) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = "\(row * 3 + col)"
                            keypadButton(digit: digit)
                        }
                    }
                }
                
                // Bottom Row: Biometric, 0, Backspace
                HStack(spacing: 22) {
                    if showBiometricButton, let onBiometricTap = onBiometricTap {
                        Button(action: onBiometricTap) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.keypadNormal)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                                
                                Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(AppColors.cyan)
                            }
                        }
                        .buttonStyle(KeypadPressStyle())
                    } else {
                        Spacer().frame(width: 72, height: 72)
                    }
                    
                    keypadButton(digit: "0")
                    
                    Button(action: backspace) {
                        ZStack {
                            Circle()
                                .fill(AppColors.keypadNormal)
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                    }
                    .buttonStyle(KeypadPressStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func keypadButton(digit: String) -> some View {
        Button(action: {
            appendDigit(digit)
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.keypadNormal)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                
                Text(digit)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .buttonStyle(KeypadPressStyle())
    }
    
    private func appendDigit(_ digit: String) {
        guard enteredPin.count < maxDigits else { return }
        if AppLockManager.shared.isVibrationEnabled {
            HapticManager.shared.impact(.light)
        }
        enteredPin.append(digit)
        
        if enteredPin.count == maxDigits {
            let submitted = enteredPin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                onComplete(submitted)
            }
        }
    }
    
    private func backspace() {
        guard !enteredPin.isEmpty else { return }
        if AppLockManager.shared.isVibrationEnabled {
            HapticManager.shared.impact(.light)
        }
        enteredPin.removeLast()
    }
}

struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.12 : 0)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

public struct ShakeEffect: AnimatableModifier {
    public var animatableData: CGFloat
    
    public init(animatableData: CGFloat) {
        self.animatableData = animatableData
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(x: sin(animatableData * .pi * 2) * 10)
    }
}
