import SwiftUI

public struct PinPadView: View {
    @Binding var enteredPin: String
    var maxDigits: Int = 6
    var onComplete: (String) -> Void
    var onBiometricTap: (() -> Void)? = nil
    var showBiometricButton: Bool = false
    var shakeAttempts: CGFloat = 0
    
    public init(
        enteredPin: Binding<String>,
        maxDigits: Int = 6,
        shakeAttempts: CGFloat = 0,
        showBiometricButton: Bool = false,
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
        VStack(spacing: 32) {
            // 6 PIN Dots matching video (00:03 - 00:07 & 00:34)
            HStack(spacing: 14) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    let filled = index < enteredPin.count
                    Circle()
                        .fill(filled ? AppColors.cyan : Color(hex: "E2E8F0"))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut(duration: 0.12), value: filled)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAttempts))
            
            // 3x4 Circular Keypad Grid matching video
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 22) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = "\(row * 3 + col)"
                            keypadButton(digit: digit)
                        }
                    }
                }
                
                // Bottom Row: Biometric (or empty), 0, Backspace
                HStack(spacing: 22) {
                    if showBiometricButton, let onBiometricTap = onBiometricTap {
                        Button(action: onBiometricTap) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.keypadNormal)
                                    .frame(width: 72, height: 72)
                                Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
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
                                .fill(Color.clear)
                                .frame(width: 72, height: 72)
                            Image(systemName: "delete.left")
                                .font(.system(size: 22, weight: .medium))
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
            Text(digit)
                .font(.system(size: 28, weight: .regular))
                .frame(width: 72, height: 72)
        }
        .buttonStyle(LightKeypadButtonStyle())
    }
    
    private func appendDigit(_ digit: String) {
        guard enteredPin.count < maxDigits else { return }
        if AppLockManager.shared.isVibrationEnabled {
            HapticManager.shared.impact(.light)
        }
        enteredPin.append(digit)
        
        if enteredPin.count == maxDigits {
            let submitted = enteredPin
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
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

struct LightKeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? .white : AppColors.textPrimary)
            .background(
                Circle()
                    .fill(configuration.isPressed ? AppColors.keypadPressed : AppColors.keypadNormal)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
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
