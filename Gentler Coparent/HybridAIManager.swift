import Foundation
import SwiftUI
import Combine

// MARK: - AI Errors
enum AIError: LocalizedError {
    case unsupportedProcessor(String)
    case processingFailed(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedProcessor(let message):
            return "Unsupported processor: \(message)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Hybrid AI Manager
// Intelligently routes between Apple Intelligence and Grok API based on task type and device capabilities

@MainActor
class HybridAIManager: ObservableObject {
    
    // MARK: - Dependencies
    @Published private var appleIntelligence: AppleIntelligenceManager
    @Published private var networkManager: NetworkManager
    
    // MARK: - Processing Statistics
    @Published var processingStats = ProcessingStats()
    
    // MARK: - Configuration
    struct AIRoutingConfig {
        let preferAppleIntelligence: Bool
        let fallbackToGrok: Bool
        let maxAppleIntelligenceLength: Int
        let confidenceThreshold: Double
        
        static let `default` = AIRoutingConfig(
            preferAppleIntelligence: true,
            fallbackToGrok: true,
            maxAppleIntelligenceLength: 1000,
            confidenceThreshold: 0.7
        )
    }
    
    @Published var config: AIRoutingConfig
    
    // MARK: - Task Classification
    enum AITask {
        case messageRewriting
        case toneAnalysis
        case conflictDetection
        case quickResponse
        case legalGuidance
        case crisisIntervention
        case documentAnalysis
        case comprehensiveAdvice
        
        var preferredProcessor: ProcessorType {
            switch self {
            case .messageRewriting, .toneAnalysis, .conflictDetection, .quickResponse:
                return .appleIntelligence
            case .legalGuidance, .crisisIntervention, .comprehensiveAdvice:
                return .grokAPI
            case .documentAnalysis:
                return .appleIntelligence
            }
        }
        
        var requiresPrivacy: Bool {
            switch self {
            case .messageRewriting, .toneAnalysis, .conflictDetection, .quickResponse:
                return true
            case .documentAnalysis:
                return true
            case .legalGuidance, .crisisIntervention, .comprehensiveAdvice:
                return false
            }
        }
    }
    
    enum ProcessorType {
        case appleIntelligence
        case grokAPI
        case hybrid
    }
    
    // MARK: - Initialization
    init(appleIntelligence: AppleIntelligenceManager? = nil,
         networkManager: NetworkManager? = nil) {
        self.appleIntelligence = appleIntelligence ?? AppleIntelligenceManager()
        self.networkManager = networkManager ?? NetworkManager()
        self.config = .default
    }
    
    // MARK: - Main Processing Interface
    func processMessage(_ message: String, 
                       task: AITask,
                       context: MessageContext) async throws -> AIResponse {
        
        let startTime = Date()
        processingStats.totalRequests += 1
        
        // Determine optimal processor
        let processor = determineProcessor(for: task, messageLength: message.count)
        
        let response: AIResponse
        
        do {
            switch processor {
            case .appleIntelligence:
                if #available(iOS 18.1, *) {
                    response = try await processWithAppleIntelligence(message, task: task, context: context)
                    processingStats.appleIntelligenceRequests += 1
                } else {
                    throw AIError.unsupportedProcessor("Apple Intelligence requires iOS 18.1 or later")
                }
                
            case .grokAPI:
                response = try await processWithGrokAPI(message, task: task, context: context)
                processingStats.grokAPIRequests += 1
                
            case .hybrid:
                response = try await processWithHybridApproach(message, task: task, context: context)
                processingStats.hybridRequests += 1
            }
            
            processingStats.successfulRequests += 1
            
        } catch {
            processingStats.failedRequests += 1
            
            // Intelligent fallback to cloud expert path
            if processor == .appleIntelligence && config.fallbackToGrok {
                print("🔄 Apple Intelligence failed, falling back to cloud expert API")
                response = try await processWithGrokAPI(message, task: task, context: context)
                processingStats.fallbackRequests += 1
            } else {
                throw error
            }
        }
        
        // Update performance metrics
        let processingTime = Date().timeIntervalSince(startTime)
        processingStats.updateAverageResponseTime(processingTime)
        
        // Final identity lock: GCP never identifies as any other model brand.
        return AIResponse(
            text: ExpertSystem.sanitizeResponseIdentity(response.text),
            processor: response.processor,
            confidence: response.confidence,
            processingTime: processingTime,
            privacy: response.privacy
        )
    }
    
    // MARK: - Processor Determination
    private func determineProcessor(for task: AITask, messageLength: Int) -> ProcessorType {
        
        // Privacy-critical tasks prefer on-device processing
        if task.requiresPrivacy && appleIntelligence.isAppleIntelligenceAvailable {
            return .appleIntelligence
        }
        
        // Long messages or complex tasks may need cloud processing
        if messageLength > config.maxAppleIntelligenceLength {
            return .grokAPI
        }
        
        // Use task preference with device capability check
        switch task.preferredProcessor {
        case .appleIntelligence:
            return appleIntelligence.isAppleIntelligenceAvailable ? .appleIntelligence : .grokAPI
        case .grokAPI:
            return .grokAPI
        case .hybrid:
            return appleIntelligence.isAppleIntelligenceAvailable ? .hybrid : .grokAPI
        }
    }
    
    // MARK: - Apple Intelligence Processing
    @available(iOS 18.1, *)
    private func processWithAppleIntelligence(_ message: String, 
                                             task: AITask,
                                             context: MessageContext) async throws -> AIResponse {
        
        let result: String
        
        switch task {
        case .messageRewriting:
            result = try await appleIntelligence.enhanceMessage(
                message,
                tone: context.desiredTone,
                purpose: context.purpose,
                childContext: context.childContext
            )
            
        case .toneAnalysis:
            let analysis = try await appleIntelligence.analyzeMessageTone(message)
            result = formatToneAnalysis(analysis)
            
        case .conflictDetection:
            let analysis = try await appleIntelligence.analyzeMessageTone(message)
            result = analysis.sentiment < -0.3 ? "High conflict potential detected" : "Message tone appears constructive"
            
        case .quickResponse:
            result = try await generateQuickResponseWithAppleIntelligence(message, context: context)
            
        case .documentAnalysis:
            // Use Apple Intelligence for secure on-device document analysis
            if let documentType = context.documentType {
                // For document analysis, the message should contain the document text
                let analysis = try await appleIntelligence.analyzeDocument(message, documentType: documentType, context: context, userProfile: context.userProfile)
                result = formatDocumentAnalysis(analysis)
            } else {
                // Fallback for general document analysis
                let analysis = try await appleIntelligence.analyzeDocument(message, documentType: .genericDocument, context: context, userProfile: context.userProfile)
                result = formatDocumentAnalysis(analysis)
            }
            
        case .comprehensiveAdvice, .legalGuidance:
            // For comprehensive advice and legal guidance, include document context
            result = try await appleIntelligence.enhanceMessage(
                message,
                tone: context.desiredTone,
                purpose: context.purpose,
                childContext: context.childContext
            )
            
        default:
            // Fallback to mock processing for unsupported tasks
            result = await appleIntelligence.mockWritingToolsForOlderDevices(message, tone: context.desiredTone)
        }
        
        return AIResponse(
            text: ExpertSystem.sanitizeResponseIdentity(result),
            processor: .appleIntelligence,
            confidence: 0.9,
            processingTime: 0.5,
            privacy: .fullyPrivate
        )
    }
    
    // MARK: - Grok API Processing  
    private func processWithGrokAPI(_ message: String,
                                   task: AITask, 
                                   context: MessageContext) async throws -> AIResponse {
        
        // Build comprehensive system prompt
        let systemPrompt = buildSystemPrompt(for: task, context: context)
        
        // Prepare messages for API
        let messages = [["role": "user", "content": message]]
        
        // Prefer profile from MessageContext; fall back to stored profile.
        nonisolated(unsafe) let userProfile = context.userProfile ?? loadUserProfileDictionary()
        
        nonisolated(unsafe) let netManager = networkManager
        let result = await netManager.performChatRequest(
            systemPrompt: systemPrompt,
            messages: messages,
            userProfile: userProfile
        )
        
        switch result {
        case .success(let response):
            // Never surface provider identity to the user.
            return AIResponse(
                text: ExpertSystem.sanitizeResponseIdentity(response),
                processor: .grokAPI,
                confidence: 0.8,
                processingTime: 2.0,
                privacy: .cloudProcessed
            )
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Hybrid Processing
    private func processWithHybridApproach(_ message: String,
                                          task: AITask,
                                          context: MessageContext) async throws -> AIResponse {
        
        // Use Apple Intelligence for initial processing
        var appleResult: AIResponse? = nil
        if appleIntelligence.isAppleIntelligenceAvailable {
            do {
                if #available(iOS 18.1, *) {
                    appleResult = try await processWithAppleIntelligence(message, task: task, context: context)
                }
            } catch {
                print("⚠️ Apple Intelligence failed in hybrid mode: \(error)")
            }
        }
        
        // Use Grok API for enhancement or validation
        let grokResult = try await processWithGrokAPI(message, task: task, context: context)
        
        // Combine results intelligently
        let combinedResult: String
        if let apple = appleResult {
            combinedResult = combineResponses(apple: apple.text, grok: grokResult.text, task: task)
        } else {
            combinedResult = grokResult.text
        }
        
        return AIResponse(
            text: ExpertSystem.sanitizeResponseIdentity(combinedResult),
            processor: .hybrid,
            confidence: 0.85,
            processingTime: max(appleResult?.processingTime ?? 0, grokResult.processingTime),
            privacy: .hybridProcessing
        )
    }
    
    // MARK: - Helper Methods
    private func buildSystemPrompt(for task: AITask, context: MessageContext) -> String {
        // Prefer caller-supplied expert prompt; otherwise build from ExpertSystem.
        if let supplied = context.systemPrompt, !supplied.isEmpty {
            let doc = context.childContext ?? ""
            if doc.isEmpty { return supplied }
            return supplied + "\n\n**FAMILY / DOCUMENT / HISTORY CONTEXT:**\n" + doc
        }
        
        let conflict = (context.userProfile?["conflictLevel"] as? Int) ?? 5
        let state = context.userProfile?["stateOfResidence"] as? String
        let taskLabel: String = switch task {
        case .legalGuidance: "legalGuidance"
        case .crisisIntervention: "crisisIntervention"
        case .documentAnalysis: "documentAnalysis"
        case .comprehensiveAdvice: "comprehensiveAdvice"
        case .messageRewriting: "messageRewriting"
        default: "comprehensiveAdvice"
        }
        
        let prompt = ExpertSystem.buildSystemPrompt(
            conflictLevel: conflict,
            stateOfResidence: state,
            taskLabel: taskLabel,
            extraContext: context.childContext ?? ""
        )
        print("📝 HybridAIManager: Expert system prompt length: \(prompt.count)")
        return prompt
    }
    
    @available(iOS 18.1, *)
    private func generateQuickResponseWithAppleIntelligence(_ message: String, context: MessageContext) async throws -> String {
        // Use Apple Intelligence to generate contextually appropriate quick responses
        let enhancedPrompt = "Generate a brief, diplomatic response to: \(message)"
        return try await appleIntelligence.enhanceMessage(
            enhancedPrompt,
            tone: .diplomatic,
            purpose: .routineCommunication
        )
    }
    
    private func combineResponses(apple: String, grok: String, task: AITask) -> String {
        switch task {
        case .documentAnalysis:
            // Use Apple Intelligence for privacy-sensitive content, Grok for comprehensive analysis
            return "On-device analysis: \(apple)\n\nDetailed insights: \(ExpertSystem.sanitizeResponseIdentity(grok))"
        default:
            return ExpertSystem.sanitizeResponseIdentity(grok)
        }
    }
    
    private func formatToneAnalysis(_ analysis: (sentiment: Double, recommendations: [String])) -> String {
        let sentimentDescription = analysis.sentiment > 0.3 ? "Positive" : 
                                 analysis.sentiment < -0.3 ? "Negative" : "Neutral"
        
        var result = "Sentiment: \(sentimentDescription) (\(String(format: "%.2f", analysis.sentiment)))"
        
        if !analysis.recommendations.isEmpty {
            result += "\n\nSuggestions:\n" + analysis.recommendations.map { "• \($0)" }.joined(separator: "\n")
        }
        
        return result
    }
    
    private func formatDocumentAnalysis(_ analysis: AppleIntelligenceManager.DocumentAnalysis) -> String {
        var result = "📋 **Document Analysis Summary**\n\n"
        
        if !analysis.keyFindings.isEmpty {
            result += "🔍 **Key Findings:**\n"
            analysis.keyFindings.forEach { finding in
                result += "• \(finding)\n"
            }
            result += "\n"
        }
        
        if !analysis.financialObligations.isEmpty {
            result += "💰 **Financial Obligations:**\n"
            analysis.financialObligations.forEach { obligation in
                result += "• \(obligation)\n"
            }
            result += "\n"
        }
        
        if !analysis.importantDates.isEmpty {
            result += "📅 **Important Dates:**\n"
            analysis.importantDates.forEach { date in
                result += "• \(date)\n"
            }
            result += "\n"
        }
        
        if !analysis.custodyDetails.isEmpty {
            result += "👨‍👩‍👧‍👦 **Custody Details:**\n"
            analysis.custodyDetails.forEach { detail in
                result += "• \(detail)\n"
            }
        }
        
        return result
    }
    
    // MARK: - User Profile Loading
    private nonisolated func loadUserProfileDictionary() -> [String: Any]? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        
        // Prefer shared dictionary (includes children + decree excerpt for server prompt)
        return profile.toDictionary()
    }
}

// MARK: - Supporting Types
struct MessageContext {
    let desiredTone: AppleIntelligenceManager.MessageTone
    let purpose: AppleIntelligenceManager.MessagePurpose
    let childContext: String?
    let systemPrompt: String?
    let documentData: Data?
    let documentType: AppleIntelligenceManager.DocumentType?
    let userProfile: [String: Any]?
    
    init(tone: AppleIntelligenceManager.MessageTone = .diplomatic,
         purpose: AppleIntelligenceManager.MessagePurpose = .routineCommunication,
         childContext: String? = nil,
         systemPrompt: String? = nil,
         documentData: Data? = nil,
         documentType: AppleIntelligenceManager.DocumentType? = nil,
         userProfile: [String: Any]? = nil) {
        self.desiredTone = tone
        self.purpose = purpose
        self.childContext = childContext
        self.systemPrompt = systemPrompt
        self.documentData = documentData
        self.documentType = documentType
        self.userProfile = userProfile
    }
}

struct AIResponse {
    let text: String
    let processor: HybridAIManager.ProcessorType
    let confidence: Double
    let processingTime: TimeInterval
    let privacy: PrivacyLevel
    
    enum PrivacyLevel {
        case fullyPrivate      // Apple Intelligence on-device
        case cloudProcessed    // Grok API cloud processing
        case hybridProcessing  // Combination of both
    }
}

struct ProcessingStats {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var appleIntelligenceRequests: Int = 0
    var grokAPIRequests: Int = 0
    var hybridRequests: Int = 0
    var fallbackRequests: Int = 0
    
    private var responseTimes: [TimeInterval] = []
    
    var averageResponseTime: TimeInterval {
        responseTimes.isEmpty ? 0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    var successRate: Double {
        totalRequests == 0 ? 0 : Double(successfulRequests) / Double(totalRequests)
    }
    
    mutating func updateAverageResponseTime(_ time: TimeInterval) {
        responseTimes.append(time)
        // Keep only last 100 measurements for rolling average
        if responseTimes.count > 100 {
            responseTimes.removeFirst()
        }
    }
}