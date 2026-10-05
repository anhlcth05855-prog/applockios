import SwiftUI

public struct PinPadView: View {
    @Binding var enteredPin: String
    var maxDigits: Int = 4
    var onComplete: (String) -> Void
    var onBiometricTap: (() -> Void)? = nil
    var showBiometricButton: Bool = true
    
    // Shake animation state
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
        VStack(spacing: 28) {
            // Pin dots indicator
            HStack(spacing: 20) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    ZStack {
                        Circle()
                            .stroke(
                                index < enteredPin.count ? AppColors.cyan : AppColors.cardBorder,
                                lineWidth: 2
                            )
                            .frame(width: 18, height: 18)
                        
                        if index < enteredPin.count {
                            Circle()
                                .fill(AppColors.cyan)
                                .frame(width: 12, height: 12)
                                .shadow(color: AppColors.cyan.opacity(0.8), radius: 6)
                                .transition(.scale)
                        }
                    }
                }
            }
            .modifier(ShakeEffect(animatableData: shakeAttempts))
            .padding(.vertical, 8)
            
            // Numeric Keypad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = "\(row * 3 + col)"
                            keypadButton(digit: digit)
                        }
                    }
                }
                
                // Bottom row: Biometric, 0, Backspace
                HStack(spacing: 24) {
                    // Biometric button or empty
                    if showBiometricButton, let onBiometricTap = onBiometricTap {
                        Button(action: onBiometricTap) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.cardBackground.opacity(0.6))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                                
                                Image(systemName: BiometricManager.shared.getAvailableBiometricType().iconName)
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(AppColors.cyan)
                            }
                        }
                    } else {
                        Spacer()
                            .frame(width: 72, height: 72)
                    }
                    
                    keypadButton(digit: "0")
                    
                    // Backspace button
                    Button(action: backspace) {
                        ZStack {
                            Circle()
                                .fill(AppColors.cardBackground.opacity(0.6))
                                .frame(width: 72, height: 72)
                                .overlay(
                                    Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
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
                    .fill(AppColors.cardBackground)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text(digit)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .buttonStyle(KeypadPressStyle())
    }
    
    private func appendDigit(_ digit: String) {
        guard enteredPin.count < maxDigits else { return }
        HapticManager.shared.impact(.light)
        enteredPin.append(digit)
        
        if enteredPin.count == maxDigits {
            onComplete(enteredPin)
        }
    }
    
    private func backspace() {
        guard !enteredPin.isEmpty else { return }
        HapticManager.shared.impact(.light)
        enteredPin.removeLast()
    }
}

// Button press animation style
struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Shake Effect Modifier
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
