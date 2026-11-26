import Foundation
import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

@MainActor
public final class ScreenTimeManager: ObservableObject {
    public static let shared = ScreenTimeManager()
    
    private let selectionStorageKey = "applock_screentime_selection"
    
    @Published public var isAuthorized: Bool = false
    @Published public var authorizationError: String? = nil
    @Published public var areShieldsPaused: Bool = false
    
    #if canImport(FamilyControls)
    @Published public var activitySelection = FamilyActivitySelection() {
        didSet {
            saveSelection()
            applyShieldRestrictions()
        }
    }
    #endif
    
    #if canImport(ManagedSettings)
    private let managedSettingsStore = ManagedSettingsStore()
    #endif
    
    public var shieldedCount: Int {
        #if canImport(FamilyControls)
        return activitySelection.applicationTokens.count + activitySelection.categoryTokens.count
        #else
        return 0
        #endif
    }
    
    private init() {
        loadSelection()
        checkCurrentStatus()
        if isAuthorized && !areShieldsPaused {
            applyShieldRestrictions()
        }
    }
    
    private func saveSelection() {
        #if canImport(FamilyControls)
        if let data = try? JSONEncoder().encode(activitySelection) {
            UserDefaults.standard.set(data, forKey: selectionStorageKey)
        }
        #endif
    }
    
    private func loadSelection() {
        #if canImport(FamilyControls)
        if let data = UserDefaults.standard.data(forKey: selectionStorageKey),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.activitySelection = decoded
        }
        #endif
    }
    
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
                    applyShieldRestrictions()
                }
                return approved
            } catch {
                self.isAuthorized = false
                self.authorizationError = "Chứng chỉ cài đặt hiện tại (Sideload / Cato / Free Apple ID) không có quyền FamilyControls đặc biệt của Apple. Vui lòng sử dụng chế độ 'Khóa Tức Thì qua Phím Tắt iOS' — hoạt động 100% trên mọi máy!"
                return false
            }
        } else {
            self.authorizationError = "Yêu cầu iOS 16.0 trở lên để sử dụng Screen Time API"
            return false
        }
        #else
        self.authorizationError = "FamilyControls framework không khả dụng trên môi trường hiện tại"
        return false
        #endif
    }
    
    public func applyShieldRestrictions() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            if isAuthorized && !areShieldsPaused {
                managedSettingsStore.shield.applications = activitySelection.applicationTokens.isEmpty ? nil : activitySelection.applicationTokens
                managedSettingsStore.shield.applicationCategories = activitySelection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
            } else {
                managedSettingsStore.shield.applications = nil
                managedSettingsStore.shield.applicationCategories = nil
            }
        }
        #endif
    }
    
    public func pauseShieldsTemporarily(seconds: Int = 120) {
        areShieldsPaused = true
        clearAllShields()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            if self.areShieldsPaused {
                self.resumeShields()
            }
        }
    }
    
    public func resumeShields() {
        areShieldsPaused = false
        applyShieldRestrictions()
    }
    
    public func clearAllShields() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            managedSettingsStore.shield.applications = nil
            managedSettingsStore.shield.applicationCategories = nil
        }
        #endif
    }
}
