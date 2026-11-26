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
    
    // Photo / Video pickers triggered from bottom-right '+' FAB
    @State private var selectedPhotosPickerItem: PhotosPickerItem? = nil
    @State private var selectedVideosPickerItem: PhotosPickerItem? = nil
    
    // Media viewer & Note editor
    @State private var viewingItem: VaultItem? = nil
    @State private var editingNote: SecretNote? = nil
    @State private var isCreatingNote: Bool = false
    
    public init() {}
    
    var photosList: [VaultItem] {
        appLockManager.vaultItems.filter { $0.fileType == .photo }
    }
    
    var videosList: [VaultItem] {
        appLockManager.vaultItems.filter { $0.fileType == .video }
    }
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Category Bar matching video (Ảnh bí mật | Video riêng | Ghi chú khóa)
                HStack(spacing: 0) {
                    ForEach(VaultTab.allCases, id: \.self) { tab in
                        let isSelected = selectedTab == tab
                        Button(action: {
                            selectedTab = tab
                            if appLockManager.isVibrationEnabled {
                                HapticManager.shared.selection()
                            }
                        }) {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? AppColors.cyan : Color.clear)
                                )
                                .foregroundColor(isSelected ? AppColors.background : AppColors.textSecondary)
                        }
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(AppColors.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(AppColors.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)
                
                // Tab Content
                switch selectedTab {
                case .photos:
                    photosGridView
                case .videos:
                    videosGridView
                case .notes:
                    notesListView
                }
            }
            
            // Floating '+' Action Button at bottom-right matching video (00:10 - 00:16)
            vaultFloatingAddButton
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .onChange(of: appLockManager.modalDismissToken) { _ in
            viewingItem = nil
            editingNote = nil
            isCreatingNote = false
        }
        .sheet(item: $viewingItem) { item in
            MediaDetailView(item: item) {
                appLockManager.deleteVaultItem(item)
            }
        }
        .sheet(item: $editingNote) { note in
            NoteEditorSheet(existingNote: note) { updatedNote in
                appLockManager.saveSecretNote(updatedNote)
                appLockManager.showToast("Đã cập nhật ghi chú bí mật!")
            }
        }
        .sheet(isPresented: $isCreatingNote) {
            NoteEditorSheet { newNote in
                appLockManager.saveSecretNote(newNote)
                appLockManager.showToast("Đã lưu ghi chú khóa an toàn!")
            }
        }
        .onChange(of: selectedPhotosPickerItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let savedItem = try? VaultManager.shared.savePhoto(data: data) {
                    await MainActor.run {
                        appLockManager.addVaultItem(savedItem)
                        appLockManager.showToast("Đã thêm vào Két bí mật an toàn!")
                    }
                }
                await MainActor.run { selectedPhotosPickerItem = nil }
            }
        }
        .onChange(of: selectedVideosPickerItem) { newItem in
            guard let newItem = newItem else { return }
            Task {
                if let movie = try? await newItem.loadTransferable(type: MovieFileTransferable.self),
                   let savedItem = try? VaultManager.shared.saveVideo(from: movie.url) {
                    await MainActor.run {
                        appLockManager.addVaultItem(savedItem)
                        appLockManager.showToast("Đã thêm vào Két bí mật an toàn!")
                    }
                }
                await MainActor.run { selectedVideosPickerItem = nil }
            }
        }
    }
    
    @ViewBuilder
    private var vaultFloatingAddButton: some View {
        switch selectedTab {
        case .photos:
            PhotosPicker(selection: $selectedPhotosPickerItem, matching: .images) {
                fabLabel
            }
        case .videos:
            PhotosPicker(selection: $selectedVideosPickerItem, matching: .videos) {
                fabLabel
            }
        case .notes:
            Button(action: { isCreatingNote = true }) {
                fabLabel
            }
        }
    }
    
    private var fabLabel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.cyan)
                .frame(width: 56, height: 56)
                .shadow(color: AppColors.cyan.opacity(0.45), radius: 8, x: 0, y: 4)
            
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.background)
        }
    }
    
    // Sub-tab 1: Photos 3-column grid
    private var photosGridView: some View {
        Group {
            if photosList.isEmpty {
                Spacer()
                Text("Chưa có ảnh nào được ẩn.\nNhấn nút + để bảo vệ ảnh của bạn.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(photosList) { item in
                            Button(action: { viewingItem = item }) {
                                AsyncThumbnailView(fileName: item.fileName, type: .photo, cornerRadius: 10, height: 112)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 84)
                }
            }
        }
    }
    
    // Sub-tab 2: Videos 3-column grid matching video (00:15)
    private var videosGridView: some View {
        Group {
            if videosList.isEmpty {
                Spacer()
                Text("Chưa có video nào trong két.\nNhấn nút + để bảo vệ video riêng tư.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(videosList) { item in
                            Button(action: { viewingItem = item }) {
                                ZStack {
                                    AsyncThumbnailView(fileName: item.fileName, type: .video, cornerRadius: 10, height: 112)
                                    
                                    Circle()
                                        .fill(Color.black.opacity(0.55))
                                        .frame(width: 34, height: 34)
                                    
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppColors.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 84)
                }
            }
        }
    }
    
    // Sub-tab 3: Secret Notes list matching video (00:16)
    private var notesListView: some View {
        Group {
            if appLockManager.secretNotes.isEmpty {
                Spacer()
                Text("Chưa có ghi chú nào được lưu.\nNhấn nút + để tạo ghi chú bí mật.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(appLockManager.secretNotes) { note in
                            Button(action: { editingNote = note }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(note.title.isEmpty ? "Ghi chú không tên" : note.title)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(AppColors.textPrimary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            appLockManager.deleteSecretNote(id: note.id)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(AppColors.textMuted)
                                        }
                                    }
                                    
                                    Text(note.content)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text("Cập nhật: \(formattedNoteDate(note.updatedAt))")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColors.cyan)
                                        .padding(.top, 2)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .padding(.bottom, 84)
                }
            }
        }
    }
    
    private func formattedNoteDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        return formatter.string(from: date)
    }
}

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
