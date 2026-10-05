import Foundation

public enum VaultMediaType: String, Codable {
    case photo = "photo"
    case video = "video"
}

public struct VaultItem: Identifiable, Codable {
    public let id: String
    public let fileName: String
    public let originalName: String
    public let fileType: VaultMediaType
    public let dateAdded: Date
    public let fileSize: Int64
    public var duration: Double? // For videos
    
    public init(
        id: String = UUID().uuidString,
        fileName: String,
        originalName: String,
        fileType: VaultMediaType,
        dateAdded: Date = Date(),
        fileSize: Int64,
        duration: Double? = nil
    ) {
        self.id = id
        self.fileName = fileName
        self.originalName = originalName
        self.fileType = fileType
        self.dateAdded = dateAdded
        self.fileSize = fileSize
        self.duration = duration
    }
    
    public var formattedSize: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB, .useKB, .useBytes]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: fileSize)
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: dateAdded)
    }
}
