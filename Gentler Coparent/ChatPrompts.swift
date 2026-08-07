import Foundation

// MARK: - Central chat prompt starters + canned replies
enum GCPChatPrompts {
    
    struct Starter: Identifiable, Hashable {
        let id: String
        let icon: String
        let title: String
        let subtitle: String
        /// When non-nil, deliver instantly with typewriter (no network).
        let cannedKey: CannedKey?
        /// When true, open attachment picker flow via canned reply.
        var isCanned: Bool { cannedKey != nil }
    }
    
    enum CannedKey: String, Hashable {
        case usageTips
        case howToTalk
        case screenshotHelp
        case makeEmpathetic
        case noConflict
        case expense
        case boundaries
    }
    
    static let starters: [Starter] = [
        Starter(id: "usage", icon: "lightbulb.fill", title: "Usage tips", subtitle: "How to get the most from GCP", cannedKey: .usageTips),
        Starter(id: "howto", icon: "bubble.left.and.bubble.right.fill", title: "How to talk to GCP", subtitle: "Better prompts, better replies", cannedKey: .howToTalk),
        Starter(id: "screenshot", icon: "camera.fill", title: "Reply to a screenshot", subtitle: "Attach a message photo", cannedKey: .screenshotHelp),
        Starter(id: "empathy", icon: "heart.fill", title: "Make this empathetic", subtitle: "Warm tone, clear points", cannedKey: .makeEmpathetic),
        Starter(id: "conflict", icon: "hand.raised.fill", title: "Raise an issue calmly", subtitle: "Diplomacy without drama", cannedKey: .noConflict),
        Starter(id: "expense", icon: "dollarsign.circle.fill", title: "Discuss an expense", subtitle: "Clear, fair money talk", cannedKey: .expense),
        Starter(id: "boundary", icon: "shield.fill", title: "Hold a boundary", subtitle: "Firm without escalating", cannedKey: .boundaries),
    ]
    
    /// Display string shown as the user bubble when a starter is tapped.
    static func userLabel(for starter: Starter) -> String {
        starter.title
    }
    
    static func cannedResponse(for key: CannedKey, coparentName: String = "your co-parent") -> String {
        switch key {
        case .usageTips:
            return """
            **Quick tips**
            
            **Family profile** — Open Settings → Family Profile so I can use real names and conflict level.
            
            **Screenshots** — Tap the paperclip, attach a message from \(coparentName), and ask for a reply draft.
            
            **New chat** — Use the + button when you want a clean thread.
            
            **Bookmark & share** — Save strong drafts with the bookmark icon; share with the share icon.
            
            **What next?** Paste a tough message, describe a situation, or attach a screenshot.
            """
        case .howToTalk:
            return """
            **How to get great help from me**
            
            **Be specific** — “Help me reply about Friday pickup at 5” beats “Help me communicate.”
            
            **Share context** — Kids’ names, what was said, and what you need (rewrite, plan, boundary).
            
            **Attach the real message** — Screenshots beat paraphrasing.
            
            **Try asking:**
            • “Make this less confrontational”
            • “Draft a reply about school expenses”
            • “Help me set a boundary without escalating”
            
            What do you want help with today?
            """
        case .screenshotHelp:
            return """
            **Reply from a screenshot**
            
            1. Tap the **paperclip** next to the message box  
            2. Choose **Photo Library** (or take a photo)  
            3. Select the screenshot of the message  
            4. Send — I’ll draft a calm, send-ready reply
            
            Ready when you are.
            """
        case .makeEmpathetic:
            return """
            I’ll reshape your draft to sound warmer and more understanding—without losing your point.
            
            **Share the message** below (type it or attach a screenshot), and I’ll rewrite it with empathy and clarity.
            """
        case .noConflict:
            return """
            I’ll help you raise the issue without fueling a fight—facts, one clear ask, child-focused tone.
            
            **What’s going on?** Briefly describe the issue and any context about how \(coparentName) usually responds.
            """
        case .expense:
            return """
            I’ll help you discuss money clearly and fairly.
            
            **Include if you can:**
            • What the expense is (medical, school, activities…)  
            • Amount and date  
            • How you propose to split it
            
            Type details or attach a receipt/screenshot.
            """
        case .boundaries:
            return """
            I’ll help you state a clear boundary without baiting a fight—short, firm, logistics-only.
            
            **Tell me:** what boundary you need (channel, topic, timing) and any sample wording you already drafted.
            """
        }
    }
}
