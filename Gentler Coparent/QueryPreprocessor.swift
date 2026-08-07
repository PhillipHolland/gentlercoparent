import Foundation
import SwiftUI

// MARK: - Enhanced Query Processing for Better RAG Retrieval
class QueryPreprocessor: ObservableObject {
    
    // MARK: - Topic Classification
    enum CoparentingTopic: String, CaseIterable {
        case custody = "custody"
        case schedule = "schedule"
        case financial = "financial"
        case medical = "medical"
        case education = "education"
        case holiday = "holiday"
        case communication = "communication"
        case legal = "legal"
        case emergency = "emergency"
        case behavior = "behavior"
        case general = "general"
        
        var keywords: [String] {
            switch self {
            case .custody:
                return ["custody", "visitation", "possession", "primary residence", "joint custody", "sole custody", "parenting time"]
            case .schedule:
                return ["schedule", "pickup", "dropoff", "exchange", "time", "weekend", "weekday", "transition"]
            case .financial:
                return ["child support", "expenses", "cost", "money", "payment", "financial", "alimony", "maintenance"]
            case .medical:
                return ["medical", "health", "doctor", "appointment", "insurance", "medication", "treatment", "emergency room"]
            case .education:
                return ["school", "education", "teacher", "grades", "homework", "activities", "extracurricular", "tuition"]
            case .holiday:
                return ["holiday", "christmas", "thanksgiving", "easter", "birthday", "vacation", "summer", "break"]
            case .communication:
                return ["communication", "message", "text", "call", "email", "contact", "discuss", "talk"]
            case .legal:
                return ["court", "lawyer", "attorney", "judge", "hearing", "motion", "contempt", "violation", "decree"]
            case .emergency:
                return ["emergency", "urgent", "crisis", "police", "hospital", "danger", "safety", "abuse", "neglect"]
            case .behavior:
                return ["behavior", "discipline", "rules", "punishment", "therapy", "counseling", "attitude", "problems"]
            case .general:
                return ["general", "advice", "help", "question", "guidance", "support"]
            }
        }
        
        var priority: Int {
            switch self {
            case .emergency: return 10
            case .legal: return 9
            case .medical: return 8
            case .custody: return 7
            case .financial: return 6
            case .education: return 5
            case .schedule: return 4
            case .holiday: return 3
            case .behavior: return 2
            case .communication: return 1
            case .general: return 0
            }
        }
    }
    
    // MARK: - Intent Classification
    enum QueryIntent: String, CaseIterable {
        case question = "question"
        case advice = "advice"
        case template = "template"
        case emergency = "emergency"
        case scheduling = "scheduling"
        case legal = "legal"
        case general = "general"
        
        var patterns: [String] {
            switch self {
            case .question:
                return ["what", "how", "when", "where", "why", "who", "can i", "should i", "is it", "will"]
            case .advice:
                return ["help", "advice", "guidance", "suggest", "recommend", "what should", "how to handle"]
            case .template:
                return ["template", "draft", "write", "message", "response", "reply", "text"]
            case .emergency:
                return ["emergency", "urgent", "crisis", "immediate", "asap", "right now", "help me"]
            case .scheduling:
                return ["schedule", "time", "pickup", "dropoff", "change", "reschedule", "move", "switch"]
            case .legal:
                return ["legal", "court", "lawyer", "rights", "violation", "contempt", "decree"]
            case .general:
                return ["general", "information", "understand", "explain"]
            }
        }
    }
    
    // MARK: - Query Analysis Result
    struct QueryAnalysis {
        let originalQuery: String
        let processedQuery: String
        let detectedTopics: [(topic: CoparentingTopic, confidence: Double)]
        let primaryIntent: QueryIntent
        let semanticKeywords: [String]
        let contextualHints: [String]
        let urgencyLevel: UrgencyLevel
        let complexity: ComplexityLevel
        let memoryContext: ConversationMemoryContext?
        let isRecurringIssue: Bool
        let recurringTheme: ConversationMemoryManager.RecurringTheme?
        
        enum UrgencyLevel: String, CaseIterable {
            case emergency = "emergency"
            case high = "high"
            case medium = "medium"
            case low = "low"
        }
        
        enum ComplexityLevel: String, CaseIterable {
            case simple = "simple"
            case moderate = "moderate"
            case complex = "complex"
        }
    }
    
    // MARK: - Main Processing Method
    @MainActor
    func analyzeQuery(_ query: String, userProfile: UserProfile? = nil, chatManager: ChatManager? = nil) -> QueryAnalysis {
        let lowercased = query.lowercased()
        let words = query.split(separator: " ").map { String($0) }
        
        // 1. Topic Detection with Confidence Scoring
        let detectedTopics = detectTopics(in: lowercased)
        
        // 2. Intent Classification
        let primaryIntent = classifyIntent(in: lowercased)
        
        // 3. Extract Semantic Keywords
        let semanticKeywords = extractSemanticKeywords(from: words, topics: detectedTopics)
        
        // 4. Generate Contextual Hints
        let contextualHints = generateContextualHints(from: query, profile: userProfile, topics: detectedTopics)
        
        // 5. Assess Urgency
        let urgencyLevel = assessUrgency(in: lowercased)
        
        // 6. Determine Complexity
        let complexity = determineComplexity(query: query, topics: detectedTopics, intent: primaryIntent)
        
        // 7. Get Conversation Memory Context
        let memoryContext = chatManager?.getConversationMemoryContext(for: query, userProfile: userProfile?.toDictionary())
        let (isRecurringIssue, recurringTheme) = memoryContext?.isRecurringIssue(query) ?? (false, nil)
        
        // 8. Create Enhanced Query for RAG
        let processedQuery = enhanceQueryForRetrieval(
            original: query,
            topics: detectedTopics,
            intent: primaryIntent,
            keywords: semanticKeywords,
            hints: contextualHints,
            memoryContext: memoryContext
        )
        
        return QueryAnalysis(
            originalQuery: query,
            processedQuery: processedQuery,
            detectedTopics: detectedTopics,
            primaryIntent: primaryIntent,
            semanticKeywords: semanticKeywords,
            contextualHints: contextualHints,
            urgencyLevel: urgencyLevel,
            complexity: complexity,
            memoryContext: memoryContext,
            isRecurringIssue: isRecurringIssue,
            recurringTheme: recurringTheme
        )
    }
    
    // MARK: - Private Helper Methods
    private func detectTopics(in query: String) -> [(topic: CoparentingTopic, confidence: Double)] {
        var topicScores: [CoparentingTopic: Double] = [:]
        
        for topic in CoparentingTopic.allCases {
            var score: Double = 0
            let keywordCount = topic.keywords.count
            
            for keyword in topic.keywords {
                if query.contains(keyword) {
                    // Give higher weight to exact matches and priority topics
                    let keywordWeight = 1.0 / Double(keywordCount)
                    let priorityBonus = Double(topic.priority) * 0.1
                    score += keywordWeight + priorityBonus
                }
            }
            
            if score > 0 {
                topicScores[topic] = score
            }
        }
        
        // Sort by confidence and return top 3
        let sortedTopics = topicScores.sorted { $0.value > $1.value }
            .prefix(3)
            .map { (topic: $0.key, confidence: min($0.value, 1.0)) }
        
        return Array(sortedTopics)
    }
    
    private func classifyIntent(in query: String) -> QueryIntent {
        var intentScores: [QueryIntent: Int] = [:]
        
        for intent in QueryIntent.allCases {
            var score = 0
            for pattern in intent.patterns {
                if query.contains(pattern) {
                    score += 1
                }
            }
            if score > 0 {
                intentScores[intent] = score
            }
        }
        
        // Return highest scoring intent, or general if none found
        return intentScores.max { $0.value < $1.value }?.key ?? .general
    }
    
    private func extractSemanticKeywords(from words: [String], topics: [(topic: CoparentingTopic, confidence: Double)]) -> [String] {
        var keywords: Set<String> = []
        
        // Add topic-specific semantic expansions
        for (topic, _) in topics {
            keywords.formUnion(Set(topic.keywords))
        }
        
        // Add important words from the original query
        let importantWords = words.filter { word in
            word.count > 3 && !["the", "and", "but", "for", "are", "can", "will", "should", "would"].contains(word.lowercased())
        }
        
        keywords.formUnion(Set(importantWords.map { $0.lowercased() }))
        
        return Array(keywords).prefix(10).map { String($0) }
    }
    
    private func generateContextualHints(from query: String, profile: UserProfile?, topics: [(topic: CoparentingTopic, confidence: Double)]) -> [String] {
        var hints: [String] = []
        
        // Add profile-based context
        if let profile = profile {
            if !profile.children.isEmpty {
                let childAges = profile.children.map { "\($0.age)" }.joined(separator: ", ")
                hints.append("Children ages: \(childAges)")
            }
            
            if profile.conflictLevel > 7 {
                hints.append("High conflict situation - emphasize boundaries and documentation")
            }
            
            if let schedule = profile.possessionSchedule {
                hints.append("Custody schedule: \(schedule)")
            }
        }
        
        // Add topic-based context
        for (topic, confidence) in topics {
            if confidence > 0.5 {
                switch topic {
                case .legal:
                    hints.append("Legal context required - suggest documentation and professional consultation")
                case .emergency:
                    hints.append("Emergency situation - prioritize immediate safety and clear action steps")
                case .medical:
                    hints.append("Medical context - consider insurance, consent, and communication protocols")
                default:
                    break
                }
            }
        }
        
        return hints
    }
    
    private func assessUrgency(in query: String) -> QueryAnalysis.UrgencyLevel {
        let emergencyWords = ["emergency", "urgent", "crisis", "immediate", "asap", "right now", "police", "hospital", "danger"]
        let highUrgencyWords = ["soon", "today", "tonight", "quickly", "help", "problem"]
        
        if emergencyWords.contains(where: { query.contains($0) }) {
            return .emergency
        } else if highUrgencyWords.contains(where: { query.contains($0) }) {
            return .high
        } else if query.contains("?") || query.contains("when") {
            return .medium
        } else {
            return .low
        }
    }
    
    private func determineComplexity(query: String, topics: [(topic: CoparentingTopic, confidence: Double)], intent: QueryIntent) -> QueryAnalysis.ComplexityLevel {
        let wordCount = query.split(separator: " ").count
        let questionCount = query.components(separatedBy: "?").count - 1
        let topicCount = topics.count
        
        // Complex if multiple factors present
        if wordCount > 50 || questionCount > 2 || topicCount > 2 || intent == .legal || intent == .emergency {
            return .complex
        } else if wordCount > 15 || questionCount > 0 || topicCount > 1 {
            return .moderate
        } else {
            return .simple
        }
    }
    
    private func enhanceQueryForRetrieval(
        original: String,
        topics: [(topic: CoparentingTopic, confidence: Double)],
        intent: QueryIntent,
        keywords: [String],
        hints: [String],
        memoryContext: ConversationMemoryContext?
    ) -> String {
        var enhancedQuery = original
        
        // Add semantic context for better retrieval
        if !topics.isEmpty {
            let topicNames = topics.map { $0.topic.rawValue }.joined(separator: ", ")
            enhancedQuery += " [Topics: \(topicNames)]"
        }
        
        // Add intent context
        enhancedQuery += " [Intent: \(intent.rawValue)]"
        
        // Add key semantic terms for better matching
        if !keywords.isEmpty {
            let keywordString = keywords.prefix(5).joined(separator: ", ")
            enhancedQuery += " [Keywords: \(keywordString)]"
        }
        
        // Add memory context for better understanding
        if let memoryContext = memoryContext {
            let memoryHints = memoryContext.generateContextualHints()
            if !memoryHints.isEmpty {
                let memoryString = memoryHints.prefix(3).joined(separator: "; ")
                enhancedQuery += " [Previous Context: \(memoryString)]"
            }
            
            // Add relationship trend
            enhancedQuery += " [Relationship Trend: \(memoryContext.relationshipTrend.rawValue)]"
            
            // Add outstanding follow-ups
            let followUps = memoryContext.getOutstandingFollowUps()
            if !followUps.isEmpty {
                let followUpString = followUps.prefix(2).joined(separator: "; ")
                enhancedQuery += " [Outstanding: \(followUpString)]"
            }
        }
        
        return enhancedQuery
    }
}