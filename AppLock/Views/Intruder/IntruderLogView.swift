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
                // Settings Card matching video (00:17 & 01:03)
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Tự động chụp ảnh kẻ gian")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Chụp ảnh bí mật bằng camera trước khi mở khóa sai")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $appLockManager.isIntruderSelfieEnabled)
                            .labelsHidden()
                            .tint(AppColors.cyan)
                            .onChange(of: appLockManager.isIntruderSelfieEnabled) { enabled in
                                appLockManager.saveSettings()
                                if enabled {
                                    Task { _ = await CameraManager.shared.requestCameraPermission() }
                                }
                            }
                    }
                    
                    Rectangle()
                        .fill(AppColors.cardBorder)
                        .frame(height: 1)
                    
                    HStack {
                        Menu {
                            Button("1 lần sai") {
                                appLockManager.intruderThreshold = 1
                                appLockManager.saveSettings()
                            }
                            Button("2 lần sai (Mặc định)") {
                                appLockManager.intruderThreshold = 2
                                appLockManager.saveSettings()
                            }
                            Button("3 lần sai") {
                                appLockManager.intruderThreshold = 3
                                appLockManager.saveSettings()
                            }
                        } label: {
                            Text("Số lần nhập sai để kích hoạt: \(appLockManager.intruderThreshold) lần")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if !appLockManager.intruderRecords.isEmpty {
                                showingClearAlert = true
                            }
                        }) {
                            Text("Xóa toàn bộ lịch sử")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColors.coral)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(16)
                
                // Logs List or Empty State
                if appLockManager.intruderRecords.isEmpty {
                    Spacer()
                    Text("Chưa phát hiện kẻ xâm nhập nào.\nThiết bị của bạn đang an toàn tuyệt đối!")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(appLockManager.intruderRecords) { record in
                                Button(action: { viewingRecord = record }) {
                                    HStack(spacing: 14) {
                                        // Circular Intruder Selfie matching video (01:03 - 01:04)
                                        AsyncThumbnailView(fileName: record.imageFileName, type: .intruder, cornerRadius: 27, height: 54)
                                            .frame(width: 54, height: 54)
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Cố gắng mở \(record.targetAppName)")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(AppColors.textPrimary)
                                                .lineLimit(1)
                                            
                                            Text(record.formattedTime)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(AppColors.cyan)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            appLockManager.deleteIntruderRecord(id: record.id)
                                        }) {
                                            ZStack {
                                                Circle()
                                                    .fill(AppColors.cardHighlight)
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppColors.cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .sheet(item: $viewingRecord) { record in
            intruderDetailSheet(record: record)
        }
        .alert("Xóa toàn bộ lịch sử?", isPresented: $showingClearAlert) {
            Button("Xóa hết", role: .destructive) {
                appLockManager.clearIntruderLogs()
                appLockManager.showToast("Đã xóa toàn bộ lịch sử xâm nhập")
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Tất cả hình ảnh kẻ xâm nhập sẽ bị xóa vĩnh viễn.")
        }
    }
    
    private func intruderDetailSheet(record: IntruderRecord) -> some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: 18) {
                HStack {
                    Text("Cố gắng mở \(record.targetAppName)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("Đóng") { viewingRecord = nil }
                        .foregroundColor(AppColors.cyan)
                }
                .padding(.top, 20)
                
                if let img = VaultManager.shared.loadIntruderPhoto(fileName: record.imageFileName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 420)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                }
                
                Text("Thời gian: \(record.formattedTime) • Sai \(record.attemptCount) lần")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.cyan)
                
                Button(role: .destructive) {
                    appLockManager.deleteIntruderRecord(id: record.id)
                    viewingRecord = nil
                } label: {
                    Text("Xóa bản ghi này")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.coral)
                        .padding(.vertical, 10)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}
