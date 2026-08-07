import Foundation

// Simplified iCloud sync using iCloud Drive (Document-based)
class iCloudSyncManager: ObservableObject, @unchecked Sendable {
    static let shared = iCloudSyncManager()
    
    private init() {}
    
    var isiCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    private var iCloudDocumentsURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }
    
    // MARK: - Generic Data Sync
    private func syncDataToiCloud(data: Any, fileName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard isiCloudAvailable else {
            completion(.failure(SyncError.iCloudUnavailable))
            return
        }
        
        guard let iCloudURL = iCloudDocumentsURL else {
            completion(.failure(SyncError.iCloudUnavailable))
            return
        }
        
        do {
            // Create Documents directory if it doesn't exist
            try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
            
            let fileURL = iCloudURL.appendingPathComponent(fileName)
            
            // Convert data to JSON if it's not already Data
            let jsonData: Data
            if let data = data as? Data {
                jsonData = data
            } else {
                jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            }
            
            // Write to iCloud
            try jsonData.write(to: fileURL)
            
            print("✅ \(fileName) synced to iCloud successfully")
            completion(.success(()))
            
        } catch {
            print("❌ Failed to sync \(fileName) to iCloud: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
    
    private func restoreDataFromiCloud(fileName: String, completion: @escaping (Result<Data?, Error>) -> Void) {
        guard isiCloudAvailable else {
            completion(.failure(SyncError.iCloudUnavailable))
            return
        }
        
        guard let iCloudURL = iCloudDocumentsURL else {
            completion(.failure(SyncError.iCloudUnavailable))
            return
        }
        
        let fileURL = iCloudURL.appendingPathComponent(fileName)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                completion(.success(data))
            } else {
                completion(.success(nil))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - User Profile Sync
    func syncUserProfile(_ profile: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get profile data from UserDefaults
        if let profileData = UserDefaults.standard.data(forKey: "userProfile") {
            syncDataToiCloud(data: profileData, fileName: "userProfile.json", completion: completion)
        } else {
            completion(.failure(SyncError.noDataFound))
        }
    }
    
    // MARK: - Bookmarks Sync
    func syncBookmarkedMessages(_ messages: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get bookmarks data from UserDefaults
        if let bookmarksData = UserDefaults.standard.data(forKey: "bookmarkedMessages") {
            syncDataToiCloud(data: bookmarksData, fileName: "bookmarkedMessages.json", completion: completion)
        } else {
            completion(.failure(SyncError.noDataFound))
        }
    }
    
    // MARK: - Restore Functions
    func restoreUserProfile(completion: @escaping (Result<Any?, Error>) -> Void) {
        restoreDataFromiCloud(fileName: "userProfile.json") { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func restoreBookmarkedMessages(completion: @escaping (Result<Any?, Error>) -> Void) {
        restoreDataFromiCloud(fileName: "bookmarkedMessages.json") { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Chat History Sync
    func syncChatHistory(_ history: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get chat history data from UserDefaults
        if let historyData = UserDefaults.standard.data(forKey: "chatHistory") {
            syncDataToiCloud(data: historyData, fileName: "chatHistory.json", completion: completion)
        } else {
            completion(.failure(SyncError.noDataFound))
        }
    }
    
    func restoreChatHistory(completion: @escaping (Result<Any?, Error>) -> Void) {
        restoreDataFromiCloud(fileName: "chatHistory.json") { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - App Settings Sync
    func syncAppSettings(_ settings: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get app settings data from UserDefaults
        if let settingsData = UserDefaults.standard.data(forKey: "appSettings") {
            syncDataToiCloud(data: settingsData, fileName: "appSettings.json", completion: completion)
        } else {
            completion(.failure(SyncError.noDataFound))
        }
    }
    
    // MARK: - Journal Entries Sync
    func syncJournalEntries(_ entries: Any, completion: @escaping (Result<Void, Error>) -> Void) {
        // Get journal entries data from UserDefaults
        if let entriesData = UserDefaults.standard.data(forKey: "journalEntries") {
            syncDataToiCloud(data: entriesData, fileName: "journalEntries.json", completion: completion)
        } else {
            completion(.failure(SyncError.noDataFound))
        }
    }
    
    func restoreJournalEntries(completion: @escaping (Result<Any?, Error>) -> Void) {
        restoreDataFromiCloud(fileName: "journalEntries.json") { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Full Account Restore
    func performFullAccountRestore(completion: @escaping (Result<RestoreResult, Error>) -> Void) {
        restoreUserProfile { profileResult in
            switch profileResult {
            case .success(let profileData):
                self.restoreBookmarkedMessages { bookmarksResult in
                    switch bookmarksResult {
                    case .success(let bookmarksData):
                        self.restoreChatHistory { chatResult in
                            switch chatResult {
                            case .success(let chatData):
                                // Extract values before the next closure to avoid capture issues
                                let profileDataLocal = profileData
                                let bookmarksDataLocal = bookmarksData
                                let chatDataLocal = chatData
                                
                                self.restoreJournalEntries { journalResult in
                                    switch journalResult {
                                    case .success(let journalData):
                                        let journalDataLocal = journalData
                                        
                                        // Save restored data to UserDefaults
                                        if let profileData = profileDataLocal as? Data {
                                            UserDefaults.standard.set(profileData, forKey: "userProfile")
                                        }
                                        if let bookmarksData = bookmarksDataLocal as? Data {
                                            UserDefaults.standard.set(bookmarksData, forKey: "bookmarkedMessages")
                                        }
                                        
                                        // Convert chat data to conversations format
                                        let conversations: [Any] = chatDataLocal != nil ? [chatDataLocal as Any] : []
                                        
                                        // Convert journal data to entries format
                                        let journalEntries: [Any] = journalDataLocal != nil ? [journalDataLocal as Any] : []
                                        
                                        let hasData = profileDataLocal != nil || bookmarksDataLocal != nil || chatDataLocal != nil || journalDataLocal != nil
                                        
                                        let result = RestoreResult(
                                            userProfile: profileDataLocal,
                                            bookmarkedMessages: bookmarksDataLocal,
                                            conversations: conversations.isEmpty ? nil : conversations,
                                            journalEntries: journalEntries.isEmpty ? nil : journalEntries,
                                            settingsRestored: chatDataLocal != nil || journalDataLocal != nil,
                                            hasData: hasData
                                        )
                                        completion(.success(result))
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Supporting Types
enum SyncError: LocalizedError {
    case iCloudUnavailable
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "iCloud is not available. Please check your iCloud settings."
        case .noDataFound:
            return "No data found to sync."
        }
    }
}

struct RestoreResult {
    let userProfile: Any?
    let bookmarkedMessages: Any?
    let conversations: [Any]?
    let journalEntries: [Any]?
    let settingsRestored: Bool
    let hasData: Bool
    
    // Convenience initializer for backward compatibility
    init(userProfile: Any?, bookmarkedMessages: Any?, hasData: Bool) {
        self.userProfile = userProfile
        self.bookmarkedMessages = bookmarkedMessages
        self.conversations = []
        self.journalEntries = []
        self.settingsRestored = false
        self.hasData = hasData
    }
    
    // Full initializer
    init(userProfile: Any?, bookmarkedMessages: Any?, conversations: [Any]?, journalEntries: [Any]?, settingsRestored: Bool, hasData: Bool) {
        self.userProfile = userProfile
        self.bookmarkedMessages = bookmarkedMessages
        self.conversations = conversations
        self.journalEntries = journalEntries
        self.settingsRestored = settingsRestored
        self.hasData = hasData
    }
}

// Alias for compatibility
typealias AccountRestoreResult = RestoreResult

// MARK: - Helper Extensions
extension RestoreResult {
    var isEmpty: Bool {
        return !hasData
    }
    
    func encodeToUserDefaults<T: Codable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    // Safe encoding for Any type
    func safeEncodeAny(_ value: Any?, forKey key: String) {
        if let data = value as? Data {
            UserDefaults.standard.set(data, forKey: key)
        } else if let stringValue = value as? String {
            UserDefaults.standard.set(stringValue, forKey: key)
        } else if let dictValue = value as? [String: Any] {
            UserDefaults.standard.set(dictValue, forKey: key)
        } else if let arrayValue = value as? [Any] {
            UserDefaults.standard.set(arrayValue, forKey: key)
        }
    }
    
    // Safe count for Any array
    var conversationsCount: Int {
        if let conversations = conversations {
            return getAnyArrayCount(conversations)
        }
        return 0
    }
    
    // Safe count for journal entries
    var journalEntriesCount: Int {
        if let entries = journalEntries {
            return getAnyArrayCount(entries)
        }
        return 0
    }
    
    // Safe isEmpty check for Any
    var conversationsIsEmpty: Bool {
        if let conversations = conversations {
            return isEmptyAnyArray(conversations)
        }
        return true
    }
    
    var journalEntriesIsEmpty: Bool {
        if let entries = journalEntries {
            return isEmptyAnyArray(entries)
        }
        return true
    }
}

// Helper to safely check if Any array is empty
func isEmptyAnyArray(_ array: Any?) -> Bool {
    if let array = array as? [Any] {
        return array.isEmpty
    }
    return array == nil
}

// Helper to safely get count from Any array
func getAnyArrayCount(_ array: Any?) -> Int {
    if let array = array as? [Any] {
        return array.count
    }
    return 0
}

// Helper to safely check isEmpty for Any
func isAnyEmpty(_ value: Any?) -> Bool {
    if value == nil { return true }
    if let string = value as? String { return string.isEmpty }
    if let array = value as? [Any] { return array.isEmpty }
    if let dict = value as? [String: Any] { return dict.isEmpty }
    return false
}