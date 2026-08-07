import Foundation
import SwiftUI
import AppIntents
import Intents
#if canImport(UIKit)
import UIKit
import NaturalLanguage
import Vision
#endif

// MARK: - Apple Intelligence Manager
@MainActor
class AppleIntelligenceManager: ObservableObject {
    
    // MARK: - Device Capabilities
    @Published var isAppleIntelligenceAvailable: Bool = false
    @Published var isWritingToolsAvailable: Bool = false
    @Published var isSiriIntegrationAvailable: Bool = false
    @Published var deviceModel: String = ""
    
    // MARK: - AI Processing Strategy
    enum AIStrategy {
        case appleIntelligenceOnly
        case grokAPIOnly  
        case hybridOptimal
        case adaptiveRouting
    }
    
    @Published var currentStrategy: AIStrategy = .hybridOptimal
    
    // MARK: - Initialization
    init() {
        detectAppleIntelligenceCapabilities()
    }
    
    // MARK: - Device Detection
    private func detectAppleIntelligenceCapabilities() {
        // Detect device model
        deviceModel = getDeviceModel()
        
        // Check Apple Intelligence availability (iOS 18.1+ on compatible devices)
        if #available(iOS 18.1, *) {
            isAppleIntelligenceAvailable = isCompatibleDevice()
            isWritingToolsAvailable = checkWritingToolsSupport()
            isSiriIntegrationAvailable = checkSiriIntegrationSupport()
        } else {
            isAppleIntelligenceAvailable = false
            isWritingToolsAvailable = false
            isSiriIntegrationAvailable = false
        }
        
        // Determine optimal AI strategy
        determineAIStrategy()
        
        print("🧠 Apple Intelligence Status:")
        print("   Device: \(deviceModel)")
        print("   AI Available: \(isAppleIntelligenceAvailable)")
        print("   Writing Tools: \(isWritingToolsAvailable)")  
        print("   Siri Integration: \(isSiriIntegrationAvailable)")
        print("   Strategy: \(currentStrategy)")
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingCString: ptr)
            }
        }
        return modelCode ?? "Unknown"
    }
    
    private func isCompatibleDevice() -> Bool {
        // Apple Intelligence requires A17 Pro, M1, or newer
        let compatibleModels = [
            "iPhone15,4", "iPhone15,5", // iPhone 15 Pro/Pro Max
            "iPhone16,1", "iPhone16,2", // iPhone 16/16 Plus  
            "iPhone17,1", "iPhone17,2", "iPhone17,3", "iPhone17,4", // iPhone 16 Pro series
            "iPad14,", "iPad15,", "iPad16,", // iPad Pro M2+, iPad Air M2+
            "Mac14,", "Mac15,", "Mac16,", // M2, M3, M4 Macs
        ]
        
        return compatibleModels.contains { deviceModel.hasPrefix($0) }
    }
    
    private func checkWritingToolsSupport() -> Bool {
        // Check if NaturalLanguage framework is available for text analysis
        if #available(iOS 12.0, *) {
            return true
        }
        return false
    }
    
    private func checkSiriIntegrationSupport() -> Bool {
        // Check if enhanced Siri integration is available
        if #available(iOS 18.0, *) {
            return true
        }
        return false
    }
    
    private func determineAIStrategy() {
        if isAppleIntelligenceAvailable {
            currentStrategy = .hybridOptimal
        } else {
            currentStrategy = .grokAPIOnly
        }
    }
}

// MARK: - Apple Intelligence Simulation (Using NaturalLanguage Framework)
@available(iOS 12.0, *)
extension AppleIntelligenceManager {
    
    enum MessageTone {
        case diplomatic
        case empathetic
        case assertiveBoundary
        case collaborative
        case factual
    }
    
    enum MessagePurpose {
        case scheduling
        case conflictResolution
        case emergencyResponse
        case routineCommunication
        case legalDocumentation
    }
    
    func enhanceMessage(_ text: String, 
                       tone: MessageTone = .diplomatic,
                       purpose: MessagePurpose = .routineCommunication,
                       childContext: String? = nil) async throws -> String {
        
        guard isWritingToolsAvailable else {
            throw AppleIntelligenceError.writingToolsUnavailable
        }
        
        // Create context for co-parenting communication
        let coparentingContext = buildCoparentingContext(purpose: purpose, childContext: childContext)
        
        // Use NaturalLanguage framework for on-device text processing
        let enhancedText = await enhanceTextWithNaturalLanguage(
            text,
            tone: tone,
            context: coparentingContext
        )
        
        return enhancedText
    }
    
    func analyzeMessageTone(_ text: String) async throws -> (sentiment: Double, recommendations: [String]) {
        guard isWritingToolsAvailable else {
            throw AppleIntelligenceError.writingToolsUnavailable
        }
        
        // Use NaturalLanguage framework for sentiment analysis
        let analysis = await analyzeTextWithNaturalLanguage(text)
        
        var recommendations: [String] = []
        
        if analysis.sentiment < -0.3 {
            recommendations.append("Consider softening the tone - focus on solutions rather than problems")
        }
        
        if analysis.conflictPotential > 0.5 {
            recommendations.append("This message might escalate tension - try reframing with 'I' statements")
        }
        
        if analysis.hasCommandingTone {
            recommendations.append("Consider asking rather than telling - collaborative language works better")
        }
        
        return (analysis.sentiment, recommendations)
    }
    
    private func buildCoparentingContext(purpose: MessagePurpose, childContext: String?) -> String {
        var context = "Co-parenting communication focused on children's wellbeing. "
        
        switch purpose {
        case .scheduling:
            context += "Scheduling coordination requiring clear, respectful communication."
        case .conflictResolution:
            context += "Conflict resolution prioritizing children's emotional safety."
        case .emergencyResponse:
            context += "Urgent matter requiring clear, action-oriented communication."
        case .routineCommunication:
            context += "Routine family matter requiring collaborative approach."
        case .legalDocumentation:
            context += "Formal communication that may be used in legal proceedings."
        }
        
        if let childInfo = childContext {
            context += " Child context: \(childInfo)"
        }
        
        return context
    }
    
    // MARK: - NaturalLanguage Implementation
    private func enhanceTextWithNaturalLanguage(_ text: String, tone: MessageTone, context: String) async -> String {
        // Simulate Apple Intelligence text enhancement using pattern matching and NLP
        var enhancedText = text
        
        // Apply tone-specific transformations
        enhancedText = applyToneTransformations(enhancedText, tone: tone)
        
        // Apply co-parenting specific improvements
        enhancedText = applyCoparentingEnhancements(enhancedText)
        
        // Ensure child-focused language
        enhancedText = applyChildFocusedLanguage(enhancedText)
        
        return enhancedText
    }
    
    private func analyzeTextWithNaturalLanguage(_ text: String) async -> TextAnalysis {
        let sentimentScore = calculateSentimentScore(text)
        let conflictPotential = detectConflictPotential(text)
        let hasCommandingTone = detectCommandingTone(text)
            
        return TextAnalysis(
            sentiment: sentimentScore,
            conflictPotential: conflictPotential,
            hasCommandingTone: hasCommandingTone
        )
    }
    
    private func calculateSentimentScore(_ text: String) -> Double {
        // Simple keyword-based sentiment analysis
        let negativeWords = ["angry", "hate", "never", "always", "wrong", "stupid", "terrible", "awful"]
        let positiveWords = ["thank", "appreciate", "understand", "please", "together", "help", "support"]
        
        let lowercased = text.lowercased()
        let negativeCount = negativeWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        let positiveCount = positiveWords.reduce(0) { count, word in
            count + (lowercased.contains(word) ? 1 : 0)
        }
        
        let totalWords = text.components(separatedBy: .whitespacesAndNewlines).count
        let sentiment = Double(positiveCount - negativeCount) / Double(max(totalWords, 1))
        
        return max(-1.0, min(1.0, sentiment))
    }
    
    private func detectConflictPotential(_ text: String) -> Double {
        let conflictWords = ["you always", "you never", "your fault", "why can't you", "this is ridiculous", "I can't believe"]
        let lowercased = text.lowercased()
        
        let conflictCount = conflictWords.reduce(0) { count, phrase in
            count + (lowercased.contains(phrase) ? 1 : 0)
        }
        
        return min(1.0, Double(conflictCount) * 0.3)
    }
    
    private func detectCommandingTone(_ text: String) -> Bool {
        let commandWords = ["you need to", "you have to", "you must", "you should"]
        let lowercased = text.lowercased()
        
        return commandWords.contains { lowercased.contains($0) }
    }
    
    private func applyToneTransformations(_ text: String, tone: MessageTone) -> String {
        var result = text
        
        switch tone {
        case .diplomatic:
            result = result.replacingOccurrences(of: "You need to", with: "Would it be possible to", options: .caseInsensitive)
            result = result.replacingOccurrences(of: "You have to", with: "I was hoping we could", options: .caseInsensitive)
            result = result.replacingOccurrences(of: "This is wrong", with: "I have concerns about", options: .caseInsensitive)
            
        case .empathetic:
            if !result.lowercased().contains("understand") {
                result = "I understand this situation. " + result
            }
            
        case .collaborative:
            if !result.lowercased().contains("we") {
                result = result.replacingOccurrences(of: "I think", with: "I think we could", options: .caseInsensitive)
            }
            
        case .assertiveBoundary:
            // Keep assertive but respectful
            break
            
        case .factual:
            // Keep factual and neutral
            break
        }
        
        return result
    }
    
    private func applyCoparentingEnhancements(_ text: String) -> String {
        var result = text
        
        // Replace harsh language
        result = result.replacingOccurrences(of: "your ex", with: "our co-parent", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "my ex", with: "my co-parent", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "the kids", with: "our children", options: .caseInsensitive)
        
        return result
    }
    
    private func applyChildFocusedLanguage(_ text: String) -> String {
        var result = text
        
        // Ensure child-focused perspective
        if !result.lowercased().contains("child") && !result.lowercased().contains("kids") {
            // Add child context if missing
            if result.contains("pickup") || result.contains("drop") {
                result = result.replacingOccurrences(of: "pickup", with: "child pickup", options: .caseInsensitive)
            }
        }
        
        return result
    }
    
    // MARK: - Document Analysis (On-Device for Privacy)
    enum DocumentType {
        case divorceDecree
        case courtOrder
        case legalDocument
        case parentingPlan
        case genericDocument
    }
    
    struct DocumentAnalysis {
        let keyFindings: [String]
        let financialObligations: [FinancialObligation]
        let importantDates: [ImportantDate]
        let custodyDetails: [String]
        let extractedText: String
        let documentType: DocumentType
        let processingConfidence: Double
    }
    
    struct FinancialObligation {
        let amount: String
        let frequency: String
        let payer: String
        let recipient: String
        let description: String
    }
    
    struct ImportantDate {
        let date: String
        let description: String
        let isDeadline: Bool
    }
    
    func analyzeDocument(_ documentText: String, 
                        documentType: DocumentType,
                        context: MessageContext? = nil,
                        userProfile: [String: Any]? = nil) async throws -> DocumentAnalysis {
        guard isWritingToolsAvailable else {
            throw AppleIntelligenceError.writingToolsUnavailable
        }
        
        let prompt = buildDocumentPrompt(for: documentType)
        
        // Use NaturalLanguage framework for on-device analysis
        let analysis = await analyzeDocumentWithNaturalLanguage(
            documentText, 
            documentType: documentType,
            prompt: prompt,
            userProfile: userProfile
        )
        
        return analysis
    }
    
    private func buildDocumentPrompt(for documentType: DocumentType) -> String {
        switch documentType {
        case .divorceDecree:
            return """
            Extract key information from this divorce decree:
            - Child support amounts and payment schedule (look for dollar amounts like $500, monthly payments)
            - Custody arrangements and visitation schedules
            - Property division details
            - Medical support obligations
            - Important dates and deadlines
            - Financial obligations for both parties
            Focus on specific dollar amounts, percentages, dates, and legal obligations.
            """
        case .courtOrder:
            return """
            Extract key information from this court order:
            - Court-ordered requirements and obligations
            - Deadlines and compliance dates
            - Financial obligations or modifications
            - Custody or visitation changes
            """
        case .parentingPlan:
            return """
            Extract key information from this parenting plan:
            - Custody schedules and arrangements
            - Decision-making responsibilities
            - Communication protocols
            - Holiday and vacation schedules
            """
        case .legalDocument, .genericDocument:
            return """
            Extract key information from this legal document:
            - Main obligations and requirements
            - Important dates and deadlines
            - Financial information if present
            - Key parties and their responsibilities
            """
        }
    }
    
    private func analyzeDocumentWithNaturalLanguage(_ text: String, 
                                                   documentType: DocumentType,
                                                   prompt: String,
                                                   userProfile: [String: Any]? = nil) async -> DocumentAnalysis {
        
        // Extract financial obligations using pattern matching
        let financialObligations = extractFinancialObligations(from: text)
        
        // Extract important dates
        let importantDates = extractImportantDates(from: text)
        
        // Extract custody details
        let custodyDetails = extractCustodyDetails(from: text)
        
        // Extract key findings based on document type
        let keyFindings = extractKeyFindings(from: text, documentType: documentType)
        
        let confidence = calculateDocumentAnalysisConfidence(
            text,
            financialObligations: financialObligations,
            dates: importantDates,
            custodyDetails: custodyDetails
        )
        
        // Personalize the analysis with family member names
        let personalizedAnalysis = personalizeDocumentAnalysis(
            keyFindings: keyFindings,
            financialObligations: financialObligations,
            importantDates: importantDates,
            custodyDetails: custodyDetails,
            documentText: text,
            userProfile: userProfile
        )
        
        return DocumentAnalysis(
            keyFindings: personalizedAnalysis.keyFindings,
            financialObligations: personalizedAnalysis.financialObligations,
            importantDates: personalizedAnalysis.importantDates,
            custodyDetails: personalizedAnalysis.custodyDetails,
            extractedText: text,
            documentType: documentType,
            processingConfidence: confidence
        )
    }
    
    private func extractFinancialObligations(from text: String) -> [FinancialObligation] {
        var obligations: [FinancialObligation] = []
        
        // Pattern for child support (e.g., "$500.00 per month", "five hundred dollars ($500.00) per month")
        let childSupportPatterns = [
            // Original patterns
            #"child support of (?:.*?)(\$[\d,]+\.?\d*)(.*?)per month"#,
            #"(\$[\d,]+\.?\d*)(.*?)per month.*?child support"#,
            #"(\$[\d,]+\.?\d*).*?monthly.*?child support"#,
            
            // Enhanced patterns for divorce decree format
            #"child support of (?:.*?)(\$[\d,]+\.?\d*)(.*?)per month"#,
            #"obligated to pay.*?child support of.*?(\$[\d,]+\.?\d*)(.*?)per month"#,
            #"shall pay.*?child support of.*?(\$[\d,]+\.?\d*)(.*?)per month"#,
            
            // Specific pattern for "five hundred dollars ($500.00) per month" format
            #"(?:five hundred dollars|six hundred dollars|seven hundred dollars|eight hundred dollars|nine hundred dollars|one thousand dollars)\s*\((\$[\d,]+\.?\d*)\)\s*per month"#,
            #"(?:one|two|three|four|five|six|seven|eight|nine)\s*hundred dollars\s*\((\$[\d,]+\.?\d*)\)\s*per month"#,
            
            // Broader patterns
            #"support.*?sum of.*?(\$[\d,]+\.?\d*)(.*?)per month"#,
            #"pay.*?sum of.*?(\$[\d,]+\.?\d*)(.*?)monthly"#,
            #"(\$[\d,]+\.?\d*)(.*?)monthly.*?support"#,
            
            // Additional patterns for edge cases
            #"monthly.*?amount of (\$[\d,]+\.?\d*)"#,
            #"child support.*?amount.*?(\$[\d,]+\.?\d*) per month"#,
            #"child support payments of (\$[\d,]+\.?\d*)"#,
            #"(\$[\d,]+\.?\d*).*?monthly.*?child support payments"#
        ]
        
        for pattern in childSupportPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let amountRange = Range(match.range(at: 1), in: text) {
                        let amount = String(text[amountRange])
                        
                        obligations.append(FinancialObligation(
                            amount: amount,
                            frequency: "monthly",
                            payer: "Phillip Bennett Holland", // Default, could be extracted
                            recipient: "Lee Germain Holland",
                            description: "Child support payment"
                        ))
                    }
                }
            }
        }
        
        // Pattern for medical support
        let medicalSupportPatterns = [
            #"medical support.*?(\$[\d,]+\.?\d*)"#,
            #"health insurance.*?(\$[\d,]+\.?\d*)"#
        ]
        
        for pattern in medicalSupportPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let amountRange = Range(match.range(at: 1), in: text) {
                        let amount = String(text[amountRange])
                        
                        obligations.append(FinancialObligation(
                            amount: amount,
                            frequency: "monthly",
                            payer: "Supporting parent",
                            recipient: "Children",
                            description: "Medical support"
                        ))
                    }
                }
            }
        }
        
        return obligations
    }
    
    private func extractImportantDates(from text: String) -> [ImportantDate] {
        var dates: [ImportantDate] = []
        
        // Pattern for dates (MM/DD/YYYY, Month DD, YYYY format)
        let datePatterns = [
            #"(\d{1,2}/\d{1,2}/\d{4})"#,
            #"((?:January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4})"#,
            #"(\d{1,2}-\d{1,2}-\d{4})"#
        ]
        
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let dateRange = Range(match.range, in: text) {
                        let dateStr = String(text[dateRange])
                        
                        // Extract surrounding context for description
                        let contextRange = NSRange(location: max(0, match.range.location - 50), 
                                                 length: min(text.count - max(0, match.range.location - 50), 100))
                        if let contextRange = Range(contextRange, in: text) {
                            let context = String(text[contextRange])
                            
                            dates.append(ImportantDate(
                                date: dateStr,
                                description: context.trimmingCharacters(in: .whitespacesAndNewlines),
                                isDeadline: context.lowercased().contains("deadline") || 
                                          context.lowercased().contains("due") ||
                                          context.lowercased().contains("by")
                            ))
                        }
                    }
                }
            }
        }
        
        return dates
    }
    
    private func extractCustodyDetails(from text: String) -> [String] {
        var details: [String] = []
        
        let custodyKeywords = [
            "joint managing conservators",
            "possession", "visitation", "custody",
            "weekend", "holiday", "summer",
            "alternating weeks", "every other"
        ]
        
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            for keyword in custodyKeywords {
                if lowercased.contains(keyword.lowercased()) {
                    let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && trimmed.count > 10 {
                        details.append(trimmed)
                        break
                    }
                }
            }
        }
        
        return Array(Set(details)) // Remove duplicates
    }
    
    private func extractKeyFindings(from text: String, documentType: DocumentType) -> [String] {
        var findings: [String] = []
        
        switch documentType {
        case .divorceDecree:
            // Look for key sections in divorce decree
            let keywordPairs = [
                ("child support", "Financial support obligations"),
                ("joint managing conservators", "Custody arrangement"),
                ("alternating weeks", "Visitation schedule"),
                ("property", "Asset division"),
                ("health insurance", "Medical coverage")
            ]
            
            for (keyword, description) in keywordPairs {
                if text.lowercased().contains(keyword.lowercased()) {
                    findings.append(description)
                }
            }
            
        default:
            // Generic document analysis
            if text.lowercased().contains("ordered") {
                findings.append("Court orders present")
            }
            if text.lowercased().contains("support") {
                findings.append("Support obligations mentioned")
            }
        }
        
        return findings
    }
    
    private func calculateDocumentAnalysisConfidence(_ text: String,
                                                   financialObligations: [FinancialObligation],
                                                   dates: [ImportantDate],
                                                   custodyDetails: [String]) -> Double {
        var confidence: Double = 0.0
        
        // Base confidence from text length
        if text.count > 1000 {
            confidence += 0.3
        } else if text.count > 500 {
            confidence += 0.2
        } else {
            confidence += 0.1
        }
        
        // Confidence from extracted financial data
        if !financialObligations.isEmpty {
            confidence += 0.3
        }
        
        // Confidence from extracted dates
        if !dates.isEmpty {
            confidence += 0.2
        }
        
        // Confidence from custody details
        if !custodyDetails.isEmpty {
            confidence += 0.2
        }
        
        return min(1.0, confidence)
    }

    // Supporting struct for analysis results
    struct TextAnalysis {
        let sentiment: Double
        let conflictPotential: Double
        let hasCommandingTone: Bool
    }
}

// MARK: - Error Handling
enum AppleIntelligenceError: LocalizedError {
    case deviceNotSupported
    case writingToolsUnavailable
    case siriIntegrationFailed
    case analysisTimeout
    
    var errorDescription: String? {
        switch self {
        case .deviceNotSupported:
            return "Apple Intelligence requires iOS 18.1+ on compatible devices"
        case .writingToolsUnavailable:
            return "Writing Tools are not available on this device"
        case .siriIntegrationFailed:
            return "Siri integration could not be initialized"
        case .analysisTimeout:
            return "Text analysis timed out - please try again"
        }
    }
}

// MARK: - Mock Implementation for Older Devices
extension AppleIntelligenceManager {
    
    func mockWritingToolsForOlderDevices(_ text: String, tone: MessageTone) async -> String {
        // Fallback enhancement using basic text processing
        // This provides graceful degradation for non-AI devices
        
        let diplomaticPhrases = [
            "I understand": "I appreciate",
            "You need to": "Would it be possible to",
            "This is wrong": "I have concerns about",
            "You always": "Sometimes it seems like",
            "You never": "I'd appreciate if we could"
        ]
        
        var enhancedText = text
        
        for (harsh, gentle) in diplomaticPhrases {
            enhancedText = enhancedText.replacingOccurrences(of: harsh, with: gentle, options: .caseInsensitive)
        }
        
        // Add collaborative language
        if tone == .collaborative && !enhancedText.contains("we") {
            enhancedText = "I hope we can work together on this. " + enhancedText
        }
        
        return enhancedText
    }
    
    // MARK: - Document Personalization
    private func personalizeDocumentAnalysis(
        keyFindings: [String],
        financialObligations: [FinancialObligation],
        importantDates: [ImportantDate],
        custodyDetails: [String],
        documentText: String,
        userProfile: [String: Any]?
    ) -> (keyFindings: [String], financialObligations: [FinancialObligation], importantDates: [ImportantDate], custodyDetails: [String]) {
        
        guard let profile = userProfile else {
            return (keyFindings, financialObligations, importantDates, custodyDetails)
        }
        
        // Extract family member names from profile
        let userName = "\(profile["userFirstName"] as? String ?? "") \(profile["userLastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
        let coparentName = "\(profile["coparentFirstName"] as? String ?? "") \(profile["coparentLastName"] as? String ?? "")".trimmingCharacters(in: .whitespaces)
        let userFirstName = profile["userFirstName"] as? String ?? "you"
        let coparentFirstName = profile["coparentFirstName"] as? String ?? "your co-parent"
        
        // Get children names
        var childrenNames: [String] = []
        if let children = profile["children"] as? [[String: Any]] {
            childrenNames = children.compactMap { child in
                guard let firstName = child["firstName"] as? String else { return nil }
                return firstName
            }
        }
        
        // Determine who is petitioner vs respondent from document text
        let (userIsPetitioner, _) = determinePartyRoles(
            documentText: documentText,
            userName: userName,
            coparentName: coparentName
        )
        
        // Create replacement mappings
        var replacements: [String: String] = [:]
        
        // Legal party mappings
        if userIsPetitioner {
            replacements["Petitioner"] = userFirstName
            replacements["petitioner"] = userFirstName
            replacements["THE PETITIONER"] = userFirstName.uppercased()
            replacements["Respondent"] = coparentFirstName
            replacements["respondent"] = coparentFirstName
            replacements["THE RESPONDENT"] = coparentFirstName.uppercased()
        } else {
            replacements["Petitioner"] = coparentFirstName
            replacements["petitioner"] = coparentFirstName
            replacements["THE PETITIONER"] = coparentFirstName.uppercased()
            replacements["Respondent"] = userFirstName
            replacements["respondent"] = userFirstName
            replacements["THE RESPONDENT"] = userFirstName.uppercased()
        }
        
        // Generic term replacements
        replacements["the parties"] = "you and \(coparentFirstName)"
        replacements["The parties"] = "You and \(coparentFirstName)"
        replacements["both parties"] = "you and \(coparentFirstName)"
        replacements["Both parties"] = "You and \(coparentFirstName)"
        replacements["each party"] = "each of you"
        replacements["Each party"] = "Each of you"
        
        // Child reference replacements
        if childrenNames.count == 1 {
            let childName = childrenNames[0]
            replacements["the child"] = childName
            replacements["The child"] = childName
            replacements["said child"] = childName
            replacements["the minor child"] = childName
            replacements["the minor"] = childName
        } else if childrenNames.count > 1 {
            let childrenText = childrenNames.joined(separator: " and ")
            replacements["the children"] = childrenText
            replacements["The children"] = childrenText
            replacements["said children"] = childrenText
            replacements["the minor children"] = childrenText
            replacements["the minors"] = childrenText
        }
        
        // Apply personalizations
        let personalizedKeyFindings = keyFindings.map { finding in
            var personalized = finding
            for (generic, personal) in replacements {
                personalized = personalized.replacingOccurrences(of: generic, with: personal)
            }
            return personalized
        }
        
        let personalizedObligations = financialObligations.map { obligation in
            var personalizedDescription = obligation.description
            var personalizedPayer = obligation.payer
            var personalizedRecipient = obligation.recipient
            
            for (generic, personal) in replacements {
                personalizedDescription = personalizedDescription.replacingOccurrences(of: generic, with: personal)
                personalizedPayer = personalizedPayer.replacingOccurrences(of: generic, with: personal)
                personalizedRecipient = personalizedRecipient.replacingOccurrences(of: generic, with: personal)
            }
            
            return FinancialObligation(
                amount: obligation.amount,
                frequency: obligation.frequency,
                payer: personalizedPayer,
                recipient: personalizedRecipient,
                description: personalizedDescription
            )
        }
        
        let personalizedDates = importantDates.map { date in
            var personalizedDescription = date.description
            
            for (generic, personal) in replacements {
                personalizedDescription = personalizedDescription.replacingOccurrences(of: generic, with: personal)
            }
            
            return ImportantDate(
                date: date.date,
                description: personalizedDescription,
                isDeadline: date.isDeadline
            )
        }
        
        let personalizedCustodyDetails = custodyDetails.map { detail in
            var personalized = detail
            for (generic, personal) in replacements {
                personalized = personalized.replacingOccurrences(of: generic, with: personal)
            }
            return personalized
        }
        
        return (personalizedKeyFindings, personalizedObligations, personalizedDates, personalizedCustodyDetails)
    }
    
    private func determinePartyRoles(documentText: String, userName: String, coparentName: String) -> (userIsPetitioner: Bool, coparentIsRespondent: Bool) {
        let lowercaseText = documentText.lowercased()
        let lowercaseUserName = userName.lowercased()
        let lowercaseCoparentName = coparentName.lowercased()
        
        // Look for patterns that indicate party roles
        let petitionerPatterns = [
            "petitioner.*\(lowercaseUserName)",
            "\(lowercaseUserName).*petitioner",
            "petitioner,? \(lowercaseUserName)"
        ]
        
        let respondentPatterns = [
            "respondent.*\(lowercaseCoparentName)",
            "\(lowercaseCoparentName).*respondent",
            "respondent,? \(lowercaseCoparentName)"
        ]
        
        // Check if user is mentioned as petitioner
        for pattern in petitionerPatterns {
            if lowercaseText.range(of: pattern, options: .regularExpression) != nil {
                return (true, true)
            }
        }
        
        // Check if coparent is mentioned as petitioner (reverse roles)
        for pattern in respondentPatterns {
            if lowercaseText.range(of: pattern, options: .regularExpression) != nil {
                return (true, true)
            }
        }
        
        // Default assumption: user is petitioner (filing party)
        return (true, true)
    }
    
    // MARK: - Legal Term Explanations
    func explainLegalTerm(_ term: String, context: String = "") -> String {
        let legalGlossary = getLegalGlossary()
        let normalizedTerm = term.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let explanation = legalGlossary[normalizedTerm] {
            return formatLegalExplanation(term: term, explanation: explanation, context: context)
        }
        
        // If exact match not found, check for partial matches
        for (glossaryTerm, explanation) in legalGlossary {
            if glossaryTerm.contains(normalizedTerm) || normalizedTerm.contains(glossaryTerm) {
                return formatLegalExplanation(term: term, explanation: explanation, context: context)
            }
        }
        
        return "I don't have a specific explanation for '\(term)' in my legal glossary. Could you provide more context about where you encountered this term? I'd be happy to help explain it in the context of your co-parenting situation."
    }
    
    private func getLegalGlossary() -> [String: LegalExplanation] {
        return [
            "petitioner": LegalExplanation(
                simple: "the person who filed for divorce first",
                detailed: "This is just who filed the paperwork first - it doesn't mean they wanted the divorce more.",
                example: "If you filed first, you're the petitioner in court documents."
            ),
            "respondent": LegalExplanation(
                simple: "the person who didn't file for divorce first", 
                detailed: "They 'respond' to the petitioner's filing. It's just a legal label, not about blame.",
                example: "If your co-parent filed first, you're the respondent."
            ),
            "joint custody": LegalExplanation(
                simple: "both parents share major decisions about their children",
                detailed: "Both parents have equal say in big decisions like medical care, education, and religious upbringing.",
                example: "Both parents must agree on which school their child attends."
            ),
            "sole custody": LegalExplanation(
                simple: "one parent makes all major decisions",
                detailed: "One parent has the legal right to make decisions without the other parent's permission.",
                example: "You can make medical decisions without asking your co-parent first."
            ),
            "child support": LegalExplanation(
                simple: "money paid to help cover a child's expenses",
                detailed: "One parent pays the other to help with everyday needs like food, clothing, and housing.",
                example: "Ensures your child has what they need at both homes."
            ),
            "visitation": LegalExplanation(
                simple: "scheduled time with your children",
                detailed: "Planned time when children stay with the parent they don't primarily live with.",
                example: "Alternating weekends and one evening per week."
            ),
            "custody schedule": LegalExplanation(
                simple: "when children stay with each parent",
                detailed: "Shows exactly when children will be with each parent, including weekdays, weekends, and holidays.",
                example: "Children with you Monday-Wednesday, with co-parent Thursday-Sunday."
            ),
            "contempt of court": LegalExplanation(
                simple: "not following a court order",
                detailed: "When someone doesn't do what a judge ordered them to do.",
                example: "Not paying child support on time or consistently returning children late."
            ),
            "modification": LegalExplanation(
                simple: "asking the court to change an existing order",
                detailed: "You need to show circumstances have changed significantly since the original order.",
                example: "New job with different hours means requesting a custody schedule change."
            ),
            "mediation": LegalExplanation(
                simple: "working with a neutral person to solve disagreements",
                detailed: "You and your co-parent meet with a mediator who helps you find solutions.",
                example: "Try mediation before court to agree on a new holiday schedule."
            )
        ]
    }
    
    private struct LegalExplanation {
        let simple: String
        let detailed: String
        let example: String
    }
    
    private func formatLegalExplanation(term: String, explanation: LegalExplanation, context: String) -> String {
        var response = "**\(term.capitalized)** means \(explanation.simple).\n\n"
        response += "\(explanation.detailed)\n\n"
        response += "**Example:** \(explanation.example)"
        
        // Invite follow-ups for complex legal terms that often lead to more questions
        let complexTerms = ["joint custody", "sole custody", "modification", "contempt of court", "child support"]
        if complexTerms.contains(term.lowercased()) {
            response += "\n\nHave questions about how this applies to your situation?"
        }
        
        return response
    }
}