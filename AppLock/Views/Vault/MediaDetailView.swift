import SwiftUI
import AVKit

public struct MediaDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let item: VaultItem
    var onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var exportSuccess = false
    @State private var showingExportAlert = false
    @State private var isExporting = false
    @State private var player: AVPlayer?
    
    public init(item: VaultItem, onDelete: @escaping () -> Void) {
        self.item = item
        self.onDelete = onDelete
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.originalName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("\(item.formattedDate) • \(item.formattedSize)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // Export button
                    Button(action: exportMedia) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.cyan)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                    .disabled(isExporting)
                    
                    // Delete button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.coral)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.15)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                
                // Content (Image or Video)
                if item.fileType == .photo {
                    if let image = VaultManager.shared.loadPhoto(fileName: item.fileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(AppColors.coral)
                            Text("Không thể tải hình ảnh")
                                .foregroundColor(.white)
                        }
                    }
                } else {
                    // Video Player
                    if let player = player {
                        VideoPlayer(player: player)
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        ProgressView()
                            .tint(AppColors.cyan)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            if item.fileType == .video {
                let videoURL = VaultManager.shared.videosURL.appendingPathComponent(item.fileName)
                self.player = AVPlayer(url: videoURL)
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Xóa tệp khỏi Két?"),
                message: Text("Tệp này sẽ bị xóa vĩnh viễn khỏi thiết bị và không thể khôi phục."),
                primaryButton: .destructive(Text("Xóa vĩnh viễn")) {
                    onDelete()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
        .alert(isPresented: $showingExportAlert) {
            Alert(
                title: Text(exportSuccess ? "Khôi phục thành công" : "Khôi phục thất bại"),
                message: Text(exportSuccess ? "Tệp đã được lưu lại vào Thư viện Ảnh của iPhone." : "Vui lòng cấp quyền truy cập Thư viện ảnh trong Cài đặt."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func exportMedia() {
        isExporting = true
        Task {
            let success: Bool
            if item.fileType == .photo {
                success = await VaultManager.shared.exportPhotoToLibrary(fileName: item.fileName)
            } else {
                success = await VaultManager.shared.exportVideoToLibrary(fileName: item.fileName)
            }
            
            await MainActor.run {
                self.exportSuccess = success
                self.isExporting = false
                self.showingExportAlert = true
                if success {
                    HapticManager.shared.notification(.success)
                } else {
                    HapticManager.shared.notification(.error)
                }
            }
        }
    }
}
