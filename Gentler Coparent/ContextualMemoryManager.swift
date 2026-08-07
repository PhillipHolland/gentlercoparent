import Foundation
import CloudKit

// MARK: - Contextual Memory System
// Learns and remembers important details about the user's co-parenting situation
// Uses on-device processing for privacy and syncs with iCloud for continuity

@MainActor
class ContextualMemoryManager: ObservableObject {
    
    // MARK: - Memory Types
    enum MemoryCategory: String, CaseIterable, Codable {
        case familyDynamics = "family_dynamics"
        case schedulePatterns = "schedule_patterns"
        case communicationStyle = "communication_style"
        case conflictTriggers = "conflict_triggers"
        case childBehavior = "child_behavior"
        case legalMatters = "legal_matters"
        case financialArrangements = "financial_arrangements"
        case emergencyContacts = "emergency_contacts"
        case preferences = "preferences"
        case successfulStrategies = "successful_strategies"
    }
    
    struct Memory: Identifiable {
        let id: String
        let category: MemoryCategory
        var content: String
        var confidence: Double // 0.0 to 1.0
        let createdAt: Date
        var lastUpdated: Date
        let source: MemorySource
        let importance: MemoryImportance
        var isActive: Bool // Can be disabled without deletion
        
        enum MemorySource: String, Codable {
            case conversation = "conversation"
            case userProfile = "user_profile"
            case documentAnalysis = "document_analysis"
            case inferredPattern = "inferred_pattern"
        }
        
        enum MemoryImportance: String, Codable {
            case critical = "critical"     // Core family info (names, ages, etc.)
            case important = "important"   // Patterns, preferences, triggers
            case helpful = "helpful"       // Context that improves responses
            case minor = "minor"          // Nice-to-know details
        }
        
        init(category: MemoryCategory, content: String, confidence: Double, source: MemorySource, importance: MemoryImportance) {
            self.id = UUID().uuidString
            self.category = category
            self.content = content
            self.confidence = confidence
            self.createdAt = Date()
            self.lastUpdated = Date()
            self.source = source
            self.importance = importance
            self.isActive = true
        }
    }
    
    // MARK: - Properties
    /// Uses the app’s single entitlements-aligned container (NOT a separate unregistered ID).
    private var container: CKContainer { GCPCloudKit.container }
    private var database: CKDatabase { GCPCloudKit.privateDatabase }
    private var memories: [String: Memory] = [:]
    private let memoryLimit = 1000 // Maximum memories to store
    private var isCloudKitAvailable = false
    
    // MARK: - Initialization
    init() {
        Task {
            let result = await GCPCloudKit.resolveAvailability()
            self.isCloudKitAvailable = result.available
            if result.available {
                print("☁️ \(result.reason) — contextual memory")
            } else {
                print("⚠️ \(result.reason) — contextual memory local-only")
            }
            await loadMemories()
        }
    }
    
    // MARK: - Memory Management
    func addMemory(category: MemoryCategory, content: String, confidence: Double = 0.8, source: Memory.MemorySource, importance: Memory.MemoryImportance) async {
        // Check for duplicate or conflicting memories
        let existingMemories = getMemories(for: category)
        
        // Look for similar content to avoid duplicates
        let similarMemory = existingMemories.first { memory in
            calculateSimilarity(content, memory.content) > 0.85
        }
        
        if let similar = similarMemory {
            // Update existing memory with higher confidence
            await updateMemory(similar.id, content: content, confidence: max(confidence, similar.confidence))
            return
        }
        
        let memory = Memory(
            category: category,
            content: content,
            confidence: confidence,
            source: source,
            importance: importance
        )
        
        memories[memory.id] = memory
        await saveToCloud(memory)
        
        // Clean up old memories if we exceed the limit
        await cleanupOldMemories()
        
        print("🧠 Added memory: [\(category.rawValue)] \(content)")
    }
    
    func updateMemory(_ memoryId: String, content: String? = nil, confidence: Double? = nil) async {
        guard var memory = memories[memoryId] else { return }
        
        if let content = content {
            memory.content = content
        }
        if let confidence = confidence {
            memory.confidence = confidence
        }
        memory.lastUpdated = Date()
        
        memories[memoryId] = memory
        await saveToCloud(memory)
    }
    
    func getMemories(for category: MemoryCategory? = nil, importance: Memory.MemoryImportance? = nil) -> [Memory] {
        var filtered = Array(memories.values).filter { $0.isActive }
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let importance = importance {
            filtered = filtered.filter { $0.importance == importance }
        }
        
        return filtered.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func getRelevantMemories(for query: String, limit: Int = 10) -> [Memory] {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        let scoredMemories = memories.values.compactMap { memory -> (Memory, Double)? in
            guard memory.isActive else { return nil }
            
            let relevanceScore = calculateRelevance(memory: memory, queryWords: queryWords)
            return relevanceScore > 0.3 ? (memory, relevanceScore) : nil
        }
        
        return scoredMemories
            .sorted { $0.1 > $1.1 } // Sort by relevance score
            .prefix(limit)
            .map { $0.0 }
    }
    
    // MARK: - Learning from Conversations
    func extractMemoriesFromConversation(userMessage: String, assistantResponse: String, userProfile: [String: Any]?) async {
        // Use Apple Intelligence for on-device memory extraction
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.extractFamilyDynamics(userMessage: userMessage, response: assistantResponse)
            }
            
            group.addTask {
                await self.extractCommunicationPatterns(userMessage: userMessage)
            }
            
            group.addTask {
                await self.extractPreferences(userMessage: userMessage, response: assistantResponse)
            }
            
            group.addTask {
                await self.extractSuccessfulStrategies(response: assistantResponse, userMessage: userMessage)
            }
        }
    }
    
    // MARK: - Context for Responses
    func getContextForResponse(userMessage: String) -> String {
        let relevantMemories = getRelevantMemories(for: userMessage, limit: 5)
        
        if relevantMemories.isEmpty {
            return ""
        }
        
        var context = "\n\n## Contextual Memory (Private - Not Shared):\n"
        
        for memory in relevantMemories {
            let categoryName = memory.category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
            context += "- \(categoryName): \(memory.content)\n"
        }
        
        context += "\nUse this context to provide more personalized and relevant guidance."
        
        return context
    }
    
    // MARK: - Cloud Sync
    private func saveToCloud(_ memory: Memory) async {
        guard isCloudKitAvailable else { return }
        do {
            let record = CKRecord(recordType: "Memory")
            record["id"] = memory.id
            record["category"] = memory.category.rawValue
            record["content"] = memory.content
            record["confidence"] = memory.confidence
            record["createdAt"] = memory.createdAt
            record["lastUpdated"] = memory.lastUpdated
            record["source"] = memory.source.rawValue
            record["importance"] = memory.importance.rawValue
            record["isActive"] = memory.isActive
            
            _ = try await database.save(record)
            print("☁️ Synced memory to iCloud: \(memory.content.prefix(50))...")
        } catch {
            GCPCloudKit.logFailure("Failed to sync memory to iCloud", error: error)
            if let ck = error as? CKError, ck.code == .permissionFailure {
                isCloudKitAvailable = false
            }
        }
    }
    
    private func loadMemories() async {
        guard isCloudKitAvailable else {
            print("💾 Contextual memories: CloudKit off — in-memory only this session")
            return
        }
        do {
            let query = CKQuery(recordType: "Memory", predicate: NSPredicate(value: true))
            let records = try await database.records(matching: query).matchResults
            
            for (_, result) in records {
                switch result {
                case .success(let record):
                    if let memory = createMemoryFromRecord(record) {
                        memories[memory.id] = memory
                    }
                case .failure(let error):
                    print("❌ Failed to load memory: \(error)")
                }
            }
            
            print("🧠 Loaded \(memories.count) memories from iCloud")
        } catch {
            GCPCloudKit.logFailure("Failed to load memories from iCloud", error: error)
            if let ck = error as? CKError, ck.code == .permissionFailure {
                isCloudKitAvailable = false
            }
        }
    }
    
    private func createMemoryFromRecord(_ record: CKRecord) -> Memory? {
        guard let _ = record["id"] as? String,
              let categoryString = record["category"] as? String,
              let category = MemoryCategory(rawValue: categoryString),
              let content = record["content"] as? String,
              let confidence = record["confidence"] as? Double,
              let _ = record["createdAt"] as? Date,
              let lastUpdated = record["lastUpdated"] as? Date,
              let sourceString = record["source"] as? String,
              let source = Memory.MemorySource(rawValue: sourceString),
              let importanceString = record["importance"] as? String,
              let importance = Memory.MemoryImportance(rawValue: importanceString),
              let isActive = record["isActive"] as? Bool else {
            return nil
        }
        
        var memory = Memory(
            category: category,
            content: content,
            confidence: confidence,
            source: source,
            importance: importance
        )
        
        // Set the loaded values
        memory.content = content
        memory.confidence = confidence
        memory.lastUpdated = lastUpdated
        memory.isActive = isActive
        
        return memory
    }
    
    // MARK: - Memory Extraction Helpers
    private func extractFamilyDynamics(userMessage: String, response: String) async {
        let keywords = ["always", "never", "usually", "tends to", "typically", "often"]
        
        for keyword in keywords {
            if userMessage.lowercased().contains(keyword) {
                // Extract pattern-based insights
                let insight = extractPatternFromText(userMessage, keyword: keyword)
                if !insight.isEmpty {
                    await addMemory(
                        category: .familyDynamics,
                        content: insight,
                        confidence: 0.7,
                        source: .conversation,
                        importance: .important
                    )
                }
            }
        }
    }
    
    private func extractCommunicationPatterns(userMessage: String) async {
        let communicationIndicators = [
            ("text", "prefers texting"),
            ("call", "uses phone calls"),
            ("email", "uses email communication"),
            ("through the kids", "communicates through children"),
            ("won't talk", "avoids direct communication")
        ]
        
        for (indicator, pattern) in communicationIndicators {
            if userMessage.lowercased().contains(indicator) {
                await addMemory(
                    category: .communicationStyle,
                    content: "Co-parent \(pattern)",
                    confidence: 0.8,
                    source: .conversation,
                    importance: .important
                )
            }
        }
    }
    
    private func extractPreferences(userMessage: String, response: String) async {
        let preferenceKeywords = ["prefer", "like", "don't like", "hate", "love", "better", "works best"]
        
        for keyword in preferenceKeywords {
            if userMessage.lowercased().contains(keyword) {
                let preference = extractPreferenceFromText(userMessage, keyword: keyword)
                if !preference.isEmpty {
                    await addMemory(
                        category: .preferences,
                        content: preference,
                        confidence: 0.9,
                        source: .conversation,
                        importance: .helpful
                    )
                }
            }
        }
    }
    
    private func extractSuccessfulStrategies(response: String, userMessage: String) async {
        // If the user follows up positively to a suggestion, mark it as successful
        let positiveResponses = ["that worked", "helped", "better", "thank you", "good advice"]
        
        for positive in positiveResponses {
            if userMessage.lowercased().contains(positive) {
                await addMemory(
                    category: .successfulStrategies,
                    content: "Previous suggestion was effective",
                    confidence: 0.9,
                    source: .conversation,
                    importance: .important
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateRelevance(memory: Memory, queryWords: [String]) -> Double {
        let memoryWords = memory.content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let matchCount = queryWords.filter { memoryWords.contains($0) }.count
        
        let baseRelevance = Double(matchCount) / Double(queryWords.count)
        let importanceBoost = memory.importance == .critical ? 0.3 : memory.importance == .important ? 0.2 : 0.1
        let confidenceBoost = memory.confidence * 0.2
        
        return min(1.0, baseRelevance + importanceBoost + confidenceBoost)
    }
    
    private func extractPatternFromText(_ text: String, keyword: String) -> String {
        // Simple pattern extraction - could be enhanced with NLP
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            if sentence.lowercased().contains(keyword) {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return ""
    }
    
    private func extractPreferenceFromText(_ text: String, keyword: String) -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            if sentence.lowercased().contains(keyword) {
                return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return ""
    }
    
    private func cleanupOldMemories() async {
        if memories.count > memoryLimit {
            let sortedMemories = memories.values.sorted {
                // Keep more important memories, then more recent ones
                if $0.importance != $1.importance {
                    return $0.importance.rawValue < $1.importance.rawValue
                }
                return $0.lastUpdated > $1.lastUpdated
            }
            
            let toRemove = sortedMemories.suffix(memories.count - memoryLimit)
            
            for memory in toRemove {
                memories.removeValue(forKey: memory.id)
            }
            
            print("🧹 Cleaned up \(toRemove.count) old memories")
        }
    }
}

// MARK: - Codable Conformance
extension ContextualMemoryManager.Memory: Codable {
    enum CodingKeys: String, CodingKey {
        case id, category, content, confidence, createdAt, lastUpdated, source, importance, isActive
    }
}