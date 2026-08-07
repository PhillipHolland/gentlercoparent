import Foundation
import CloudKit
import Combine

// MARK: - Enhanced Conversation Memory for Persistent Context
@MainActor
class ConversationMemoryManager: ObservableObject {
    
    // MARK: - Memory Models
    struct ConversationContext: Codable, Identifiable {
        let id: UUID
        let conversationId: UUID
        let timestamp: Date
        let topicSummary: String
        let keyInsights: [String]
        let emotionalTone: EmotionalTone
        let conflictLevel: ConflictLevel
        let outcomes: [String]
        let followUpNeeded: [String]
        let conversationSnapshot: String // Full text searchable
        let participantKeywords: [String] // Names, places, events mentioned
        
        init(conversationId: UUID, timestamp: Date, topicSummary: String, keyInsights: [String], emotionalTone: EmotionalTone, conflictLevel: ConflictLevel, outcomes: [String], followUpNeeded: [String], conversationSnapshot: String = "", participantKeywords: [String] = []) {
            self.id = UUID()
            self.conversationId = conversationId
            self.timestamp = timestamp
            self.topicSummary = topicSummary
            self.keyInsights = keyInsights
            self.emotionalTone = emotionalTone
            self.conflictLevel = conflictLevel
            self.outcomes = outcomes
            self.followUpNeeded = followUpNeeded
            self.conversationSnapshot = conversationSnapshot
            self.participantKeywords = participantKeywords
        }
        
        enum EmotionalTone: String, Codable, CaseIterable {
            case calm, frustrated, angry, anxious, hopeful, collaborative, defensive
        }
        
        enum ConflictLevel: Int, Codable, CaseIterable {
            case none = 0, low = 1, moderate = 2, high = 3, crisis = 4
        }
    }
    
    struct RecentMemoryContext: Codable {
        let contexts: [ConversationContext]
        let recurringThemes: [RecurringTheme]
        let relationshipTrends: RelationshipTrend
        let lastAnalyzed: Date
    }
    
    struct RecurringTheme: Codable, Identifiable {
        let id: UUID
        let theme: String
        let frequency: Int
        let lastMentioned: Date
        let severity: ThemeSeverity
        let suggestedActions: [String]
        
        init(theme: String, frequency: Int, lastMentioned: Date, severity: ThemeSeverity, suggestedActions: [String]) {
            self.id = UUID()
            self.theme = theme
            self.frequency = frequency
            self.lastMentioned = lastMentioned
            self.severity = severity
            self.suggestedActions = suggestedActions
        }
        
        enum ThemeSeverity: String, Codable {
            case minor, moderate, concerning, urgent
        }
    }
    
    enum RelationshipTrend: String, Codable {
        case improving, stable, declining, volatile, unknown
    }
    
    // MARK: - Properties
    @Published var recentContexts: [ConversationContext] = []
    @Published var recurringThemes: [RecurringTheme] = []
    @Published var relationshipTrend: RelationshipTrend = .unknown
    @Published var isCloudKitAvailable: Bool = false
    
    private let maxContextRetention = 50 // Keep last 50 conversation contexts
    private let themeAnalysisWindow: TimeInterval = 30 * 24 * 60 * 60 // 30 days
    
    // CloudKit for cross-device sync — shared container (entitlements-aligned)
    private var container: CKContainer { GCPCloudKit.container }
    private var database: CKDatabase { GCPCloudKit.privateDatabase }
    
    // Local persistence fallback
    private let localDataKey = "conversationMemoryLocal"
    
    // MARK: - Initialization
    init() {
        Task { [weak self] in
            guard let self else { return }
            await self.setupCloudKit()
            await self.loadPersistedMemories()
        }
    }
    
    // MARK: - CloudKit Setup
    private func setupCloudKit() async {
        let result = await GCPCloudKit.resolveAvailability()
        await MainActor.run {
            self.isCloudKitAvailable = result.available
            if result.available {
                print("☁️ \(result.reason) — conversation memory")
            } else {
                print("⚠️ \(result.reason) — conversation memory using local storage only")
            }
        }
    }
    
    // MARK: - Core Memory Functions
    
    /// Extract and store conversation context after each conversation
    func processConversationEnd(_ conversation: [ChatMessage], conversationId: UUID) async {
        guard conversation.count >= 2 else { return } // Need at least one exchange
        
        let context = await analyzeConversation(conversation, conversationId: conversationId)
        
        recentContexts.insert(context, at: 0)
        
        // Maintain retention limit
        if recentContexts.count > maxContextRetention {
            recentContexts = Array(recentContexts.prefix(maxContextRetention))
        }
        
        // Update recurring themes and trends
        await updateRecurringThemes()
        await updateRelationshipTrend()
        
        // Persist to CloudKit or local storage
        await saveContext(context)
        await saveRecurringThemes()
    }
    
    /// Get relevant context for current conversation
    func getRelevantContextForQuery(_ query: String, userProfile: [String: Any]?) -> ConversationMemoryContext {
        let startTime = Date()
        
        print("🧠 ConversationMemory: Processing query '\(query)'")
        print("🧠 Available contexts: \(recentContexts.count)")
        
        let relevantContexts = findRelevantPastContexts(for: query)
        let activeThemes = getActiveRecurringThemes()
        let trendInsights = getTrendBasedInsights()
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("🧠 ConversationMemory: Found \(relevantContexts.count) relevant contexts in \(String(format: "%.3f", processingTime))s")
        print("🧠 Active themes: \(activeThemes.count)")
        print("🧠 Trend: \(relationshipTrend.rawValue)")
        
        if !relevantContexts.isEmpty {
            print("🧠 Top relevant contexts:")
            for (index, context) in relevantContexts.prefix(3).enumerated() {
                let daysSince = Int(Date().timeIntervalSince(context.timestamp) / (24 * 60 * 60))
                print("   \(index + 1). \(context.topicSummary) (\(daysSince) days ago)")
            }
        }
        
        return ConversationMemoryContext(
            relevantPastContexts: relevantContexts,
            recurringThemes: activeThemes,
            relationshipTrend: relationshipTrend,
            trendInsights: trendInsights,
            conversationHistory: generateConversationSummary()
        )
    }
    
    // MARK: - Conversation Analysis
    private func analyzeConversation(_ conversation: [ChatMessage], conversationId: UUID) async -> ConversationContext {
        let userMessages = conversation.filter { $0.sender != "Gentler Coparent" }
        let assistantMessages = conversation.filter { $0.sender == "Gentler Coparent" }
        
        // Analyze conversation content
        let topicSummary = await extractTopicSummary(conversation)
        let keyInsights = await extractKeyInsights(conversation)
        let emotionalTone = analyzeEmotionalTone(userMessages)
        let conflictLevel = assessConflictLevel(userMessages)
        let outcomes = extractOutcomes(assistantMessages)
        let followUpNeeded = identifyFollowUpItems(conversation)
        
        // Generate searchable snapshot
        let conversationSnapshot = generateConversationSnapshot(conversation)
        let participantKeywords = extractParticipantKeywords(conversation)
        
        return ConversationContext(
            conversationId: conversationId,
            timestamp: conversation.last?.timestamp ?? Date(),
            topicSummary: topicSummary,
            keyInsights: keyInsights,
            emotionalTone: emotionalTone,
            conflictLevel: conflictLevel,
            outcomes: outcomes,
            followUpNeeded: followUpNeeded,
            conversationSnapshot: conversationSnapshot,
            participantKeywords: participantKeywords
        )
    }
    
    private func generateConversationSnapshot(_ conversation: [ChatMessage]) -> String {
        // Create a condensed, searchable summary of the conversation
        let userMessages = conversation.filter { $0.sender != "Gentler Coparent" }
        let assistantMessages = conversation.filter { $0.sender == "Gentler Coparent" }
        
        var snapshot = "USER: "
        snapshot += userMessages.map { $0.text }.joined(separator: " | ")
        
        if !assistantMessages.isEmpty {
            snapshot += " RESPONSE: "
            snapshot += assistantMessages.map { $0.text }.joined(separator: " | ")
        }
        
        return snapshot.prefix(2000).description // Limit snapshot size
    }
    
    private func extractParticipantKeywords(_ conversation: [ChatMessage]) -> [String] {
        let allText = conversation.map { $0.text }.joined(separator: " ")
        var keywords: [String] = []
        
        // Extract names (capitalized words that might be names)
        let namePattern = try! NSRegularExpression(pattern: "\\b[A-Z][a-z]{2,}\\b", options: [])
        let nameMatches = namePattern.matches(in: allText, options: [], range: NSRange(location: 0, length: allText.utf16.count))
        
        for match in nameMatches {
            if let range = Range(match.range, in: allText) {
                let name = String(allText[range])
                // Filter out common non-names
                if !["The", "This", "That", "When", "Where", "What", "How", "Why", "Could", "Would", "Should", "Can't", "Don't", "Won't"].contains(name) {
                    keywords.append(name)
                }
            }
        }
        
        // Extract specific co-parenting entities
        let coparentingEntities = [
            "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
            "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December",
            "Christmas", "Thanksgiving", "Easter", "Halloween", "birthday", "school", "soccer", "football", "dance", "piano"
        ]
        
        for entity in coparentingEntities {
            if allText.localizedCaseInsensitiveContains(entity) {
                keywords.append(entity.lowercased())
            }
        }
        
        return Array(Set(keywords)) // Remove duplicates
    }
    
    private func extractTopicSummary(_ conversation: [ChatMessage]) async -> String {
        let allText = conversation.map { $0.text }.joined(separator: " ")
        
        // Topic detection patterns for co-parenting
        let topicPatterns = [
            ("Schedule/Custody", ["schedule", "custody", "visit", "pickup", "dropoff", "weekend"]),
            ("Financial", ["support", "money", "payment", "medical", "insurance", "cost"]),
            ("Communication", ["message", "text", "call", "talk", "respond", "communication"]),
            ("Children's Wellbeing", ["child", "children", "school", "health", "behavior", "needs"]),
            ("Legal/Documentation", ["court", "lawyer", "agreement", "decree", "legal", "documentation"]),
            ("Conflict Resolution", ["disagreement", "conflict", "problem", "issue", "solution", "mediation"]),
            ("Emergency", ["emergency", "urgent", "hospital", "immediate", "crisis", "help"])
        ]
        
        var detectedTopics: [String] = []
        let lowerText = allText.lowercased()
        
        for (topic, keywords) in topicPatterns {
            if keywords.contains(where: { lowerText.contains($0) }) {
                detectedTopics.append(topic)
            }
        }
        
        return detectedTopics.isEmpty ? "General Discussion" : detectedTopics.joined(separator: ", ")
    }
    
    private func extractKeyInsights(_ conversation: [ChatMessage]) async -> [String] {
        var insights: [String] = []
        
        let userMessages = conversation.filter { $0.sender != "Gentler Coparent" }
        
        for message in userMessages {
            let text = message.text.lowercased()
            
            // Pattern recognition for key insights
            if text.contains("need help with") || text.contains("struggling with") {
                insights.append("User expressed need for support")
            }
            
            if text.contains("refused") || text.contains("won't") || text.contains("doesn't want") {
                insights.append("Resistance or non-cooperation mentioned")
            }
            
            if text.contains("emergency") || text.contains("urgent") {
                insights.append("Urgent situation identified")
            }
            
            if text.contains("lawyer") || text.contains("court") {
                insights.append("Legal involvement mentioned")
            }
            
            if text.contains("child said") || text.contains("kid mentioned") {
                insights.append("Child's perspective or input shared")
            }
            
            if text.contains("worked well") || text.contains("success") || text.contains("better") {
                insights.append("Positive outcome or improvement noted")
            }
        }
        
        return Array(Set(insights)) // Remove duplicates
    }
    
    private func analyzeEmotionalTone(_ userMessages: [ChatMessage]) -> ConversationContext.EmotionalTone {
        guard !userMessages.isEmpty else { return .calm }
        
        let allText = userMessages.map { $0.text }.joined(separator: " ").lowercased()
        
        // Emotion detection patterns
        let emotionPatterns: [(ConversationContext.EmotionalTone, [String])] = [
            (.angry, ["angry", "furious", "mad", "hate", "disgusted", "outraged", "livid"]),
            (.frustrated, ["frustrated", "annoyed", "irritated", "fed up", "sick of", "tired of"]),
            (.anxious, ["worried", "anxious", "scared", "nervous", "concerned", "afraid"]),
            (.defensive, ["not my fault", "you always", "never", "always", "but", "however"]),
            (.hopeful, ["hope", "maybe", "could work", "try", "willing", "open to"]),
            (.collaborative, ["we", "us", "together", "work with", "cooperate", "partner"])
        ]
        
        var emotionScores: [ConversationContext.EmotionalTone: Int] = [:]
        
        for (emotion, keywords) in emotionPatterns {
            let count = keywords.reduce(0) { count, keyword in
                count + allText.components(separatedBy: keyword).count - 1
            }
            emotionScores[emotion] = count
        }
        
        return emotionScores.max(by: { $0.value < $1.value })?.key ?? .calm
    }
    
    private func assessConflictLevel(_ userMessages: [ChatMessage]) -> ConversationContext.ConflictLevel {
        let allText = userMessages.map { $0.text }.joined(separator: " ").lowercased()
        
        let conflictIndicators = [
            ("crisis", 4), ("emergency", 4), ("threatening", 4), ("violence", 4),
            ("furious", 3), ("hate", 3), ("never again", 3), ("done with", 3),
            ("frustrated", 2), ("unfair", 2), ("disagree", 2), ("problem", 2),
            ("concerned", 1), ("issue", 1), ("question", 1)
        ]
        
        var totalScore = 0
        for (indicator, score) in conflictIndicators {
            if allText.contains(indicator) {
                totalScore += score
            }
        }
        
        switch totalScore {
        case 0: return .none
        case 1...2: return .low
        case 3...5: return .moderate
        case 6...8: return .high
        default: return .crisis
        }
    }
    
    private func extractOutcomes(_ assistantMessages: [ChatMessage]) -> [String] {
        var outcomes: [String] = []
        
        for message in assistantMessages {
            let text = message.text.lowercased()
            
            if text.contains("suggest") || text.contains("recommend") {
                outcomes.append("Recommendations provided")
            }
            
            if text.contains("template") || text.contains("example") {
                outcomes.append("Communication template offered")
            }
            
            if text.contains("legal") || text.contains("attorney") {
                outcomes.append("Legal guidance suggested")
            }
            
            if text.contains("mediation") || text.contains("neutral") {
                outcomes.append("Mediation resources mentioned")
            }
        }
        
        return outcomes
    }
    
    private func identifyFollowUpItems(_ conversation: [ChatMessage]) -> [String] {
        var followUps: [String] = []
        
        let allText = conversation.map { $0.text }.joined(separator: " ").lowercased()
        
        if allText.contains("will try") || allText.contains("going to") {
            followUps.append("Check on planned actions")
        }
        
        if allText.contains("court date") || allText.contains("meeting") {
            followUps.append("Follow up after scheduled event")
        }
        
        if allText.contains("think about") || allText.contains("consider") {
            followUps.append("Follow up on decision-making")
        }
        
        if allText.contains("emergency") || allText.contains("urgent") {
            followUps.append("Check on urgent situation resolution")
        }
        
        return followUps
    }
    
    // MARK: - Theme Analysis
    private func updateRecurringThemes() async {
        let thirtyDaysAgo = Date().addingTimeInterval(-themeAnalysisWindow)
        let recentContexts = self.recentContexts.filter { $0.timestamp > thirtyDaysAgo }
        
        var themeCounts: [String: Int] = [:]
        var themeLastMentioned: [String: Date] = [:]
        
        for context in recentContexts {
            // Count topic occurrences
            let topics = context.topicSummary.components(separatedBy: ", ")
            for topic in topics {
                themeCounts[topic, default: 0] += 1
                themeLastMentioned[topic] = max(themeLastMentioned[topic] ?? Date.distantPast, context.timestamp)
            }
            
            // Count insight patterns
            for insight in context.keyInsights {
                themeCounts[insight, default: 0] += 1
                themeLastMentioned[insight] = max(themeLastMentioned[insight] ?? Date.distantPast, context.timestamp)
            }
        }
        
        // Create recurring themes (frequency >= 3 in 30 days)
        let newThemes = themeCounts.compactMap { theme, count -> RecurringTheme? in
            guard count >= 3, let lastMentioned = themeLastMentioned[theme] else { return nil }
            
            let severity: RecurringTheme.ThemeSeverity
            switch count {
            case 3...5: severity = .minor
            case 6...10: severity = .moderate
            case 11...20: severity = .concerning
            default: severity = .urgent
            }
            
            return RecurringTheme(
                theme: theme,
                frequency: count,
                lastMentioned: lastMentioned,
                severity: severity,
                suggestedActions: generateSuggestedActions(for: theme, severity: severity)
            )
        }
        
        recurringThemes = newThemes
    }
    
    private func generateSuggestedActions(for theme: String, severity: RecurringTheme.ThemeSeverity) -> [String] {
        var actions: [String] = []
        
        switch theme {
        case let t where t.contains("Schedule"):
            actions = ["Review custody schedule", "Consider schedule modifications", "Set up shared calendar"]
        case let t where t.contains("Financial"):
            actions = ["Review financial agreements", "Document expenses", "Consider mediation"]
        case let t where t.contains("Communication"):
            actions = ["Establish communication boundaries", "Use written communication", "Consider communication app"]
        case let t where t.contains("Conflict"):
            actions = ["Consider professional mediation", "Review conflict resolution strategies", "Focus on child-centered solutions"]
        default:
            actions = ["Monitor situation", "Consider professional guidance", "Document patterns"]
        }
        
        if severity == .urgent {
            actions.insert("Consider immediate professional intervention", at: 0)
        }
        
        return actions
    }
    
    private func updateRelationshipTrend() async {
        guard recentContexts.count >= 5 else {
            relationshipTrend = .unknown 
            return
        }
        
        let recentFive = Array(recentContexts.prefix(5))
        let conflictLevels = recentFive.map { $0.conflictLevel.rawValue }
        
        let averageConflict = Double(conflictLevels.reduce(0, +)) / Double(conflictLevels.count)
        
        // Compare to historical average
        let historicalContexts = Array(recentContexts.dropFirst(5).prefix(10))
        if !historicalContexts.isEmpty {
            let historicalAverage = Double(historicalContexts.map { $0.conflictLevel.rawValue }.reduce(0, +)) / Double(historicalContexts.count)
            
            let trend: RelationshipTrend
            if averageConflict < historicalAverage - 0.5 {
                trend = .improving
            } else if averageConflict > historicalAverage + 0.5 {
                trend = .declining
            } else if conflictLevels.max()! - conflictLevels.min()! > 2 {
                trend = .volatile
            } else {
                trend = .stable
            }
            
            relationshipTrend = trend
        }
    }
    
    // MARK: - Context Retrieval
    private func findRelevantPastContexts(for query: String) -> [ConversationContext] {
        let queryLower = query.lowercased()
        let queryWords = Set(queryLower.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        
        // Enhanced relevance scoring with multiple factors
        let scoredContexts = recentContexts.compactMap { context -> (context: ConversationContext, score: Double)? in
            var score = 0.0
            
            // 1. Topic exact match (highest weight)
            let topicWords = Set(context.topicSummary.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let topicIntersection = queryWords.intersection(topicWords)
            score += Double(topicIntersection.count) * 3.0
            
            // 2. Key insights match
            let allInsights = context.keyInsights.joined(separator: " ").lowercased()
            let insightWords = Set(allInsights.components(separatedBy: .whitespacesAndNewlines))
            let insightIntersection = queryWords.intersection(insightWords)
            score += Double(insightIntersection.count) * 2.0
            
            // 3. Semantic similarity for common co-parenting terms
            score += semanticSimilarityScore(query: queryLower, context: context)
            
            // 4. Full-text search in conversation snapshot
            if context.conversationSnapshot.lowercased().contains(queryLower) {
                score += 2.5
            }
            
            // 5. Participant keywords match
            let keywordMatches = context.participantKeywords.filter { keyword in
                queryWords.contains(keyword.lowercased()) || queryLower.contains(keyword.lowercased())
            }
            score += Double(keywordMatches.count) * 1.5
            
            // 6. Recency boost (more recent = higher score)
            let daysSince = Date().timeIntervalSince(context.timestamp) / (24 * 60 * 60)
            let recencyBoost = max(0, 1.0 - (daysSince / 30.0)) // Linear decay over 30 days
            score += recencyBoost
            
            // 7. Conflict level relevance (if query suggests urgency)
            if queryLower.contains("emergency") || queryLower.contains("urgent") || queryLower.contains("help") {
                score += Double(context.conflictLevel.rawValue) * 0.5
            }
            
            return score > 0.1 ? (context, score) : nil
        }
        
        // Debug logging for scoring
        let totalContexts = recentContexts.count
        let scoredCount = scoredContexts.count
        print("🔍 Context Search: \(totalContexts) total, \(scoredCount) scored above threshold")
        
        let sortedContexts = scoredContexts.sorted { $0.score > $1.score }
        if !sortedContexts.isEmpty {
            print("🔍 Top scores:")
            for (index, item) in sortedContexts.prefix(3).enumerated() {
                print("   \(index + 1). Score: \(String(format: "%.2f", item.score)) - \(item.context.topicSummary)")
            }
        }
        
        // Return top contexts sorted by relevance score
        return sortedContexts
            .prefix(8) // Increased from 5 to 8 for better coverage
            .map { $0.context }
    }
    
    // Enhanced semantic similarity for co-parenting domain
    private func semanticSimilarityScore(query: String, context: ConversationContext) -> Double {
        let coparentingSemanticGroups = [
            ["child support", "support", "financial", "money", "payment", "monthly", "court ordered"]: 1.0,
            ["custody", "schedule", "visitation", "possession", "pickup", "dropoff", "time", "weekend"]: 1.0,
            ["christmas", "holiday", "thanksgiving", "vacation", "summer", "school", "break"]: 1.0,
            ["communication", "text", "message", "email", "call", "contact", "talk", "discuss"]: 0.8,
            ["legal", "court", "lawyer", "attorney", "decree", "agreement", "documentation"]: 1.0,
            ["children", "kids", "school", "health", "behavior", "wellbeing", "development"]: 0.9,
            ["conflict", "disagreement", "problem", "issue", "fight", "argument", "tension"]: 0.8,
            ["emergency", "urgent", "crisis", "immediate", "help", "concern", "worry"]: 1.2
        ]
        
        var maxScore = 0.0
        let contextText = (context.topicSummary + " " + context.keyInsights.joined(separator: " ")).lowercased()
        
        for (semanticGroup, weight) in coparentingSemanticGroups {
            var queryMatches = 0
            var contextMatches = 0
            
            for term in semanticGroup {
                if query.contains(term) { queryMatches += 1 }
                if contextText.contains(term) { contextMatches += 1 }
            }
            
            if queryMatches > 0 && contextMatches > 0 {
                let similarity = Double(min(queryMatches, contextMatches)) / Double(max(queryMatches, contextMatches))
                maxScore = max(maxScore, similarity * weight)
            }
        }
        
        return maxScore
    }
    
    private func getActiveRecurringThemes() -> [RecurringTheme] {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        return recurringThemes.filter { $0.lastMentioned > sevenDaysAgo }
    }
    
    private func getTrendBasedInsights() -> [String] {
        var insights: [String] = []
        
        switch relationshipTrend {
        case .improving:
            insights.append("Communication patterns show positive improvement")
        case .declining:
            insights.append("Increased conflict detected - consider proactive intervention")
        case .volatile:
            insights.append("Communication shows high variability - focus on consistency")
        case .stable:
            insights.append("Communication remains stable")
        case .unknown:
            insights.append("Still learning your communication patterns")
        }
        
        return insights
    }
    
    private func generateConversationSummary() -> String {
        let recentFive = Array(recentContexts.prefix(5))
        if recentFive.isEmpty { return "No previous conversations" }
        
        let topics = recentFive.map { $0.topicSummary }.joined(separator: "; ")
        let trend = relationshipTrend.rawValue.capitalized
        
        return "Recent topics: \(topics). Relationship trend: \(trend)"
    }
    
    // MARK: - Persistence (CloudKit + Local Fallback)
    private func saveContext(_ context: ConversationContext) async {
        if isCloudKitAvailable {
            await saveContextToCloud(context)
        } else {
            saveContextToLocal(context)
        }
    }
    
    private func saveContextToCloud(_ context: ConversationContext) async {
        do {
            let record = CKRecord(recordType: "ConversationContext")
            record["conversationId"] = context.conversationId.uuidString
            record["timestamp"] = context.timestamp
            record["topicSummary"] = context.topicSummary
            record["keyInsights"] = context.keyInsights
            record["emotionalTone"] = context.emotionalTone.rawValue
            record["conflictLevel"] = context.conflictLevel.rawValue
            record["outcomes"] = context.outcomes
            record["followUpNeeded"] = context.followUpNeeded
            record["conversationSnapshot"] = context.conversationSnapshot
            record["participantKeywords"] = context.participantKeywords
            
            _ = try await database.save(record)
            print("☁️ Synced conversation context to iCloud")
        } catch {
            GCPCloudKit.logFailure("Failed to sync conversation context to CloudKit", error: error)
            // Permission / container mismatch → stop hammering CloudKit this session
            if let ck = error as? CKError, ck.code == .permissionFailure {
                await MainActor.run { self.isCloudKitAvailable = false }
            }
            saveContextToLocal(context)
        }
    }
    
    private func saveContextToLocal(_ context: ConversationContext) {
        do {
            var localContexts = loadLocalContexts()
            localContexts.insert(context, at: 0)
            
            // Keep within retention limit
            if localContexts.count > maxContextRetention {
                localContexts = Array(localContexts.prefix(maxContextRetention))
            }
            
            let data = try JSONEncoder().encode(localContexts)
            UserDefaults.standard.set(data, forKey: localDataKey + "_contexts")
            print("💾 Saved conversation context locally")
        } catch {
            print("❌ Failed to save context locally: \(error)")
        }
    }
    
    private func saveRecurringThemes() async {
        if isCloudKitAvailable {
            await saveRecurringThemesToCloud()
        } else {
            saveRecurringThemesToLocal()
        }
    }
    
    private func saveRecurringThemesToCloud() async {
        do {
            // Delete old themes
            let query = CKQuery(recordType: "RecurringThemes", predicate: NSPredicate(value: true))
            let records = try await database.records(matching: query).matchResults
            
            for (_, result) in records {
                if case .success(let record) = result {
                    try await database.deleteRecord(withID: record.recordID)
                }
            }
            
            // Save new themes
            for theme in recurringThemes {
                let record = CKRecord(recordType: "RecurringThemes")
                record["theme"] = theme.theme
                record["frequency"] = theme.frequency
                record["lastMentioned"] = theme.lastMentioned
                record["severity"] = theme.severity.rawValue
                record["suggestedActions"] = theme.suggestedActions
                
                _ = try await database.save(record)
            }
            
            print("☁️ Synced \(recurringThemes.count) recurring themes to iCloud")
        } catch {
            GCPCloudKit.logFailure("Failed to sync recurring themes to CloudKit", error: error)
            if let ck = error as? CKError, ck.code == .permissionFailure {
                await MainActor.run { self.isCloudKitAvailable = false }
            }
            saveRecurringThemesToLocal()
        }
    }
    
    private func saveRecurringThemesToLocal() {
        do {
            let data = try JSONEncoder().encode(recurringThemes)
            UserDefaults.standard.set(data, forKey: localDataKey + "_themes")
            print("💾 Saved \(recurringThemes.count) recurring themes locally")
        } catch {
            print("❌ Failed to save themes locally: \(error)")
        }
    }
    
    private func loadPersistedMemories() async {
        if isCloudKitAvailable {
            await loadMemoriesFromCloud()
        } else {
            loadMemoriesFromLocal()
        }
    }
    
    private func loadMemoriesFromCloud() async {
        // Load conversation contexts
        do {
            let query = CKQuery(recordType: "ConversationContext", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            let records = try await database.records(matching: query).matchResults
            var contexts: [ConversationContext] = []
            
            for (_, result) in records {
                if case .success(let record) = result,
                   let context = createContextFromRecord(record) {
                    contexts.append(context)
                }
            }
            
            await MainActor.run {
                self.recentContexts = Array(contexts.prefix(self.maxContextRetention))
            }
            print("🧠 Loaded \(contexts.count) conversation contexts from iCloud")
        } catch {
            GCPCloudKit.logFailure("Failed to load conversation contexts from CloudKit", error: error)
            if let ck = error as? CKError, ck.code == .permissionFailure {
                await MainActor.run { self.isCloudKitAvailable = false }
            }
            loadMemoriesFromLocal()
            return
        }
        
        // Load recurring themes
        do {
            let query = CKQuery(recordType: "RecurringThemes", predicate: NSPredicate(value: true))
            let records = try await database.records(matching: query).matchResults
            var themes: [RecurringTheme] = []
            
            for (_, result) in records {
                if case .success(let record) = result,
                   let theme = createThemeFromRecord(record) {
                    themes.append(theme)
                }
            }
            
            await MainActor.run {
                self.recurringThemes = themes
            }
            print("🧠 Loaded \(themes.count) recurring themes from iCloud")
        } catch {
            print("❌ Failed to load recurring themes from CloudKit: \(error)")
        }
        
        // Update relationship trend based on loaded data
        await updateRelationshipTrend()
    }
    
    private func loadMemoriesFromLocal() {
        // Load conversation contexts from local storage
        let localContexts = loadLocalContexts()
        recentContexts = Array(localContexts.prefix(maxContextRetention))
        print("💾 Loaded \(localContexts.count) conversation contexts from local storage")
        
        // Load recurring themes from local storage
        if let data = UserDefaults.standard.data(forKey: localDataKey + "_themes"),
           let themes = try? JSONDecoder().decode([RecurringTheme].self, from: data) {
            recurringThemes = themes
            print("💾 Loaded \(themes.count) recurring themes from local storage")
        }
    }
    
    private func loadLocalContexts() -> [ConversationContext] {
        guard let data = UserDefaults.standard.data(forKey: localDataKey + "_contexts"),
              let contexts = try? JSONDecoder().decode([ConversationContext].self, from: data) else {
            return []
        }
        return contexts
    }
    
    private func createContextFromRecord(_ record: CKRecord) -> ConversationContext? {
        guard let conversationIdString = record["conversationId"] as? String,
              let conversationId = UUID(uuidString: conversationIdString),
              let timestamp = record["timestamp"] as? Date,
              let topicSummary = record["topicSummary"] as? String,
              let keyInsights = record["keyInsights"] as? [String],
              let emotionalToneString = record["emotionalTone"] as? String,
              let emotionalTone = ConversationContext.EmotionalTone(rawValue: emotionalToneString),
              let conflictLevelInt = record["conflictLevel"] as? Int,
              let conflictLevel = ConversationContext.ConflictLevel(rawValue: conflictLevelInt),
              let outcomes = record["outcomes"] as? [String],
              let followUpNeeded = record["followUpNeeded"] as? [String] else {
            return nil
        }
        
        // Handle backwards compatibility for new fields
        let conversationSnapshot = record["conversationSnapshot"] as? String ?? ""
        let participantKeywords = record["participantKeywords"] as? [String] ?? []
        
        return ConversationContext(
            conversationId: conversationId,
            timestamp: timestamp,
            topicSummary: topicSummary,
            keyInsights: keyInsights,
            emotionalTone: emotionalTone,
            conflictLevel: conflictLevel,
            outcomes: outcomes,
            followUpNeeded: followUpNeeded,
            conversationSnapshot: conversationSnapshot,
            participantKeywords: participantKeywords
        )
    }
    
    private func createThemeFromRecord(_ record: CKRecord) -> RecurringTheme? {
        guard let theme = record["theme"] as? String,
              let frequency = record["frequency"] as? Int,
              let lastMentioned = record["lastMentioned"] as? Date,
              let severityString = record["severity"] as? String,
              let severity = RecurringTheme.ThemeSeverity(rawValue: severityString),
              let suggestedActions = record["suggestedActions"] as? [String] else {
            return nil
        }
        
        return RecurringTheme(
            theme: theme,
            frequency: frequency,
            lastMentioned: lastMentioned,
            severity: severity,
            suggestedActions: suggestedActions
        )
    }
    
    // MARK: - Helper Functions
    private func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsLength = lhs.count
        let rhsLength = rhs.count
        
        if lhsLength == 0 { return rhsLength }
        if rhsLength == 0 { return lhsLength }
        
        var matrix = Array(repeating: Array(repeating: 0, count: rhsLength + 1), count: lhsLength + 1)
        
        for i in 0...lhsLength {
            matrix[i][0] = i
        }
        
        for j in 0...rhsLength {
            matrix[0][j] = j
        }
        
        let lhsArray = Array(lhs)
        let rhsArray = Array(rhs)
        
        for i in 1...lhsLength {
            for j in 1...rhsLength {
                if lhsArray[i - 1] == rhsArray[j - 1] {
                    matrix[i][j] = matrix[i - 1][j - 1]
                } else {
                    matrix[i][j] = Swift.min(
                        matrix[i - 1][j] + 1,      // deletion
                        matrix[i][j - 1] + 1,      // insertion
                        matrix[i - 1][j - 1] + 1   // substitution
                    )
                }
            }
        }
        
        return matrix[lhsLength][rhsLength]
    }
}

// MARK: - Memory Context Model for Queries
struct ConversationMemoryContext {
    let relevantPastContexts: [ConversationMemoryManager.ConversationContext]
    let recurringThemes: [ConversationMemoryManager.RecurringTheme]
    let relationshipTrend: ConversationMemoryManager.RelationshipTrend
    let trendInsights: [String]
    let conversationHistory: String
    
    /// Generate contextual hints for AI processing
    func generateContextualHints() -> [String] {
        var hints: [String] = []
        
        // Add relevant past context
        for context in relevantPastContexts.prefix(3) {
            hints.append("Previous discussion: \(context.topicSummary) (Conflict level: \(context.conflictLevel))")
        }
        
        // Add recurring themes
        for theme in recurringThemes.prefix(2) {
            hints.append("Recurring theme: \(theme.theme) (Mentioned \(theme.frequency) times)")
        }
        
        // Add trend insights
        hints.append(contentsOf: trendInsights)
        
        // Add conversation summary
        hints.append("Conversation history: \(conversationHistory)")
        
        return hints
    }
    
    /// Check if this is a recurring issue
    func isRecurringIssue(_ query: String) -> (isRecurring: Bool, theme: ConversationMemoryManager.RecurringTheme?) {
        let queryLower = query.lowercased()
        
        for theme in recurringThemes {
            if theme.theme.lowercased().contains(where: { queryLower.contains(String($0)) }) {
                return (true, theme)
            }
        }
        
        return (false, nil)
    }
    
    /// Get follow-up items from previous conversations
    func getOutstandingFollowUps() -> [String] {
        let recentFollowUps = relevantPastContexts
            .filter { Date().timeIntervalSince($0.timestamp) < 7 * 24 * 60 * 60 } // Last 7 days
            .flatMap { $0.followUpNeeded }
        
        return Array(Set(recentFollowUps))
    }
}
