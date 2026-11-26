import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppLockManager: ObservableObject {
    public static let shared = AppLockManager()
    
    private enum Keys {
        static let isFirstLaunch = "applock_is_first_launch"
        static let lockType = "applock_lock_type"
        static let pin = "applock_pin"
        static let pattern = "applock_pattern"
        static let isBiometricEnabled = "applock_biometric_enabled"
        static let isIntruderEnabled = "applock_intruder_enabled"
        static let intruderThreshold = "applock_intruder_threshold"
        static let securityQuestion = "applock_security_question"
        static let securityAnswer = "applock_security_answer"
        static let relockPolicy = "applock_relock_policy"
        static let isVibrationEnabled = "applock_vibration_enabled"
        static let intruderRecords = "applock_intruder_records"
        static let vaultItems = "applock_vault_items"
        static let secretNotes = "applock_secret_notes"
    }
    
    @Published public var isFirstLaunch: Bool
    @Published public var lockType: LockType
    @Published public var pin: String
    @Published public var pattern: [Int]
    @Published public var isBiometricEnabled: Bool
    @Published public var isIntruderSelfieEnabled: Bool
    @Published public var intruderThreshold: Int
    @Published public var securityQuestion: String
    @Published public var securityAnswer: String
    @Published public var relockPolicy: RelockPolicy
    @Published public var isVibrationEnabled: Bool
    
    @Published public var intruderRecords: [IntruderRecord]
    @Published public var vaultItems: [VaultItem]
    @Published public var secretNotes: [SecretNote]
    
    // Session State
    @Published public var isAppUnlocked: Bool = false
    @Published public var isShowingLockOverlay: Bool = true
    @Published public var failedAttemptsCount: Int = 0
    @Published public var lastBackgroundDate: Date? = nil
    @Published public var toastMessage: String? = nil
    @Published public var modalDismissToken: Int = 0
    @Published public var needsScreenTimeSetupAfterPin: Bool = false
    
    private var didEnterBackground: Bool = false
    private var toastWorkItem: DispatchWorkItem? = nil
    
    private init() {
        let defaults = UserDefaults.standard
        
        self.isFirstLaunch = defaults.object(forKey: Keys.isFirstLaunch) == nil ? true : defaults.bool(forKey: Keys.isFirstLaunch)
        
        let savedLockType = defaults.string(forKey: Keys.lockType) ?? LockType.pin.rawValue
        self.lockType = LockType(rawValue: savedLockType) ?? .pin
        
        // 6-digit passcode default matching video
        let savedPin = defaults.string(forKey: Keys.pin) ?? "111111"
        self.pin = savedPin.count == 6 ? savedPin : "111111"
        self.pattern = defaults.array(forKey: Keys.pattern) as? [Int] ?? [0, 1, 2, 4, 6]
        self.isBiometricEnabled = defaults.object(forKey: Keys.isBiometricEnabled) == nil ? true : defaults.bool(forKey: Keys.isBiometricEnabled)
        self.isIntruderSelfieEnabled = defaults.object(forKey: Keys.isIntruderEnabled) == nil ? true : defaults.bool(forKey: Keys.isIntruderEnabled)
        self.intruderThreshold = defaults.object(forKey: Keys.intruderThreshold) == nil ? 2 : defaults.integer(forKey: Keys.intruderThreshold)
        self.securityQuestion = defaults.string(forKey: Keys.securityQuestion) ?? "Tên thú cưng đầu tiên của bạn?"
        self.securityAnswer = defaults.string(forKey: Keys.securityAnswer) ?? "Miu"
        
        let savedPolicy = defaults.string(forKey: Keys.relockPolicy) ?? RelockPolicy.immediately.rawValue
        self.relockPolicy = RelockPolicy(rawValue: savedPolicy) ?? .immediately
        self.isVibrationEnabled = defaults.object(forKey: Keys.isVibrationEnabled) == nil ? true : defaults.bool(forKey: Keys.isVibrationEnabled)
        
        if let data = defaults.data(forKey: Keys.intruderRecords),
           let savedLogs = try? JSONDecoder().decode([IntruderRecord].self, from: data) {
            self.intruderRecords = savedLogs
        } else {
            self.intruderRecords = []
        }
        
        if let data = defaults.data(forKey: Keys.vaultItems),
           let savedItems = try? JSONDecoder().decode([VaultItem].self, from: data) {
            self.vaultItems = savedItems
        } else {
            self.vaultItems = []
        }
        
        if let data = defaults.data(forKey: Keys.secretNotes),
           let savedNotes = try? JSONDecoder().decode([SecretNote].self, from: data) {
            self.secretNotes = savedNotes
        } else {
            self.secretNotes = []
        }
        
        // On first launch, let user see the Home Modes screen with yellow highlight prompt (matching 00:01 in video!)
        // Once passcode is configured (isFirstLaunch == false), always require unlock at launch.
        self.isShowingLockOverlay = !self.isFirstLaunch
        self.isAppUnlocked = self.isFirstLaunch
    }
    
    public func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch)
        defaults.set(lockType.rawValue, forKey: Keys.lockType)
        defaults.set(pin, forKey: Keys.pin)
        defaults.set(pattern, forKey: Keys.pattern)
        defaults.set(isBiometricEnabled, forKey: Keys.isBiometricEnabled)
        defaults.set(isIntruderSelfieEnabled, forKey: Keys.isIntruderEnabled)
        defaults.set(intruderThreshold, forKey: Keys.intruderThreshold)
        defaults.set(securityQuestion, forKey: Keys.securityQuestion)
        defaults.set(securityAnswer, forKey: Keys.securityAnswer)
        defaults.set(relockPolicy.rawValue, forKey: Keys.relockPolicy)
        defaults.set(isVibrationEnabled, forKey: Keys.isVibrationEnabled)
        
        if let data = try? JSONEncoder().encode(intruderRecords) {
            defaults.set(data, forKey: Keys.intruderRecords)
        }
        if let data = try? JSONEncoder().encode(vaultItems) {
            defaults.set(data, forKey: Keys.vaultItems)
        }
        if let data = try? JSONEncoder().encode(secretNotes) {
            defaults.set(data, forKey: Keys.secretNotes)
        }
    }
    
    public func showToast(_ message: String) {
        toastWorkItem?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.toastMessage = message
        }
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.toastMessage = nil
                }
            }
        }
        toastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: item)
    }
    
    // MARK: - Verification
    
    public func verifyPIN(_ enteredPIN: String) -> Bool {
        return enteredPIN == self.pin
    }
    
    public func verifyPattern(_ enteredPattern: [Int]) -> Bool {
        return enteredPattern == self.pattern
    }
    
    public func verifySecurityAnswer(_ answer: String) -> Bool {
        let cleaned1 = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleaned2 = securityAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return cleaned1 == cleaned2
    }
    
    public func handleSuccessfulUnlock() {
        self.failedAttemptsCount = 0
        self.isAppUnlocked = true
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            self.isShowingLockOverlay = false
        }
        if isVibrationEnabled {
            HapticManager.shared.notification(.success)
        }
        
        // Lift Screen Time shields temporarily when unlocked!
        ScreenTimeManager.shared.temporarilyUnlockShields()
    }
    
    public func handleFailedAttempt() {
        self.failedAttemptsCount += 1
        if isVibrationEnabled {
            HapticManager.shared.notification(.error)
        }
        
        if isIntruderSelfieEnabled && self.failedAttemptsCount >= self.intruderThreshold {
            CameraManager.shared.captureIntruderPhoto(targetAppName: "Khoá App") { [weak self] result in
                guard let self = self else { return }
                if case .success(let fileName) = result {
                    let record = IntruderRecord(
                        targetAppName: "Khoá App",
                        imageFileName: fileName,
                        attemptCount: self.failedAttemptsCount
                    )
                    self.intruderRecords.insert(record, at: 0)
                    self.saveSettings()
                }
            }
        }
    }
    
    // MARK: - Scene Phase Lifecycle
    
    public func appMovedToBackground() {
        didEnterBackground = true
        lastBackgroundDate = Date()
        
        guard !isFirstLaunch else { return }
        
        if relockPolicy == .immediately {
            isAppUnlocked = false
            modalDismissToken += 1
            isShowingLockOverlay = true
        }
    }
    
    public func appBecameActive() {
        guard !isFirstLaunch else { return }
        
        // Check if user tapped "Mở khóa" on a Shield notification
        if ScreenTimeManager.shared.checkPendingShieldUnlock() {
            isAppUnlocked = false
            modalDismissToken += 1
            isShowingLockOverlay = true
            didEnterBackground = false
            return
        }
        
        guard didEnterBackground else { return }
        didEnterBackground = false
        
        switch relockPolicy {
        case .immediately, .screenOff:
            isAppUnlocked = false
            modalDismissToken += 1
            isShowingLockOverlay = true
        case .oneMinute:
            if let lastBg = lastBackgroundDate, Date().timeIntervalSince(lastBg) > 60 {
                isAppUnlocked = false
                modalDismissToken += 1
                isShowingLockOverlay = true
            }
        }
    }
    
    public func triggerUnlockFromNotification() {
        guard !isFirstLaunch else { return }
        isAppUnlocked = false
        modalDismissToken += 1
        isShowingLockOverlay = true
    }
    
    // MARK: - Vault & Notes & Intruder Logs
    
    public func addVaultItem(_ item: VaultItem) {
        vaultItems.insert(item, at: 0)
        saveSettings()
    }
    
    public func deleteVaultItem(_ item: VaultItem) {
        vaultItems.removeAll { $0.id == item.id }
        VaultManager.shared.deleteVaultFile(fileName: item.fileName, type: item.fileType)
        saveSettings()
    }
    
    public func saveSecretNote(_ note: SecretNote) {
        if let index = secretNotes.firstIndex(where: { $0.id == note.id }) {
            secretNotes[index] = note
        } else {
            secretNotes.insert(note, at: 0)
        }
        saveSettings()
    }
    
    public func deleteSecretNote(id: String) {
        secretNotes.removeAll { $0.id == id }
        saveSettings()
    }
    
    public func clearIntruderLogs() {
        for record in intruderRecords {
            VaultManager.shared.deleteIntruderFile(fileName: record.imageFileName)
        }
        intruderRecords.removeAll()
        saveSettings()
    }
    
    public func deleteIntruderRecord(id: String) {
        if let record = intruderRecords.first(where: { $0.id == id }) {
            VaultManager.shared.deleteIntruderFile(fileName: record.imageFileName)
        }
        intruderRecords.removeAll { $0.id == id }
        saveSettings()
    }
}
