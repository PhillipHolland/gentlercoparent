import Foundation
import CloudKit

@MainActor
class ChatManager: ObservableObject {
    // Published properties for SwiftUI observation
    @Published var currentConversation: [ChatMessage]
    @Published var chatHistory: [ChatConversation]
    @Published var journalEntries: [JournalEntry]
    @Published var conversationID: UUID
    
    // Key for storing the current conversation ID
    private let currentConversationIDKey = "CurrentConversationID"
    
    // iCloud sync manager for automatic backup
    private let iCloudSync = iCloudSyncManager.shared
    
    // Enhanced conversation memory manager
    private let conversationMemory = ConversationMemoryManager()
    
    // Get conversation memory context for enhanced responses
    func getConversationMemoryContext(for query: String, userProfile: [String: Any]?) -> ConversationMemoryContext {
        return conversationMemory.getRelevantContextForQuery(query, userProfile: userProfile)
    }

    // Initializer with optional user profile
    init(userProfile: UserProfile? = nil) {
        let initialMessage = ChatManager.createInitialMessage(from: userProfile)
        self.currentConversation = [ChatMessage(sender: "Gentler Coparent", text: initialMessage, timestamp: Date())]
        self.chatHistory = []
        self.journalEntries = []
        self.conversationID = UUID()
        
        // Load existing data
        loadChatHistory()
        loadJournalEntries()
        
        // Attempt to restore from iCloud if available and local data is empty
        if chatHistory.isEmpty {
            restoreChatHistoryFromiCloud()
        }
        if journalEntries.isEmpty {
            restoreJournalEntriesFromiCloud()
        }
        
        // Get the last known conversation ID
        if let storedIDString = UserDefaults.standard.string(forKey: currentConversationIDKey),
           let storedID = UUID(uuidString: storedIDString) {
            print("On init: stored conversationID = \(storedID), chatHistory count = \(chatHistory.count)")
            
            // Check if the stored ID exists in chatHistory
            if let lastConversation = chatHistory.first(where: { $0.id == storedID }), !lastConversation.messages.isEmpty {
                self.currentConversation = lastConversation.messages
                self.conversationID = lastConversation.id
                print("Restored last saved conversation: \(lastConversation.title ?? "Untitled") with \(lastConversation.messages.count) messages")
            } else {
                // Stored ID not found in history (e.g., new chat not saved), start fresh
                self.currentConversation = [ChatMessage(sender: "Gentler Coparent", text: initialMessage, timestamp: Date())]
                self.conversationID = UUID()
                UserDefaults.standard.set(self.conversationID.uuidString, forKey: currentConversationIDKey)
                print("Stored ID \(storedID) not in history, starting fresh with: \(initialMessage)")
            }
        } else {
            // No stored ID, use initial setup
            UserDefaults.standard.set(self.conversationID.uuidString, forKey: currentConversationIDKey)
            print("No stored conversation ID, started with initial message: \(initialMessage)")
        }
    }

    // Static method to create the initial message
    private static func createInitialMessage(from profile: UserProfile?) -> String {
        guard let profile = profile, !profile.userFirstName.isEmpty else {
            return "How can I make coparenting less stressful for you and the kids today?"
        }
        let childrenInfo = profile.children.isEmpty ? "" : profile.children.map { $0.firstName }.joined(separator: " and ")
        let childName = childrenInfo.isEmpty ? "the kids" : childrenInfo
        let conflictLevel = profile.conflictLevel
        switch conflictLevel {
        case 1...3:
            return "Hi \(profile.userFirstName), let’s make coparenting a breeze for \(childName) today—how can I help?"
        case 4...6:
            return "Hi \(profile.userFirstName), how can I support you in keeping things calm for \(childName) today?"
        case 7...10:
            return "Hi \(profile.userFirstName), I’m here to help you manage coparenting for \(childName)’s sake—where should we start?"
        default:
            return "Hi \(profile.userFirstName), how can I help you with \(childName) today?"
        }
    }

    // Start a new conversation
    func startNewConversation(userProfile: UserProfile? = nil) {
        if currentConversation.count > 1 {
            // Process conversation memory before saving
            let conversationData = currentConversation
            let convId = conversationID
            Task { @MainActor in
                await conversationMemory.processConversationEnd(conversationData, conversationId: convId)
            }
            
            let userTitle = currentConversation.first(where: { $0.sender == "You" })?.text ?? "Untitled"
            let newConversation = ChatConversation(id: conversationID, title: userTitle, timestamp: Date(), messages: currentConversation, isStarred: false)
            if let index = chatHistory.firstIndex(where: { $0.id == conversationID }) {
                chatHistory[index] = newConversation // Update existing
            } else {
                chatHistory.append(newConversation) // Add new
            }
            saveChatHistory()
            print("Saved previous conversation: \(userTitle) with \(currentConversation.count) messages")
        }
        
        let initialMessage = ChatManager.createInitialMessage(from: userProfile)
        currentConversation = [ChatMessage(sender: "Gentler Coparent", text: initialMessage, timestamp: Date())]
        conversationID = UUID() // Reset ID for the new conversation
        UserDefaults.standard.set(conversationID.uuidString, forKey: currentConversationIDKey) // Store the new ID
        saveChatHistory() // Save the new initial state
        print("Started new chat with ID: \(conversationID)")
    }

    // Add a message to the current conversation
    func addMessage(_ message: ChatMessage) {
        let timestampedMessage = ChatMessage(id: message.id, sender: message.sender, text: message.text, timestamp: Date(), isStreaming: message.isStreaming)
        currentConversation.append(timestampedMessage)
        
        // Update or add to chatHistory
        let userTitle = currentConversation.first(where: { $0.sender == "You" })?.text ?? "Untitled"
        let updatedConversation = ChatConversation(id: conversationID, title: userTitle, timestamp: Date(), messages: currentConversation, isStarred: false)
        if let index = chatHistory.firstIndex(where: { $0.id == conversationID }) {
            chatHistory[index] = updatedConversation // Update existing conversation
        } else {
            chatHistory.append(updatedConversation) // Add as new if not found
        }
        saveChatHistory()
        UserDefaults.standard.set(conversationID.uuidString, forKey: currentConversationIDKey) // Update stored ID
        print("Added message and saved: \(message.text.prefix(50))... to conversation \(conversationID)")
    }
    
    // Start a streaming message (adds empty message that will be updated)
    func startStreamingMessage(sender: String) -> UUID {
        let streamingMessage = ChatMessage(sender: sender, text: "", timestamp: Date(), isStreaming: true)
        currentConversation.append(streamingMessage)
        return streamingMessage.id
    }
    
    // Append a chunk (legacy streaming path)
    func updateStreamingMessage(id: UUID, withChunk chunk: String) {
        if let index = currentConversation.firstIndex(where: { $0.id == id }) {
            currentConversation[index].text += chunk
        }
    }
    
    /// Replace streaming body in place (preferred for typewriter — avoids double-append bugs).
    func setStreamingMessageText(id: UUID, text: String) {
        if let index = currentConversation.firstIndex(where: { $0.id == id }) {
            currentConversation[index].text = text
        }
    }
    
    // Finish a streaming message (marks as complete)
    func finishStreamingMessage(id: UUID) {
        if let index = currentConversation.firstIndex(where: { $0.id == id }) {
            currentConversation[index].isStreaming = false
            
            // Save to chat history now that streaming is complete
            let userTitle = currentConversation.first(where: { $0.sender == "You" })?.text ?? "Untitled"
            let updatedConversation = ChatConversation(id: conversationID, title: userTitle, timestamp: Date(), messages: currentConversation, isStarred: false)
            if let historyIndex = chatHistory.firstIndex(where: { $0.id == conversationID }) {
                chatHistory[historyIndex] = updatedConversation
            } else {
                chatHistory.append(updatedConversation)
            }
            saveChatHistory()
        }
    }

    // Load a conversation from history
    func loadConversation(id: UUID) {
        guard let selected = chatHistory.first(where: { $0.id == id }) else { return }
        currentConversation = selected.messages
        conversationID = id // Use the loaded conversation's ID
        UserDefaults.standard.set(conversationID.uuidString, forKey: currentConversationIDKey) // Update stored ID
        print("Loaded conversation: \(selected.title ?? "Untitled") with \(selected.messages.count) messages")
    }

    // Delete a conversation
    func deleteConversation(id: UUID) {
        chatHistory.removeAll { $0.id == id }
        saveChatHistory()
        print("Deleted conversation with ID: \(id)")
    }

    // Toggle star status for a conversation
    func toggleStar(for conversationID: UUID) {
        if let index = chatHistory.firstIndex(where: { $0.id == conversationID }) {
            chatHistory[index].isStarred.toggle()
            saveChatHistory()
            print("Toggled star for conversation: \(chatHistory[index].title ?? "Untitled") - now \(chatHistory[index].isStarred ? "starred" : "unstarred")")
        }
    }

    // Add a journal entry (newest first)
    @discardableResult
    func addJournalEntry(
        text: String,
        location: JournalEntry.Location? = nil,
        title: String? = nil,
        mood: JournalMood? = nil,
        tags: [JournalTag] = [],
        attachmentFileNames: [String] = []
    ) -> JournalEntry {
        let entry = JournalEntry(
            text: text,
            location: location,
            title: title,
            mood: mood,
            tags: tags,
            attachmentFileNames: attachmentFileNames
        )
        journalEntries.insert(entry, at: 0)
        saveJournalEntries()
        return entry
    }
    
    /// Replace a full journal entry (preserves id/timestamp/star when provided via entry).
    func saveJournalEntry(_ entry: JournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
        } else {
            journalEntries.insert(entry, at: 0)
        }
        saveJournalEntries()
    }
    
    // Update an existing journal entry. When `replaceLocation` is true, `location` overwrites (including nil).
    func updateJournalEntry(
        id: UUID,
        text: String,
        location: JournalEntry.Location? = nil,
        replaceLocation: Bool = false,
        title: String? = nil,
        mood: JournalMood? = nil,
        tags: [JournalTag]? = nil,
        attachmentFileNames: [String]? = nil
    ) {
        guard let index = journalEntries.firstIndex(where: { $0.id == id }) else { return }
        let existing = journalEntries[index]
        journalEntries[index] = JournalEntry(
            id: existing.id,
            text: text,
            timestamp: existing.timestamp,
            location: replaceLocation ? location : (location ?? existing.location),
            isStarred: existing.isStarred,
            title: title ?? existing.title,
            mood: mood ?? existing.mood,
            tags: tags ?? existing.tags,
            attachmentFileNames: attachmentFileNames ?? existing.attachmentFileNames
        )
        saveJournalEntries()
    }
    
    // Delete and clean up attachment files
    func deleteJournalEntry(id: UUID) {
        if let entry = journalEntries.first(where: { $0.id == id }) {
            for name in entry.attachmentFileNames {
                JournalAttachmentStore.delete(fileName: name)
            }
        }
        journalEntries.removeAll { $0.id == id }
        saveJournalEntries()
    }

    // Toggle star status for a journal entry
    func toggleStarForJournalEntry(id: UUID) {
        if let index = journalEntries.firstIndex(where: { $0.id == id }) {
            journalEntries[index].isStarred.toggle()
            saveJournalEntries()
        }
    }

    // Save chat history to UserDefaults and sync to iCloud
    private func saveChatHistory() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(chatHistory)
            UserDefaults.standard.set(data, forKey: "chatHistory")
            print("Saved chatHistory with \(chatHistory.count) conversations")
            
            // Automatically sync to iCloud if available
            syncChatHistoryToiCloud()
        } catch {
            print("Failed to save chat history: \(error)")
        }
    }
    
    // Sync chat history to iCloud
    private func syncChatHistoryToiCloud() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available, skipping sync")
            return
        }
        
        // Convert ChatConversation to Conversation for iCloud sync
        let conversations = chatHistory.map { chatConversation in
            return Conversation(
                id: chatConversation.id,
                title: chatConversation.title ?? "Untitled",
                messages: chatConversation.messages,
                timestamp: chatConversation.timestamp
            )
        }
        
        iCloudSync.syncChatHistory(conversations) { result in
            switch result {
            case .success():
                print("✅ Chat history synced to iCloud successfully")
            case .failure(let error):
                print("❌ Failed to sync chat history to iCloud: \(error.localizedDescription)")
            }
        }
    }

    // Load chat history from UserDefaults
    private func loadChatHistory() {
        if let data = UserDefaults.standard.data(forKey: "chatHistory") {
            let decoder = JSONDecoder()
            do {
                chatHistory = try decoder.decode([ChatConversation].self, from: data)
                print("Loaded chatHistory with \(chatHistory.count) conversations")
            } catch {
                print("Failed to load chat history: \(error)")
            }
        }
    }

    // Save journal entries to UserDefaults and sync to iCloud
    private func saveJournalEntries() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(journalEntries)
            UserDefaults.standard.set(data, forKey: "journalEntries")
            
            // Automatically sync journal entries to iCloud
            syncJournalEntriesToiCloud()
        } catch {
            print("Failed to save journal entries: \(error)")
        }
    }
    
    // Sync journal entries to iCloud
    private func syncJournalEntriesToiCloud() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available, skipping journal sync")
            return
        }
        
        iCloudSync.syncJournalEntries(journalEntries) { result in
            switch result {
            case .success():
                print("✅ Journal entries synced to iCloud successfully")
            case .failure(let error):
                print("❌ Failed to sync journal entries to iCloud: \(error.localizedDescription)")
            }
        }
    }
    
    // Sync app settings to iCloud
    private func syncAppSettingsToiCloud() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available, skipping settings sync")
            return
        }
        
        iCloudSync.syncAppSettings([:] as [String: Any]) { result in
            switch result {
            case .success():
                print("✅ App settings synced to iCloud successfully")
            case .failure(let error):
                print("❌ Failed to sync app settings to iCloud: \(error.localizedDescription)")
            }
        }
    }

    // Load journal entries from UserDefaults
    private func loadJournalEntries() {
        if let data = UserDefaults.standard.data(forKey: "journalEntries") {
            let decoder = JSONDecoder()
            do {
                journalEntries = try decoder.decode([JournalEntry].self, from: data)
            } catch {
                print("Failed to load journal entries: \(error)")
            }
        }
    }
    
    // Restore chat history from iCloud
    private func restoreChatHistoryFromiCloud() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available, skipping chat history restore")
            return
        }
        
        iCloudSync.restoreChatHistory { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conversations):
                    if !isAnyEmpty(conversations) {
                        // Convert restored data back to chat history if it exists
                        if let conversationsArray = conversations as? [[String: Any]] {
                            // Parse restored conversation data
                            self.chatHistory = conversationsArray.compactMap { dict in
                                // Try to reconstruct ChatConversation from dictionary
                                guard let idString = dict["id"] as? String,
                                      let title = dict["title"] as? String,
                                      let timestamp = dict["timestamp"] as? Date else {
                                    return nil
                                }
                                
                                // Create a basic ChatConversation
                                return ChatConversation(
                                    id: UUID(uuidString: idString) ?? UUID(),
                                    title: title,
                                    timestamp: timestamp,
                                    messages: [], // Empty messages for now
                                    isStarred: false
                                )
                            }
                        } else {
                            // Fallback: create empty history
                            self.chatHistory = []
                        }
                        
                        // Save restored data locally
                        self.saveChatHistoryLocally()
                        print("✅ Restored \(self.chatHistory.count) conversations from iCloud")
                    }
                case .failure(let error):
                    print("❌ Failed to restore chat history from iCloud: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Save chat history to UserDefaults only (without triggering iCloud sync)
    private func saveChatHistoryLocally() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(chatHistory)
            UserDefaults.standard.set(data, forKey: "chatHistory")
            print("Saved chatHistory locally with \(chatHistory.count) conversations")
        } catch {
            print("Failed to save chat history locally: \(error)")
        }
    }
    
    // Restore journal entries from iCloud
    private func restoreJournalEntriesFromiCloud() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available, skipping journal entries restore")
            return
        }
        
        iCloudSync.restoreJournalEntries { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let entries):
                    if !isAnyEmpty(entries) {
                        // Convert restored data back to JournalEntry array if possible
                        if let entriesArray = entries as? [[String: Any]] {
                            self.journalEntries = entriesArray.compactMap { dict in
                                // Try to reconstruct JournalEntry from dictionary
                                guard let idString = dict["id"] as? String,
                                      let text = dict["text"] as? String,
                                      let timestamp = dict["timestamp"] as? Date else {
                                    return nil
                                }
                                
                                // Reconstruct location if available
                                var location: JournalEntry.Location?
                                if let lat = dict["latitude"] as? Double,
                                   let lng = dict["longitude"] as? Double {
                                    location = JournalEntry.Location(latitude: lat, longitude: lng)
                                }
                                
                                return JournalEntry(
                                    id: UUID(uuidString: idString) ?? UUID(),
                                    text: text,
                                    timestamp: timestamp,
                                    location: location,
                                    isStarred: dict["isStarred"] as? Bool ?? false
                                )
                            }
                        } else {
                            // Fallback: create empty journal entries
                            self.journalEntries = []
                        }
                        
                        // Save restored data locally
                        self.saveJournalEntriesLocally()
                        print("✅ Restored \(self.journalEntries.count) journal entries from iCloud")
                    }
                case .failure(let error):
                    print("❌ Failed to restore journal entries from iCloud: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Save journal entries to UserDefaults only (without triggering iCloud sync)
    private func saveJournalEntriesLocally() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(journalEntries)
            UserDefaults.standard.set(data, forKey: "journalEntries")
            print("Saved journal entries locally with \(journalEntries.count) entries")
        } catch {
            print("Failed to save journal entries locally: \(error)")
        }
    }
}
