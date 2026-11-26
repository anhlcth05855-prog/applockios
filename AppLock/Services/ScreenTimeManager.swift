import Foundation
import SwiftUI
import UserNotifications
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

@MainActor
public final class ScreenTimeManager: ObservableObject {
    public static let shared = ScreenTimeManager()
    
    public static let appGroupId = "group.com.guardio.applock"
    private let modesKey = "applock_modes_v2"
    private let pendingShieldUnlockKey = "applock_pending_shield_unlock"
    
    private var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupId) ?? .standard
    }
    
    @Published public var isAuthorized: Bool = false
    @Published public var authorizationError: String? = nil
    @Published public var modes: [LockModeItem] = LockModeItem.defaultModes
    @Published public var isTemporarilyUnlocked: Bool = false
    @Published public var showReturnToAppBanner: Bool = false
    @Published public var pendingShieldUnlock: Bool = false
    
    #if canImport(FamilyControls)
    @Published public var lockSelections: [String: FamilyActivitySelection] = [:]
    @Published public var hideSelections: [String: FamilyActivitySelection] = [:]
    #endif
    
    #if canImport(ManagedSettings)
    private let managedSettingsStore = ManagedSettingsStore()
    #endif
    
    private var relockTask: Task<Void, Never>? = nil
    
    private init() {
        loadState()
        checkCurrentStatus()
        if isAuthorized {
            applyActiveRestrictions()
        }
    }
    
    // MARK: - Persistence
    
    private func loadState() {
        if let data = sharedDefaults.data(forKey: modesKey),
           let decoded = try? JSONDecoder().decode([LockModeItem].self, from: data),
           !decoded.isEmpty {
            self.modes = decoded
        } else {
            self.modes = LockModeItem.defaultModes
        }
        
        #if canImport(FamilyControls)
        for mode in modes {
            if let lockData = sharedDefaults.data(forKey: "lock_sel_\(mode.id)"),
               let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: lockData) {
                lockSelections[mode.id] = sel
            }
            if let hideData = sharedDefaults.data(forKey: "hide_sel_\(mode.id)"),
               let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: hideData) {
                hideSelections[mode.id] = sel
            }
        }
        #endif
    }
    
    public func saveModes() {
        if let data = try? JSONEncoder().encode(modes) {
            sharedDefaults.set(data, forKey: modesKey)
        }
        #if canImport(FamilyControls)
        for mode in modes {
            if let sel = lockSelections[mode.id], let data = try? JSONEncoder().encode(sel) {
                sharedDefaults.set(data, forKey: "lock_sel_\(mode.id)")
            }
            if let sel = hideSelections[mode.id], let data = try? JSONEncoder().encode(sel) {
                sharedDefaults.set(data, forKey: "hide_sel_\(mode.id)")
            }
        }
        #endif
        sharedDefaults.synchronize()
    }
    
    // MARK: - Authorization
    
    public func checkCurrentStatus() {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            let status = AuthorizationCenter.shared.authorizationStatus
            self.isAuthorized = (status == .approved)
        } else {
            self.isAuthorized = false
        }
        #else
        self.isAuthorized = false
        #endif
    }
    
    public func requestAuthorization() async -> Bool {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                let approved = (AuthorizationCenter.shared.authorizationStatus == .approved)
                self.isAuthorized = approved
                if approved {
                    self.authorizationError = nil
                    applyActiveRestrictions()
                }
                return approved
            } catch {
                self.isAuthorized = false
                self.authorizationError = "iOS từ chối cấp quyền Thời gian sử dụng (\(error.localizedDescription)).\n\nLưu ý: Quyền FamilyControls yêu cầu file .ipa được ký bằng chứng chỉ Apple Developer có cấp quyền Family Controls chính thức từ Apple."
                return false
            }
        } else {
            self.authorizationError = "Yêu cầu iOS 16.0 trở lên."
            return false
        }
        #else
        self.authorizationError = "FamilyControls không khả dụng trên môi trường này."
        return false
        #endif
    }
    
    public func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    // MARK: - Mode Updates & Restrictions
    
    public func mode(for id: String) -> LockModeItem {
        modes.first(where: { $0.id == id }) ?? LockModeItem.defaultModes[2]
    }
    
    public func updateMode(_ updated: LockModeItem) {
        if let index = modes.firstIndex(where: { $0.id == updated.id }) {
            modes[index] = updated
            saveModes()
            isTemporarilyUnlocked = false
            showReturnToAppBanner = false
            applyActiveRestrictions()
        }
    }
    
    #if canImport(FamilyControls)
    public func lockSelectionBinding(for modeId: String) -> Binding<FamilyActivitySelection> {
        Binding(
            get: { self.lockSelections[modeId] ?? FamilyActivitySelection() },
            set: { newValue in
                self.lockSelections[modeId] = newValue
                self.saveModes()
                self.isTemporarilyUnlocked = false
                self.applyActiveRestrictions()
            }
        )
    }
    
    public func hideSelectionBinding(for modeId: String) -> Binding<FamilyActivitySelection> {
        Binding(
            get: { self.hideSelections[modeId] ?? FamilyActivitySelection() },
            set: { newValue in
                self.hideSelections[modeId] = newValue
                self.saveModes()
                self.applyActiveRestrictions()
            }
        )
    }
    
    public func lockCount(for modeId: String) -> Int {
        guard let sel = lockSelections[modeId] else { return 0 }
        return sel.applicationTokens.count + sel.categoryTokens.count + sel.webDomainTokens.count
    }
    
    public func hideCount(for modeId: String) -> Int {
        guard let sel = hideSelections[modeId] else { return 0 }
        return sel.applicationTokens.count
    }
    #endif
    
    public var totalProtectedAppsCount: Int {
        #if canImport(FamilyControls)
        return modes.filter { $0.isEnabled && $0.isScheduleEnabled }
            .reduce(0) { $0 + lockCount(for: $1.id) }
        #else
        return 0
        #endif
    }
    
    public var hasAnyShieldActive: Bool {
        totalProtectedAppsCount > 0 && !isTemporarilyUnlocked
    }
    
    public func applyActiveRestrictions() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        guard #available(iOS 16.0, *), isAuthorized else { return }
        
        if isTemporarilyUnlocked {
            managedSettingsStore.shield.applications = nil
            managedSettingsStore.shield.applicationCategories = nil
            managedSettingsStore.shield.webDomains = nil
        } else {
            var appTokens = Set<ApplicationToken>()
            var catTokens = Set<ActivityCategoryToken>()
            var webTokens = Set<WebDomainToken>()
            
            for mode in modes where mode.isEnabled && mode.isScheduleEnabled {
                if let sel = lockSelections[mode.id] {
                    appTokens.formUnion(sel.applicationTokens)
                    catTokens.formUnion(sel.categoryTokens)
                    webTokens.formUnion(sel.webDomainTokens)
                }
            }
            
            managedSettingsStore.shield.applications = appTokens.isEmpty ? nil : appTokens
            managedSettingsStore.shield.applicationCategories = catTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(catTokens)
            managedSettingsStore.shield.webDomains = webTokens.isEmpty ? nil : webTokens
        }
        
        // Hidden apps (blockedApplications)
        var hiddenApps = Set<Application>()
        var denyPurchases = false
        var denyRemoval = false
        var denyInstall = false
        
        for mode in modes where mode.isEnabled {
            if let hideSel = hideSelections[mode.id] {
                for token in hideSel.applicationTokens {
                    hiddenApps.insert(Application(token: token))
                }
            }
            if mode.denyInAppPurchases { denyPurchases = true }
            if mode.denyAppRemoval { denyRemoval = true }
            if mode.denyAppInstallation { denyInstall = true }
        }
        
        managedSettingsStore.application.blockedApplications = hiddenApps.isEmpty ? nil : hiddenApps
        managedSettingsStore.appStore.denyInAppPurchases = denyPurchases
        managedSettingsStore.application.denyAppRemoval = denyRemoval
        managedSettingsStore.application.denyAppInstallation = denyInstall
        #endif
    }
    
    // MARK: - Temporary Unlock & Auto Re-lock
    
    public func checkPendingShieldUnlock() -> Bool {
        let pending = sharedDefaults.bool(forKey: pendingShieldUnlockKey)
        self.pendingShieldUnlock = pending
        return pending
    }
    
    public func clearPendingShieldUnlock() {
        sharedDefaults.set(false, forKey: pendingShieldUnlockKey)
        sharedDefaults.synchronize()
        self.pendingShieldUnlock = false
    }
    
    public func temporarilyUnlockShields() {
        let wasPending = checkPendingShieldUnlock()
        clearPendingShieldUnlock()
        
        isTemporarilyUnlocked = true
        if wasPending || totalProtectedAppsCount > 0 {
            showReturnToAppBanner = true
        }
        applyActiveRestrictions()
        
        // Schedule automatic re-lock based on enabled mode's autoRelockMinutes
        let minutes = modes.first(where: { $0.isEnabled && $0.autoRelockMinutes > 0 })?.autoRelockMinutes ?? 5
        relockTask?.cancel()
        relockTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60 * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.relockShieldsNow()
        }
    }
    
    public func relockShieldsNow() {
        relockTask?.cancel()
        isTemporarilyUnlocked = false
        showReturnToAppBanner = false
        applyActiveRestrictions()
    }
    
    public func clearAllShields() {
        relockTask?.cancel()
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            managedSettingsStore.clearAllSettings()
        }
        #endif
    }
}
