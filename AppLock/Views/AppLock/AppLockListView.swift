import SwiftUI

public struct AppLockListView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: AppFilter = .all
    @State private var showShortcutsGuide: Bool = false
    @State private var showLockTestOverlay: Bool = false
    @State private var testTargetAppName: String = ""
    
    enum AppFilter: String, CaseIterable {
        case all = "Tất cả"
        case locked = "Đã khóa"
        case recommended = "Khuyên dùng"
        case system = "Hệ thống"
    }
    
    public init() {}
    
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
                    subtitle: "Khóa ứng dụng nhạy cảm bảo vệ thông tin riêng tư",
                    badgeText: "Đang khóa \(lockedCount) app",
                    badgeColor: lockedCount > 0 ? AppColors.cyan : AppColors.textMuted
                )
                
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textSecondary)
                    
                    TextField("Tìm kiếm ứng dụng...", text: $searchText)
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
                .padding(.vertical, 8)
                
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
                    .padding(.vertical, 6)
                }
                
                // Quick Lock Bar & Shortcuts Banner
                HStack(spacing: 12) {
                    Button(action: {
                        appLockManager.lockAllRecommended()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                            Text("Khóa đề xuất")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColors.cyan)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
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
                        appLockManager.unlockAll()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.open.fill")
                            Text("Mở khóa hết")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
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
                        showShortcutsGuide = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle.fill")
                            Text("HD Khóa iOS")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.amber)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                
                // App List
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredApps) { app in
                            AppRowView(
                                app: app,
                                onToggle: {
                                    appLockManager.toggleAppLock(id: app.id)
                                },
                                onTestLock: {
                                    testTargetAppName = app.appName
                                    appLockManager.currentLockedAppTarget = app.appName
                                    showLockTestOverlay = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(isPresented: $showShortcutsGuide) {
            ShortcutsGuideView()
        }
        .fullScreenCover(isPresented: $showLockTestOverlay) {
            LockScreenOverlayView()
        }
    }
}
