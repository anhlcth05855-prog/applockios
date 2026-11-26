import SwiftUI

public enum ThumbnailSourceType {
    case photo
    case video
    case intruder
}

public struct AsyncThumbnailView: View {
    let fileName: String
    let type: ThumbnailSourceType
    var cornerRadius: CGFloat = 12
    var height: CGFloat = 110
    
    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    
    public init(fileName: String, type: ThumbnailSourceType, cornerRadius: CGFloat = 12, height: CGFloat = 110) {
        self.fileName = fileName
        self.type = type
        self.cornerRadius = cornerRadius
        self.height = height
    }
    
    public var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipped()
                    .cornerRadius(cornerRadius)
            } else {
                Rectangle()
                    .fill(AppColors.cardBackground)
                    .frame(height: height)
                    .cornerRadius(cornerRadius)
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppColors.cyan))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: placeholderIcon)
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.textSecondary.opacity(0.5))
                            }
                        }
                    )
            }
        }
        .task(id: fileName) {
            await loadThumbnail()
        }
    }
    
    private var placeholderIcon: String {
        switch type {
        case .photo: return "photo"
        case .video: return "video"
        case .intruder: return "person.crop.rectangle"
        }
    }
    
    private func loadThumbnail() async {
        switch type {
        case .photo:
            let loaded = await VaultManager.shared.loadPhotoThumbnailAsync(fileName: fileName)
            await MainActor.run {
                self.image = loaded
                self.isLoading = false
            }
        case .video:
            let loaded = await VaultManager.shared.loadVideoThumbnailAsync(fileName: fileName)
            await MainActor.run {
                self.image = loaded
                self.isLoading = false
            }
        case .intruder:
            let loaded = await VaultManager.shared.loadIntruderPhotoAsync(fileName: fileName)
            await MainActor.run {
                self.image = loaded
                self.isLoading = false
            }
        }
    }
}
