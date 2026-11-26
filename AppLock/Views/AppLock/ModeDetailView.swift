import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

/// Mode Detail screen matching 00:21 - 00:29 & 00:40 - 00:42 in the reference video
public struct ModeDetailView: View {
    @ObservedObject var screenTimeManager = ScreenTimeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let modeId: String
    
    enum DetailTab: String, CaseIterable {
        case schedule = "Lịch trình"
        case hide = "Ẩn"
        case more = "Thêm"
        
        var icon: String {
            switch self {
            case .schedule: return "calendar"
            case .hide: return "eye.slash"
            case .more: return "slider.horizontal.3"
            }
        }
    }
    
    @State private var selectedTab: DetailTab = .schedule
    @State private var showLockPicker: Bool = false
    @State private var showHidePicker: Bool = false
    @State private var showPermissionSheet: Bool = false
    @State private var showLockSuccessPopup: Bool = false
    
    public init(modeId: String) {
        self.modeId = modeId
    }
    
    private var mode: LockModeItem {
        screenTimeManager.mode(for: modeId)
    }
    
    private var cleanModeTitle: String {
        mode.title.replacingOccurrences(of: "\n", with: " ")
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Return to unlocked app banner matching 00:35
                if screenTimeManager.showReturnToAppBanner {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Nhấn vào góc trên bên trái để quay lại ứng dụng đã mở khóa")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Khóa lại") {
                            screenTimeManager.relockShieldsNow()
                        }
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(AppColors.yellowCard)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0F172A"))
                }
                
                // Top Header matching 00:21 & 00:28
                HStack(spacing: 10) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(width: 34, height: 34)
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(mode.isHighlighted ? AppColors.yellowCard : AppColors.cardHighlight)
                            .frame(width: 28, height: 28)
                        Image(systemName: mode.iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(mode.isHighlighted ? AppColors.textPrimary : AppColors.cyan)
                    }
                    
                    Text(cleanModeTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Master OFF/ON Pill Toggle matching 00:28
                    Button(action: toggleMasterMode) {
                        HStack(spacing: 6) {
                            if mode.isEnabled {
                                Text("ON")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.white)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                            } else {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 22, height: 22)
                                Text("OFF")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 5)
                        .frame(width: 68, height: 30)
                        .background(
                            Capsule()
                                .fill(mode.isEnabled ? AppColors.cyan : Color(hex: "CBD5E1"))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                
                // 3 Tabs Bar matching 00:21 & 00:40 - 00:42
                HStack(spacing: 8) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab
                        Button(action: {
                            selectedTab = tab
                            HapticManager.shared.selection()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(tab.rawValue)
                                    .font(.system(size: 13.5, weight: isSelected ? .bold : .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? AppColors.cardHighlight : Color.clear)
                            )
                            .foregroundColor(isSelected ? AppColors.cyan : AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                
                Divider()
                
                // Tab Content
                switch selectedTab {
                case .schedule:
                    scheduleTabView
                case .hide:
                    hideTabView
                case .more:
                    moreTabView
                }
            }
            
            // Floating '+' Blue Button when items exist in Lịch trình (00:28)
            if selectedTab == .schedule && lockAppCount > 0 {
                Button(action: openLockPicker) {
                    ZStack {
                        Circle()
                            .fill(AppColors.cyan)
                            .frame(width: 54, height: 54)
                            .shadow(color: AppColors.cyan.opacity(0.35), radius: 8, y: 4)
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 22)
                .padding(.bottom, 24)
            }
            
            // Success Popup matching 00:29
            if showLockSuccessPopup {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { showLockSuccessPopup = false }
                
                VStack(spacing: 16) {
                    Text("Các ứng dụng đã chọn đã được khóa thành công! Hãy kiểm tra ngay bây giờ!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showLockSuccessPopup = false
                    }) {
                        Text("Kiểm tra")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 140, height: 42)
                            .background(Capsule().fill(AppColors.cyan))
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 20)
                )
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPermissionSheet) {
            ScreenTimePermissionView {
                showPermissionSheet = false
            }
        }
        #if canImport(FamilyControls)
        .familyActivityPicker(
            isPresented: $showLockPicker,
            selection: screenTimeManager.lockSelectionBinding(for: modeId)
        )
        .familyActivityPicker(
            isPresented: $showHidePicker,
            selection: screenTimeManager.hideSelectionBinding(for: modeId)
        )
        #endif
    }
    
    private var lockAppCount: Int {
        #if canImport(FamilyControls)
        return screenTimeManager.lockCount(for: modeId)
        #else
        return 0
        #endif
    }
    
    private var hideAppCount: Int {
        #if canImport(FamilyControls)
        return screenTimeManager.hideCount(for: modeId)
        #else
        return 0
        #endif
    }
    
    // MARK: - Tab 1: Lịch trình (00:21 & 00:28)
    private var scheduleTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !mode.isEnabled && lockAppCount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(AppColors.amber)
                        Text("Lịch khóa chưa bật. Bật công tắc ON ở góc trên phải.")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color(hex: "92400E"))
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "FEF3C7"))
                    )
                }
                
                if lockAppCount == 0 {
                    Spacer().frame(height: 90)
                    
                    Text("Khoá ứng dụng")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Vui lòng chọn các ứng dụng bạn muốn khoá.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                    
                    Button(action: openLockPicker) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Chọn app")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 156, height: 46)
                        .background(Capsule().fill(AppColors.cyan))
                    }
                    .padding(.top, 8)
                } else {
                    // Schedule Card "Cả ngày / Mỗi ngày" matching 00:28
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cả ngày")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text("Mỗi ngày • \(lockAppCount) mục đã chọn")
                                    .font(.system(size: 12.5))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            Button(action: openLockPicker) {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                                    .padding(8)
                            }
                        }
                        
                        HStack(spacing: 10) {
                            #if canImport(FamilyControls)
                            if let sel = screenTimeManager.lockSelections[modeId] {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(Array(sel.applicationTokens), id: \.self) { token in
                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(1.25)
                                                .frame(width: 36, height: 36)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.inputBackground))
                                        }
                                        ForEach(Array(sel.categoryTokens), id: \.self) { token in
                                            Label(token)
                                                .labelStyle(.iconOnly)
                                                .scaleEffect(1.2)
                                                .frame(width: 36, height: 36)
                                                .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.inputBackground))
                                        }
                                    }
                                }
                            }
                            #endif
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { mode.isScheduleEnabled },
                                set: { val in
                                    var updated = mode
                                    updated.isScheduleEnabled = val
                                    screenTimeManager.updateMode(updated)
                                }
                            ))
                            .labelsHidden()
                            .tint(AppColors.cyan)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                    )
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Tab 2: Ẩn ứng dụng (00:40)
    private var hideTabView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if hideAppCount == 0 {
                    Spacer().frame(height: 90)
                    
                    Text("Ẩn ứng dụng")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Vui lòng chọn các ứng dụng bạn muốn ẩn khỏi màn hình chính.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button(action: openHidePicker) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Chọn app")
                        }
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 156, height: 46)
                        .background(Capsule().fill(AppColors.cyan))
                    }
                    .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ứng dụng đang ẩn (\(hideAppCount))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Button("Chỉnh sửa", action: openHidePicker)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.cyan)
                        }
                        
                        #if canImport(FamilyControls)
                        if let sel = screenTimeManager.hideSelections[modeId] {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Array(sel.applicationTokens), id: \.self) { token in
                                        Label(token)
                                            .labelStyle(.iconOnly)
                                            .scaleEffect(1.25)
                                            .frame(width: 36, height: 36)
                                            .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.inputBackground))
                                    }
                                }
                            }
                        }
                        #endif
                        
                        Text(mode.isEnabled ? "Đang ẩn khỏi màn hình chính & Thư viện ứng dụng." : "Bật công tắc ON ở góc trên để áp dụng ẩn ứng dụng.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                    )
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Tab 3: Thêm (00:42)
    private var moreTabView: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 1. Đặt lại Lịch khóa
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(AppColors.cardHighlight).frame(width: 38, height: 38)
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(AppColors.cyan)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Đặt lại Lịch khóa")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Mở khóa ứng dụng, và nó sẽ tự động khóa lại sau thời gian được đặt.")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                    Menu {
                        Button("1 phút") { updateRelockMinutes(1) }
                        Button("5 phút") { updateRelockMinutes(5) }
                        Button("15 phút") { updateRelockMinutes(15) }
                        Button("30 phút") { updateRelockMinutes(30) }
                        Button("Tắt") { updateRelockMinutes(0) }
                    } label: {
                        Text(mode.autoRelockMinutes == 0 ? "Tắt" : "\(mode.autoRelockMinutes) phút")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.cyan)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(AppColors.cardHighlight))
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                
                // 2. Thông báo Mở khóa
                restrictionToggleCard(
                    icon: "bell.badge.fill",
                    title: "Thông báo Mở khóa",
                    subtitle: "Gửi thông báo ngay khi bấm 'Mở khóa' để mở nhanh màn hình nhập mã.",
                    isOn: Binding(
                        get: { mode.unlockNotificationEnabled },
                        set: { val in
                            var updated = mode
                            updated.unlockNotificationEnabled = val
                            screenTimeManager.updateMode(updated)
                            if val {
                                Task { await screenTimeManager.requestNotificationPermission() }
                            }
                        }
                    )
                )
                
                // 3. Cấm thanh toán trong ứng dụng
                restrictionToggleCard(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    title: "Cấm thanh toán trong ứng dụng",
                    subtitle: "Ngăn trả tiền trái phép và các khoản thanh toán bổ sung.",
                    isOn: Binding(
                        get: { mode.denyInAppPurchases },
                        set: { val in
                            var updated = mode
                            updated.denyInAppPurchases = val
                            screenTimeManager.updateMode(updated)
                        }
                    )
                )
                
                // 4. Cấm xóa ứng dụng
                restrictionToggleCard(
                    icon: "trash.slash.fill",
                    title: "Cấm xóa ứng dụng",
                    subtitle: "Ngăn xóa ứng dụng quan trọng và mất dữ liệu do sơ suất.",
                    isOn: Binding(
                        get: { mode.denyAppRemoval },
                        set: { val in
                            var updated = mode
                            updated.denyAppRemoval = val
                            screenTimeManager.updateMode(updated)
                        }
                    )
                )
                
                // 5. Cấm cài đặt ứng dụng
                restrictionToggleCard(
                    icon: "app.badge",
                    title: "Cấm cài đặt ứng dụng",
                    subtitle: "Ngăn cài đặt ứng dụng mới từ App Store khi chế độ bật.",
                    isOn: Binding(
                        get: { mode.denyAppInstallation },
                        set: { val in
                            var updated = mode
                            updated.denyAppInstallation = val
                            screenTimeManager.updateMode(updated)
                        }
                    )
                )
            }
            .padding(16)
        }
    }
    
    private func restrictionToggleCard(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.cardHighlight).frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(AppColors.cyan)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.cyan)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
    }
    
    private func updateRelockMinutes(_ mins: Int) {
        var updated = mode
        updated.autoRelockMinutes = mins
        screenTimeManager.updateMode(updated)
    }
    
    private func openLockPicker() {
        screenTimeManager.checkCurrentStatus()
        if screenTimeManager.isAuthorized {
            showLockPicker = true
        } else {
            showPermissionSheet = true
        }
    }
    
    private func openHidePicker() {
        screenTimeManager.checkCurrentStatus()
        if screenTimeManager.isAuthorized {
            showHidePicker = true
        } else {
            showPermissionSheet = true
        }
    }
    
    private func toggleMasterMode() {
        screenTimeManager.checkCurrentStatus()
        if !screenTimeManager.isAuthorized {
            showPermissionSheet = true
            return
        }
        var updated = mode
        updated.isEnabled.toggle()
        screenTimeManager.updateMode(updated)
        HapticManager.shared.notification(updated.isEnabled ? .success : .warning)
        
        if updated.isEnabled && lockAppCount > 0 {
            Task { await screenTimeManager.requestNotificationPermission() }
            showLockSuccessPopup = true
        }
    }
}
