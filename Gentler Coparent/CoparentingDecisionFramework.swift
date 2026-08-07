import Foundation
import SwiftUI

// MARK: - Comprehensive Co-Parenting Decision and Communication Framework
class CoparentingDecisionFramework: ObservableObject {
    
    // MARK: - Core Decision Categories
    enum DecisionCategory: String, CaseIterable, Codable {
        // Schedule & Time Management
        case regularSchedule = "regular_schedule"
        case holidaySchedule = "holiday_schedule" 
        case vacationTime = "vacation_time"
        case specialOccasions = "special_occasions"
        case scheduleChanges = "schedule_changes"
        
        // Financial Responsibilities
        case childSupport = "child_support"
        case medicalExpenses = "medical_expenses"
        case educationCosts = "education_costs"
        case extracurricularCosts = "extracurricular_costs"
        case childcareCosts = "childcare_costs"
        case clothingExpenses = "clothing_expenses"
        case travelExpenses = "travel_expenses"
        
        // Medical & Health
        case routineMedical = "routine_medical"
        case emergencyMedical = "emergency_medical"
        case mentalHealthCare = "mental_health_care"
        case specialistCare = "specialist_care"
        case medicationDecisions = "medication_decisions"
        case medicalInsurance = "medical_insurance"
        case medicalInformation = "medical_information"
        
        // Education & Development
        case schoolChoice = "school_choice"
        case academicPerformance = "academic_performance"
        case parentTeacherConferences = "parent_teacher_conferences"
        case specialEducationServices = "special_education_services"
        case tutoring = "tutoring"
        case schoolEvents = "school_events"
        
        // Activities & Enrichment
        case extracurricularActivities = "extracurricular_activities"
        case sportsParticipation = "sports_participation"
        case musicLessons = "music_lessons"
        case summerCamps = "summer_camps"
        case socialActivities = "social_activities"
        case religiousActivities = "religious_activities"
        
        // Transportation & Logistics
        case dailyTransportation = "daily_transportation"
        case activityTransportation = "activity_transportation"
        case emergencyPickup = "emergency_pickup"
        case travelPermissions = "travel_permissions"
        case carSeatRequirements = "car_seat_requirements"
        
        // Communication & Information Sharing
        case schoolCommunication = "school_communication"
        case medicalUpdates = "medical_updates"
        case behavioralConcerns = "behavioral_concerns"
        case achievementSharing = "achievement_sharing"
        case emergencyNotification = "emergency_notification"
        case routineUpdates = "routine_updates"
        
        // Legal & Documentation
        case passportApplications = "passport_applications"
        case nameChanges = "name_changes"
        case legalDocuments = "legal_documents"
        case courtCompliance = "court_compliance"
        case modificationRequests = "modification_requests"
        
        // Special Circumstances
        case disciplinaryIssues = "disciplinary_issues"
        case behavioralTherapy = "behavioral_therapy"
        case specialNeeds = "special_needs"
        case emergencySituations = "emergency_situations"
        case relationshipConcerns = "relationship_concerns"
        
        var displayName: String {
            switch self {
            case .regularSchedule: return "Regular Custody Schedule"
            case .holidaySchedule: return "Holiday & Special Days"
            case .vacationTime: return "Vacation Time"
            case .specialOccasions: return "Birthdays & Special Occasions"
            case .scheduleChanges: return "Schedule Modifications"
            case .childSupport: return "Child Support"
            case .medicalExpenses: return "Medical Expenses"
            case .educationCosts: return "Education Costs"
            case .extracurricularCosts: return "Activity Costs"
            case .childcareCosts: return "Childcare Expenses"
            case .clothingExpenses: return "Clothing & Personal Items"
            case .travelExpenses: return "Travel Costs"
            case .routineMedical: return "Routine Medical Care"
            case .emergencyMedical: return "Medical Emergencies"
            case .mentalHealthCare: return "Mental Health Services"
            case .specialistCare: return "Specialist Care"
            case .medicationDecisions: return "Medication Decisions"
            case .medicalInsurance: return "Health Insurance"
            case .medicalInformation: return "Medical Information Sharing"
            case .schoolChoice: return "School Selection"
            case .academicPerformance: return "Academic Progress"
            case .parentTeacherConferences: return "Parent-Teacher Conferences"
            case .specialEducationServices: return "Special Education"
            case .tutoring: return "Tutoring & Academic Support"
            case .schoolEvents: return "School Events & Activities"
            case .extracurricularActivities: return "Extracurricular Activities"
            case .sportsParticipation: return "Sports & Athletics"
            case .musicLessons: return "Music & Arts"
            case .summerCamps: return "Summer Programs"
            case .socialActivities: return "Social Activities"
            case .religiousActivities: return "Religious Activities"
            case .dailyTransportation: return "Daily Transportation"
            case .activityTransportation: return "Activity Transportation"
            case .emergencyPickup: return "Emergency Pickup"
            case .travelPermissions: return "Travel Authorization"
            case .carSeatRequirements: return "Car Seat & Safety"
            case .schoolCommunication: return "School Communication"
            case .medicalUpdates: return "Medical Updates"
            case .behavioralConcerns: return "Behavioral Issues"
            case .achievementSharing: return "Achievements & Milestones"
            case .emergencyNotification: return "Emergency Notifications"
            case .routineUpdates: return "Routine Information Sharing"
            case .passportApplications: return "Travel Documents"
            case .nameChanges: return "Name Changes"
            case .legalDocuments: return "Legal Documentation"
            case .courtCompliance: return "Court Order Compliance"
            case .modificationRequests: return "Modification Requests"
            case .disciplinaryIssues: return "Discipline & Consequences"
            case .behavioralTherapy: return "Behavioral Therapy"
            case .specialNeeds: return "Special Needs Support"
            case .emergencySituations: return "Crisis Management"
            case .relationshipConcerns: return "Relationship Issues"
            }
        }
        
        var urgencyLevel: UrgencyLevel {
            switch self {
            case .emergencyMedical, .emergencySituations, .emergencyPickup, .emergencyNotification:
                return .critical
            case .medicalExpenses, .medicationDecisions, .behavioralConcerns, .disciplinaryIssues, .courtCompliance:
                return .high
            case .scheduleChanges, .schoolCommunication, .medicalUpdates, .parentTeacherConferences, .specialNeeds:
                return .medium
            case .routineUpdates, .achievementSharing, .clothingExpenses, .socialActivities:
                return .low
            default:
                return .medium
            }
        }
        
        var decisionMakingType: DecisionMakingType {
            switch self {
            case .emergencyMedical, .emergencySituations, .emergencyPickup:
                return .immediateUnilateral
            case .schoolChoice, .medicalInsurance, .specialistCare, .nameChanges, .passportApplications:
                return .jointRequired
            case .extracurricularActivities, .dailyTransportation, .routineMedical, .tutoring:
                return .consultationRecommended
            case .scheduleChanges, .vacationTime, .travelPermissions:
                return .mutualAgreement
            default:
                return .consultationRecommended
            }
        }
        
        enum UrgencyLevel: String, CaseIterable, Codable {
            case critical = "critical"     // Immediate response required
            case high = "high"            // Same day response needed  
            case medium = "medium"        // 24-48 hour response
            case low = "low"             // Can wait several days
        }
        
        enum DecisionMakingType: String, CaseIterable, Codable {
            case immediateUnilateral = "immediate_unilateral"      // Emergency - act first, notify after
            case jointRequired = "joint_required"                  // Both parents must agree
            case consultationRecommended = "consultation_recommended" // Consult if possible, but can proceed
            case mutualAgreement = "mutual_agreement"             // Should have mutual agreement
            case informationOnly = "information_only"             // Just need to inform the other parent
        }
    }
    
    // MARK: - Communication Templates and Guidance
    struct CommunicationGuidance {
        let category: DecisionCategory
        let suggestedApproach: String
        let keyPoints: [String]
        let templatePhrases: [String]
        let commonPitfalls: [String]
        let legalConsiderations: [String]
        let documentationNeeded: [String]
    }
    
    // MARK: - Comprehensive Guidance Database
    static let guidanceDatabase: [DecisionCategory: CommunicationGuidance] = [
        
        .regularSchedule: CommunicationGuidance(
            category: .regularSchedule,
            suggestedApproach: "Reference the specific custody order provisions and focus on the children's routine and stability",
            keyPoints: [
                "Refer to exact decree language for pickup/dropoff times",
                "Mention specific locations and procedures",
                "Emphasize consistency for children's wellbeing",
                "Address any safety or logistics concerns"
            ],
            templatePhrases: [
                "According to our custody order, the regular schedule specifies...",
                "To maintain consistency for [child's name], I wanted to confirm...",
                "The decree states that exchanges occur at...",
                "For the children's stability, let's ensure we follow..."
            ],
            commonPitfalls: [
                "Don't suggest major changes without court approval",
                "Avoid emotional language about the schedule",
                "Don't make unilateral changes"
            ],
            legalConsiderations: [
                "Schedule changes may require court approval",
                "Document any agreed-upon temporary modifications",
                "Consistent violations could affect custody"
            ],
            documentationNeeded: [
                "Original custody order",
                "Any approved modifications",
                "Communication records about schedule"
            ]
        ),
        
        .holidaySchedule: CommunicationGuidance(
            category: .holidaySchedule,
            suggestedApproach: "Reference the specific holiday provisions in your decree and plan well in advance",
            keyPoints: [
                "Check decree for specific holiday allocations",
                "Plan months ahead for major holidays",
                "Consider the children's extended family relationships",
                "Address transportation for holiday exchanges"
            ],
            templatePhrases: [
                "Looking at our holiday schedule, this year [holiday] is designated for...",
                "I wanted to coordinate early for [holiday] arrangements...",
                "The decree specifies that [holiday] alternates, so this year...",
                "To help the children prepare, let's confirm the [holiday] plan..."
            ],
            commonPitfalls: [
                "Don't assume flexibility without discussion",
                "Avoid last-minute holiday requests",
                "Don't use holidays as negotiation leverage"
            ],
            legalConsiderations: [
                "Holiday schedules often override regular custody",
                "Some holidays may have specific start/end times",
                "Document any holiday trade agreements"
            ],
            documentationNeeded: [
                "Holiday schedule from decree",
                "Previous year's arrangements",
                "Extended family event information"
            ]
        ),
        
        .childSupport: CommunicationGuidance(
            category: .childSupport,
            suggestedApproach: "Keep discussions factual, reference court orders, and document everything",
            keyPoints: [
                "Reference exact support amount and due date",
                "Discuss any changes in circumstances",
                "Address additional expenses covered/not covered",
                "Maintain professional tone"
            ],
            templatePhrases: [
                "According to our support order, the monthly amount of $[amount] is due...",
                "I wanted to discuss the additional expense for [specific item]...",
                "The decree specifies that [expense type] is shared/covered by...",
                "I'm providing documentation for the [medical/education/other] expense..."
            ],
            commonPitfalls: [
                "Don't threaten withholding visitation for support issues",
                "Avoid emotional language about money",
                "Don't mix support issues with other disagreements"
            ],
            legalConsiderations: [
                "Support modifications require court approval",
                "Document all expenses and payments",
                "Keep support and visitation issues separate"
            ],
            documentationNeeded: [
                "Support order details",
                "Expense receipts and documentation",
                "Income change documentation"
            ]
        ),
        
        .medicalExpenses: CommunicationGuidance(
            category: .medicalExpenses,
            suggestedApproach: "Provide clear documentation and reference insurance/decree provisions",
            keyPoints: [
                "Include all relevant medical documentation",
                "Clarify insurance coverage and responsibility",
                "Provide timely notification of expenses",
                "Reference decree provisions for medical costs"
            ],
            templatePhrases: [
                "I'm forwarding the medical bills for [child's name]'s recent [treatment/appointment]...",
                "According to our decree, medical expenses are shared [percentage/method]...",
                "The insurance covered $[amount], leaving a balance of $[amount] to be split...",
                "I wanted to get your input on this recommended [treatment/specialist]..."
            ],
            commonPitfalls: [
                "Don't delay sharing medical expense information",
                "Avoid making unilateral medical decisions without consultation",
                "Don't withhold medical information over payment disputes"
            ],
            legalConsiderations: [
                "Most decrees specify how medical expenses are shared",
                "Some medical decisions require joint consent",
                "Document all medical communications"
            ],
            documentationNeeded: [
                "Medical bills and insurance statements",
                "Doctor's recommendations",
                "Insurance coverage details"
            ]
        ),
        
        .extracurricularActivities: CommunicationGuidance(
            category: .extracurricularActivities,
            suggestedApproach: "Discuss the child's interests, costs, schedule impact, and transportation logistics",
            keyPoints: [
                "Consider the child's genuine interest and aptitude",
                "Discuss cost sharing arrangements",
                "Address transportation responsibilities",
                "Consider impact on custody schedule"
            ],
            templatePhrases: [
                "[Child's name] has expressed interest in [activity] and I wanted to discuss...",
                "The cost for [activity] is $[amount] and according to our agreement...",
                "I can handle transportation to [activity] on [days] if you can cover...",
                "This activity would conflict with our regular schedule on [days]..."
            ],
            commonPitfalls: [
                "Don't enroll without discussing with co-parent",
                "Avoid activities that unfairly burden the other parent",
                "Don't use activities to manipulate custody time"
            ],
            legalConsiderations: [
                "Some decrees address extracurricular enrollment authority",
                "Cost sharing arrangements should be documented",
                "Schedule changes may need formal approval"
            ],
            documentationNeeded: [
                "Activity details and costs",
                "Schedule requirements",
                "Transportation arrangements"
            ]
        ),
        
        .schoolCommunication: CommunicationGuidance(
            category: .schoolCommunication,
            suggestedApproach: "Keep both parents informed and coordinate on educational decisions",
            keyPoints: [
                "Share report cards and academic updates",
                "Coordinate on parent-teacher conferences",
                "Discuss any academic concerns or achievements",
                "Address school events and activities"
            ],
            templatePhrases: [
                "I received [child's name]'s report card and wanted to share...",
                "There's a parent-teacher conference scheduled for [date]...",
                "The teacher mentioned that [child] is [struggling with/excelling in]...",
                "There's a school event on [date] that [child] would like both of us to attend..."
            ],
            commonPitfalls: [
                "Don't withhold school information",
                "Avoid contradicting the other parent at school events",
                "Don't use school staff as messengers"
            ],
            legalConsiderations: [
                "Both parents typically have rights to school information",
                "Educational decisions may require joint input",
                "Document important school communications"
            ],
            documentationNeeded: [
                "Report cards and progress reports",
                "Teacher communications",
                "School event information"
            ]
        ),
        
        .emergencyMedical: CommunicationGuidance(
            category: .emergencyMedical,
            suggestedApproach: "Act immediately for the child's safety, then notify and document thoroughly",
            keyPoints: [
                "Prioritize the child's immediate medical needs",
                "Notify the other parent as soon as possible",
                "Provide detailed information about the situation",
                "Keep thorough records of the emergency"
            ],
            templatePhrases: [
                "I'm at [hospital/clinic] with [child's name] for [emergency situation]...",
                "[Child] is stable and receiving [treatment]. The doctor says...",
                "I'll keep you updated as I learn more about [child's] condition...",
                "The medical team would like to speak with both parents about..."
            ],
            commonPitfalls: [
                "Don't delay necessary medical treatment",
                "Don't exclude the other parent from medical discussions",
                "Avoid blame or emotional accusations during crisis"
            ],
            legalConsiderations: [
                "Emergency medical decisions can be made unilaterally",
                "Other parent should be notified promptly",
                "Document all emergency medical decisions"
            ],
            documentationNeeded: [
                "Medical records and treatment details",
                "Insurance information",
                "Communication with medical providers"
            ]
        ),
        
        .scheduleChanges: CommunicationGuidance(
            category: .scheduleChanges,
            suggestedApproach: "Request changes respectfully with adequate notice and offer alternatives",
            keyPoints: [
                "Provide as much advance notice as possible",
                "Explain the reason for the change request",
                "Offer make-up time or alternative arrangements",
                "Be flexible and considerate of the other parent's schedule"
            ],
            templatePhrases: [
                "I have a [reason] on [date] and would like to request...",
                "Could we swap [date] for [alternative date] so that...",
                "I understand this is short notice, but [situation] has come up...",
                "I'm happy to offer [make-up time/alternative] in return for..."
            ],
            commonPitfalls: [
                "Don't make last-minute requests without good reason",
                "Avoid making changes that consistently favor one parent",
                "Don't expect the other parent to always accommodate"
            ],
            legalConsiderations: [
                "Frequent changes may require court modification",
                "Document agreed-upon changes",
                "Maintain the overall custody balance"
            ],
            documentationNeeded: [
                "Reason for schedule change",
                "Alternative arrangements offered",
                "Agreement to the change"
            ]
        )
    ]
    
    // MARK: - Context-Aware Response Generation
    func generateContextualGuidance(
        for category: DecisionCategory,
        with parsedDecree: DivorceDecreeParser.ParsedDivorceDecree?
    ) -> String {
        
        guard let guidance = Self.guidanceDatabase[category] else {
            return "General co-parenting communication principles apply."
        }
        
        var contextualGuidance = """
        ## \(category.displayName) - Communication Guidance
        
        **Recommended Approach**: \(guidance.suggestedApproach)
        
        **Key Discussion Points**:
        """
        
        for point in guidance.keyPoints {
            contextualGuidance += "\n• \(point)"
        }
        
        // Add decree-specific context if available
        if let decree = parsedDecree {
            contextualGuidance += "\n\n**From Your Divorce Decree**:"
            
            switch category {
            case .regularSchedule, .holidaySchedule, .scheduleChanges:
                if decree.schedule.standardSchedule != nil {
                    contextualGuidance += "\n• Your custody order specifies established parenting time arrangements"
                }
                if !decree.holidaySchedule.christmas.isNilOrEmpty || !decree.holidaySchedule.thanksgiving.isNilOrEmpty {
                    contextualGuidance += "\n• Holiday schedules are court-ordered and should be followed"
                }
                
            case .childSupport, .medicalExpenses, .educationCosts, .extracurricularCosts:
                if let childSupport = decree.financialTerms.childSupport {
                    contextualGuidance += "\n• Child support: \(childSupport.amount ?? "Amount specified") \(childSupport.frequency ?? "")"
                }
                if decree.financialTerms.expenseSharing?.medical != nil {
                    contextualGuidance += "\n• Medical expense sharing arrangements are specified"
                }
                
            case .routineMedical, .emergencyMedical, .medicalInformation:
                if decree.custodyArrangement.jointDecisionMaking {
                    contextualGuidance += "\n• Joint medical decision-making is required per your custody order"
                }
                if decree.medicalProvisions.decisionMaking != nil {
                    contextualGuidance += "\n• Specific medical decision protocols are established"
                }
                
            case .schoolChoice, .academicPerformance, .schoolCommunication:
                if decree.custodyArrangement.jointDecisionMaking {
                    contextualGuidance += "\n• Joint educational decision-making is required"
                }
                if decree.educationProvisions.decisionMaking != nil {
                    contextualGuidance += "\n• Educational decision protocols are specified in your decree"
                }
                
            default:
                if !decree.restrictions.isEmpty {
                    contextualGuidance += "\n• Court-ordered restrictions may apply to this situation"
                }
            }
        }
        
        contextualGuidance += "\n\n**Suggested Phrases**:"
        for phrase in guidance.templatePhrases {
            contextualGuidance += "\n• \"\(phrase)\""
        }
        
        contextualGuidance += "\n\n**Avoid These Common Mistakes**:"
        for pitfall in guidance.commonPitfalls {
            contextualGuidance += "\n• \(pitfall)"
        }
        
        // Add urgency and decision-making context
        contextualGuidance += "\n\n**Response Timeline**: \(category.urgencyLevel.rawValue.capitalized) priority"
        contextualGuidance += "\n**Decision Making**: \(category.decisionMakingType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)"
        
        return contextualGuidance
    }
    
    // MARK: - Category Detection from User Query
    func detectCategories(from query: String) -> [DecisionCategory] {
        let lowercased = query.lowercased()
        var detectedCategories: [DecisionCategory] = []
        
        // Define keyword mappings for each category
        let categoryKeywords: [DecisionCategory: [String]] = [
            .regularSchedule: ["schedule", "custody", "visitation", "pickup", "dropoff", "parenting time"],
            .holidaySchedule: ["holiday", "christmas", "thanksgiving", "easter", "birthday", "special day"],
            .vacationTime: ["vacation", "trip", "travel", "summer break", "spring break"],
            .childSupport: ["child support", "payment", "monthly", "support order", "money"],
            .medicalExpenses: ["medical", "doctor", "hospital", "bill", "insurance", "copay"],
            .extracurricularActivities: ["activity", "sport", "music", "dance", "club", "team"],
            .schoolCommunication: ["school", "teacher", "grade", "report card", "conference", "education"],
            .emergencyMedical: ["emergency", "urgent", "hospital", "injury", "accident", "crisis"],
            .scheduleChanges: ["change", "switch", "swap", "modify", "different time", "reschedule"],
            .dailyTransportation: ["transportation", "pickup", "dropoff", "drive", "carpool"]
        ]
        
        for (category, keywords) in categoryKeywords {
            if keywords.contains(where: { lowercased.contains($0) }) {
                detectedCategories.append(category)
            }
        }
        
        return detectedCategories.isEmpty ? [.routineUpdates] : detectedCategories
    }
}

// MARK: - Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}