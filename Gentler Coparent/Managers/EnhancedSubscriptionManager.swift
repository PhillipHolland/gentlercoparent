import Foundation
import StoreKit
import SwiftUI

// MARK: - Trial / paywall UX (StoreKit lives on SubscriptionManager only)
/// Does **not** load products or finish transactions — avoids racing a second StoreKit listener.
@MainActor
final class EnhancedSubscriptionManager: ObservableObject {
    
    // MARK: - Synced from SubscriptionManager (single source of truth for purchases)
    @Published var purchasedProductIDs: Set<String> = []
    
    // MARK: - Enhanced Properties
    @Published var freeTrialStatus: TrialStatus = .notStarted
    @Published var remainingUsage: UsageInfo = UsageInfo()
    @Published var subscriptionValue: SubscriptionValue = SubscriptionValue()
    @Published var showUsageIndicator: Bool = false
    @Published var showValueMessaging: Bool = false
    
    // Trial configuration
    private let trialDurationDays: Int = 7
    private let freeTrialPromptLimit: Int = 15
    private let freeTrialFeatures: Set<PremiumFeature> = [
        .unlimitedChats, .advancedPersonalization, .documentAnalysis, 
        .prioritySupport, .cloudSync
    ]
    
    init() {
        loadTrialStatus()
        calculateRemainingUsage()
        determineValueMessaging()
    }
    
    /// Keep trial/paywall logic in sync with the real StoreKit manager.
    func syncPurchases(from productIDs: Set<String>) {
        purchasedProductIDs = productIDs
    }
    
    // MARK: - Trial Management
    func startFreeTrial() {
        guard freeTrialStatus == .notStarted else { return }
        
        let trialStart = Date()
        let trialEnd = Calendar.current.date(byAdding: .day, value: trialDurationDays, to: trialStart) ?? Date()
        
        UserDefaults.standard.set(trialStart, forKey: "freeTrialStartDate")
        UserDefaults.standard.set(trialEnd, forKey: "freeTrialEndDate")
        UserDefaults.standard.set(0, forKey: "trialPromptsUsed")
        UserDefaults.standard.set(true, forKey: "hasStartedFreeTrial")
        
        freeTrialStatus = .active(daysRemaining: trialDurationDays)
        calculateRemainingUsage()
        
        print("🎉 7-day free trial started!")
    }
    
    func extendTrial(additionalDays: Int = 3) {
        guard case .active = freeTrialStatus else { return }
        
        if let currentEndDate = UserDefaults.standard.object(forKey: "freeTrialEndDate") as? Date {
            let extendedEndDate = Calendar.current.date(byAdding: .day, value: additionalDays, to: currentEndDate) ?? currentEndDate
            UserDefaults.standard.set(extendedEndDate, forKey: "freeTrialEndDate")
            loadTrialStatus()
            print("🎁 Trial extended by \(additionalDays) days!")
        }
    }
    
    private func loadTrialStatus() {
        let hasStartedTrial = UserDefaults.standard.bool(forKey: "hasStartedFreeTrial")
        
        if !hasStartedTrial {
            freeTrialStatus = .notStarted
            return
        }
        
        guard let endDate = UserDefaults.standard.object(forKey: "freeTrialEndDate") as? Date else {
            freeTrialStatus = .expired
            return
        }
        
        let now = Date()
        if now > endDate {
            freeTrialStatus = .expired
        } else {
            let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
            freeTrialStatus = .active(daysRemaining: max(0, daysRemaining))
        }
    }
    
    // MARK: - Usage Tracking
    func trackPromptUsage() {
        let currentCount = UserDefaults.standard.integer(forKey: "trialPromptsUsed")
        UserDefaults.standard.set(currentCount + 1, forKey: "trialPromptsUsed")
        calculateRemainingUsage()
        
        // Show/hide usage indicator based on remaining prompts
        if remainingUsage.promptsRemaining <= 3 {
            showUsageIndicator = true
        } else {
            showUsageIndicator = false
        }
        
        // Trigger value messaging at strategic points
        if shouldShowValueMessaging(promptsUsed: currentCount + 1) {
            showValueMessaging = true
        }
    }
    
    private func calculateRemainingUsage() {
        let promptsUsed = UserDefaults.standard.integer(forKey: "trialPromptsUsed")
        
        switch freeTrialStatus {
        case .active(let daysRemaining):
            remainingUsage = UsageInfo(
                promptsRemaining: max(0, freeTrialPromptLimit - promptsUsed),
                daysRemaining: daysRemaining,
                percentageUsed: Double(promptsUsed) / Double(freeTrialPromptLimit)
            )
        case .expired:
            remainingUsage = UsageInfo(promptsRemaining: 0, daysRemaining: 0, percentageUsed: 1.0)
        case .notStarted:
            remainingUsage = UsageInfo(
                promptsRemaining: freeTrialPromptLimit,
                daysRemaining: trialDurationDays,
                percentageUsed: 0.0
            )
        }
    }
    
    // MARK: - Subscription Value Messaging
    private func determineValueMessaging() {
        subscriptionValue = SubscriptionValue(
            primaryBenefit: determinePrimaryBenefit(),
            costComparison: calculateCostComparison(),
            featureHighlight: selectFeatureHighlight(),
            socialProof: getSocialProof()
        )
    }
    
    private func determinePrimaryBenefit() -> String {
        switch freeTrialStatus {
        case .active(let days) where days <= 2:
            return "Continue your progress with unlimited access"
        case .expired:
            return "Resume peaceful co-parenting conversations"
        default:
            return "Unlock unlimited personalized guidance"
        }
    }
    
    private func calculateCostComparison() -> String {
        // Annual subscription cost compared to alternatives
        return "Less than one therapy session per month"
    }
    
    private func selectFeatureHighlight() -> PremiumFeature {
        let promptsUsed = UserDefaults.standard.integer(forKey: "trialPromptsUsed")
        
        if promptsUsed > 10 {
            return .unlimitedChats
        } else if promptsUsed > 5 {
            return .advancedPersonalization
        } else {
            return .documentAnalysis
        }
    }
    
    private func getSocialProof() -> String {
        return "Join 10,000+ parents creating healthier co-parenting relationships"
    }
    
    private func shouldShowValueMessaging(promptsUsed: Int) -> Bool {
        // Show value messaging at strategic usage points
        let triggerPoints = [5, 10, 13] // Show at 33%, 66%, and 86% usage
        return triggerPoints.contains(promptsUsed)
    }
    
    // MARK: - Paywall Triggers
    func shouldTriggerPaywall() -> PaywallTrigger? {
        print("🔧 PaywallTrigger Debug:")
        print("🔧   hasActiveSubscription: \(hasActiveSubscription)")
        print("🔧   purchasedProductIDs: \(purchasedProductIDs)")
        print("🔧   freeTrialStatus: \(freeTrialStatus)")
        
        // Subscription users never see paywall
        if hasActiveSubscription {
            print("🔧   Result: nil (user has active subscription)")
            return nil
        }
        
        switch freeTrialStatus {
        case .notStarted:
            print("🔧   Result: .trialOffer (trial not started)")
            return .trialOffer
        case .active:
            if remainingUsage.promptsRemaining == 0 {
                print("🔧   Result: .usageExceeded (no prompts remaining)")
                return .usageExceeded
            } else if remainingUsage.daysRemaining == 0 {
                print("🔧   Result: .trialExpired (no days remaining)")
                return .trialExpired
            } else if remainingUsage.promptsRemaining <= 2 {
                print("🔧   Result: .approachingLimit (≤2 prompts remaining)")
                return .approachingLimit
            }
            print("🔧   Result: nil (trial active, usage available)")
            return nil
        case .expired:
            print("🔧   Result: .trialExpired (trial expired)")
            return .trialExpired
        }
    }
    
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    var canUseFeature: Bool {
        hasActiveSubscription || (freeTrialStatus.isActive && remainingUsage.promptsRemaining > 0)
    }
    
    // MARK: - Premium Feature Access
    func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        if hasActiveSubscription {
            return true
        }
        
        switch freeTrialStatus {
        case .active:
            return freeTrialFeatures.contains(feature) && remainingUsage.promptsRemaining > 0
        default:
            return false
        }
    }
}

// MARK: - Data Models
enum TrialStatus: Equatable {
    case notStarted
    case active(daysRemaining: Int)
    case expired
    
    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
    
    var displayText: String {
        switch self {
        case .notStarted:
            return "Start 7-day free trial"
        case .active(let days):
            return days > 1 ? "\(days) days remaining" : "Last day of trial"
        case .expired:
            return "Trial expired"
        }
    }
}

struct UsageInfo {
    let promptsRemaining: Int
    let daysRemaining: Int
    let percentageUsed: Double
    
    init(promptsRemaining: Int = 0, daysRemaining: Int = 0, percentageUsed: Double = 0.0) {
        self.promptsRemaining = promptsRemaining
        self.daysRemaining = daysRemaining
        self.percentageUsed = percentageUsed
    }
    
    var urgencyLevel: UrgencyLevel {
        if percentageUsed >= 0.9 { return .critical }
        if percentageUsed >= 0.7 { return .warning }
        if percentageUsed >= 0.5 { return .moderate }
        return .low
    }
}

enum UrgencyLevel {
    case low, moderate, warning, critical
    
    var color: Color {
        switch self {
        case .low: return Color(hex: "C2EDCE")
        case .moderate: return Color.orange.opacity(0.7)
        case .warning: return Color.orange
        case .critical: return Color.red
        }
    }
}

struct SubscriptionValue {
    let primaryBenefit: String
    let costComparison: String
    let featureHighlight: PremiumFeature
    let socialProof: String
    
    init(primaryBenefit: String = "", costComparison: String = "", featureHighlight: PremiumFeature = .unlimitedChats, socialProof: String = "") {
        self.primaryBenefit = primaryBenefit
        self.costComparison = costComparison
        self.featureHighlight = featureHighlight
        self.socialProof = socialProof
    }
}

enum PremiumFeature: String, CaseIterable {
    case unlimitedChats = "Unlimited Conversations"
    case advancedPersonalization = "Advanced Personalization"
    case documentAnalysis = "Document Analysis"
    case prioritySupport = "Priority Support"
    case cloudSync = "Cloud Sync"
    case exportConversations = "Export Conversations"
    
    var description: String {
        switch self {
        case .unlimitedChats:
            return "Chat without limits, get guidance anytime"
        case .advancedPersonalization:
            return "Responses tailored to your family's unique situation"
        case .documentAnalysis:
            return "Upload and analyze legal documents, screenshots"
        case .prioritySupport:
            return "Get help when you need it most"
        case .cloudSync:
            return "Access your conversations across all devices"
        case .exportConversations:
            return "Save and share important conversations"
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedChats: return "infinity.circle.fill"
        case .advancedPersonalization: return "person.crop.circle.fill"
        case .documentAnalysis: return "doc.text.magnifyingglass"
        case .prioritySupport: return "headphones.circle.fill"
        case .cloudSync: return "icloud.circle.fill"
        case .exportConversations: return "square.and.arrow.up.circle.fill"
        }
    }
}

enum PaywallTrigger {
    case trialOffer
    case usageExceeded
    case approachingLimit
    case trialExpired
    case featureGated(PremiumFeature)
    
    var title: String {
        switch self {
        case .trialOffer:
            return "Try Gentler Coparent Free for 7 Days"
        case .usageExceeded:
            return "You've Used All Free Messages"
        case .approachingLimit:
            return "Almost Out of Free Messages"
        case .trialExpired:
            return "Continue Your Progress"
        case .featureGated(let feature):
            return "Unlock \(feature.rawValue)"
        }
    }
    
    var message: String {
        switch self {
        case .trialOffer:
            return "Experience all premium features free for 7 days. No commitment required."
        case .usageExceeded:
            return "Continue getting personalized co-parenting guidance with unlimited access."
        case .approachingLimit:
            return "You have limited messages remaining. Upgrade for unlimited conversations."
        case .trialExpired:
            return "Your free trial has ended. Continue your co-parenting journey with full access."
        case .featureGated(let feature):
            return feature.description
        }
    }
}

