import SwiftUI

// MARK: - IntroStep Enum
enum IntroStep: CaseIterable {
    case none
    case welcome
    case coparentName
    case numChildren
    case childName
    case childBirthday
    case state
    case parentingPlan
    case conflictLevel
    case decreeUpload
    case skipDecree
    case finalMessage
    
    // Progress tracking
    var stepNumber: Int {
        switch self {
        case .none: return 0
        case .welcome: return 1
        case .coparentName: return 2
        case .numChildren: return 3
        case .childName: return 4
        case .childBirthday: return 5
        case .state: return 6
        case .parentingPlan: return 7
        case .conflictLevel: return 8
        case .decreeUpload: return 9
        case .skipDecree: return 9 // Same as decreeUpload since they're alternatives
        case .finalMessage: return 10
        }
    }
    
    var totalSteps: Int { 10 }
    
    var progressPercentage: Double {
        guard stepNumber > 0 else { return 0.0 }
        return Double(stepNumber) / Double(totalSteps)
    }
    
    var stepTitle: String {
        switch self {
        case .none: return ""
        case .welcome: return "Welcome"
        case .coparentName: return "Co-parent Info"
        case .numChildren: return "Family Size"
        case .childName: return "Children Names"
        case .childBirthday: return "Children Ages"
        case .state: return "Location"
        case .parentingPlan: return "Parenting Plan"
        case .conflictLevel: return "Conflict Level"
        case .decreeUpload, .skipDecree: return "Documents"
        case .finalMessage: return "Complete"
        }
    }
}

// MARK: - Prompt Helpers View Component
struct PromptHelpersView: View {
    let promptHelpers: [String]
    let chatManager: ChatManager
    @EnvironmentObject var audioManager: AudioManager
    @State var introStep: IntroStep = .none
    @Binding var message: String
    @Binding var selectedAttachmentURL: URL?
    @Binding var attachmentImage: UIImage?
    @Binding var extractedText: String?
    @Binding var isFromShareSheet: Bool
    let onSendMessage: () -> Void
    let onStartIntroFlow: () -> Void
    
    // Stream usage tips response with typing effect
    private func streamUsageTipsResponse(_ responseText: String) async {
        await MainActor.run {
            audioManager.playReceiveSound()
        }
        
        let streamingMessageID = await MainActor.run {
            chatManager.startStreamingMessage(sender: "Gentler Coparent")
        }
        
        let words = responseText.split(separator: " ")
        var currentText = ""
        
        for (index, word) in words.enumerated() {
            currentText += String(word)
            if index < words.count - 1 {
                currentText += " "
            }
            
            await MainActor.run {
                chatManager.updateStreamingMessage(id: streamingMessageID, withChunk: "")
                if let messageIndex = chatManager.currentConversation.firstIndex(where: { $0.id == streamingMessageID }) {
                    chatManager.currentConversation[messageIndex].text = currentText
                }
            }
            
            // Natural typing rhythm
            try? await Task.sleep(nanoseconds: UInt64.random(in: 80_000_000...140_000_000))
        }
        
        await MainActor.run {
            chatManager.finishStreamingMessage(id: streamingMessageID)
            audioManager.stopWaitingSound()
        }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(promptHelpers, id: \.self) { helper in
                    Button(action: {
                        #if canImport(UIKit)
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        #endif
                        
                        if UserDefaults.standard.data(forKey: "userProfile") == nil {
                            chatManager.addMessage(ChatMessage(sender: "Gentler Coparent", text: "Please finish setting up your family profile to begin using Gentler Coparent.", timestamp: Date()))
                            introStep = .none
                            onStartIntroFlow()
                        } else {
                            if helper == "💡Usage Tips" {
                                var profile: UserProfile? = nil
                                if let data = UserDefaults.standard.data(forKey: "userProfile") {
                                    do {
                                        profile = try JSONDecoder().decode(UserProfile.self, from: data)
                                    } catch {
                                        print("ContentView: Failed to load profile for Usage Tips - \(error)")
                                    }
                                }
                                let coparentName = profile?.coparentFirstName ?? "your coparent"
                                let usageTipsMessage = """
                                ⚙️**Family Profile** - Personalize your profile from the settings menu at the lower left. Understanding your unique situation will allow us to help you best.
                                
                                🧵**New Chat** - Tap the ➕ sign at the lower right to start a new conversation with Gentler Coparent.
                                
                                🖼️**Super Helpful** - Add screen shots of messages from \(coparentName) to the chat using the 📎 paperclip icon. Gentler Coparent will draft a reply from the screenshot!
                                
                                🔖**Bookmark Responses** - Tap the icon to the right of this message to save responses.
                                
                                📑**Copying & Sharing** - Tap the 📤 share icon next to a reply to share using the iOS share sheet.
                                
                                📜**Conversation History** - Tap the 🔄 history icon at the bottom right and you can search past Gentler Coparent conversations.
                                """
                                // Add the prompt helper message to the conversation history
                                chatManager.addMessage(ChatMessage(sender: "You", text: helper, timestamp: Date()))
                                
                                // Stream the usage tips response for natural effect
                                Task {
                                    await streamUsageTipsResponse(usageTipsMessage)
                                }
                            } else {
                                // Set message and send (sendMessage() will add to chat history)
                                message = helper
                                selectedAttachmentURL = nil
                                attachmentImage = nil
                                extractedText = nil
                                isFromShareSheet = false
                                onSendMessage()
                                print("ContentView: Prompt selected: \(helper), cleared thumbnail")
                            }
                        }
                    }) {
                        Text(helper)
                            .font(Font.custom("Avenir-Book", size: 14))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color(hex: "C2EDCE").opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .background(Color(hex: "BADFE7"))
    }
}

// MARK: - Banner View Component  
struct BannerView: View {
    var body: some View {
        Image("banner")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
    }
}

// MARK: - Trial Message View Component
struct TrialMessageView: View {
    let profileSetupDate: Date?
    let waitingPeriodDays: Double
    let promptCount: Int
    let promptQuotaLimit: Int
    
    var body: some View {
        if let setupDate = profileSetupDate {
            let daysSinceSetup = Calendar.current.dateComponents([.day], from: setupDate, to: Date()).day ?? 0
            let isWithinWaitingPeriod = daysSinceSetup < Int(waitingPeriodDays)
            let daysRemaining = max(0, Int(waitingPeriodDays) - daysSinceSetup)
            let promptsRemaining = max(0, promptQuotaLimit - promptCount)
            
            if isWithinWaitingPeriod {
                VStack(spacing: 4) {
                    Text("Free Trial: \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left, \(promptsRemaining) prompt\(promptsRemaining == 1 ? "" : "s") remaining")
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(.black)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(Color.yellow.opacity(0.8))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
    }
}