import SwiftUI
#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers
import PDFKit
import AVFoundation
import CoreText
import Network
import Vision
import Photos
import UserNotifications
import CloudKit
import Firebase
#endif

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var chatManager: ChatManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var enhancedSubscriptionManager = EnhancedSubscriptionManager()
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var privacyLockManager: PrivacyLockManager
    @StateObject private var appleIntelligenceManager = AppleIntelligenceManager()
    @StateObject private var hybridAIManager: HybridAIManager
    @StateObject private var networkManager = NetworkManager()
    @StateObject private var iCloudSync = iCloudSyncManager.shared
    @StateObject private var decisionFramework = CoparentingDecisionFramework()
    @EnvironmentObject var documentStorageManager: DocumentStorageManager

    // UI State
    @State private var message = ""
    @State private var lineCount = 1
    @State private var showMenu = false
    @State private var showSettings = false
    @State private var showJournal = false
    @State private var showLearningSection = false
    @State private var showBookmarks = false
    @State private var showSubscription = false
    @State private var showPhotoPicker = false
    @State private var showDocumentPicker = false
    @State private var showPickerOptions = false
    @State private var showHistory = false
    @State private var selectedTab: GCPTab = .chat
    @State private var dragOffset: CGFloat = 0
    @State private var isLoading = false
    @State private var scrollToBottom = false
    @State private var isResponseStreaming = false
    @State private var bookmarkedMessages: [ChatMessage] = []
    /// Cancels in-flight AI + typewriter when user starts a new chat or stops.
    @State private var responseTask: Task<Void, Never>?
    @State private var isNetworkAvailable = true
    @State private var messageToShare: ChatMessage?
    @State private var showShareOptions = false
    @State private var isAnimating = false
    @State private var isScrolling = false
    @State private var selectedPrompt: String?
    @State private var showSubscriptionCard = false // For modal subscription card

    // Attachment handling
    @State private var selectedAttachmentURL: URL?
    @State private var attachmentImage: UIImage?
    @State private var extractedText: String?
    @State private var isFromShareSheet = false

    // Trial system state
    @State private var profileSetupDate: Date?
    @State private var promptCount: Int = 0
    private let promptQuotaLimit: Int = 5
    private let waitingPeriodDays: Double = 7
    
    // Legacy labels (Chat uses GCPChatPrompts.starters — top 6 only)
    private let promptHelpers = [
        "💡Usage Tips",
        "🌟How to talk to GCP",
        "🖼️Help me reply to the message in this screenshot",
        "🥺Make this message empathetic",
        "☮️Communicate an issue without conflict",
        "💸Help me discuss this expense"
    ]

    // Intro flow state
    @State private var introStep: IntroStep = .none
    @State private var showOnboardingProgress = false
    @State private var showCompletionCelebration = false
    @State private var onboardingSkipped = false

    init(chatManager: ChatManager, hybridAIManager: HybridAIManager) {
        self._chatManager = StateObject(wrappedValue: chatManager)
        self._hybridAIManager = StateObject(wrappedValue: hybridAIManager)
    }



    // MARK: - View Components (from 1.0.11 reference)
    private var bannerView: some View {
        // Full-width brand mark again — Settings is in the tab bar, so no gear overlay squeeze.
        Image("banner")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .accessibilityLabel("Gentler Coparent")
    }

    private var chatAreaView: some View {
        ChatAreaView(
            messages: chatManager.currentConversation,
            isLoading: isLoading,
            isNetworkAvailable: isNetworkAvailable,
            isScrolling: isScrolling,
            bookmarkedMessages: bookmarkedMessages,
            onBookmark: bookmarkMessage,
            onShare: shareMessage,
            onNewChat: handleNewChat,
            onPromptHelper: handlePromptHelper
        )
        .environmentObject(audioManager)
    }


    
    // MARK: - Helper Functions for New Chat Button
    private func loadHasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    private func proceedWithNewChat() {
        // Interrupt any ongoing AI / typewriter work
        responseTask?.cancel()
        responseTask = nil
        isResponseStreaming = false
        isLoading = false
        audioManager.stopWaitingSound()
        
        // Drop empty streaming placeholders so they never ghost the next chat
        chatManager.currentConversation.removeAll {
            $0.sender == "Gentler Coparent" && $0.isStreaming
                && $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        // Finish any half-streamed assistant rows so they save cleanly
        for msg in chatManager.currentConversation where msg.isStreaming {
            chatManager.finishStreamingMessage(id: msg.id)
        }
        
        // Clear UI state
        message = ""
        selectedAttachmentURL = nil
        attachmentImage = nil
        extractedText = nil
        isFromShareSheet = false
        
        // Start new conversation
        chatManager.startNewConversation()
        
        // Additional haptic feedback for interruption
        audioManager.triggerHapticFeedback(.success)
    }
    
    private func cancelInFlightResponse() {
        responseTask?.cancel()
        responseTask = nil
        isLoading = false
        isResponseStreaming = false
        audioManager.stopWaitingSound()
        // Keep partial text if any, mark complete
        for msg in chatManager.currentConversation where msg.isStreaming {
            if msg.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                chatManager.currentConversation.removeAll { $0.id == msg.id }
            } else {
                chatManager.finishStreamingMessage(id: msg.id)
            }
        }
    }
    
    @MainActor
    private func displayTemplateResponse(_ templateText: String) async {
        isResponseStreaming = true
        isLoading = false // typing indicator is the streaming bubble itself
        scrollToBottom = true
        audioManager.stopWaitingSound()
        
        let streamingID = chatManager.startStreamingMessage(sender: "Gentler Coparent")
        await typewriterStream(text: templateText, messageID: streamingID, pace: .canned)
        
        chatManager.finishStreamingMessage(id: streamingID)
        isResponseStreaming = false
        isLoading = false
        audioManager.playReceiveSound()
    }
    
    /// Adaptive typewriter: short replies feel snappy; long ones chunk faster.
    private enum TypewriterPace {
        case canned
        case network
    }
    
    private func typewriterStream(text: String, messageID: UUID, pace: TypewriterPace) async {
        let chars = Array(text)
        guard !chars.isEmpty else {
            guard !Task.isCancelled else { return }
            await MainActor.run { chatManager.setStreamingMessageText(id: messageID, text: text) }
            return
        }
        
        // Larger steps for longer answers → fewer MainActor hops / layout passes.
        let step: Int = {
            let n = chars.count
            switch pace {
            case .canned:
                if n < 120 { return 3 }
                if n < 400 { return 6 }
                return 10
            case .network:
                if n < 200 { return 4 }
                if n < 800 { return 10 }
                return 18
            }
        }()
        
        let baseDelay: UInt64 = pace == .canned ? 8_000_000 : 6_000_000
        
        var i = 0
        while i < chars.count {
            if Task.isCancelled { return }
            i = min(i + step, chars.count)
            let slice = String(chars[..<i])
            await MainActor.run {
                chatManager.setStreamingMessageText(id: messageID, text: slice)
            }
            let justEndedLine = slice.last == "\n"
            let delay = justEndedLine ? baseDelay * 2 : baseDelay
            try? await Task.sleep(nanoseconds: delay)
        }
        
        guard !Task.isCancelled else { return }
        await MainActor.run {
            chatManager.setStreamingMessageText(id: messageID, text: text)
        }
    }

    private var promptHelpersView: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 10) {
                    ForEach(promptHelpers, id: \.self) { helper in
                    Button(action: {
                        // Visual feedback
                        selectedPrompt = helper
                        audioManager.triggerHapticFeedback(.success)
                        
                        // Reset selection after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            selectedPrompt = nil
                        }
                        
                        if UserDefaults.standard.data(forKey: "userProfile") == nil {
                            chatManager.addMessage(ChatMessage(sender: "Gentler Coparent", text: "Please finish setting up your family profile to begin using Gentler Coparent.", timestamp: Date()))
                            introStep = .none
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
                                ⚙️**Profile Setup** - Complete your family profile in Settings (lower left) for personalized assistance.
                                
                                🖼️**Screenshot Support** - Use the 📎 paperclip to attach screenshots of messages from \(coparentName). I'll help draft appropriate replies!
                                
                                🔖**Save & Share** - Bookmark helpful responses and share them using the icons next to each message.
                                """
                                // Display template response with typing effect (no user message needed)
                                Task { @MainActor in
                                    await displayTemplateResponse(usageTipsMessage)
                                }
                            } else if helper == "🖼️Help me reply to the message in this screenshot" {
                                let screenshotHelpMessage = """
                                1️⃣ **Tap the paperclip icon** 📎 (next to the message box)
                                
                                2️⃣ **Choose "Photo Library"** from the popup
                                
                                3️⃣ **Select your screenshot** of the message
                                
                                4️⃣ **Get your suggested response** - I'll analyze and draft a diplomatic reply
                                
                                Ready to upload your screenshot?
                                """
                                // Display template response with typing effect
                                Task { @MainActor in
                                    await displayTemplateResponse(screenshotHelpMessage)
                                }
                            } else if helper == "🌟How to talk to GCP" {
                                let talkingTipsMessage = """
                                **Be specific** - "Help me respond to this text about pickup time" vs "Help me communicate"
                                
                                **Share context** - Mention your child's name, the situation, or your co-parent's communication style
                                
                                **Upload screenshots** - Use 📎 to share actual messages for personalized responses
                                
                                **Try these examples:**
                                • "Make this message less confrontational"
                                • "Help me discuss changing the custody schedule"
                                • "Draft a response about school expenses"
                                
                                What would you like help with today?
                                """
                                Task { @MainActor in
                                    await displayTemplateResponse(talkingTipsMessage)
                                }
                            } else {
                                // Clear UI immediately for instant feedback (like top-tier apps)
                                let messageToSend = helper
                                message = ""
                                selectedAttachmentURL = nil
                                attachmentImage = nil
                                extractedText = nil
                                isFromShareSheet = false
                                
                                // Send the message using captured text
                                Task { @MainActor in
                                    await sendMessageDirect(messageToSend)
                                }
                            }
                        }
                    }) {
                        Text(helper)
                            .font(Font.custom("Avenir-Book", size: 14))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Color(hex: "C2EDCE").opacity(selectedPrompt == helper ? 1.0 : 0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 2, y: 2)
                            .scaleEffect(selectedPrompt == helper ? 0.95 : 1.0)
                            .opacity(selectedPrompt == helper ? 0.8 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedPrompt)
                    }
                }
                }
                .padding(.horizontal)
            }
            Spacer() // Push pills to top of container
        }
        .frame(height: 55)
        .padding(.vertical, 4)
    }

    private var inputBarView: some View {
        InputBarView(
            message: $message,
            lineCount: $lineCount,
            selectedAttachmentURL: $selectedAttachmentURL,
            attachmentImage: $attachmentImage,
            isLoading: isLoading,
            onSend: {
                // Capture message text and attachments before InputBarView clears them
                let messageText = message.trimmingCharacters(in: .whitespacesAndNewlines)
                let attachmentURL = selectedAttachmentURL
                let attachment = attachmentImage
                let extracted = extractedText
                
                print("🚀 ContentView onSend - messageText: '\(messageText)', hasAttachment: \(attachment != nil)")
                
                guard !messageText.isEmpty || attachmentURL != nil else { 
                    print("❌ Message is empty and no attachment, returning")
                    return 
                }
                
                // Clear attachments immediately like professional chat apps
                selectedAttachmentURL = nil
                attachmentImage = nil
                extractedText = nil
                
                print("✅ Sending message with text: '\(messageText)'")
                
                // Send the captured message with attachments
                Task { @MainActor in
                    await sendMessageWithAttachments(messageText, attachmentImage: attachment, extractedText: extracted)
                }
            },
            onAttachmentTap: {
                showPickerOptions = true
                audioManager.triggerHapticFeedback(.success)
            }
        )
    }

    private var bottomNavigationView: some View {
        HStack {
            Button(action: { showSettings = true }) {
                VStack(spacing: 0) {
                    Image("menu")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "388083"))
                    Text("Settings")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083"))
                }
            }
            
            Spacer()
            
            Button(action: { showLearningSection = true }) {
                VStack(spacing: 0) {
                    Image("learning")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "388083"))
                    Text("Learning")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083"))
                }
            }
            
            Spacer()
            
            Button(action: { showJournal = true }) {
                VStack(spacing: 0) {
                    Image("journal")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "388083"))
                    Text("Journal")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083"))
                }
            }
            
            Spacer()
            
            Button(action: { showBookmarks = true }) {
                VStack(spacing: 0) {
                    Image("bookmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "388083"))
                    Text("Bookmarks")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083"))
                }
            }
            
            Spacer()
            
            Button(action: { showHistory = true }) {
                VStack(spacing: 0) {
                    Image("historyicon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color(hex: "388083"))
                    Text("History")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083"))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(hex: "BADFE7"))
    }

    private var shouldShowUsageIndicator: Bool {
        enhancedSubscriptionManager.showUsageIndicator && !enhancedSubscriptionManager.hasActiveSubscription
    }
    
    private var usageIndicatorView: some View {
        Group {
            if shouldShowUsageIndicator {
                UsageIndicatorView(
                    usage: enhancedSubscriptionManager.remainingUsage,
                    trialStatus: enhancedSubscriptionManager.freeTrialStatus,
                    showSubscription: $showSubscription
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
    
    private var chatTabContent: some View {
        VStack(spacing: 0) {
            // Full-width logo — Settings lives in the tab bar (not overlaid on the banner).
            bannerView
            usageIndicatorView
            // Cream message card sits inside sky-blue frame (side + vertical gutter)
            chatAreaView
                .padding(.horizontal, GCPTheme.chatFrameInset)
                .padding(.top, 4)
                .padding(.bottom, 6)
            inputBarView
        }
        // BLUE FRAMING — outer shell must stay sky (not cream)
        .background(GCPTheme.chatFrame.ignoresSafeArea())
    }
    
    private var mainContentView: some View {
        TabView(selection: $selectedTab) {
            chatTabContent
                .tabItem { GCPTabIcon.label(.chat) }
                .tag(GCPTab.chat)
            
            NavigationStack {
                JournalView(chatManager: chatManager)
            }
            .tabItem { GCPTabIcon.label(.journal) }
            .tag(GCPTab.journal)
            
            NavigationStack {
                BookmarksView(bookmarkedMessages: $bookmarkedMessages)
            }
            .tabItem { GCPTabIcon.label(.bookmarks) }
            .tag(GCPTab.bookmarks)
            
            NavigationStack {
                MenuView(
                    chatManager: chatManager,
                    message: $message,
                    showMenu: Binding(
                        get: { selectedTab == .history },
                        set: { if !$0 { selectedTab = .chat } }
                    ),
                    onSelectConversation: { conversationId in
                        if let conversation = chatManager.chatHistory.first(where: { $0.id == conversationId }) {
                            chatManager.currentConversation = conversation.messages
                            chatManager.conversationID = conversationId
                            selectedTab = .chat
                        }
                    }
                )
            }
            .tabItem { GCPTabIcon.label(.history) }
            .tag(GCPTab.history)
            
            // Learning tab hidden for now — Settings in the tab bar instead.
            NavigationStack {
                SettingsView(
                    showSettings: Binding(
                        get: { selectedTab == .settings },
                        set: { if !$0 { selectedTab = .chat } }
                    ),
                    showsDismissButton: false
                )
                .environmentObject(subscriptionManager)
                .environmentObject(documentStorageManager)
                .environmentObject(audioManager)
                .environmentObject(privacyLockManager)
            }
            .tabItem { GCPTabIcon.label(.settings) }
            .tag(GCPTab.settings)
        }
        .tint(GCPTheme.primary)
        .toolbarBackground(GCPTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
    
    private var mainContentWithModifiers: some View {
        mainContentView
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // Keyboard handling
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                // Keyboard handling
            }
    }
    
    private var filePickerOverlay: some View {
        Group {
            if showPickerOptions {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showPickerOptions = false
                    }
                
                VStack(spacing: 0) {
                    // Photo Library Option
                    Button(action: {
                        showPickerOptions = false
                        showPhotoPicker = true
                        audioManager.triggerHapticFeedback(.success)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Photo Library")
                                    .font(Font.custom("Avenir-Book", size: 18).weight(.medium))
                                    .foregroundColor(.primary)
                                Text("Choose from your photos")
                                    .font(Font.custom("Avenir-Book", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                        .background(Color(hex: "BADFE7").opacity(0.5))
                        .padding(.horizontal, 20)
                    
                    // Files Option
                    Button(action: {
                        showPickerOptions = false
                        showDocumentPicker = true
                        audioManager.triggerHapticFeedback(.success)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "388083"), Color(hex: "388083").opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Files")
                                    .font(Font.custom("Avenir-Book", size: 18).weight(.medium))
                                    .foregroundColor(.primary)
                                Text("Browse documents & PDFs")
                                    .font(Font.custom("Avenir-Book", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 30)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var mainZStackView: some View {
        ZStack {
            mainContentWithModifiers
            filePickerOverlay
        }
        .animation(.easeInOut(duration: 0.2), value: showPickerOptions)
    }
    
    private var viewWithLifecycle: some View {
        mainZStackView
            .onAppear {
                loadBookmarkedMessages()
                loadProfileSetupInfo()
                restoreProfileFromiCloudIfNeeded()
                restoreBookmarksFromiCloudIfNeeded()
                checkOnboardingStatus()
                debugDocumentStorageState() // Debug document storage on app load
                
                // Always try to ensure documents are synced between systems
                print("🔄 Checking document synchronization between UserProfile and DocumentStorageManager...")
                testDocumentMigration()
                
                enhancedSubscriptionManager.syncPurchases(from: subscriptionManager.purchasedProductIDs)
            }
            .onChange(of: bookmarkedMessages) { _, _ in
                // Persist whenever the tab/list mutates bookmarks (delete, bulk, etc.)
                saveBookmarkedMessages()
            }
            .onReceive(subscriptionManager.$purchasedProductIDs) { purchasedIDs in
                // Single StoreKit source of truth → trial/paywall UX layer
                enhancedSubscriptionManager.syncPurchases(from: purchasedIDs)
            }
            .onReceive(NotificationCenter.default.publisher(for: .skipOnboarding)) { _ in
                skipOnboarding()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
                selectedTab = .settings
            }
            .onReceive(NotificationCenter.default.publisher(for: .startChatOnboarding)) { _ in
                startOnboardingFlow()
            }
    }
    
    private var onboardingProgressOverlay: some View {
        Group {
            if showOnboardingProgress && introStep != .none && introStep != .finalMessage {
                VStack {
                    OnboardingProgressView(currentStep: introStep)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnboardingProgress)
    }
    
    private var completionCelebrationOverlay: some View {
        Group {
            if showCompletionCelebration {
                OnboardingCompletionView {
                    showCompletionCelebration = false
                    showOnboardingProgress = false
                }
                .transition(.opacity)
            }
        }
    }
    
    private var subscriptionValueOverlay: some View {
        VStack {
            Spacer()
            
            // Subscription value messaging banner
            if enhancedSubscriptionManager.showValueMessaging && !enhancedSubscriptionManager.hasActiveSubscription {
                SubscriptionValueBanner(
                    subscriptionValue: enhancedSubscriptionManager.subscriptionValue,
                    trigger: .approachingLimit,
                    showSubscription: $showSubscription
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Above input area
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: enhancedSubscriptionManager.showValueMessaging)
    }
    
    var body: some View {
        viewWithLifecycle
            .overlay(onboardingProgressOverlay)
            .overlay(completionCelebrationOverlay)
            .overlay(subscriptionValueOverlay)
            .overlay(
                // 1.0.11 Subscription Card Modal
                Group {
                    if showSubscriptionCard {
                        SubscriptionCard(showSubscription: $showSubscriptionCard)
                            .environmentObject(subscriptionManager)
                            .environmentObject(subscriptionManager)
                    }
                }
            )
        .sheet(isPresented: $showPhotoPicker) {
            DocumentPicker(pickerType: .photos) { url in
                selectedAttachmentURL = url
                if ["jpg", "jpeg", "png", "heic"].contains(url.pathExtension.lowercased()) {
                    Task { @MainActor in
                        if let image = UIImage(contentsOfFile: url.path) {
                            attachmentImage = image
                            extractedText = await extractTextFromImage(image)
                        }
                    }
                }
                print("ContentView: Photo selected from library: \(url.lastPathComponent)")
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker(pickerType: .documents) { url in
                selectedAttachmentURL = url
                
                Task { @MainActor in
                    // Store document securely on device
                    let documentType = determineDocumentType(from: url.lastPathComponent)
                    let stored = await documentStorageManager.storeDocument(url: url, type: documentType)
                    
                    if stored {
                        print("✅ Document stored securely: \(url.lastPathComponent)")
                        
                        // Also extract text for immediate use
                        if url.pathExtension.lowercased() == "pdf" {
                            extractedText = await extractTextFromPDF(url: url)
                        }
                    } else {
                        print("❌ Failed to store document securely")
                        // Fallback to temporary processing
                        if url.pathExtension.lowercased() == "pdf" {
                            extractedText = await extractTextFromPDF(url: url)
                        }
                    }
                }
                
                print("ContentView: Document selected: \(url.lastPathComponent)")
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(showSettings: $showSettings, showsDismissButton: true)
                    .environmentObject(subscriptionManager)
                    .environmentObject(documentStorageManager)
                    .environmentObject(audioManager)
                    .environmentObject(privacyLockManager)
            }
        }
        .sheet(isPresented: $showJournal) {
            JournalView(chatManager: chatManager)
        }
        .sheet(isPresented: $showLearningSection) {
            LearningView()
        }
        .sheet(isPresented: $showBookmarks) {
            BookmarksView(bookmarkedMessages: $bookmarkedMessages)
        }
        .sheet(isPresented: $showHistory) {
            MenuView(
                chatManager: chatManager,
                message: $message,
                showMenu: $showHistory,
                onSelectConversation: { conversationId in
                    // Load the selected conversation
                    if let conversation = chatManager.chatHistory.first(where: { $0.id == conversationId }) {
                        chatManager.currentConversation = conversation.messages
                        chatManager.conversationID = conversationId
                        showHistory = false
                    }
                }
            )
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView(showSubscription: $showSubscription)
                .environmentObject(subscriptionManager)
        }
        .sheet(item: $messageToShare) { message in
            ActivitySheet(activityItems: [message.text])
        }
        .background(Color(hex: "BADFE7"))
        .environmentObject(audioManager)
    }

    private func handleNewChat() {
        audioManager.triggerHapticFeedback(.success)
        
        // Always allow interrupting responses for instant new chat
        proceedWithNewChat()
        
        // Check paywall after interruption (non-blocking)
        if let trigger = enhancedSubscriptionManager.shouldTriggerPaywall() {
            switch trigger {
            case .trialOffer:
                showSubscriptionCard = true
            case .usageExceeded, .trialExpired:
                showSubscription = true
            case .approachingLimit:
                showSubscriptionCard = true
            case .featureGated(_):
                showSubscription = true
            }
        }
    }
    
    private func handlePromptHelper(_ helper: String) {
        audioManager.triggerHapticFeedback(.success)
        
        if UserDefaults.standard.data(forKey: "userProfile") == nil {
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "Please finish setting up your family profile in Settings so I can personalize guidance.",
                timestamp: Date()
            ))
            return
        }
        
        // Resolve modern starter id OR legacy emoji label
        let starter = GCPChatPrompts.starters.first(where: { $0.id == helper })
            ?? GCPChatPrompts.starters.first(where: { helper.localizedCaseInsensitiveContains($0.title) })
        
        let userLabel = starter.map { GCPChatPrompts.userLabel(for: $0) } ?? helper
        
        if let starter, let key = starter.cannedKey {
            chatManager.addMessage(ChatMessage(sender: "You", text: userLabel, timestamp: Date()))
            var coparentName = "your co-parent"
            if let data = UserDefaults.standard.data(forKey: "userProfile"),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
               !profile.coparentFirstName.isEmpty {
                coparentName = profile.coparentFirstName
            }
            let reply = GCPChatPrompts.cannedResponse(for: key, coparentName: coparentName)
            Task { @MainActor in
                await displayTemplateResponse(reply)
            }
            return
        }
        
        // Free-form send path adds the user message itself
        Task { @MainActor in
            await sendMessageWithAttachments(userLabel, attachmentImage: nil, extractedText: nil)
        }
    }

    private func shareMessage(_ message: ChatMessage) {
        messageToShare = message
    }

    private func bookmarkMessage(_ message: ChatMessage) {
        // Toggle: tap again to remove
        if let index = bookmarkedMessages.firstIndex(where: { $0.id == message.id }) {
            bookmarkedMessages.remove(at: index)
        } else {
            // Store a clean non-streaming copy
            let saved = ChatMessage(
                id: message.id,
                sender: message.sender,
                text: message.text,
                timestamp: message.timestamp,
                isStreaming: false
            )
            bookmarkedMessages.insert(saved, at: 0)
        }
        saveBookmarkedMessages()
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func saveBookmarkedMessages() {
        if let encoded = try? JSONEncoder().encode(bookmarkedMessages) {
            UserDefaults.standard.set(encoded, forKey: "bookmarkedMessages")
            // Best-effort iCloud backup (reads UserDefaults after write above)
            iCloudSyncManager.shared.syncBookmarkedMessages(encoded) { _ in }
        } else if bookmarkedMessages.isEmpty {
            UserDefaults.standard.removeObject(forKey: "bookmarkedMessages")
        }
    }

    private func loadBookmarkedMessages() {
        if let data = UserDefaults.standard.data(forKey: "bookmarkedMessages"),
           let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            bookmarkedMessages = messages
        }
    }

    private func loadProfileSetupInfo() {
        if let data = UserDefaults.standard.data(forKey: "userProfile") {
            do {
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                if let setupDate = profile.setupDate {
                    profileSetupDate = setupDate
                }
            } catch {
                print("Failed to load profile setup date: \(error)")
            }
        }
    }

    private func restoreProfileFromiCloudIfNeeded() {
        guard UserDefaults.standard.data(forKey: "userProfile") == nil else { return }
        
        let iCloudSync = iCloudSyncManager.shared
        guard iCloudSync.isiCloudAvailable else { return }
        
        print("🔄 No local profile found, attempting iCloud restore...")
        
        iCloudSync.restoreUserProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    print("✅ Successfully restored profile from iCloud")
                    if let profileDict = profile as? [String: Any],
                       let profileData = try? JSONSerialization.data(withJSONObject: profileDict),
                       let userProfile = try? JSONDecoder().decode(UserProfile.self, from: profileData),
                       let encodedData = try? JSONEncoder().encode(userProfile) {
                        UserDefaults.standard.set(encodedData, forKey: "userProfile")
                    }
                case .failure(let error):
                    print("❌ Failed to restore profile from iCloud: \(error)")
                }
            }
        }
    }

    private func restoreBookmarksFromiCloudIfNeeded() {
        guard bookmarkedMessages.isEmpty else { return }
        
        let iCloudSync = iCloudSyncManager.shared
        guard iCloudSync.isiCloudAvailable else { return }
        
        print("🔄 No local bookmarks found, attempting iCloud restore...")
        
        iCloudSync.restoreBookmarkedMessages { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let messages):
                    if let messagesArray = messages as? [ChatMessage] {
                        print("✅ Successfully restored \(messagesArray.count) bookmarks from iCloud")
                        self.bookmarkedMessages = messagesArray
                        self.saveBookmarkedMessages()
                    } else {
                        print("⚠️ iCloud data format mismatch for bookmarks")
                    }
                case .failure(let error):
                    print("❌ Failed to restore bookmarks from iCloud: \(error)")
                }
            }
        }
    }


    private func sendMessage() async {
        let messageText = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        // Track usage for subscription management
        enhancedSubscriptionManager.trackPromptUsage()

        await MainActor.run {
            isResponseStreaming = true
            isLoading = true
            
            audioManager.playSendSound()
        }

        // Send with retry logic
        var attempt = 0
        var success = false
        let maxRetries = 3

        while attempt < maxRetries && !success {
            do {
                try await attemptSendMessage(messageText: messageText)
                success = true
            } catch {
                attempt += 1
                print("Send attempt \(attempt) failed: \(error)")
                
                if attempt >= maxRetries {
                    await MainActor.run {
                        chatManager.addMessage(ChatMessage(sender: "System", text: "Failed to send message after \(maxRetries) attempts. Please check your connection and try again.", timestamp: Date()))
                        isLoading = false
                        isResponseStreaming = false
                        audioManager.stopWaitingSound()
                    }
                }
            }
        }
    }

    private func sendMessageWithAttachments(_ messageText: String, attachmentImage: UIImage?, extractedText: String?) async {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("📤 sendMessageWithAttachments called with: '\(trimmedText)'")
        
        guard !trimmedText.isEmpty else { 
            print("❌ sendMessageWithAttachments: trimmed text is empty")
            return 
        }
        
        print("✅ sendMessageWithAttachments: proceeding with message")
        
        // Track usage for subscription management
        enhancedSubscriptionManager.trackPromptUsage()
        
        await MainActor.run {
            isResponseStreaming = true
            isLoading = true
            
            audioManager.playSendSound()
        }
        // Send with retry logic
        var attempt = 0
        var success = false
        let maxRetries = 3
        while attempt < maxRetries && !success {
            do {
                try await attemptSendMessage(messageText: trimmedText, attachmentImage: attachmentImage, extractedText: extractedText)
                success = true
            } catch {
                attempt += 1
                print("Send attempt \(attempt) failed: \(error)")
                
                if attempt >= maxRetries {
                    await MainActor.run {
                        chatManager.addMessage(ChatMessage(sender: "System", text: "Failed to send message after \(maxRetries) attempts. Please check your connection and try again.", timestamp: Date()))
                        isLoading = false
                        isResponseStreaming = false
                        audioManager.stopWaitingSound()
                    }
                }
            }
        }
    }
    
    private func sendMessageDirect(_ messageText: String) async {
        await sendMessageWithAttachments(messageText, attachmentImage: attachmentImage, extractedText: extractedText)
    }

    private func attemptSendMessage(messageText: String, attachmentImage: UIImage? = nil, extractedText: String? = nil) async throws {
        print("🎯 attemptSendMessage called with: '\(messageText)'")
        
        // Check if we're in onboarding flow
        if introStep != .none {
            print("📚 In onboarding flow, handling message")
            await handleOnboardingMessage(messageText)
            return
        }
        
        print("💬 Adding user message to chat: '\(messageText)'")
        
        // Add user message
        await MainActor.run {
            chatManager.addMessage(ChatMessage(sender: "You", text: messageText, timestamp: Date()))
            scrollToBottom = true
            print("✅ User message added to chatManager")
        }

        // Prepare context
        var userProfile: UserProfile?
        if let data = UserDefaults.standard.data(forKey: "userProfile") {
            userProfile = try? JSONDecoder().decode(UserProfile.self, from: data)
        }

        let contextualContext = buildContextualPrompt(originalMessage: messageText, userProfile: userProfile, attachmentText: extractedText)

        // Process with AI
        await processMessageWithAI(messageText, attachmentImage: attachmentImage, extractedText: extractedText, userProfile: userProfile, contextualContext: contextualContext)
    }

    @MainActor
    private func buildContextualPrompt(originalMessage: String, userProfile: UserProfile?, attachmentText: String?) -> String {
        var contextualizedPrompt = ""

        // Add comprehensive family and context information for personalization
        if let profile = userProfile {
            contextualizedPrompt += buildEnhancedUserContext(profile, for: originalMessage)
        }
        
        // Add conversation history context if the user is asking about previous conversations
        let isHistoryQuery = isAskingAboutPreviousConversations(originalMessage)
        print("🔍 History query detected: \(isHistoryQuery) for message: '\(originalMessage)'")
        
        if isHistoryQuery {
            // Try advanced conversation memory first
            let conversationMemoryContext = chatManager.getConversationMemoryContext(for: originalMessage, userProfile: userProfile?.toDictionary())
            var historyContext = formatConversationMemoryForAI(conversationMemoryContext)
            
            // If advanced memory is empty (CloudKit issues), fall back to simple local search
            if historyContext.isEmpty {
                print("🔄 Advanced memory empty, falling back to local conversation search")
                historyContext = searchLocalConversationHistory(for: originalMessage)
            }
            
            print("📚 Retrieved conversation context: \(historyContext.isEmpty ? "empty" : "\(historyContext.count) characters")")
            
            if !historyContext.isEmpty {
                contextualizedPrompt += "\n\n**Previous Conversation Context:**\n\(historyContext)\n"
                print("✅ Added conversation history to prompt")
            } else {
                print("⚠️ No conversation history found despite having \(chatManager.chatHistory.count) conversations")
            }
        }

        // Add attachment text with intelligent context integration
        if let attachmentText = attachmentText, !attachmentText.isEmpty {
            let documentContext = analyzeAttachmentContent(attachmentText, userMessage: originalMessage)
            contextualizedPrompt += documentContext
        }
        
        // Add stored document context if relevant to the user's message
        print("🔍 ContentView: Checking for document context with DocumentStorageManager...")
        print("🔍 ContentView: DocumentStorageManager has \(documentStorageManager.storedDocuments.count) stored documents")
        
        if let storedDocumentContext = documentStorageManager.getDocumentContext(for: originalMessage) {
            print("✅ ContentView: Got document context, length: \(storedDocumentContext.count) characters")
            print("📝 ContentView: Document context preview: \(storedDocumentContext.prefix(200))...")
            contextualizedPrompt += storedDocumentContext
        } else {
            print("❌ ContentView: No document context returned from DocumentStorageManager")
        }

        // Add original message
        contextualizedPrompt += "\n\nUser's message: \(originalMessage.isEmpty ? "No additional context provided." : originalMessage)\n\nPlease provide a helpful response for this co-parenting situation."

        print("📤 ContentView: Final contextualized prompt length: \(contextualizedPrompt.count) characters")
        print("📤 ContentView: Final prompt preview (first 500 chars):")
        print(String(contextualizedPrompt.prefix(500)))
        print("--- END PROMPT PREVIEW ---")
        
        return contextualizedPrompt
    }
    
    // MARK: - Conversation Memory Helpers
    
    /// Detect if the user is asking about previous conversations
    private func isAskingAboutPreviousConversations(_ message: String) -> Bool {
        let lowerMessage = message.lowercased()
        
        // Keywords that indicate questions about past conversations
        let historyKeywords = [
            // Time references
            "last", "previous", "before", "earlier", "ago", "yesterday", "week", "month", "year",
            // Question words about past events
            "what did", "when did", "where did", "who had", "how did", "what happened",
            // Memory/recall indicators
            "remember", "recall", "discuss", "talked about", "mentioned", "said",
            // Specific co-parenting topics that users often ask about
            "christmas", "holidays", "vacation", "soccer", "appointment", "doctor", "expense", "cost", "paid", "pickup", "dropoff"
        ]
        
        return historyKeywords.contains { keyword in
            lowerMessage.contains(keyword)
        }
    }
    
    /// Format conversation memory context for AI consumption
    private func formatConversationMemoryForAI(_ context: ConversationMemoryContext) -> String {
        var formatted = ""
        
        // Add relevant past contexts
        if !context.relevantPastContexts.isEmpty {
            formatted += "**Recent Relevant Conversations:**\n"
            for pastContext in context.relevantPastContexts.prefix(3) { // Limit to most relevant
                let date = DateFormatter.localizedString(from: pastContext.timestamp, dateStyle: .medium, timeStyle: .none)
                formatted += "• \(date): \(pastContext.topicSummary)\n"
                if !pastContext.keyInsights.isEmpty {
                    formatted += "  - Key points: \(pastContext.keyInsights.joined(separator: ", "))\n"
                }
            }
            formatted += "\n"
        }
        
        // Add recurring themes if relevant
        if !context.recurringThemes.isEmpty {
            formatted += "**Recurring Discussion Topics:**\n"
            for theme in context.recurringThemes.prefix(3) {
                formatted += "• \(theme.theme): mentioned \(theme.frequency) times\n"
            }
            formatted += "\n"
        }
        
        // Add trend insights
        if !context.trendInsights.isEmpty {
            formatted += "**Communication Patterns:**\n"
            for insight in context.trendInsights.prefix(2) {
                formatted += "• \(insight)\n"
            }
            formatted += "\n"
        }
        
        // Add overall conversation history summary
        if !context.conversationHistory.isEmpty {
            formatted += "**Overall Context:** \(context.conversationHistory)\n"
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Enhanced fallback local conversation search when CloudKit memory is unavailable
    private func searchLocalConversationHistory(for query: String) -> String {
        let searchContext = analyzeQueryContext(query)
        var relevantConversations: [(ChatConversation, Double)] = []
        
        // Search through chat history with semantic scoring
        for conversation in chatManager.chatHistory {
            let relevanceScore = calculateEnhancedRelevanceScore(conversation: conversation, searchContext: searchContext)
            if relevanceScore > 0.1 { // Use threshold for meaningful relevance
                relevantConversations.append((conversation, relevanceScore))
            }
        }
        
        // Sort by enhanced relevance and recency
        relevantConversations.sort { first, second in
            let recencyBonus1 = calculateRecencyBonus(first.0.timestamp)
            let recencyBonus2 = calculateRecencyBonus(second.0.timestamp)
            let score1 = first.1 + recencyBonus1
            let score2 = second.1 + recencyBonus2
            return score1 > score2
        }
        
        // Format the most relevant conversations with better context
        return formatRelevantConversations(relevantConversations, searchContext: searchContext)
    }
    
    // MARK: - Enhanced Conversation Memory Helpers
    
    /// Analyze query context for better semantic search
    private func analyzeQueryContext(_ query: String) -> SearchContext {
        let lowercased = query.lowercased()
        var categories: [String] = []
        var timeframe: TimeFrame = .any
        var keywords: [String] = []
        
        // Extract keywords
        let words = lowercased.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty && $0.count > 2 }
        keywords = words
        
        // Identify categories
        if lowercased.contains("school") || lowercased.contains("teacher") || lowercased.contains("grade") {
            categories.append("school")
        }
        if lowercased.contains("doctor") || lowercased.contains("medical") || lowercased.contains("appointment") {
            categories.append("medical")
        }
        if lowercased.contains("money") || lowercased.contains("cost") || lowercased.contains("expense") || lowercased.contains("payment") {
            categories.append("financial")
        }
        if lowercased.contains("schedule") || lowercased.contains("pickup") || lowercased.contains("drop") || lowercased.contains("time") {
            categories.append("scheduling")
        }
        if lowercased.contains("behavior") || lowercased.contains("discipline") || lowercased.contains("rules") {
            categories.append("parenting")
        }
        
        // Identify timeframe
        if lowercased.contains("last week") || lowercased.contains("recently") {
            timeframe = .recent
        } else if lowercased.contains("last month") || lowercased.contains("while ago") {
            timeframe = .medium
        } else if lowercased.contains("long ago") || lowercased.contains("months ago") {
            timeframe = .distant
        }
        
        return SearchContext(keywords: keywords, categories: categories, timeframe: timeframe, originalQuery: query)
    }
    
    /// Calculate enhanced relevance score using semantic analysis
    private func calculateEnhancedRelevanceScore(conversation: ChatConversation, searchContext: SearchContext) -> Double {
        var score = 0.0
        
        // Category matching (high weight)
        for category in searchContext.categories {
            if conversationContainsCategory(conversation, category: category) {
                score += 0.3
            }
        }
        
        // Keyword matching (medium weight)
        let keywordMatches = searchContext.keywords.compactMap { keyword in
            conversationContainsKeyword(conversation, keyword: keyword) ? keyword : nil
        }
        score += Double(keywordMatches.count) * 0.2
        
        // Title/topic matching (high weight)
        if let title = conversation.title {
            for keyword in searchContext.keywords {
                if title.localizedCaseInsensitiveContains(keyword) {
                    score += 0.25
                }
            }
        }
        
        // Message content depth (considers message engagement)
        let messageCount = conversation.messages.count
        if messageCount > 4 { // Longer conversations likely more important
            score += 0.1
        }
        
        return min(score, 1.0) // Cap at 1.0
    }
    
    /// Calculate recency bonus for conversation relevance
    private func calculateRecencyBonus(_ timestamp: Date) -> Double {
        let daysSince = Date().timeIntervalSince(timestamp) / (24 * 60 * 60)
        
        if daysSince < 1 { return 0.2 } // Today
        else if daysSince < 7 { return 0.15 } // This week
        else if daysSince < 30 { return 0.1 } // This month
        else if daysSince < 90 { return 0.05 } // Last 3 months
        else { return 0.0 } // Older
    }
    
    /// Format relevant conversations with enhanced context
    private func formatRelevantConversations(_ conversations: [(ChatConversation, Double)], searchContext: SearchContext) -> String {
        let maxConversations = min(3, conversations.count)
        guard maxConversations > 0 else { return "" }
        
        var formatted = "**Found \(maxConversations) relevant previous conversation(s):**\n\n"
        
        for i in 0..<maxConversations {
            let (conversation, score) = conversations[i]
            let date = DateFormatter.localizedString(from: conversation.timestamp, dateStyle: .medium, timeStyle: .none)
            let title = conversation.title ?? "Untitled"
            let scorePercent = Int(score * 100)
            
            formatted += "• **\(date)**: \(title) (\(scorePercent)% relevance)\n"
            
            // Add most relevant messages from the conversation
            let relevantMessages = extractMostRelevantMessages(from: conversation, searchContext: searchContext)
            for message in relevantMessages.prefix(2) {
                let preview = String(message.text.prefix(120))
                formatted += "  - \(message.sender): \(preview)\(message.text.count > 120 ? "..." : "")\n"
            }
            formatted += "\n"
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Helper functions for semantic analysis
    private func conversationContainsCategory(_ conversation: ChatConversation, category: String) -> Bool {
        let allText = conversation.messages.map { $0.text }.joined(separator: " ").lowercased()
        
        switch category {
        case "school":
            return allText.contains("school") || allText.contains("teacher") || allText.contains("grade") || allText.contains("homework")
        case "medical":
            return allText.contains("doctor") || allText.contains("medical") || allText.contains("appointment") || allText.contains("sick")
        case "financial":
            return allText.contains("money") || allText.contains("cost") || allText.contains("expense") || allText.contains("payment") || allText.contains("$")
        case "scheduling":
            return allText.contains("schedule") || allText.contains("pickup") || allText.contains("drop") || allText.contains("time") || allText.contains("when")
        case "parenting":
            return allText.contains("behavior") || allText.contains("discipline") || allText.contains("rules") || allText.contains("parenting")
        default:
            return false
        }
    }
    
    private func conversationContainsKeyword(_ conversation: ChatConversation, keyword: String) -> Bool {
        return conversation.messages.contains { message in
            message.text.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    private func extractMostRelevantMessages(from conversation: ChatConversation, searchContext: SearchContext) -> [ChatMessage] {
        return conversation.messages.filter { message in
            !message.text.isEmpty && (
                searchContext.keywords.contains { keyword in
                    message.text.localizedCaseInsensitiveContains(keyword)
                } || searchContext.categories.contains { category in
                    conversationContainsCategory(conversation, category: category) &&
                    message.text.localizedCaseInsensitiveContains(category)
                }
            )
        }
    }
    
    // MARK: - Search Context Types
    struct SearchContext {
        let keywords: [String]
        let categories: [String]
        let timeframe: TimeFrame
        let originalQuery: String
    }
    
    enum TimeFrame {
        case any, recent, medium, distant
    }
    
    /// Extract search terms from the user's query
    private func extractSearchTerms(from query: String) -> [String] {
        let lowercaseQuery = query.lowercased()
        var terms: [String] = []
        
        // Common co-parenting topics
        let coparentingTerms = [
            "soccer", "football", "basketball", "sports", "game", "practice", "tournament",
            "doctor", "appointment", "medical", "checkup", "dentist", "hospital",
            "school", "teacher", "homework", "grades", "conference", "meeting",
            "pickup", "dropoff", "exchange", "custody", "schedule", "time",
            "expense", "cost", "money", "payment", "bill", "fee",
            "christmas", "holiday", "vacation", "birthday", "celebration",
            "behavior", "discipline", "rules", "bedtime", "chores"
        ]
        
        // Add terms that appear in the query
        for term in coparentingTerms {
            if lowercaseQuery.contains(term) {
                terms.append(term)
            }
        }
        
        // Add important words from the query (nouns, verbs)
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words = lowercaseQuery.components(separatedBy: separators)
            .filter { $0.count > 2 && !["the", "and", "but", "for", "are", "was", "were", "been", "have", "has", "had", "did", "will", "would", "could", "should"].contains($0) }
        
        terms.append(contentsOf: words)
        
        return Array(Set(terms)) // Remove duplicates
    }
    
    /// Calculate relevance score for a conversation
    private func calculateRelevanceScore(conversation: ChatConversation, searchTerms: [String]) -> Int {
        var score = 0
        let allText = conversation.messages.map { $0.text }.joined(separator: " ").lowercased()
        
        for term in searchTerms {
            let occurrences = allText.components(separatedBy: term).count - 1
            score += occurrences * (term.count > 4 ? 3 : 1) // Weight longer terms more heavily
        }
        
        return score
    }
    
    // MARK: - UI/UX Performance Helpers
    
    /// Professional keyboard dismissal like top-tier chat apps
    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func processMessageWithAI(_ messageText: String, attachmentImage: UIImage?, extractedText: String?, userProfile: UserProfile?, contextualContext: String) async {
        do {
            // Infer task so legal/crisis/rewrite get stronger expert guidance.
            let taskLabel = Self.inferExpertTaskLabel(from: messageText, hasAttachment: extractedText != nil || attachmentImage != nil)
            let aiTask = Self.mapExpertTaskToAITask(taskLabel)
            
            let expertPrompt = ExpertSystem.buildSystemPrompt(
                conflictLevel: userProfile?.conflictLevel ?? 5,
                stateOfResidence: userProfile?.stateOfResidence,
                taskLabel: taskLabel,
                extraContext: contextualContext
            )
            
            let context = MessageContext(
                tone: .diplomatic,
                purpose: .routineCommunication,
                childContext: contextualContext,
                systemPrompt: expertPrompt,
                userProfile: userProfile?.toDictionary()
            )
            
            // Prefer rich user payload (message + context) for cloud path quality.
            let userPayload: String
            if contextualContext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                userPayload = messageText
            } else {
                userPayload = """
                \(messageText)
                
                ---
                Context for this request (family, documents, history — use accurately; do not invent):
                \(contextualContext)
                """
            }
            
            let routingResult = try await hybridAIManager.processMessage(
                userPayload,
                task: aiTask,
                context: context
            )

            // Never surface model-provider identity; always speak as GCP.
            let finalResponse = ExpertSystem.sanitizeResponseIdentity(routingResult.text)
            
            await streamAIResponse(finalResponse)
            
        } catch {
            await MainActor.run {
                chatManager.addMessage(ChatMessage(sender: "Gentler Coparent", text: "I'm having trouble processing your request. Please try again.", timestamp: Date()))
                isLoading = false
                isResponseStreaming = false
                audioManager.stopWaitingSound()
            }
        }
    }
    
    /// Map free-text user intent into ExpertSystem task labels.
    private static func inferExpertTaskLabel(from message: String, hasAttachment: Bool) -> String {
        let lower = message.lowercased()
        if hasAttachment || lower.contains("document") || lower.contains("decree") || lower.contains("order") || lower.contains("screenshot") {
            return "documentAnalysis"
        }
        if lower.contains("emergency") || lower.contains("threatened") || lower.contains("afraid") || lower.contains("hit me") || lower.contains("violence") || lower.contains("911") {
            return "crisisIntervention"
        }
        if lower.contains("statute") || lower.contains("lawyer") || lower.contains("attorney") || lower.contains("court order") || lower.contains("custody law") || lower.contains("legal right") {
            return "legalGuidance"
        }
        if lower.contains("rewrite") || lower.contains("rephrase") || lower.contains("make this sound") || lower.contains("tone down") || lower.contains("draft a response") || lower.contains("reply to this") {
            return "messageRewriting"
        }
        return "comprehensiveAdvice"
    }
    
    private static func mapExpertTaskToAITask(_ label: String) -> HybridAIManager.AITask {
        switch label {
        case "legalGuidance": return .legalGuidance
        case "crisisIntervention": return .crisisIntervention
        case "documentAnalysis": return .documentAnalysis
        case "messageRewriting": return .messageRewriting
        default: return .comprehensiveAdvice
        }
    }

    private func streamAIResponse(_ responseText: String) async {
        let streamingMessageID = await MainActor.run {
            audioManager.stopWaitingSound()
            isLoading = false
            return chatManager.startStreamingMessage(sender: "Gentler Coparent")
        }
        
        await typewriterStream(text: responseText, messageID: streamingMessageID, pace: .network)
        
        await MainActor.run {
            chatManager.finishStreamingMessage(id: streamingMessageID)
            isLoading = false
            isResponseStreaming = false
            audioManager.stopWaitingSound()
            audioManager.playReceiveSound()
        }
    }

}


// OCR Text extraction from images using VisionKit
private func extractTextFromImage(_ image: UIImage) async -> String? {
    #if canImport(Vision)
    guard let cgImage = image.cgImage else { return nil }
    
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    
    return await withCheckedContinuation { continuation in
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            let results = request.results ?? []
            let recognizedStrings = results.compactMap { $0.topCandidates(1).first?.string }
            let fullText = recognizedStrings.joined(separator: "\n")
            continuation.resume(returning: fullText.isEmpty ? nil : fullText)
        } catch {
            print("Text recognition error: \(error)")
            continuation.resume(returning: nil)
        }
    }
    #else
    return nil
    #endif
}

// PDF text extraction
private func extractTextFromPDF(url: URL) async -> String? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            guard let pdfDocument = PDFDocument(url: url) else {
                continuation.resume(returning: nil)
                return
            }
            
            var extractedText = ""
            for i in 0..<pdfDocument.pageCount {
                if let page = pdfDocument.page(at: i) {
                    extractedText += page.string ?? ""
                    extractedText += "\n"
                }
            }
            
            continuation.resume(returning: extractedText.isEmpty ? nil : extractedText)
        }
    }
}

// MARK: - Enhanced Context Utilization
extension ContentView {
    
    /// Build comprehensive user context from profile data (+ decree summary when storage is empty)
    private func buildEnhancedUserContext(_ profile: UserProfile, for message: String) -> String {
        var context = "\n\n**Family & Situation Context:**"
        
        // Basic names (always included)
        if !profile.userFirstName.isEmpty {
            context += "\n- User: \(profile.userFirstName)"
            if !profile.userLastName.isEmpty { context += " \(profile.userLastName)" }
        }
        if !profile.coparentFirstName.isEmpty {
            context += "\n- Co-parent: \(profile.coparentFirstName)"
            if !profile.coparentLastName.isEmpty { context += " \(profile.coparentLastName)" }
        }
        
        // Children information with ages for age-appropriate advice
        let childInfo = profile.children.compactMap { child -> String? in
            guard !child.firstName.isEmpty else { return nil }
            let age = child.age > 0 ? " (age \(child.age))" : ""
            return "\(child.firstName)\(age)"
        }.joined(separator: ", ")
        
        if !childInfo.isEmpty {
            context += "\n- Children: \(childInfo)"
        }
        
        // Conflict level 1–10 (matches profile setup)
        let band = ExpertSystem.ConflictBand.from(level: profile.conflictLevel)
        context += "\n- Conflict level (1–10): \(profile.conflictLevel) → \(band.label)"
        context += "\n- Active policy mode: \(band.rawValue)"
        
        // Possession schedule from profile (often auto-filled from decree OCR)
        if let schedule = profile.possessionSchedule, !schedule.isEmpty {
            context += "\n- Custody / schedule notes:\n\(schedule.prefix(1200))"
        }
        
        // State for legal context
        if !profile.stateOfResidence.isEmpty {
            context += "\n- State: \(profile.stateOfResidence) (general guidance only; confirm legal specifics with local counsel)"
        }
        
        // Fallback decree text if DocumentStorageManager didn't attach structured context
        if documentStorageManager.getPrimaryDivorceDecree() == nil,
           let decreeText = profile.divorceDecreeText,
           !decreeText.isEmpty {
            // Larger local budget — full extract is stored; we inject a generous excerpt
            let budget = 6000
            let excerpt = String(decreeText.prefix(budget))
            context += "\n\n**Divorce decree text on file (\(decreeText.count.formatted()) chars total; excerpt):**\n\(excerpt)"
            if decreeText.count > budget {
                context += "\n…[excerpt of full \(decreeText.count.formatted())-character extract stored on device]"
            }
        }
        
        context += "\n\n**Personalization:** Use real names. Follow ExpertSystem conflict mode. Prefer decree/schedule facts over guesses. Keep children out of adult conflict. Never identify as any other AI brand."
        
        return context
    }
    
    // MARK: - Debug Functions
    private func debugDocumentStorageState() {
        print("🔍 === DOCUMENT STORAGE DEBUG ===")
        print("📄 DocumentStorageManager stored documents count: \(documentStorageManager.storedDocuments.count)")
        
        for (index, doc) in documentStorageManager.storedDocuments.enumerated() {
            print("📄 Document \(index + 1):")
            print("   - Filename: \(doc.filename)")
            print("   - Type: \(doc.type.rawValue)")
            print("   - Upload Date: \(doc.uploadDate)")
            print("   - Text Content Length: \(doc.textContent.count) characters")
            print("   - Parsed Data Available: \(doc.parsedData != nil)")
            if let parsed = doc.parsedData {
                print("     - Party Names: \(parsed.partyNames)")
                print("     - Children: \(parsed.children)")
                print("     - Custody: \(parsed.custodyArrangement ?? "None")")
                print("     - Support: \(parsed.supportAmount ?? "None")")
                print("     - Schedule: \(parsed.schedule ?? "None")")
                print("     - Confidence: \(parsed.confidence)")
            }
        }
        
        // Check UserProfile for comparison
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            print("📄 UserProfile divorce decree URL: \(profile.divorceDecreeURL?.absoluteString ?? "None")")
            print("📄 UserProfile decree text length: \(profile.divorceDecreeText?.count ?? 0) characters")
        } else {
            print("📄 No UserProfile found or failed to decode")
        }
        
        print("🔍 === END DOCUMENT DEBUG ===")
    }
    
    private func testDocumentMigration() {
        print("🔄 === DOCUMENT SYNCHRONIZATION CHECK ===")
        
        // Check if DocumentStorageManager already has divorce decree
        if let existingDoc = documentStorageManager.getPrimaryDivorceDecree() {
            print("✅ DocumentStorageManager already has divorce decree: \(existingDoc.filename)")
            print("📄 Text content length: \(existingDoc.textContent.count) characters")
            print("📄 Parsed data available: \(existingDoc.parsedData != nil)")
            return
        }
        
        print("📄 No divorce decree in DocumentStorageManager, checking UserProfile...")
        
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
              let divorceDecreeURL = profile.divorceDecreeURL else {
            print("❌ No UserProfile with divorce decree found")
            return
        }
        
        print("✅ Found UserProfile with decree URL: \(divorceDecreeURL.absoluteString)")
        print("📄 UserProfile decree text length: \(profile.divorceDecreeText?.count ?? 0) characters")
        
        // Migrate from UserProfile to DocumentStorageManager.
        // Prefer PDF re-store; if that fails (security scope / missing file), seed from existing OCR text.
        Task {
            print("🔄 Starting migration from UserProfile to DocumentStorageManager...")
            var success = await documentStorageManager.storeDocument(url: divorceDecreeURL, type: .divorceDecree)
            
            if !success, let text = profile.divorceDecreeText, !text.isEmpty {
                print("📄 PDF store failed — seeding from UserProfile.divorceDecreeText (\(text.count) chars)")
                success = await documentStorageManager.storeDocumentFromExistingText(
                    text: text,
                    filename: divorceDecreeURL.lastPathComponent,
                    type: .divorceDecree,
                    sourceURL: divorceDecreeURL
                )
            }
            
            await MainActor.run {
                if success {
                    print("✅ Document migration successful!")
                    print("📄 DocumentStorageManager now has \(documentStorageManager.storedDocuments.count) documents")
                } else {
                    print("❌ Document migration failed - chat will use UserProfile decree excerpt fallback")
                }
            }
        }
    }
    
    // MARK: - Subscription Sync Fix
    private func syncSubscriptionManagers() {
        print("🔧 === SUBSCRIPTION SYNC DEBUG ===")
        print("💳 Base SubscriptionManager products: \(subscriptionManager.purchasedProductIDs)")
        print("💳 Enhanced SubscriptionManager products: \(enhancedSubscriptionManager.purchasedProductIDs)")
        print("💳 Base hasActiveSubscription: \(subscriptionManager.hasActiveSubscription())")
        print("💳 Enhanced hasActiveSubscription: \(enhancedSubscriptionManager.hasActiveSubscription)")
        
        // Sync the subscription data
        enhancedSubscriptionManager.purchasedProductIDs = subscriptionManager.purchasedProductIDs
        
        print("💳 After sync - Enhanced hasActiveSubscription: \(enhancedSubscriptionManager.hasActiveSubscription)")
        print("🔧 === END SUBSCRIPTION SYNC ===")
    }
    
    /// Analyze attachment content for intelligent context integration
    private func determineDocumentType(from filename: String) -> DocumentStorageManager.StoredDocument.DocumentType {
        // Since we only support divorce decrees, always return that type
        return .divorceDecree
    }
    
    private func analyzeAttachmentContent(_ attachmentText: String, userMessage: String) -> String {
        let text = attachmentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = userMessage.lowercased()
        
        // Detect document type and provide appropriate context
        var documentType = "document"
        var contextualGuidance = ""
        
        // Legal document detection
        if text.contains("COURT") || text.contains("ORDER") || text.contains("DECREE") || 
           text.contains("CUSTODY") || text.contains("VISITATION") || text.contains("CHILD SUPPORT") ||
           text.contains("PARENTING PLAN") || text.contains("MEDIATION") {
            documentType = "legal document"
            contextualGuidance = "This appears to be a legal document. Focus on compliance, understanding obligations, and practical implementation."
        }
        
        // School/medical document detection  
        else if text.contains("SCHOOL") || text.contains("TEACHER") || text.contains("GRADE") ||
                text.contains("DOCTOR") || text.contains("MEDICAL") || text.contains("HOSPITAL") ||
                text.contains("APPOINTMENT") || text.contains("PRESCRIPTION") {
            documentType = "school or medical document"
            contextualGuidance = "This appears to be a school or medical document. Focus on child welfare, coordination between parents, and appropriate responses."
        }
        
        // Text message/communication detection
        else if text.contains("AM") || text.contains("PM") || text.contains("Today") ||
                text.contains("Tomorrow") || text.contains("Message") || text.count < 500 {
            documentType = "message or communication"
            contextualGuidance = "This appears to be a message or communication. Focus on improving the tone, clarity, and effectiveness of the response."
        }
        
        // Financial document detection
        else if text.contains("$") || text.contains("COST") || text.contains("EXPENSE") ||
                text.contains("PAYMENT") || text.contains("BILL") || text.contains("RECEIPT") {
            documentType = "financial document"
            contextualGuidance = "This appears to be financial information. Focus on fair cost-sharing, transparency, and maintaining good financial communication."
        }
        
        var contextString = "\n\n**Attached \(documentType.capitalized):**\n\(text)"
        
        if !contextualGuidance.isEmpty {
            contextString += "\n\n**Document Analysis Guidance:** \(contextualGuidance)"
        }
        
        // Add specific prompting based on user's request
        if message.contains("help me respond") || message.contains("how should i") || message.contains("what should i say") {
            contextString += "\n\n**User is asking for help crafting a response to this \(documentType). Provide specific, actionable communication advice.**"
        }
        
        return contextString
    }
}

// MARK: - Onboarding Flow Management
extension ContentView {
    private func checkOnboardingStatus() {
        // Check if onboarding was skipped
        onboardingSkipped = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Start onboarding if no profile exists and not skipped
        if UserDefaults.standard.data(forKey: "userProfile") == nil && !onboardingSkipped {
            startOnboardingFlow()
        }
    }
    
    private func startOnboardingFlow() {
        introStep = .welcome
        showOnboardingProgress = true
        chatManager.currentConversation = []
        chatManager.addMessage(ChatMessage(
            sender: "Gentler Coparent", 
            text: "**👋🏼 Welcome to Gentler Coparent!** Your path to more peaceful communication begins today.\n\n⚙️ These next steps will personalize your conversations. You won't need to do this again.\n\n✍🏼 Let's start with your first and last name.", 
            timestamp: Date()
        ))
    }
    
    private func handleOnboardingMessage(_ messageText: String) async {
        await MainActor.run {
            chatManager.addMessage(ChatMessage(sender: "You", text: messageText, timestamp: Date()))
        }
        
        // Process onboarding step
        switch introStep {
        case .welcome:
            await processWelcomeStep(messageText)
        case .coparentName:
            await processCoparentNameStep(messageText)
        case .numChildren:
            await processChildrenCountStep(messageText)
        case .childName:
            await processChildNameStep(messageText)
        case .childBirthday:
            await processChildBirthdayStep(messageText)
        case .state:
            await processStateStep(messageText)
        case .parentingPlan:
            await processParentingPlanStep(messageText)
        case .conflictLevel:
            await processConflictLevelStep(messageText)
        case .decreeUpload:
            await processDecreeUploadStep(messageText)
        case .skipDecree:
            await processSkipDecreeStep(messageText)
        default:
            break
        }
        
        await MainActor.run {
            isLoading = false
            isResponseStreaming = false
            audioManager.stopWaitingSound()
        }
    }
    
    private func processWelcomeStep(_ messageText: String) async {
        let names = messageText.split(separator: " ").map { String($0) }
        let userFirstName = names.first ?? ""
        let userLastName = names.count > 1 ? names.last ?? "" : ""
        
        // Store names temporarily
        UserDefaults.standard.set(userFirstName, forKey: "tempUserFirstName")
        UserDefaults.standard.set(userLastName, forKey: "tempUserLastName")
        
        await MainActor.run {
            introStep = .coparentName
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "👏🏼 Thanks \(userFirstName)! What is your co-parent's first and last name?",
                timestamp: Date()
            ))
        }
    }
    
    private func processCoparentNameStep(_ messageText: String) async {
        let names = messageText.split(separator: " ").map { String($0) }
        let coparentFirstName = names.first ?? ""
        let coparentLastName = names.count > 1 ? names.last ?? "" : ""
        
        // Store co-parent names temporarily
        UserDefaults.standard.set(coparentFirstName, forKey: "tempCoparentFirstName")
        UserDefaults.standard.set(coparentLastName, forKey: "tempCoparentLastName")
        
        await MainActor.run {
            introStep = .numChildren
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "🧑‍🧒‍🧒 How many children do you have together?",
                timestamp: Date()
            ))
        }
    }
    
    private func processChildrenCountStep(_ messageText: String) async {
        guard let numberOfChildren = Int(messageText), numberOfChildren > 0, numberOfChildren <= 10 else {
            await MainActor.run {
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "Please enter a number between 1 and 10.",
                    timestamp: Date()
                ))
            }
            return
        }
        
        UserDefaults.standard.set(numberOfChildren, forKey: "tempNumberOfChildren")
        UserDefaults.standard.set(0, forKey: "tempCurrentChildIndex") // Start with first child
        
        await MainActor.run {
            introStep = .childName
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "👶 What is your first child's first name?",
                timestamp: Date()
            ))
        }
    }
    
    private func processChildNameStep(_ messageText: String) async {
        let currentChildIndex = UserDefaults.standard.integer(forKey: "tempCurrentChildIndex")
        
        // Store child name
        UserDefaults.standard.set(messageText, forKey: "tempChild\(currentChildIndex)Name")
        
        await MainActor.run {
            introStep = .childBirthday
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "📅 What is \(messageText)'s birthday? (MM/DD/YYYY)",
                timestamp: Date()
            ))
        }
    }
    
    private func processChildBirthdayStep(_ messageText: String) async {
        let currentChildIndex = UserDefaults.standard.integer(forKey: "tempCurrentChildIndex")
        let numberOfChildren = UserDefaults.standard.integer(forKey: "tempNumberOfChildren")
        
        // Parse and store birthday
        UserDefaults.standard.set(messageText, forKey: "tempChild\(currentChildIndex)Birthday")
        
        let nextChildIndex = currentChildIndex + 1
        
        if nextChildIndex < numberOfChildren {
            // More children to process
            UserDefaults.standard.set(nextChildIndex, forKey: "tempCurrentChildIndex")
            await MainActor.run {
                introStep = .childName
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "👶 What is your next child's first name?",
                    timestamp: Date()
                ))
            }
        } else {
            // Move to next step
            await MainActor.run {
                introStep = .state
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "🗺️ What state or country do you live in?",
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func processStateStep(_ messageText: String) async {
        UserDefaults.standard.set(messageText, forKey: "tempState")
        
        await MainActor.run {
            introStep = .conflictLevel
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "📊 On a scale of 1-10, how would you rate your day-to-day conflict level with your co-parent? (1 = very peaceful, 10 = very high conflict)",
                timestamp: Date()
            ))
        }
    }
    
    private func processParentingPlanStep(_ messageText: String) async {
        // This step is currently skipped in the optimized flow
        await MainActor.run {
            introStep = .conflictLevel
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "📊 On a scale of 1-10, how would you rate your day-to-day conflict level with your co-parent? (1 = very peaceful, 10 = very high conflict)",
                timestamp: Date()
            ))
        }
    }
    
    private func processConflictLevelStep(_ messageText: String) async {
        guard let level = Int(messageText), (1...10).contains(level) else {
            await MainActor.run {
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "Please enter a number between 1 and 10.",
                    timestamp: Date()
                ))
            }
            return
        }
        
        UserDefaults.standard.set(level, forKey: "tempConflictLevel")
        
        await MainActor.run {
            introStep = .decreeUpload
            chatManager.addMessage(ChatMessage(
                sender: "Gentler Coparent",
                text: "📎 Optional: Tap the paperclip icon to upload your divorce decree for enhanced personalization.\n\n⏭️ Or type **skip** if you prefer to continue without it.",
                timestamp: Date()
            ))
        }
    }
    
    private func processDecreeUploadStep(_ messageText: String) async {
        if messageText.lowercased().contains("skip") {
            await completeOnboarding()
        } else {
            await MainActor.run {
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "Please use the 📎 paperclip icon to upload your document, or type **skip** to continue.",
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func processSkipDecreeStep(_ messageText: String) async {
        await completeOnboarding()
    }
    
    private func completeOnboarding() async {
        // Create UserProfile from temp data
        let userFirstName = UserDefaults.standard.string(forKey: "tempUserFirstName") ?? ""
        let userLastName = UserDefaults.standard.string(forKey: "tempUserLastName") ?? ""
        let coparentFirstName = UserDefaults.standard.string(forKey: "tempCoparentFirstName") ?? ""
        let coparentLastName = UserDefaults.standard.string(forKey: "tempCoparentLastName") ?? ""
        let numberOfChildren = UserDefaults.standard.integer(forKey: "tempNumberOfChildren")
        let state = UserDefaults.standard.string(forKey: "tempState") ?? ""
        let conflictLevel = UserDefaults.standard.integer(forKey: "tempConflictLevel")
        
        var children: [UserProfile.Child] = []
        for i in 0..<numberOfChildren {
            let name = UserDefaults.standard.string(forKey: "tempChild\(i)Name") ?? ""
            let birthdayString = UserDefaults.standard.string(forKey: "tempChild\(i)Birthday") ?? ""
            
            // Parse birthday
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let birthday = dateFormatter.date(from: birthdayString) ?? Date()
            let components = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
            
            children.append(UserProfile.Child(
                firstName: name,
                lastName: userLastName,
                birthday: components,
                gender: "Rather not say"
            ))
        }
        
        let profile = UserProfile(
            userFirstName: userFirstName,
            userLastName: userLastName,
            coparentFirstName: coparentFirstName,
            coparentLastName: coparentLastName,
            children: children,
            stateOfResidence: state,
            country: "United States",
            conflictLevel: conflictLevel,
            possessionSchedule: nil,
            divorceDecreeURL: nil,
            divorceDecreeBookmark: nil,
            divorceDecreeText: nil,
            setupDate: Date()
        )
        
        // Save profile
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: "userProfile")
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            
            // Clean up temp data
            cleanupTempOnboardingData()
            
            // Start free trial for new users
            if enhancedSubscriptionManager.freeTrialStatus == .notStarted && !enhancedSubscriptionManager.hasActiveSubscription {
                enhancedSubscriptionManager.startFreeTrial()
            }

            await MainActor.run {
                introStep = .finalMessage
                showCompletionCelebration = true
                showOnboardingProgress = false
                
                let baseMessage = "🎉 **Profile Complete!** Gentler Coparent is now personalized for your family."
                let hasTrialOrSubscription = enhancedSubscriptionManager.freeTrialStatus == .notStarted || enhancedSubscriptionManager.hasActiveSubscription
                let trialMessage: String
                
                if hasTrialOrSubscription {
                    trialMessage = baseMessage + " Let's start having more peaceful conversations!"
                } else {
                    trialMessage = baseMessage + " You're also starting your 7-day free trial with unlimited access to all premium features. Let's start having more peaceful conversations!"
                }
                
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: trialMessage,
                    timestamp: Date()
                ))
            }
            
        } catch {
            await MainActor.run {
                chatManager.addMessage(ChatMessage(
                    sender: "Gentler Coparent",
                    text: "There was an error saving your profile. Please try again or contact support.",
                    timestamp: Date()
                ))
            }
        }
    }
    
    private func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        cleanupTempOnboardingData()
        
        introStep = .none
        showOnboardingProgress = false
        onboardingSkipped = true
        
        chatManager.addMessage(ChatMessage(
            sender: "Gentler Coparent",
            text: "You can complete your family profile anytime in Settings for more personalized guidance. How can I help you today?",
            timestamp: Date()
        ))
    }
    
    private func cleanupTempOnboardingData() {
        let keysToRemove = [
            "tempUserFirstName", "tempUserLastName",
            "tempCoparentFirstName", "tempCoparentLastName",
            "tempNumberOfChildren", "tempCurrentChildIndex",
            "tempState", "tempConflictLevel"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        // Remove temp child data
        for i in 0..<10 {
            UserDefaults.standard.removeObject(forKey: "tempChild\(i)Name")
            UserDefaults.standard.removeObject(forKey: "tempChild\(i)Birthday")
        }
    }
}

// Activity sheet for sharing text content
struct ActivitySheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Placeholder for Learning Resources View
struct LearningResourcesPlaceholder: View {
    @Binding var showLearningSection: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "book.circle")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "388083"))
                
                Text("Learning Resources")
                    .font(Font.custom("Avenir-Book", size: 24).weight(.bold))
                    .foregroundColor(Color(hex: "388083"))
                
                Text("Coming Soon")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                    .padding()
                
                Spacer()
            }
            .padding()
            .background(Color(hex: "BADFE7"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { 
                        showLearningSection = false
                        dismiss()
                    }) {
                        Text("Close")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }
        }
    }
}