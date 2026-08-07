import AppIntents
import Foundation
import SwiftUI

// MARK: - App Intent Definitions for Siri & Shortcuts

// MARK: - Quick Response Intent
@available(iOS 16.0, *)
struct QuickResponseIntent: AppIntent {
    static let title: LocalizedStringResource = "Send Quick Co-parenting Response"
    static let description = IntentDescription("Quickly respond to your co-parent with AI assistance")
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Response Type")
    var responseType: ResponseType
    
    @Parameter(title: "Message Context", description: "What are you responding to?")
    var context: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Send \(\.$responseType) response about \(\.$context)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let response = generateQuickResponse(type: responseType, context: context ?? "")
        
        return .result(dialog: IntentDialog(stringLiteral: response)) {
            OpenGentlerCoparentView(initialMessage: response)
        }
    }
    
    private func generateQuickResponse(type: ResponseType, context: String) -> String {
        switch type {
        case .acknowledge:
            return "Thanks for letting me know about \(context). I'll check my calendar and get back to you."
        case .confirmPickup:
            return "Pickup confirmed for the scheduled time. I'll make sure everything is ready."
        case .requestChange:
            return "I need to discuss a potential schedule change regarding \(context). When would be a good time to talk?"
        case .emergency:
            return "I understand this is urgent regarding \(context). Please call me so we can coordinate immediately."
        case .gratitude:
            return "Thank you for being flexible with \(context). I really appreciate your cooperation."
        }
    }
}

enum ResponseType: String, AppEnum, CaseIterable {
    case acknowledge = "acknowledge"
    case confirmPickup = "confirmPickup" 
    case requestChange = "requestChange"
    case emergency = "emergency"
    case gratitude = "gratitude"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Response Type")
    static let caseDisplayRepresentations: [ResponseType: DisplayRepresentation] = [
        .acknowledge: "Acknowledge",
        .confirmPickup: "Confirm Pickup",
        .requestChange: "Request Change",
        .emergency: "Emergency Response", 
        .gratitude: "Express Gratitude"
    ]
}

// MARK: - Schedule Check Intent
@available(iOS 16.0, *)
struct CheckScheduleIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Co-parenting Schedule"
    static let description = IntentDescription("Check upcoming custody schedule and events")
    static let openAppWhenRun: Bool = false
    
    @Parameter(title: "Time Period")
    var timePeriod: TimePeriod
    
    static var parameterSummary: some ParameterSummary {
        Summary("Check schedule for \(\.$timePeriod)")
    }
    
    func perform() async throws -> some IntentResult {
        let scheduleInfo = await getScheduleInfo(for: timePeriod)
        
        return .result(dialog: IntentDialog(stringLiteral: scheduleInfo))
    }
    
    private func getScheduleInfo(for period: TimePeriod) async -> String {
        // This would integrate with your actual schedule data
        switch period {
        case .today:
            return "Today: You have the children until 6 PM. Pickup scheduled at soccer practice."
        case .thisWeek:
            return "This week: Children with you Mon-Wed, transition Thursday 6 PM, return Sunday 6 PM."
        case .nextWeek:
            return "Next week: Regular schedule - you have children Mon-Wed and weekend."
        case .thisMonth:
            return "This month: Standard custody schedule with holiday adjustment on the 25th."
        }
    }
}

enum TimePeriod: String, AppEnum, CaseIterable {
    case today = "today"
    case thisWeek = "thisWeek"
    case nextWeek = "nextWeek" 
    case thisMonth = "thisMonth"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Period")
    static let caseDisplayRepresentations: [TimePeriod: DisplayRepresentation] = [
        .today: "Today",
        .thisWeek: "This Week",
        .nextWeek: "Next Week",
        .thisMonth: "This Month"
    ]
}

// MARK: - Draft Message Intent
@available(iOS 16.0, *)
struct DraftMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Draft Co-parenting Message"
    static let description = IntentDescription("Get AI help drafting a diplomatic co-parenting message")
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Message Topic") 
    var topic: MessageTopic
    
    @Parameter(title: "Situation Details", description: "Describe the situation")
    var details: String?
    
    @Parameter(title: "Tone")
    var tone: MessageToneIntent
    
    static var parameterSummary: some ParameterSummary {
        Summary("Draft \(\.$tone) message about \(\.$topic): \(\.$details)")
    }
    
    func perform() async throws -> some IntentResult {
        let draftedMessage = await generateDraftMessage(
            topic: topic, 
            details: details ?? "",
            tone: tone
        )
        
        return await MainActor.run {
            .result(dialog: IntentDialog(stringLiteral: "Message drafted and ready to review")) {
                OpenGentlerCoparentView(initialMessage: draftedMessage)
            }
        }
    }
    
    private func generateDraftMessage(topic: MessageTopic, details: String, tone: MessageToneIntent) async -> String {
        let baseMessage = switch topic {
        case .scheduling:
            "I wanted to discuss our schedule regarding \(details)."
        case .pickup:
            "About pickup arrangements for \(details)."
        case .emergency:
            "I need to let you know about an urgent situation: \(details)."
        case .school:
            "Regarding our child's school situation: \(details)."
        case .medical:
            "I wanted to coordinate about medical needs: \(details)."
        case .activities:
            "About extracurricular activities: \(details)."
        }
        
        let toneModifier = switch tone {
        case .diplomatic:
            "I hope we can work together to find a solution that works for everyone."
        case .urgent:
            "Please let me know your thoughts as soon as possible."
        case .appreciative:
            "I really appreciate your flexibility and cooperation."
        case .collaborative:
            "I'd love to hear your ideas on how we can handle this together."
        }
        
        return "\(baseMessage) \(toneModifier)"
    }
}

enum MessageTopic: String, AppEnum, CaseIterable {
    case scheduling = "scheduling"
    case pickup = "pickup"
    case emergency = "emergency"
    case school = "school"
    case medical = "medical"
    case activities = "activities"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Message Topic")
    static let caseDisplayRepresentations: [MessageTopic: DisplayRepresentation] = [
        .scheduling: "Schedule Change",
        .pickup: "Pickup/Drop-off",
        .emergency: "Emergency",
        .school: "School Matter",
        .medical: "Medical Issue",
        .activities: "Activities"
    ]
}

enum MessageToneIntent: String, AppEnum, CaseIterable {
    case diplomatic = "diplomatic"
    case urgent = "urgent"
    case appreciative = "appreciative"
    case collaborative = "collaborative"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Message Tone")
    static let caseDisplayRepresentations: [MessageToneIntent: DisplayRepresentation] = [
        .diplomatic: "Diplomatic",
        .urgent: "Urgent",
        .appreciative: "Appreciative", 
        .collaborative: "Collaborative"
    ]
}


// MARK: - Emergency Contact Intent
@available(iOS 16.0, *)
struct EmergencyContactIntent: AppIntent {
    static let title: LocalizedStringResource = "Emergency Co-parent Contact"
    static let description = IntentDescription("Quickly contact your co-parent for emergencies")
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Emergency Type")
    var emergencyType: EmergencyType
    
    @Parameter(title: "Emergency Details", description: "What's the emergency?")
    var details: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Contact co-parent about \(\.$emergencyType): \(\.$details)")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let emergencyMessage = generateEmergencyMessage(type: emergencyType, details: details)
        
        // This would trigger immediate notification/call
        return .result(dialog: IntentDialog(stringLiteral: "Emergency message prepared. Opening app to send immediately.")) {
            OpenGentlerCoparentView(initialMessage: emergencyMessage, isEmergency: true)
        }
    }
    
    private func generateEmergencyMessage(type: EmergencyType, details: String) -> String {
        let urgencyLevel = "🚨 URGENT - "
        
        let message = switch type {
        case .medical:
            "\(urgencyLevel)Medical emergency: \(details). Please call me immediately."
        case .safety:
            "\(urgencyLevel)Safety concern: \(details). Need to coordinate right away."
        case .schoolEmergency:
            "\(urgencyLevel)School emergency: \(details). They need both parents contacted."
        case .travelIssue:
            "\(urgencyLevel)Travel/pickup emergency: \(details). Please respond ASAP."
        }
        
        return message
    }
}

enum EmergencyType: String, AppEnum, CaseIterable {
    case medical = "medical"
    case safety = "safety"
    case schoolEmergency = "schoolEmergency"
    case travelIssue = "travelIssue"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Emergency Type")
    static let caseDisplayRepresentations: [EmergencyType: DisplayRepresentation] = [
        .medical: "Medical Emergency",
        .safety: "Safety Concern", 
        .schoolEmergency: "School Emergency",
        .travelIssue: "Travel/Pickup Issue"
    ]
}

// MARK: - App Shortcuts Provider
@available(iOS 16.0, *)
struct CoparentingShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickResponseIntent(),
            phrases: [
                "Respond to my co-parent in \(.applicationName)",
                "Send co-parent response using \(.applicationName)",
                "Quick co-parent reply with \(.applicationName)"
            ],
            shortTitle: "Quick Response",
            systemImageName: "message.fill"
        )
        
        AppShortcut(
            intent: CheckScheduleIntent(),
            phrases: [
                "Check my custody schedule in \(.applicationName)",
                "What's my co-parenting schedule in \(.applicationName)",
                "Show custody calendar with \(.applicationName)"
            ],
            shortTitle: "Check Schedule",
            systemImageName: "calendar"
        )
        
        AppShortcut(
            intent: DraftMessageIntent(),
            phrases: [
                "Draft co-parent message in \(.applicationName)",
                "Help me write to my co-parent using \(.applicationName)", 
                "Create diplomatic message with \(.applicationName)"
            ],
            shortTitle: "Draft Message",
            systemImageName: "square.and.pencil"
        )
        
        AppShortcut(
            intent: EmergencyContactIntent(),
            phrases: [
                "Emergency contact co-parent with \(.applicationName)",
                "Urgent message to co-parent using \(.applicationName)"
            ],
            shortTitle: "Emergency Contact", 
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}

// MARK: - View Integration
struct OpenGentlerCoparentView: View {
    let initialMessage: String
    let isEmergency: Bool
    
    init(initialMessage: String, isEmergency: Bool = false) {
        self.initialMessage = initialMessage
        self.isEmergency = isEmergency
    }
    
    var body: some View {
        ContentView(
            chatManager: ChatManager(),
            hybridAIManager: HybridAIManager()
        )
        .environmentObject(SubscriptionManager())
        .environmentObject(AudioManager())
        .environmentObject(AppleIntelligenceManager())
    }
}