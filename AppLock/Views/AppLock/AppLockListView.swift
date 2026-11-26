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
    
    // Screen Time & Alerts
    @State private var showFamilyPicker: Bool = false
    @State private var showScreenTimeErrorAlert: Bool = false
    @State private var showSetupPromptAlert: Bool = false
    @State private var promptedAppName: String = "Facebook"
    
    // Custom App Sheet
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
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return list
    }
    
    var lockedCount: Int {
        appLockManager.apps.filter { $0.isLocked }.count
    }
    
    var recommendedCount: Int {
        appLockManager.apps.filter { $0.isRecommended }.count
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CyberHeader(
                    title: "Bảo Vệ Ứng Dụng",
                    subtitle: "Khóa Facebook, Zalo & ứng dụng riêng tư trên iOS",
                    badgeText: isSystemProtectionActive ? "Bảo vệ: \(lockedCount) app" : "Cần bật chặn iOS",
                    badgeColor: isSystemProtectionActive ? AppColors.emerald : AppColors.amber
                )
                
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("Tìm kiếm ứng dụng (Facebook, Zalo...)", text: $searchText)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppFilter.allCases, id: \.self) { filter in
                            let count: Int = {
                                switch filter {
                                case .all: return appLockManager.apps.count
                                case .locked: return lockedCount
                                case .recommended: return recommendedCount
                                case .system: return appLockManager.apps.filter { $0.isSystemApp }.count
                                }
                            }()
                            
                            let isSelected = selectedFilter == filter
                            
                            Button(action: {
                                selectedFilter = filter
                                HapticManager.shared.selection()
                            }) {
                                HStack(spacing: 5) {
                                    Text(filter.rawValue)
                                        .font(.system(size: 13, weight: .bold))
                                    Text("(\(count))")
                                        .font(.system(size: 11, weight: .medium))
                                        .opacity(0.8)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AppColors.cyan : AppColors.cardBackground)
                                )
                                .foregroundColor(isSelected ? .black : AppColors.textSecondary)
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? AppColors.cyan : AppColors.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                }
                
                // Quick Lock Bar
                HStack(spacing: 10) {
                    Button(action: {
                        appLockManager.lockAllRecommended()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.shield.fill")
                            Text("Khóa đề xuất")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.cyan.opacity(0.12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    Button(action: {
                        showAddAppSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.app.fill")
                            Text("Thêm App")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AppColors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                        )
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        guideInitialApp = "Facebook"
                        showShortcutsGuide = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.shield.fill")
                            Text("Kích hoạt iOS")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.amber)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                
                // Main Scrollable Content
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Temporary Grace Period Banner (if unlocked recently)
                        if appLockManager.isWithinGracePeriod || screenTimeManager.areShieldsPaused {
                            graceSessionBanner
                        }
                        
                        // System Protection Activation Banner
                        systemProtectionCard
                        
                        // App List
                        ForEach(filteredApps) { app in
                            AppRowView(
                                app: app,
                                onToggle: {
                                    let nowLocked = appLockManager.toggleAppLock(id: app.id)
                                    if nowLocked && !isSystemProtectionActive {
                                        promptedAppName = app.appName
                                        showSetupPromptAlert = true
                                    }
                                },
                                onTestLock: {
                                    appLockManager.currentLockedAppTarget = app.appName
                                    appLockManager.isExternalIntercept = false
                                    appLockManager.isAppUnlocked = false
                                    appLockManager.isShowingLockOverlay = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .padding(.bottom, 95)
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
        .alert("Cần kích hoạt chặn trên iOS", isPresented: $showSetupPromptAlert) {
            Button("Thiết lập ngay (20 giây)") {
                guideInitialApp = promptedAppName
                showShortcutsGuide = true
            }
            Button("Khóa qua Screen Time") {
                triggerScreenTimePicker()
            }
            Button("Để sau", role: .cancel) {}
        } message: {
            Text("Đã bật công tắc khóa cho \(promptedAppName)!\n\nDo cơ chế bảo mật của Apple, bạn cần liên kết Tự động hóa Phím Tắt iOS (chỉ làm 1 lần, không lặp vô hạn, mở khóa tự vào thẳng \(promptedAppName)) để khi bấm ngoài màn hình chính sẽ hiện khóa bảo vệ ngay.")
        }
        .alert("Thông báo Screen Time iOS", isPresented: $showScreenTimeErrorAlert) {
            Button("Dùng Khóa Phím Tắt (100% Mọi máy)") {
                guideInitialApp = "Facebook"
                showShortcutsGuide = true
            }
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(screenTimeManager.authorizationError ?? "Không thể kích hoạt FamilyControls trên chứng chỉ hiện tại.")
        }
    }
    
    // MARK: - Subviews
    
    private var graceSessionBanner: some View {
        GlassCard(
            cornerRadius: 14,
            borderColor: AppColors.emerald.opacity(0.5),
            backgroundColor: AppColors.emerald.opacity(0.12)
        ) {
            HStack(spacing: 10) {
                Image(systemName: "lock.open.rotation")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.emerald)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Đang trong phiên mở khóa tạm thời")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Cho phép mở app mượt mà không bị lặp khóa")
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    appLockManager.relockExternalAppsNow()
                }) {
                    Text("Khóa lại ngay")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.emerald)
                        .cornerRadius(8)
                }
            }
            .padding(12)
        }
    }
    
    @ViewBuilder
    private var systemProtectionCard: some View {
        if !isSystemProtectionActive {
            GlassCard(
                cornerRadius: 16,
                borderColor: AppColors.amber.opacity(0.6),
                backgroundColor: AppColors.cardBackground.opacity(0.92)
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.amber)
                        
                        Text("BƯỚC BẮT BUỘC ĐỂ CHẶN FACEBOOK TRÊN iOS")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(AppColors.amber)
                    }
                    
                    Text("Khác với Android, iOS không cho phép app tự chặn màn hình chính nếu chưa kết nối hệ thống. Hãy bật 1 trong 2 chế độ dưới đây để khóa thực tế:")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            guideInitialApp = "Facebook"
                            showShortcutsGuide = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                Text("Bật Khóa Phím Tắt (Mọi máy)")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cyan)
                            .cornerRadius(10)
                        }
                        
                        Button(action: triggerScreenTimePicker) {
                            HStack(spacing: 5) {
                                Image(systemName: "hourglass")
                                Text("Screen Time")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(14)
            }
            .padding(.bottom, 4)
        } else {
            GlassCard(
                cornerRadius: 14,
                borderColor: AppColors.emerald.opacity(0.4),
                backgroundColor: AppColors.cardBackground.opacity(0.8)
            ) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.emerald)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bảo vệ hệ thống iOS đã sẵn sàng")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.emerald)
                        Text(screenTimeManager.shieldedCount > 0
                             ? "Đang chặn \(screenTimeManager.shieldedCount) mục qua Screen Time & Phím Tắt"
                             : "Gạt công tắc từng app bên dưới để bật/tắt khóa tức thì")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    if screenTimeManager.isAuthorized {
                        Button(action: { showFamilyPicker = true }) {
                            Text("Chọn App")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppColors.cyan.opacity(0.15))
                                .cornerRadius(6)
                        }
                    } else {
                        Button(action: {
                            guideInitialApp = "Facebook"
                            showShortcutsGuide = true
                        }) {
                            Text("Thêm App")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppColors.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(AppColors.cyan.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(12)
            }
            .padding(.bottom, 4)
        }
    }
    
    private var addCustomAppSheet: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 18) {
                HStack {
                    Text("Thêm ứng dụng cần khóa")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("Đóng") {
                        showAddAppSheet = false
                    }
                    .foregroundColor(AppColors.cyan)
                }
                .padding(.top, 20)
                
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tên ứng dụng (đúng tên bạn nhập trong Phím Tắt):")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                        
                        TextField("Ví dụ: VNeID, Viettel Money, Liên Quân...", text: $customAppNameInput)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(10)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                        
                        Text("URL Scheme tự mở lại sau khi nhập PIN (Tùy chọn):")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("Ví dụ: fb://, zalo:// (có thể bỏ trống)", text: $customAppSchemeInput)
                            .foregroundColor(AppColors.textPrimary)
                            .autocapitalization(.none)
                            .padding(10)
                            .background(AppColors.backgroundSecondary)
                            .cornerRadius(8)
                    }
                    .padding(16)
                }
                
                Button(action: {
                    appLockManager.addCustomApp(name: customAppNameInput, urlScheme: customAppSchemeInput)
                    let addedName = customAppNameInput
                    customAppNameInput = ""
                    customAppSchemeInput = ""
                    showAddAppSheet = false
                    if !isSystemProtectionActive {
                        guideInitialApp = addedName
                        showShortcutsGuide = true
                    }
                }) {
                    Text("Lưu & Bật khóa ứng dụng")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CyberButtonStyle(primaryColor: AppColors.cyan))
                .disabled(customAppNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func triggerScreenTimePicker() {
        Task {
            let granted = await screenTimeManager.requestAuthorization()
            if granted {
                showFamilyPicker = true
            } else {
                showScreenTimeErrorAlert = true
            }
        }
    }
}
