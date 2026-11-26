import SwiftUI
import PhotosUI

public struct VaultView: View {
    @ObservedObject var appLockManager = AppLockManager.shared
    
    enum VaultTab: String, CaseIterable {
        case photos = "Ảnh bí mật"
        case videos = "Video riêng"
        case notes = "Ghi chú khóa"
    }
    
    @State private var selectedTab: VaultTab = .photos
    
    // Photo picker states
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @State private var selectedVideosPickerItem: PhotosPickerItem? = nil
    
    // Media viewer sheet
    @State private var viewingItem: VaultItem? = nil
    
    // Note editor sheet
    @State private var editingNote: SecretNote? = nil
    @State private var isCreatingNote: Bool = false
    
    public init() {}
    
    var photosList: [VaultItem] {
        appLockManager.vaultItems.filter { $0.fileType == .photo }
    }
    
    var videosList: [VaultItem] {
        appLockManager.vaultItems.filter { $0.fileType == .video }
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CyberHeader(
                    title: "Két Riêng Tư",
                    subtitle: "Mã hóa & ẩn ảnh, video, ghi chú cá nhân an toàn",
                    badgeText: "\(appLockManager.vaultItems.count + appLockManager.secretNotes.count) mục",
                    badgeColor: AppColors.cyan
                )
                
                // Sub-tabs segment
                HStack(spacing: 8) {
                    ForEach(VaultTab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab
                        Button(action: {
                            selectedTab = tab
                            HapticManager.shared.selection()
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSelected ? AppColors.cyan : AppColors.cardBackground)
                                )
                                .foregroundColor(isSelected ? .black : AppColors.textSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? AppColors.cyan : AppColors.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // Content Views
                switch selectedTab {
                case .photos:
                    photosGridView
                case .videos:
                    videosGridView
                case .notes:
                    notesListView
                }
            }
        }
        .sheet(item: $viewingItem) { item in
            MediaDetailView(item: item) {
                appLockManager.deleteVaultItem(item)
            }
        }
        .sheet(item: $editingNote) { note in
            NoteEditorSheet(existingNote: note) { updatedNote in
                appLockManager.saveSecretNote(updatedNote)
            }
        }
        .sheet(isPresented: $isCreatingNote) {
            NoteEditorSheet { newNote in
                appLockManager.saveSecretNote(newNote)
            }
        }
        .onChange(of: selectedPhotosPickerItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    if let savedItem = try? VaultManager.shared.savePhoto(data: data) {
                        await MainActor.run {
                            appLockManager.addVaultItem(savedItem)
                            HapticManager.shared.notification(.success)
                        }
                    }
                }
                selectedPhotosPickerItem = nil
            }
        }
        .onChange(of: selectedVideosPickerItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let movie = try? await newItem.loadTransferable(type: MovieFileTransferable.self) {
                    if let savedItem = try? VaultManager.shared.saveVideo(from: movie.url) {
                        await MainActor.run {
                            appLockManager.addVaultItem(savedItem)
                            HapticManager.shared.notification(.success)
                        }
                    }
                }
                selectedVideosPickerItem = nil
            }
        }
    }
    
    // Sub-tab 1: Photos Grid
    private var photosGridView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Action row
                PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm ảnh vào Két bảo mật")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.cyan)
                    .cornerRadius(12)
                    .shadow(color: AppColors.cyan.opacity(0.3), radius: 6)
                }
                .padding(.horizontal, 20)
                
                if photosList.isEmpty {
                    emptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "Chưa có ảnh nào được ẩn",
                        description: "Nhấn nút 'Thêm ảnh vào Két bảo mật' để lưu trữ hình ảnh riêng tư vào vùng an toàn."
                    )
                } else {
                    let columns = [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(photosList) { item in
                            Button(action: {
                                viewingItem = item
                            }) {
                                AsyncThumbnailView(fileName: item.fileName, type: .photo, cornerRadius: 12, height: 110)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
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
    
    // Sub-tab 2: Videos Grid
    private var videosGridView: some View {
        ScrollView {
            VStack(spacing: 16) {
                PhotosPicker(selection: $selectedVideosPickerItem, matching: .videos) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm video vào Két bảo mật")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.emerald)
                    .cornerRadius(12)
                    .shadow(color: AppColors.emerald.opacity(0.3), radius: 6)
                }
                .padding(.horizontal, 20)
                
                if videosList.isEmpty {
                    emptyStateView(
                        icon: "video.slash",
                        title: "Chưa có video riêng tư nào",
                        description: "Ẩn các video nhạy cảm khỏi Thư viện ảnh để đảm bảo không ai khác nhìn thấy."
                    )
                } else {
                    let columns = [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(videosList) { item in
                            Button(action: {
                                viewingItem = item
                            }) {
                                ZStack(alignment: .bottomLeading) {
                                    AsyncThumbnailView(fileName: item.fileName, type: .video, cornerRadius: 12, height: 130)
                                    
                                    // Play icon overlay
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color.white.opacity(0.9))
                                        .shadow(radius: 4)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    
                                    // Duration badge
                                    HStack {
                                        Image(systemName: "video.fill")
                                            .font(.system(size: 9))
                                        Text(item.formattedSize)
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                    .padding(8)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
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
    
    // Sub-tab 3: Notes List
    private var notesListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button(action: {
                    isCreatingNote = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Tạo ghi chú bảo mật mới")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.purple)
                    .cornerRadius(12)
                    .shadow(color: AppColors.purple.opacity(0.3), radius: 6)
                }
                .padding(.horizontal, 20)
                
                if appLockManager.secretNotes.isEmpty {
                    emptyStateView(
                        icon: "note.text.badge.plus",
                        title: "Chưa có ghi chú nào",
                        description: "Lưu trữ thông tin bí mật như mã thẻ ngân hàng, tài khoản hoặc ghi chép mật."
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(appLockManager.secretNotes) { note in
                            GlassCard(cornerRadius: 14) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        if note.isPinned {
                                            Image(systemName: "pin.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppColors.amber)
                                        }
                                        
                                        Text(note.title)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text(note.formattedDate)
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    
                                    Text(note.content)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(2)
                                }
                                .padding(16)
                            }
                            .onTapGesture {
                                editingNote = note
                            }
                            .contextMenu {
                                Button(action: {
                                    var updated = note
                                    updated.isPinned.toggle()
                                    appLockManager.saveSecretNote(updated)
                                }) {
                                    Label(note.isPinned ? "Bỏ ghim" : "Ghim lên đầu", systemImage: "pin")
                                }
                                
                                Button(role: .destructive, action: {
                                    appLockManager.deleteSecretNote(id: note.id)
                                }) {
                                    Label("Xóa ghi chú", systemImage: "trash")
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
    
    private func emptyStateView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.cardBackground)
                    .frame(width: 76, height: 76)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 40)
            
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
            
            Text(description)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
    }
}

// Transferable wrapper for video import
struct MovieFileTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory.appendingPathComponent(received.file.lastPathComponent)
            try? FileManager.default.removeItem(at: copy)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}
