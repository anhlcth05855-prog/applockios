import SwiftUI

public struct IntruderLogView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    @State private var viewingRecord: IntruderRecord? = nil
    @State private var showingClearAlert = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CyberHeader(
                    title: "Bắt Kẻ Xâm Nhập",
                    subtitle: "Tự động chụp camera trước khi nhập sai mật khẩu",
                    badgeText: "\(appLockManager.intruderRecords.count) cảnh báo",
                    badgeColor: appLockManager.intruderRecords.isEmpty ? AppColors.textMuted : AppColors.coral
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Configuration Card
                        GlassCard {
                            VStack(spacing: 16) {
                                // Toggle selfie
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Tự động chụp ảnh kẻ gian")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("Chụp ảnh bí mật khi mở khóa sai")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $appLockManager.isIntruderSelfieEnabled)
                                        .labelsHidden()
                                        .tint(AppColors.coral)
                                        .onChange(of: appLockManager.isIntruderSelfieEnabled) { _ in
                                            appLockManager.saveSettings()
                                        }
                                }
                                
                                Divider().background(AppColors.cardBorder)
                                
                                // Threshold picker
                                HStack {
                                    Text("Số lần sai để chụp ảnh:")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    Picker("", selection: $appLockManager.intruderThreshold) {
                                        Text("1 lần").tag(1)
                                        Text("2 lần").tag(2)
                                        Text("3 lần").tag(3)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 160)
                                    .onChange(of: appLockManager.intruderThreshold) { _ in
                                        appLockManager.saveSettings()
                                    }
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 20)
                        
                        // Clear history button
                        if !appLockManager.intruderRecords.isEmpty {
                            HStack {
                                Text("LỊCH SỬ XÂM NHẬP")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                Button(action: {
                                    showingClearAlert = true
                                }) {
                                    Text("Xóa toàn bộ")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(AppColors.coral)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                        
                        // Intruder logs list
                        if appLockManager.intruderRecords.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.cardBackground)
                                        .frame(width: 76, height: 76)
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(AppColors.emerald)
                                }
                                .padding(.top, 40)
                                
                                Text("Chưa có kẻ xâm nhập nào")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppColors.textPrimary)
                                
                                Text("Thiết bị của bạn đang an toàn tuyệt đối!\nKhi ai đó cố tình nhập sai mật mã, hình ảnh của họ sẽ xuất hiện tại đây.")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 36)
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(appLockManager.intruderRecords) { record in
                                    Button(action: {
                                        viewingRecord = record
                                    }) {
                                        GlassCard(cornerRadius: 14) {
                                            HStack(spacing: 14) {
                                                // Intruder photo thumbnail
                                                AsyncThumbnailView(fileName: record.imageFileName, type: .intruder, cornerRadius: 10, height: 54)
                                                    .frame(width: 54, height: 54)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(AppColors.coral.opacity(0.5), lineWidth: 1)
                                                    )
                                                
                                                // Info
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack {
                                                        Text("Cố mở: \(record.targetAppName)")
                                                            .font(.system(size: 15, weight: .bold))
                                                            .foregroundColor(AppColors.textPrimary)
                                                        
                                                        Spacer()
                                                        
                                                        Text("\(record.attemptCount) lần sai")
                                                            .font(.system(size: 11, weight: .bold))
                                                            .foregroundColor(AppColors.coral)
                                                            .padding(.horizontal, 6)
                                                            .padding(.vertical, 2)
                                                            .background(AppColors.coral.opacity(0.15))
                                                            .cornerRadius(4)
                                                    }
                                                    
                                                    Text(record.formattedTime)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AppColors.textSecondary)
                                                }
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                            .padding(14)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 90)
                }
            }
        }
        .sheet(item: $viewingRecord) { record in
            intruderDetailSheet(record: record)
        }
        .alert(isPresented: $showingClearAlert) {
            Alert(
                title: Text("Xóa toàn bộ lịch sử?"),
                message: Text("Tất cả hình ảnh kẻ xâm nhập sẽ bị xóa và không thể khôi phục."),
                primaryButton: .destructive(Text("Xóa hết")) {
                    appLockManager.clearIntruderLogs()
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
    
    // Photo viewer sheet for intruder
    private func intruderDetailSheet(record: IntruderRecord) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Phát hiện xâm nhập!")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(AppColors.coral)
                        Text("\(record.targetAppName) • \(record.formattedTime)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button("Đóng") {
                        viewingRecord = nil
                    }
                    .foregroundColor(AppColors.cyan)
                }
                .padding(20)
                
                Spacer()
                
                if let img = VaultManager.shared.loadIntruderPhoto(fileName: record.imageFileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(16)
                        .padding(16)
                } else {
                    Text("Không thể tải hình ảnh")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    appLockManager.deleteIntruderRecord(id: record.id)
                    viewingRecord = nil
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Xóa bản ghi này")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.coral.opacity(0.8))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
