import Foundation

public struct IntruderRecord: Identifiable, Codable {
    public let id: String
    public let timestamp: Date
    public let targetAppName: String
    public let imageFileName: String
    public let attemptCount: Int
    
    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        targetAppName: String,
        imageFileName: String,
        attemptCount: Int = 1
    ) {
        self.id = id
        self.timestamp = timestamp
        self.targetAppName = targetAppName
        self.imageFileName = imageFileName
        self.attemptCount = attemptCount
    }
    
    public var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: timestamp)
    }
}
