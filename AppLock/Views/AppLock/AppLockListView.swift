import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

public struct AppLockListView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: AppFilter = .all
    @State private var showShortcutsGuide: Bool = false
    @State private var guideInitialApp: String = "Facebook"
    @State private var showFamilyPicker: Bool = false
    @State private var showAddAppSheet: Bool = false
    @State private var customAppNameInput: String = ""
    @State private var customAppSchemeInput: String = ""
    
    enum AppFilter: String, CaseIterable {
        case all = "Tất cả"
        case locked = "Đã khóa"
        case recommended = "Khuyên dùng"
        case system = "Hệ thống"
    }
    
    public init() {}
    
    var isSystemProtectionActive: Bool {
        appLockManager.isAutomationVerified || (screenTimeManager.isAuthorized && screenTimeManager.shieldedCount > 0)
    }
    
    var filteredApps: [AppItem] {
        var list = appLockManager.apps
        
        switch selectedFilter {
        case .all:
            break
        case .locked:
            list = list.filter { $0.isLocked }
        case .recommended:
            list = list.filter { $0.isRecommended }
        case .system:
            list = list.filter { $0.isSystemApp }
        }
        
        if !searchText.isEmpty {
            list = list.filter {
                $0.appName.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleId.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return list
    }
    
    var lockedCount: Int {
        appLockManager.apps.filter { $0.isLocked }.count
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar matching video (48pt height, #152037)
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textMuted)
                    
                    TextField("Tìm kiếm ứng dụng...", text: $searchText)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    } else {
                        Button(action: { showAddAppSheet = true }) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 17))
                                .foregroundColor(AppColors.cyan.opacity(0.85))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Horizontal Filter Chips (Tất cả | Đã khóa | Khuyên dùng | Hệ thống)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppFilter.allCases, id: \.self) { filter in
                            let isSelected = selectedFilter == filter
                            
                            Button(action: {
                                selectedFilter = filter
                                if appLockManager.isVibrationEnabled {
                                    HapticManager.shared.selection()
                                }
                            }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                                    .padding(.horizontal, 16)
                                    .frame(height: 32)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? AppColors.cyan : AppColors.cardBackground)
                                    )
                                    .foregroundColor(isSelected ? AppColors.background : AppColors.textSecondary)
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? AppColors.cyan : AppColors.cardBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                
                // Summary & Quick Action Bar ("Tổng: XX ứng dụng (Y đã bảo vệ)" | "Khóa toàn bộ đề xuất")
                HStack {
                    Text("Tổng: \(appLockManager.apps.count) ứng dụng (\(lockedCount) đã bảo vệ)")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textMuted)
                    
                    Spacer()
                    
                    Button(action: {
                        appLockManager.lockAllRecommended()
                        appLockManager.showToast("Đã khóa toàn bộ ứng dụng nhạy cảm!")
                    }) {
                        Text("Khóa toàn bộ đề xuất")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 6)
                
                // Compact iOS Activation Bar (if Shortcuts / Screen Time not yet linked)
                if !isSystemProtectionActive {
                    Button(action: {
                        guideInitialApp = "Facebook"
                        showShortcutsGuide = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.shield.fill")
                                .foregroundColor(AppColors.amber)
                            Text("Chạm để cấp quyền tự động chặn ứng dụng trên iOS")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .lineLimit(1)
                            Spacer()
                            Text("Bật ngay")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.background)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AppColors.cyan))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.cardHighlight)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.cyan.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                } else if appLockManager.isWithinGracePeriod {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.rotation")
                            .foregroundColor(AppColors.emerald)
                        Text("Đang tạm mở khóa phiên dùng ứng dụng")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Button("Khóa lại") {
                            appLockManager.relockExternalAppsNow()
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
                
                // Apps List
                if filteredApps.isEmpty {
                    Spacer()
                    Text("Không tìm thấy ứng dụng phù hợp")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredApps) { app in
                                AppRowView(
                                    app: app,
                                    onToggle: {
                                        let locked = appLockManager.toggleAppLock(id: app.id)
                                        appLockManager.showToast(locked ? "Đã khóa bảo vệ \(app.appName)" : "Đã mở khóa \(app.appName)")
                                    },
                                    onTestLock: {
                                        appLockManager.currentLockedAppTarget = app.appName
                                        appLockManager.isExternalIntercept = false
                                        appLockManager.isAppUnlocked = false
                                        appLockManager.isShowingLockOverlay = true
                                    },
                                    onOpenGuide: {
                                        guideInitialApp = app.appName
                                        showShortcutsGuide = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 2)
                        .padding(.bottom, 18)
                    }
                }
            }
        }
        .sheet(isPresented: $showShortcutsGuide) {
            ShortcutsGuideView(initialAppName: guideInitialApp)
        }
        .sheet(isPresented: $showAddAppSheet) {
            addCustomAppSheet
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(isPresented: $showFamilyPicker, selection: $screenTimeManager.activitySelection)
        #endif
    }
    
    private var addCustomAppSheet: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Text("Thêm ứng dụng vào danh sách")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("Đóng") { showAddAppSheet = false }
                        .foregroundColor(AppColors.cyan)
                }
                .padding(.top, 20)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tên ứng dụng:")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        TextField("Ví dụ: VNeID, Liên Quân, CapCut...", text: $customAppNameInput)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(10)
                            .background(AppColors.inputBackground)
                            .cornerRadius(8)
                        
                        Text("URL Scheme tự mở lại (không bắt buộc):")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        TextField("Ví dụ: fb://, youtube://", text: $customAppSchemeInput)
                            .foregroundColor(AppColors.textPrimary)
                            .autocapitalization(.none)
                            .padding(10)
                            .background(AppColors.inputBackground)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
                
                Button(action: {
                    appLockManager.addCustomApp(name: customAppNameInput, urlScheme: customAppSchemeInput)
                    appLockManager.showToast("Đã thêm & khóa \(customAppNameInput)!")
                    customAppNameInput = ""
                    customAppSchemeInput = ""
                    showAddAppSheet = false
                }) {
                    Text("Lưu & Khóa ứng dụng")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                .disabled(customAppNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}
