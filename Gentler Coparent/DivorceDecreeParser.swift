import Foundation
import PDFKit
import NaturalLanguage

// MARK: - Advanced Divorce Decree Parser
class DivorceDecreeParser: ObservableObject {
    
    // MARK: - Structured Data Models
    struct ParsedDivorceDecree: Codable {
        let rawText: String
        let parsingConfidence: Double
        let parties: PartyInformation
        let children: [ParsedChildInfo]
        let custodyArrangement: CustodyArrangement
        let schedule: VisitationSchedule
        let financialTerms: FinancialTerms
        let medicalProvisions: MedicalProvisions
        let educationProvisions: EducationProvisions
        let holidaySchedule: HolidaySchedule
        let restrictions: [String]
        let specialProvisions: [String]
        let courtInformation: CourtInformation
        let keyDates: [String: Date]
        let extractedSections: [DocumentSection]
        
        struct PartyInformation: Codable {
            let petitioner: String?
            let respondent: String?
            let petitionerAddress: String?
            let respondentAddress: String?
            let caseNumber: String?
        }
        
        struct ParsedChildInfo: Codable {
            let name: String
            let birthDate: Date?
            let age: Int?
            let gender: String?
            let specialNeeds: String?
        }
        
        struct CustodyArrangement: Codable {
            let type: CustodyType
            let primaryResidence: String?
            let jointDecisionMaking: Bool
            let details: String
            
            enum CustodyType: String, CaseIterable, Codable {
                case joint = "joint"
                case sole = "sole"
                case split = "split"
                case shared = "shared"
                case unknown = "unknown"
            }
        }
        
        struct VisitationSchedule: Codable {
            let standardSchedule: String?
            let weekendSchedule: String?
            let weekdaySchedule: String?
            let summerSchedule: String?
            let exchangeLocation: String?
            let exchangeTime: String?
            let modifications: [String]
        }
        
        struct FinancialTerms: Codable {
            let childSupport: ChildSupportInfo?
            let spousalSupport: SpousalSupportInfo?
            let expenseSharing: ExpenseSharing?
            
            struct ChildSupportInfo: Codable {
                let amount: String?
                let frequency: String?
                let payer: String?
                let endDate: Date?
                let modifications: [String]
            }
            
            struct SpousalSupportInfo: Codable {
                let amount: String?
                let frequency: String?
                let duration: String?
                let payer: String?
            }
            
            struct ExpenseSharing: Codable {
                let medical: String?
                let education: String?
                let extracurricular: String?
                let childcare: String?
            }
        }
        
        struct MedicalProvisions: Codable {
            let insuranceProvider: String?
            let insurancePayer: String?
            let uninsuredExpenses: String?
            let decisionMaking: String?
            let emergencyAuthorization: String?
        }
        
        struct EducationProvisions: Codable {
            let schoolChoice: String?
            let decisionMaking: String?
            let expenseSharing: String?
            let extracurriculars: String?
        }
        
        struct HolidaySchedule: Codable {
            let christmas: String?
            let thanksgiving: String?
            let easter: String?
            let birthdayArrangement: String?
            let vacationTime: String?
            let otherHolidays: [String: String]
        }
        
        struct CourtInformation: Codable {
            let courtName: String?
            let judgeName: String?
            let finalDate: Date?
            let caseNumber: String?
            let filingDate: Date?
        }
        
        struct DocumentSection: Codable {
            let title: String
            let content: String
            let relevanceScore: Double
            let category: SectionCategory
            
            enum SectionCategory: String, CaseIterable, Codable {
                case custody = "custody"
                case visitation = "visitation"
                case financial = "financial"
                case medical = "medical"
                case education = "education"
                case holiday = "holiday"
                case general = "general"
                case restrictions = "restrictions"
            }
        }
    }
    
    // MARK: - Parsing Configuration
    struct ParsingConfig {
        let enableAdvancedNLP: Bool = true
        let confidenceThreshold: Double = 0.7
        let enableEntityRecognition: Bool = true
        let enableDateExtraction: Bool = true
        let maxSections: Int = 20
    }
    
    // MARK: - Regular Expression Patterns
    private struct RegexPatterns {
        // Party Information
        static let petitioner = #"(?i)petitioner(?:['']?s?)?\s*[:\-]?\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        static let respondent = #"(?i)respondent(?:['']?s?)?\s*[:\-]?\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        static let caseNumber = #"(?i)(?:case|cause)\s*(?:no\.?|number)?\s*[:\-]?\s*([0-9\-A-Z]+)"#
        
        // Child Information
        static let childName = #"(?i)(?:minor )?child(?:ren)?(?:'?s?)?\s*(?:name|named)?\s*[:\-]?\s*([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
        static let birthDate = #"(?i)(?:born|birth(?:\s*date)?)\s*[:\-]?\s*([A-Za-z]+ \d{1,2}, \d{4}|\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2})"#
        
        // Financial Terms
        static let childSupport = #"(?i)child support.*?(?:\$)?([\d,]+(?:\.\d{2})?)\s*(?:per|/)\s*(month|week)"#
        static let spousalSupport = #"(?i)(?:spousal|alimony).*?(?:\$)?([\d,]+(?:\.\d{2})?)\s*(?:per|/)\s*(month|week)"#
        
        // Schedule Information
        static let weekendSchedule = #"(?i)(?:weekend|saturday|friday).*?(?:from|at)?\s*(\d{1,2}:\d{2}(?:\s*[ap]m)?)"#
        static let exchangeTime = #"(?i)(?:exchange|pickup|drop.*?off).*?(?:at|@)?\s*(\d{1,2}:\d{2}(?:\s*[ap]m)?)"#
        
        // Holiday Patterns
        static let christmas = #"(?i)christmas.*?(?:with|to)\s*(petitioner|respondent|mother|father)"#
        static let thanksgiving = #"(?i)thanksgiving.*?(?:with|to)\s*(petitioner|respondent|mother|father)"#
        
        // Custody Type
        static let custodyType = #"(?i)(joint|sole|shared|split)\s*(?:legal|physical)?\s*custody"#
        
        // Dates
        static let datePattern = #"([A-Za-z]+ \d{1,2}, \d{4}|\d{1,2}/\d{1,2}/\d{4}|\d{4}-\d{2}-\d{2})"#
        
        // Court Information
        static let courtName = #"(?i)(?:in the|before the)\s+([^,\n]+court[^,\n]*)"#
        static let judgeName = #"(?i)(?:judge|hon\.?|honorable)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)"#
    }
    
    // MARK: - Main Parsing Method
    func parseDecree(_ url: URL) async -> ParsedDivorceDecree? {
        // Prefer high-quality extractor (native text + OCR for scans)
        let rawText = await DocumentTextExtractor.extractText(from: url) ?? extractTextFromPDF(url)
        guard let rawText, !rawText.isEmpty else {
            print("❌ Failed to extract text from document")
            return nil
        }
        return parseExtractedText(rawText)
    }
    
    /// Parse already-extracted decree text (from OCR or PDF).
    func parseExtractedText(_ rawText: String) -> ParsedDivorceDecree? {
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        print("📄 Starting advanced divorce decree parsing...")
        print("📄 Document length: \(rawText.count) characters")
        
        let startTime = Date()
        let processedText = preprocessText(rawText)
        let sections = extractDocumentSections(from: processedText)
        let parties = extractPartyInformation(from: processedText)
        let children = extractChildInformation(from: processedText)
        let custody = extractCustodyArrangement(from: processedText, sections: sections)
        let schedule = extractVisitationSchedule(from: processedText, sections: sections)
        let financial = extractFinancialTerms(from: processedText, sections: sections)
        let medical = extractMedicalProvisions(from: processedText, sections: sections)
        let education = extractEducationProvisions(from: processedText, sections: sections)
        let holidays = extractHolidaySchedule(from: processedText, sections: sections)
        let restrictions = extractRestrictions(from: processedText, sections: sections)
        let specialProvisions = extractSpecialProvisions(from: processedText, sections: sections)
        let court = extractCourtInformation(from: processedText)
        let keyDates = extractKeyDates(from: processedText)
        let confidence = calculateParsingConfidence(
            parties: parties,
            children: children,
            custody: custody,
            sections: sections
        )
        
        let processingTime = Date().timeIntervalSince(startTime)
        print("✅ Divorce decree parsing completed in \(String(format: "%.2f", processingTime))s")
        print("🎯 Parsing confidence: \(String(format: "%.1f", confidence * 100))%")
        
        return ParsedDivorceDecree(
            rawText: rawText,
            parsingConfidence: confidence,
            parties: parties,
            children: children,
            custodyArrangement: custody,
            schedule: schedule,
            financialTerms: financial,
            medicalProvisions: medical,
            educationProvisions: education,
            holidaySchedule: holidays,
            restrictions: restrictions,
            specialProvisions: specialProvisions,
            courtInformation: court,
            keyDates: keyDates,
            extractedSections: sections
        )
    }
    
    // MARK: - Text Preprocessing
    private func preprocessText(_ text: String) -> String {
        var processed = text
        
        // Normalize whitespace and line breaks
        processed = processed.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        processed = processed.replacingOccurrences(of: #"\n+"#, with: "\n", options: .regularExpression)
        
        // Fix common OCR errors
        processed = processed.replacingOccurrences(of: "o'clock", with: "o'clock")
        processed = processed.replacingOccurrences(of: "'", with: "'") // Smart quotes
        processed = processed.replacingOccurrences(of: "\u{201C}", with: "\"")
        processed = processed.replacingOccurrences(of: "\u{201D}", with: "\"")
        
        // Standardize legal terminology
        let legalTermMappings = [
            ("custodial parent", "custodial parent"),
            ("non-custodial parent", "non-custodial parent"),
            ("visitation", "parenting time"),
            ("possession", "parenting time")
        ]
        
        for (old, new) in legalTermMappings {
            processed = processed.replacingOccurrences(of: old, with: new, options: .caseInsensitive)
        }
        
        return processed
    }
    
    // MARK: - Section Extraction
    private func extractDocumentSections(from text: String) -> [ParsedDivorceDecree.DocumentSection] {
        var sections: [ParsedDivorceDecree.DocumentSection] = []
        
        // Define section patterns with their categories
        let sectionPatterns = [
            (#"(?i)(custody|conservatorship).*?(?=\n\d+\.|\nIT IS|\Z)"#, ParsedDivorceDecree.DocumentSection.SectionCategory.custody),
            (#"(?i)(visitation|possession|parenting time).*?(?=\n\d+\.|\nIT IS|\Z)"#, .visitation),
            (#"(?i)(child support|financial|support).*?(?=\n\d+\.|\nIT IS|\Z)"#, .financial),
            (#"(?i)(medical|health|insurance).*?(?=\n\d+\.|\nIT IS|\Z)"#, .medical),
            (#"(?i)(education|school).*?(?=\n\d+\.|\nIT IS|\Z)"#, .education),
            (#"(?i)(holiday|vacation|christmas|thanksgiving).*?(?=\n\d+\.|\nIT IS|\Z)"#, .holiday),
            (#"(?i)(restriction|limitation|prohibition).*?(?=\n\d+\.|\nIT IS|\Z)"#, .restrictions)
        ]
        
        for (pattern, category) in sectionPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            let matches = regex?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
            
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let content = String(text[range])
                    let title = extractSectionTitle(from: content)
                    let relevanceScore = calculateSectionRelevance(content: content, category: category)
                    
                    let section = ParsedDivorceDecree.DocumentSection(
                        title: title,
                        content: content,
                        relevanceScore: relevanceScore,
                        category: category
                    )
                    sections.append(section)
                }
            }
        }
        
        return sections.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func extractSectionTitle(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        for line in lines.prefix(3) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 5 && trimmed.count < 100 {
                return trimmed
            }
        }
        return "Section"
    }
    
    private func calculateSectionRelevance(content: String, category: ParsedDivorceDecree.DocumentSection.SectionCategory) -> Double {
        let lowercased = content.lowercased()
        var score = 0.0
        
        // Category-specific keywords
        let keywords: [String]
        switch category {
        case .custody:
            keywords = ["custody", "conservator", "joint", "sole", "primary", "residence"]
        case .visitation:
            keywords = ["visitation", "possession", "parenting time", "schedule", "weekend", "holiday"]
        case .financial:
            keywords = ["support", "payment", "monthly", "expenses", "child support"]
        case .medical:
            keywords = ["medical", "health", "insurance", "doctor", "treatment"]
        case .education:
            keywords = ["school", "education", "tuition", "activities"]
        case .holiday:
            keywords = ["christmas", "thanksgiving", "holiday", "vacation", "birthday"]
        case .restrictions:
            keywords = ["restrict", "prohibit", "limit", "not", "shall not"]
        case .general:
            keywords = ["decree", "court", "order"]
        }
        
        for keyword in keywords {
            let occurrences = lowercased.components(separatedBy: keyword).count - 1
            score += Double(occurrences) * 0.1
        }
        
        // Length bonus (longer sections often more detailed)
        score += min(Double(content.count) / 1000.0, 0.5)
        
        return min(score, 1.0)
    }
    
    // MARK: - Entity Extraction Methods
    private func extractPartyInformation(from text: String) -> ParsedDivorceDecree.PartyInformation {
        let petitioner = extractMatch(from: text, pattern: RegexPatterns.petitioner)
        let respondent = extractMatch(from: text, pattern: RegexPatterns.respondent)
        let caseNumber = extractMatch(from: text, pattern: RegexPatterns.caseNumber)
        
        return ParsedDivorceDecree.PartyInformation(
            petitioner: petitioner,
            respondent: respondent,
            petitionerAddress: nil, // Could be enhanced with address extraction
            respondentAddress: nil,
            caseNumber: caseNumber
        )
    }
    
    private func extractChildInformation(from text: String) -> [ParsedDivorceDecree.ParsedChildInfo] {
        var children: [ParsedDivorceDecree.ParsedChildInfo] = []
        
        // This is simplified - could use NLP for better extraction
        let childNames = extractMatches(from: text, pattern: RegexPatterns.childName)
        
        for name in childNames {
            let child = ParsedDivorceDecree.ParsedChildInfo(
                name: name,
                birthDate: nil, // Could extract from context
                age: nil,
                gender: nil,
                specialNeeds: nil
            )
            children.append(child)
        }
        
        return children
    }
    
    private func extractCustodyArrangement(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.CustodyArrangement {
        let custodyTypeString = extractMatch(from: text, pattern: RegexPatterns.custodyType) ?? "unknown"
        let custodyType = ParsedDivorceDecree.CustodyArrangement.CustodyType(rawValue: custodyTypeString.lowercased()) ?? .unknown
        
        // Find relevant custody sections
        let custodySections = sections.filter { $0.category == .custody }
        let details = custodySections.first?.content ?? ""
        
        let jointDecisionMaking = text.lowercased().contains("joint") && (text.lowercased().contains("decision") || text.lowercased().contains("legal"))
        
        return ParsedDivorceDecree.CustodyArrangement(
            type: custodyType,
            primaryResidence: nil,
            jointDecisionMaking: jointDecisionMaking,
            details: details
        )
    }
    
    private func extractVisitationSchedule(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.VisitationSchedule {
        let weekendSchedule = extractMatch(from: text, pattern: RegexPatterns.weekendSchedule)
        let exchangeTime = extractMatch(from: text, pattern: RegexPatterns.exchangeTime)
        
        // Find relevant visitation sections
        let visitationSections = sections.filter { $0.category == .visitation }
        let standardSchedule = visitationSections.first?.content
        
        return ParsedDivorceDecree.VisitationSchedule(
            standardSchedule: standardSchedule,
            weekendSchedule: weekendSchedule,
            weekdaySchedule: nil,
            summerSchedule: nil,
            exchangeLocation: nil,
            exchangeTime: exchangeTime,
            modifications: []
        )
    }
    
    private func extractFinancialTerms(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.FinancialTerms {
        let childSupportAmount = extractMatch(from: text, pattern: RegexPatterns.childSupport)
        let spousalSupportAmount = extractMatch(from: text, pattern: RegexPatterns.spousalSupport)
        
        let childSupport = childSupportAmount != nil ? ParsedDivorceDecree.FinancialTerms.ChildSupportInfo(
            amount: childSupportAmount,
            frequency: "monthly", // Could be extracted
            payer: nil,
            endDate: nil,
            modifications: []
        ) : nil
        
        let spousalSupport = spousalSupportAmount != nil ? ParsedDivorceDecree.FinancialTerms.SpousalSupportInfo(
            amount: spousalSupportAmount,
            frequency: "monthly",
            duration: nil,
            payer: nil
        ) : nil
        
        return ParsedDivorceDecree.FinancialTerms(
            childSupport: childSupport,
            spousalSupport: spousalSupport,
            expenseSharing: nil
        )
    }
    
    private func extractMedicalProvisions(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.MedicalProvisions {
        let medicalSections = sections.filter { $0.category == .medical }
        
        return ParsedDivorceDecree.MedicalProvisions(
            insuranceProvider: nil,
            insurancePayer: nil,
            uninsuredExpenses: nil,
            decisionMaking: medicalSections.first?.content,
            emergencyAuthorization: nil
        )
    }
    
    private func extractEducationProvisions(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.EducationProvisions {
        let educationSections = sections.filter { $0.category == .education }
        
        return ParsedDivorceDecree.EducationProvisions(
            schoolChoice: nil,
            decisionMaking: educationSections.first?.content,
            expenseSharing: nil,
            extracurriculars: nil
        )
    }
    
    private func extractHolidaySchedule(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> ParsedDivorceDecree.HolidaySchedule {
        let christmas = extractMatch(from: text, pattern: RegexPatterns.christmas)
        let thanksgiving = extractMatch(from: text, pattern: RegexPatterns.thanksgiving)
        
        return ParsedDivorceDecree.HolidaySchedule(
            christmas: christmas,
            thanksgiving: thanksgiving,
            easter: nil,
            birthdayArrangement: nil,
            vacationTime: nil,
            otherHolidays: [:]
        )
    }
    
    private func extractRestrictions(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> [String] {
        let restrictionSections = sections.filter { $0.category == .restrictions }
        return restrictionSections.map { $0.content }
    }
    
    private func extractSpecialProvisions(from text: String, sections: [ParsedDivorceDecree.DocumentSection]) -> [String] {
        var provisions: [String] = []
        
        // Look for special provisions keywords
        let specialKeywords = ["special", "additional", "specific", "unique", "particular"]
        
        for section in sections {
            let lowercased = section.content.lowercased()
            if specialKeywords.contains(where: { lowercased.contains($0) }) {
                provisions.append(section.content)
            }
        }
        
        return provisions
    }
    
    private func extractCourtInformation(from text: String) -> ParsedDivorceDecree.CourtInformation {
        let courtName = extractMatch(from: text, pattern: RegexPatterns.courtName)
        let judgeName = extractMatch(from: text, pattern: RegexPatterns.judgeName)
        let caseNumber = extractMatch(from: text, pattern: RegexPatterns.caseNumber)
        
        return ParsedDivorceDecree.CourtInformation(
            courtName: courtName,
            judgeName: judgeName,
            finalDate: nil,
            caseNumber: caseNumber,
            filingDate: nil
        )
    }
    
    private func extractKeyDates(from text: String) -> [String: Date] {
        var dates: [String: Date] = [:]
        
        let dateMatches = extractMatches(from: text, pattern: RegexPatterns.datePattern)
        let formatter = DateFormatter()
        
        for dateString in dateMatches {
            // Try multiple date formats
            let formats = ["MMMM d, yyyy", "MM/dd/yyyy", "yyyy-MM-dd"]
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    dates[dateString] = date
                    break
                }
            }
        }
        
        return dates
    }
    
    // MARK: - Helper Methods
    private func extractTextFromPDF(_ url: URL) -> String? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let pdfDocument = PDFDocument(url: url) else { return nil }
        
        var fullText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i) {
                fullText += page.string ?? ""
            }
        }
        
        return fullText.isEmpty ? nil : fullText
    }
    
    private func extractMatch(from text: String, pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        
        if let match = regex?.firstMatch(in: text, range: range),
           match.numberOfRanges > 1,
           let captureRange = Range(match.range(at: 1), in: text) {
            return String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    private func extractMatches(from text: String, pattern: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, range: range) ?? []
        
        return matches.compactMap { match in
            if match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: text) {
                return String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        }
    }
    
    private func calculateParsingConfidence(
        parties: ParsedDivorceDecree.PartyInformation,
        children: [ParsedDivorceDecree.ParsedChildInfo],
        custody: ParsedDivorceDecree.CustodyArrangement,
        sections: [ParsedDivorceDecree.DocumentSection]
    ) -> Double {
        var confidence = 0.0
        
        // Party information found
        if parties.petitioner != nil { confidence += 0.2 }
        if parties.respondent != nil { confidence += 0.2 }
        if parties.caseNumber != nil { confidence += 0.1 }
        
        // Child information found
        if !children.isEmpty { confidence += 0.2 }
        
        // Custody information found
        if custody.type != .unknown { confidence += 0.1 }
        
        // Document sections found
        if !sections.isEmpty {
            confidence += min(Double(sections.count) / 10.0, 0.2)
        }
        
        return min(confidence, 1.0)
    }
}