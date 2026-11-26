import Foundation
import SwiftUI
import UIKit
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
        static let isAutomationVerified = "applock_automation_verified"
        static let unlockGraceSeconds = "applock_unlock_grace_seconds"
        static let unlockedGraceUntil = "applock_unlocked_grace_until"
        static let pendingExternalTarget = "applock_pending_external_target"
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
    
    // Shortcut & Grace Window Settings
    @Published public var isAutomationVerified: Bool
    @Published public var unlockGraceSeconds: Int
    @Published public var unlockedGraceUntil: Date?
    
    @Published public var apps: [AppItem]
    @Published public var intruderRecords: [IntruderRecord]
    @Published public var vaultItems: [VaultItem]
    @Published public var secretNotes: [SecretNote]
    
    // Session State
    @Published public var isAppUnlocked: Bool = false
    @Published public var isShowingLockOverlay: Bool = true
    @Published public var currentLockedAppTarget: String? = nil
    @Published public var isExternalIntercept: Bool = false
    @Published public var failedAttemptsCount: Int = 0
    @Published public var lastBackgroundDate: Date? = nil
    @Published public var toastMessage: String? = nil
    @Published public var showPermissionGuideOnLaunch: Bool = false
    
    private var didEnterBackground: Bool = false
    private var toastWorkItem: DispatchWorkItem? = nil
    
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
        
        let savedPolicy = defaults.string(forKey: Keys.relockPolicy) ?? RelockPolicy.immediately.rawValue
        self.relockPolicy = RelockPolicy(rawValue: savedPolicy) ?? .immediately
        self.isVibrationEnabled = defaults.object(forKey: Keys.isVibrationEnabled) == nil ? true : defaults.bool(forKey: Keys.isVibrationEnabled)
        
        self.isAutomationVerified = defaults.bool(forKey: Keys.isAutomationVerified)
        let savedGrace = defaults.integer(forKey: Keys.unlockGraceSeconds)
        self.unlockGraceSeconds = savedGrace > 0 ? savedGrace : 120 // Mặc định cho phép dùng 2 phút sau khi mở khóa
        if let graceTimestamp = defaults.object(forKey: Keys.unlockedGraceUntil) as? Double {
            let date = Date(timeIntervalSince1970: graceTimestamp)
            self.unlockedGraceUntil = date > Date() ? date : nil
        } else {
            self.unlockedGraceUntil = nil
        }
        
        // Load apps & merge any new default apps
        if let data = defaults.data(forKey: Keys.lockedApps),
           var savedApps = try? JSONDecoder().decode([AppItem].self, from: data) {
            let existingNames = Set(savedApps.map { $0.appName.lowercased() })
            for defApp in AppItem.defaultApps where !existingNames.contains(defApp.appName.lowercased()) {
                savedApps.append(defApp)
            }
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
        
        // Restore pending target if launched from background Shortcut intent
        if let pending = defaults.string(forKey: Keys.pendingExternalTarget), !pending.isEmpty {
            self.currentLockedAppTarget = pending
            self.isExternalIntercept = true
        }
        
        // Always require authentication or setup at launch
        self.isShowingLockOverlay = true
        self.isAppUnlocked = false
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
        defaults.set(isAutomationVerified, forKey: Keys.isAutomationVerified)
        defaults.set(unlockGraceSeconds, forKey: Keys.unlockGraceSeconds)
        
        if let graceDate = unlockedGraceUntil {
            defaults.set(graceDate.timeIntervalSince1970, forKey: Keys.unlockedGraceUntil)
        } else {
            defaults.removeObject(forKey: Keys.unlockedGraceUntil)
        }
        
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
    
    // Check if currently inside temporary unlocked grace period
    public var isWithinGracePeriod: Bool {
        guard let until = unlockedGraceUntil else { return false }
        return Date() < until
    }
    
    // Re-lock all external apps immediately
    public func relockExternalAppsNow() {
        unlockedGraceUntil = nil
        UserDefaults.standard.removeObject(forKey: Keys.unlockedGraceUntil)
        ScreenTimeManager.shared.resumeShields()
        if isVibrationEnabled {
            HapticManager.shared.notification(.success)
        }
        showToast("Đã kích hoạt khóa lại toàn bộ ứng dụng!")
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
        let interceptedTarget = self.currentLockedAppTarget
        let wasExternal = self.isExternalIntercept
        
        self.failedAttemptsCount = 0
        self.isAppUnlocked = true
        self.isExternalIntercept = false
        UserDefaults.standard.removeObject(forKey: Keys.pendingExternalTarget)
        
        // Nếu mở khóa khi đang chặn một ứng dụng bên ngoài (VD: Facebook), cấp quyền truy cập tạm thời và tự động mở lại app đó!
        if wasExternal {
            let graceDate = Date().addingTimeInterval(TimeInterval(unlockGraceSeconds))
            self.unlockedGraceUntil = graceDate
            UserDefaults.standard.set(graceDate.timeIntervalSince1970, forKey: Keys.unlockedGraceUntil)
        }
        
        withAnimation(.spring()) {
            self.isShowingLockOverlay = false
            self.currentLockedAppTarget = nil
        }
        
        if isVibrationEnabled {
            HapticManager.shared.notification(.success)
        }
        
        if wasExternal, let targetName = interceptedTarget {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.openExternalAppIfPossible(named: targetName)
            }
        }
    }
    
    public func openExternalAppIfPossible(named targetName: String) {
        let trimmed = targetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Tìm URL Schemes từ danh sách ứng dụng hoặc bảng ánh xạ thông minh
        var candidateSchemes: [String] = []
        if let matchedApp = apps.first(where: {
            $0.appName.localizedCaseInsensitiveContains(trimmed) ||
            trimmed.localizedCaseInsensitiveContains($0.appName)
        }) {
            candidateSchemes.append(contentsOf: matchedApp.urlSchemes)
        }
        candidateSchemes.append(contentsOf: AppItem.knownSchemes(for: trimmed))
        
        for scheme in candidateSchemes {
            if let url = URL(string: scheme) {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success { return }
                }
                if UIApplication.shared.canOpenURL(url) {
                    return
                }
            }
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
    
    // MARK: - Shortcut AppIntent & URL Interception
    
    /// Được gọi ngầm từ CheckAppLockIntent khi người dùng bấm mở Facebook / Zalo / v.v.
    /// Trả về `true` nếu CẦN KHÓA (chuyển ngay sang AppLock), `false` nếu cho phép mở bình thường.
    public func evaluateShortcutIntercept(appName: String) -> Bool {
        let cleaned = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetTitle = cleaned.isEmpty ? "Ứng dụng bảo vệ" : cleaned
        
        if !isAutomationVerified {
            isAutomationVerified = true
            UserDefaults.standard.set(true, forKey: Keys.isAutomationVerified)
        }
        
        // 1. Kiểm tra xem công tắc khóa của ứng dụng này trong AppLock có đang BẬT không
        if !cleaned.isEmpty,
           let matchedApp = apps.first(where: {
               $0.appName.localizedCaseInsensitiveCompare(cleaned) == .orderedSame ||
               $0.appName.localizedCaseInsensitiveContains(cleaned) ||
               cleaned.localizedCaseInsensitiveContains($0.appName)
           }) {
            if !matchedApp.isLocked {
                // Người dùng đã tắt khóa cho app này trong danh sách -> cho vào thẳng!
                return false
            }
        }
        
        // 2. Kiểm tra xem người dùng vừa mới mở khóa xác thực trong thời gian cho phép không (chống lặp vô hạn!)
        if let timestamp = UserDefaults.standard.object(forKey: Keys.unlockedGraceUntil) as? Double {
            let graceUntil = Date(timeIntervalSince1970: timestamp)
            if Date() < graceUntil {
                self.unlockedGraceUntil = graceUntil
                return false
            }
        }
        
        // 3. Cần khóa! Chuẩn bị sẵn màn hình khóa cho ứng dụng mục tiêu
        self.currentLockedAppTarget = targetTitle
        self.isExternalIntercept = true
        self.isAppUnlocked = false
        self.isShowingLockOverlay = true
        UserDefaults.standard.set(targetTitle, forKey: Keys.pendingExternalTarget)
        return true
    }
    
    public func forceInterceptLock(appName: String) -> Bool {
        let cleaned = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetTitle = cleaned.isEmpty ? "Ứng dụng bảo vệ" : cleaned
        if !isAutomationVerified {
            isAutomationVerified = true
            UserDefaults.standard.set(true, forKey: Keys.isAutomationVerified)
        }
        self.currentLockedAppTarget = targetTitle
        self.isExternalIntercept = true
        self.isAppUnlocked = false
        self.isShowingLockOverlay = true
        UserDefaults.standard.set(targetTitle, forKey: Keys.pendingExternalTarget)
        return true
    }
    
    // App locking actions
    @discardableResult
    public func toggleAppLock(id: String) -> Bool {
        if let index = apps.firstIndex(where: { $0.id == id }) {
            apps[index].isLocked.toggle()
            let nowLocked = apps[index].isLocked
            saveSettings()
            if isVibrationEnabled {
                HapticManager.shared.selection()
            }
            return nowLocked
        }
        return false
    }
    
    public func addCustomApp(name: String, urlScheme: String = "") {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var schemes = AppItem.knownSchemes(for: trimmed)
        let customScheme = urlScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customScheme.isEmpty {
            let formatted = customScheme.contains("://") ? customScheme : "\(customScheme)://"
            schemes.insert(formatted, at: 0)
        }
        let item = AppItem(
            bundleId: "custom.\(UUID().uuidString)",
            appName: trimmed,
            isLocked: true,
            isSystemApp: false,
            isRecommended: false,
            iconSymbol: "lock.app.dashed",
            category: "Tùy chỉnh",
            urlSchemes: schemes
        )
        apps.insert(item, at: 0)
        saveSettings()
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
    
    // Scene phase handling (chỉ khóa lại khi thực sự thoát ra nền, tránh lỗi lặp khóa khi hiện bảng Face ID!)
    public func appMovedToBackground() {
        didEnterBackground = true
        lastBackgroundDate = Date()
        if relockPolicy == .immediately {
            isAppUnlocked = false
            isShowingLockOverlay = true
        }
    }
    
    public func appBecameActive() {
        // Kiểm tra nếu vừa được gọi từ Shortcut Intent ngầm
        if let pending = UserDefaults.standard.string(forKey: Keys.pendingExternalTarget), !pending.isEmpty {
            self.currentLockedAppTarget = pending
            self.isExternalIntercept = true
            self.isAppUnlocked = false
            self.isShowingLockOverlay = true
            didEnterBackground = false
            return
        }
        
        if isFirstLaunch {
            isShowingLockOverlay = true
            return
        }
        
        guard didEnterBackground else { return }
        didEnterBackground = false
        
        switch relockPolicy {
        case .immediately, .screenOff:
            isAppUnlocked = false
            isShowingLockOverlay = true
        case .oneMinute:
            if let lastBg = lastBackgroundDate, Date().timeIntervalSince(lastBg) > 60 {
                isAppUnlocked = false
                isShowingLockOverlay = true
            }
        }
    }
    
    // Deep Link & Apple Shortcuts URL Scheme trigger (applock://lock?app=Facebook)
    public func handleDeepLink(url: URL) {
        guard url.scheme?.lowercased() == "applock" else { return }
        
        if !isAutomationVerified {
            isAutomationVerified = true
            UserDefaults.standard.set(true, forKey: Keys.isAutomationVerified)
        }
        
        var targetAppName = "Ứng dụng được bảo vệ"
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let appQuery = components.queryItems?.first(where: { $0.name.lowercased() == "app" })?.value,
               !appQuery.isEmpty {
                targetAppName = appQuery
            } else if let host = components.host, !host.isEmpty && host.lowercased() != "lock" {
                targetAppName = host
            }
        }
        
        // Nếu đang trong thời gian mở khóa tạm thời, tự động quay lại ứng dụng mục tiêu ngay tránh lặp!
        if isWithinGracePeriod {
            openExternalAppIfPossible(named: targetAppName)
            return
        }
        
        self.currentLockedAppTarget = targetAppName
        self.isExternalIntercept = true
        self.isAppUnlocked = false
        self.isShowingLockOverlay = true
        if isVibrationEnabled {
            HapticManager.shared.notification(.warning)
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
