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
    
    @Published public var isAuthorized: Bool = false
    @Published public var authorizationError: String? = nil
    
    #if canImport(FamilyControls)
    @Published public var activitySelection = FamilyActivitySelection() {
        didSet {
            applyShieldRestrictions()
        }
    }
    #endif
    
    #if canImport(ManagedSettings)
    private let managedSettingsStore = ManagedSettingsStore()
    #endif
    
    private init() {
        checkCurrentStatus()
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
    
    public func requestAuthorization() async {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                self.isAuthorized = (AuthorizationCenter.shared.authorizationStatus == .approved)
                self.authorizationError = nil
            } catch {
                self.isAuthorized = false
                self.authorizationError = error.localizedDescription
            }
        } else {
            self.authorizationError = "Yêu cầu iOS 16.0 trở lên để sử dụng Screen Time API"
        }
        #else
        self.authorizationError = "FamilyControls framework không khả dụng trên môi trường hiện tại"
        #endif
    }
    
    public func applyShieldRestrictions() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            if isAuthorized {
                // Apply shields to selected applications
                managedSettingsStore.shield.applications = activitySelection.applicationTokens.isEmpty ? nil : activitySelection.applicationTokens
                managedSettingsStore.shield.applicationCategories = activitySelection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(activitySelection.categoryTokens)
            } else {
                managedSettingsStore.shield.applications = nil
                managedSettingsStore.shield.applicationCategories = nil
            }
        }
        #endif
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
