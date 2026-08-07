import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct UserProfile: Codable {
    var userFirstName: String
    var userLastName: String
    var coparentFirstName: String
    var coparentLastName: String
    var children: [Child]
    var stateOfResidence: String
    var country: String
    var conflictLevel: Int
    var possessionSchedule: String?
    var divorceDecreeURL: URL?
    var divorceDecreeBookmark: Data? // Security-scoped bookmark for persistent access
    var divorceDecreeText: String?
    var setupDate: Date?
    
    // Convert to dictionary for API / memory context.
    // IMPORTANT: values must be JSON-serializable (no Date / URL objects).
    // Raw Date caused: NSInvalidArgumentException Invalid type in JSON write (__NSTaggedDate).
    func toDictionary() -> [String: Any] {
        let iso = ISO8601DateFormatter()
        var dict: [String: Any] = [
            "userFirstName": userFirstName,
            "userLastName": userLastName,
            "coparentFirstName": coparentFirstName,
            "coparentLastName": coparentLastName,
            "childrenCount": children.count,
            "stateOfResidence": stateOfResidence,
            "country": country,
            "conflictLevel": conflictLevel,
            "possessionSchedule": possessionSchedule ?? "",
            "hasDecreeText": divorceDecreeText != nil && !(divorceDecreeText?.isEmpty ?? true)
        ]
        if let setupDate {
            dict["setupDate"] = iso.string(from: setupDate)
        }
        // Structured children for server personalization
        dict["children"] = children.map { child -> [String: Any] in
            [
                "firstName": child.firstName,
                "lastName": child.lastName,
                "gender": child.gender,
                "age": child.age
            ]
        }
        // Decree excerpt for server prompt (not full upload to knowledge base — privacy + size)
        // Larger than before so multi-page terms still reach the model when client storage fails
        if let text = divorceDecreeText, !text.isEmpty {
            dict["decreeExcerpt"] = String(text.prefix(5000))
            dict["decreeCharCount"] = text.count
        }
        return dict
    }

    struct Child: Codable, Identifiable, Equatable {
        let id: UUID
        var firstName: String
        var lastName: String
        var birthday: DateComponents
        var gender: String
        var age: Int { calculateAge() }

        init(id: UUID = UUID(), firstName: String = "", lastName: String = "", birthday: DateComponents, gender: String = "Rather not say") {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.birthday = birthday
            self.gender = gender
        }

        private func calculateAge() -> Int {
            guard let birthDate = Calendar.current.date(from: birthday),
                  let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year else {
                return 0
            }
            return age
        }
        
        // Equatable conformance
        static func == (lhs: Child, rhs: Child) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.firstName == rhs.firstName &&
                   lhs.lastName == rhs.lastName &&
                   lhs.birthday.year == rhs.birthday.year &&
                   lhs.birthday.month == rhs.birthday.month &&
                   lhs.birthday.day == rhs.birthday.day &&
                   lhs.gender == rhs.gender
        }
    }
}

struct ChatConversation: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String?
    let timestamp: Date
    var messages: [ChatMessage]
    var isStarred: Bool

    init(id: UUID, title: String?, timestamp: Date, messages: [ChatMessage], isStarred: Bool = false) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.messages = messages
        self.isStarred = isStarred
    }

    static func == (lhs: ChatConversation, rhs: ChatConversation) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let sender: String
    var text: String // Changed to var for streaming updates
    let timestamp: Date
    var isStreaming: Bool = false // New property for streaming state

    init(id: UUID = UUID(), sender: String, text: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    enum CodingKeys: String, CodingKey {
        case id
        case sender
        case text
        case timestamp
        // Note: isStreaming is not saved to avoid persistence issues
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.sender == rhs.sender && lhs.text == rhs.text
            && lhs.timestamp == rhs.timestamp && lhs.isStreaming == rhs.isStreaming
    }
}

// Simplified Conversation model for iCloud sync (without isStarred)
struct Conversation: Codable, Identifiable {
    let id: UUID
    let title: String
    let messages: [ChatMessage]
    let timestamp: Date
    
    init(id: UUID, title: String, messages: [ChatMessage], timestamp: Date) {
        self.id = id
        self.title = title
        self.messages = messages
        self.timestamp = timestamp
    }
}

// MARK: - Journal mood (optional, for co-parenting check-ins)
enum JournalMood: String, Codable, CaseIterable, Identifiable {
    case calm, hopeful, grateful, stressed, frustrated, sad, anxious, proud, overwhelmed, neutral
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .calm: return "🌿"
        case .hopeful: return "✨"
        case .grateful: return "💛"
        case .stressed: return "😮‍💨"
        case .frustrated: return "😤"
        case .sad: return "💙"
        case .anxious: return "🌊"
        case .proud: return "🌟"
        case .overwhelmed: return "🌀"
        case .neutral: return "☁️"
        }
    }
    
    var label: String {
        rawValue.capitalized
    }
}

// MARK: - Co-parenting journal tags
enum JournalTag: String, Codable, CaseIterable, Identifiable {
    case kids, exchange, school, medical, money, court, boundary, communication, selfCare, gratitude, incident
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .kids: return "Kids"
        case .exchange: return "Exchange"
        case .school: return "School"
        case .medical: return "Medical"
        case .money: return "Money"
        case .court: return "Court / legal"
        case .boundary: return "Boundary"
        case .communication: return "Communication"
        case .selfCare: return "Self-care"
        case .gratitude: return "Gratitude"
        case .incident: return "Incident log"
        }
    }
    
    var icon: String {
        switch self {
        case .kids: return "figure.and.child.holdinghands"
        case .exchange: return "arrow.left.arrow.right"
        case .school: return "graduationcap"
        case .medical: return "cross.case"
        case .money: return "dollarsign.circle"
        case .court: return "building.columns"
        case .boundary: return "hand.raised"
        case .communication: return "bubble.left.and.bubble.right"
        case .selfCare: return "heart"
        case .gratitude: return "sun.max"
        case .incident: return "exclamationmark.shield"
        }
    }
}

struct JournalEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    let timestamp: Date
    var location: Location?
    var isStarred: Bool
    /// Optional short headline shown on cards
    var title: String?
    var mood: JournalMood?
    var tags: [JournalTag]
    /// Filenames under Documents/JournalAttachments/
    var attachmentFileNames: [String]

    struct Location: Codable, Equatable {
        let latitude: Double
        let longitude: Double
    }

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        location: Location? = nil,
        isStarred: Bool = false,
        title: String? = nil,
        mood: JournalMood? = nil,
        tags: [JournalTag] = [],
        attachmentFileNames: [String] = []
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.location = location
        self.isStarred = isStarred
        self.title = title
        self.mood = mood
        self.tags = tags
        self.attachmentFileNames = attachmentFileNames
    }
    
    // Backward-compatible decode for older entries missing new keys
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        location = try c.decodeIfPresent(Location.self, forKey: .location)
        isStarred = try c.decodeIfPresent(Bool.self, forKey: .isStarred) ?? false
        title = try c.decodeIfPresent(String.self, forKey: .title)
        mood = try c.decodeIfPresent(JournalMood.self, forKey: .mood)
        tags = try c.decodeIfPresent([JournalTag].self, forKey: .tags) ?? []
        attachmentFileNames = try c.decodeIfPresent([String].self, forKey: .attachmentFileNames) ?? []
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text, timestamp, location, isStarred, title, mood, tags, attachmentFileNames
    }
}

// MARK: - On-disk journal photo storage
enum JournalAttachmentStore {
    static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("JournalAttachments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }
    
    #if canImport(UIKit)
    static func saveImage(_ image: UIImage, preferredName: String? = nil) -> String? {
        let name = preferredName ?? "\(UUID().uuidString).jpg"
        let url = url(for: name)
        guard let data = image.jpegData(compressionQuality: 0.82) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }
    
    static func loadImage(fileName: String) -> UIImage? {
        let url = url(for: fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    #endif
    
    static func delete(fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }
}

struct ConversationAnalysis: Codable {
    let sender: String
    let recipient: String
    let messageType: MessageType
    let extractedText: String
    let suggestedResponse: String
    
    enum MessageType: String, Codable {
        case childRelated = "child_related"
        case scheduling = "scheduling"
        case financial = "financial"
        case other = "other"
    }
    
    init(sender: String, recipient: String, messageType: MessageType, extractedText: String, suggestedResponse: String) {
        self.sender = sender
        self.recipient = recipient
        self.messageType = messageType
        self.extractedText = extractedText
        self.suggestedResponse = suggestedResponse
    }
}

