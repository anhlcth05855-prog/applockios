import Foundation

public struct SecretNote: Identifiable, Codable {
    public let id: String
    public var title: String
    public var content: String
    public var updatedAt: Date
    public var isPinned: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        updatedAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.updatedAt = updatedAt
        self.isPinned = isPinned
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: updatedAt)
    }
}
