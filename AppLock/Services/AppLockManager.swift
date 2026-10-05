import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppLockManager: ObservableObject {
    public static let shared = AppLockManager()
    
    // Keys for UserDefaults
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
        static let lockedApps = "applock_locked_apps"
        static let intruderRecords = "applock_intruder_records"
        static let vaultItems = "applock_vault_items"
        static let secretNotes = "applock_secret_notes"
    }
    
    // Published Properties
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
    
    @Published public var apps: [AppItem]
    @Published public var intruderRecords: [IntruderRecord]
    @Published public var vaultItems: [VaultItem]
    @Published public var secretNotes: [SecretNote]
    
    // Session State
    @Published public var isAppUnlocked: Bool = false
    @Published public var isShowingLockOverlay: Bool = true
    @Published public var currentLockedAppTarget: String? = nil
    @Published public var failedAttemptsCount: Int = 0
    @Published public var lastBackgroundDate: Date? = nil
    
    private init() {
        let defaults = UserDefaults.standard
        
        self.isFirstLaunch = defaults.object(forKey: Keys.isFirstLaunch) == nil ? true : defaults.bool(forKey: Keys.isFirstLaunch)
        
        let savedLockType = defaults.string(forKey: Keys.lockType) ?? LockType.pin.rawValue
        self.lockType = LockType(rawValue: savedLockType) ?? .pin
        
        self.pin = defaults.string(forKey: Keys.pin) ?? "1234"
        self.pattern = defaults.array(forKey: Keys.pattern) as? [Int] ?? [0, 1, 2, 4, 6]
        self.isBiometricEnabled = defaults.object(forKey: Keys.isBiometricEnabled) == nil ? true : defaults.bool(forKey: Keys.isBiometricEnabled)
        self.isIntruderSelfieEnabled = defaults.object(forKey: Keys.isIntruderEnabled) == nil ? true : defaults.bool(forKey: Keys.isIntruderEnabled)
        self.intruderThreshold = defaults.object(forKey: Keys.intruderThreshold) == nil ? 2 : defaults.integer(forKey: Keys.intruderThreshold)
        self.securityQuestion = defaults.string(forKey: Keys.securityQuestion) ?? "Tên thú cưng đầu tiên của bạn là gì?"
        self.securityAnswer = defaults.string(forKey: Keys.securityAnswer) ?? "Miu"
        
        let savedPolicy = defaults.string(forKey: Keys.relockPolicy) ?? RelockPolicy.screenOff.rawValue
        self.relockPolicy = RelockPolicy(rawValue: savedPolicy) ?? .screenOff
        self.isVibrationEnabled = defaults.object(forKey: Keys.isVibrationEnabled) == nil ? true : defaults.bool(forKey: Keys.isVibrationEnabled)
        
        // Load apps
        if let data = defaults.data(forKey: Keys.lockedApps),
           let savedApps = try? JSONDecoder().decode([AppItem].self, from: data) {
            self.apps = savedApps
        } else {
            self.apps = AppItem.defaultApps
        }
        
        // Load intruder records
        if let data = defaults.data(forKey: Keys.intruderRecords),
           let savedLogs = try? JSONDecoder().decode([IntruderRecord].self, from: data) {
            self.intruderRecords = savedLogs
        } else {
            self.intruderRecords = []
        }
        
        // Load vault items
        if let data = defaults.data(forKey: Keys.vaultItems),
           let savedItems = try? JSONDecoder().decode([VaultItem].self, from: data) {
            self.vaultItems = savedItems
        } else {
            self.vaultItems = []
        }
        
        // Load secret notes
        if let data = defaults.data(forKey: Keys.secretNotes),
           let savedNotes = try? JSONDecoder().decode([SecretNote].self, from: data) {
            self.secretNotes = savedNotes
        } else {
            self.secretNotes = [
                SecretNote(
                    title: "Mã PIN thẻ ATM / Ngân hàng",
                    content: "VCB Visa: 9812\nTechcombank Debit: 4321\nMã OTP SmartOTP: 889900",
                    updatedAt: Date(),
                    isPinned: true
                ),
                SecretNote(
                    title: "Mật khẩu mạng Wi-Fi riêng",
                    content: "Office 5G: SecuRe#2026@Pass\nHome Studio: VIPGuest2026",
                    updatedAt: Date().addingTimeInterval(-3600),
                    isPinned: false
                )
            ]
        }
        
        // If first launch, show lock overlay or setup
        self.isShowingLockOverlay = !isFirstLaunch
    }
    
    // Save state helper
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
        
        if let data = try? JSONEncoder().encode(apps) {
            defaults.set(data, forKey: Keys.lockedApps)
        }
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
    
    // Verification methods
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
        withAnimation(.spring()) {
            self.isShowingLockOverlay = false
            self.currentLockedAppTarget = nil
        }
        if isVibrationEnabled {
            HapticManager.shared.notification(.success)
        }
    }
    
    public func handleFailedAttempt(targetApp: String = "AppLock") {
        self.failedAttemptsCount += 1
        if isVibrationEnabled {
            HapticManager.shared.notification(.error)
        }
        
        // Check if Intruder selfie threshold is reached
        if isIntruderSelfieEnabled && self.failedAttemptsCount >= self.intruderThreshold {
            CameraManager.shared.captureIntruderPhoto(targetAppName: targetApp) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let fileName):
                    let record = IntruderRecord(
                        targetAppName: targetApp,
                        imageFileName: fileName,
                        attemptCount: self.failedAttemptsCount
                    )
                    self.intruderRecords.insert(record, at: 0)
                    self.saveSettings()
                case .failure(let error):
                    print("Failed capturing intruder: \(error)")
                }
            }
        }
    }
    
    // App locking actions
    public func toggleAppLock(id: String) {
        if let index = apps.firstIndex(where: { $0.id == id }) {
            apps[index].isLocked.toggle()
            saveSettings()
            if isVibrationEnabled {
                HapticManager.shared.selection()
            }
        }
    }
    
    public func lockAllRecommended() {
        for index in apps.indices {
            if apps[index].isRecommended {
                apps[index].isLocked = true
            }
        }
        saveSettings()
        if isVibrationEnabled {
            HapticManager.shared.notification(.success)
        }
    }
    
    public func unlockAll() {
        for index in apps.indices {
            apps[index].isLocked = false
        }
        saveSettings()
        if isVibrationEnabled {
            HapticManager.shared.notification(.warning)
        }
    }
    
    // Scene phase handling (when app goes to background or becomes active)
    public func appMovedToBackground() {
        lastBackgroundDate = Date()
        if relockPolicy == .immediately {
            isAppUnlocked = false
            isShowingLockOverlay = true
        }
    }
    
    public func appBecameActive() {
        guard !isFirstLaunch else { return }
        
        if relockPolicy == .screenOff {
            // Relock if device was locked or app was in background
            if !isAppUnlocked {
                isShowingLockOverlay = true
            }
        } else if relockPolicy == .oneMinute {
            if let lastBg = lastBackgroundDate, Date().timeIntervalSince(lastBg) > 60 {
                isAppUnlocked = false
                isShowingLockOverlay = true
            }
        }
    }
    
    // Vault Actions
    public func addVaultItem(_ item: VaultItem) {
        vaultItems.insert(item, at: 0)
        saveSettings()
    }
    
    public func deleteVaultItem(_ item: VaultItem) {
        vaultItems.removeAll { $0.id == item.id }
        VaultManager.shared.deleteVaultFile(fileName: item.fileName, type: item.fileType)
        saveSettings()
    }
    
    // Note Actions
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
    
    // Intruder Logs Actions
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
