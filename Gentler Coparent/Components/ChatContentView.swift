import SwiftUI

// MARK: - Enhanced Chat Content View Component
@available(iOS 17.0, *)
struct ChatContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var shouldUseIPadLayout: Bool {
        isIPad && horizontalSizeClass == .regular
    }
    let messages: [ChatMessage]
    let isLoading: Bool
    let isNetworkAvailable: Bool
    let isScrolling: Bool
    @EnvironmentObject var audioManager: AudioManager
    let bookmarkedMessages: [ChatMessage]
    
    let onBookmark: (ChatMessage) -> Void
    let onShare: (ChatMessage) -> Void
    let onPromptHelper: (String) -> Void // Add callback for prompt helpers
    
    @State private var lastStreamingMessageText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var showScrollToBottomButton = false
    @State private var isUserScrolling = false
    @State private var lastMessageCount = 0
    
    // Helper to break up complex expression
    private func isMessageBookmarked(_ message: ChatMessage) -> Bool {
        return bookmarkedMessages.contains(where: { $0.id == message.id })
    }
    
    // Determine if we should show prompt starters
    private var shouldShowPromptStarters: Bool {
        // Never show if loading
        if isLoading { return false }
        
        // Always show if completely empty
        if messages.isEmpty { return true }
        
        // Show if conversation only has initial AI greeting message(s) and no user messages
        let userMessages = messages.filter { $0.sender == "You" }
        let aiMessages = messages.filter { $0.sender == "Gentler Coparent" }
        
        // Show if: no user messages AND only 1-2 AI messages (initial greeting(s))
        return userMessages.isEmpty && aiMessages.count <= 2 && messages.count <= 2
    }
    
    private var chatBackgroundGradient: some View {
        // Cream paper only for the message card (parent provides blue frame)
        GCPTheme.chatCanvas
    }
    
    // Separate message row — no drawingGroup (that rasterizes every stream frame)
    private func messageRowView(_ item: ChatMessage) -> some View {
        MessageView(
            item: item,
            isBookmarked: isMessageBookmarked(item),
            onBookmark: { onBookmark(item) },
            onShare: { onShare(item) }
        )
        .id(item.id)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    var body: some View {
        chatContentBody
    }
    
    private var chatContentBody: some View {
        ScrollViewReader { scrollView in
            ZStack(alignment: .bottomTrailing) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: shouldUseIPadLayout ? .center : .leading, spacing: shouldUseIPadLayout ? 16 : 12) {
                        if shouldShowPromptStarters {
                            promptStartersView
                        }
                        
                        ForEach(messages) { item in
                            // Skip empty non-streaming ghosts
                            if !(item.sender == "Gentler Coparent" && item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !item.isStreaming) {
                                messageRowView(item)
                            }
                        }
                        
                        // Loading indicator only when no streaming assistant row is already showing
                        if isLoading {
                            let hasStreamingAssistant = messages.contains {
                                $0.sender == "Gentler Coparent" && $0.isStreaming
                            }
                            if !hasStreamingAssistant {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("loading")
                                .transition(.opacity)
                            }
                        }
                        
                        if !isNetworkAvailable {
                            Text("Network connection lost. Retrying…")
                                .font(GCPTheme.caption(13))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .id("networkStatus")
                        }
                        
                        Spacer(minLength: isLoading ? 48 : 24)
                            .id("chat-bottom-anchor")
                    }
                    .padding(.horizontal, shouldUseIPadLayout ? 32 : 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                })
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    // Show scroll to bottom button when user scrolls up
                    let threshold: CGFloat = -100
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showScrollToBottomButton = scrollOffset < threshold && !isUserScrolling
                    }
                }
                
                // Scroll to bottom button
                if showScrollToBottomButton {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            if let lastMessage = messages.last {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            } else if isLoading {
                                scrollView.scrollTo("loading", anchor: .bottom)
                            }
                        }
                        showScrollToBottomButton = false
                    }) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                // iOS 18: Dynamic color mixing based on scroll state
                                Group {
                                    if #available(iOS 18.0, *) {
                                        Color(hex: "388083").mix(
                                            with: Color(hex: "388083").opacity(0.8), 
                                            by: showScrollToBottomButton ? 0.2 : 0.0
                                        )
                                    } else {
                                        // Fallback for iOS 17
                                        Color(hex: "388083").opacity(showScrollToBottomButton ? 0.8 : 1.0)
                                    }
                                }
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
                }
            }
            .frame(maxHeight: .infinity)
            .background(chatBackgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous))
            .simultaneousGesture(
                DragGesture(minimumDistance: 3) // More responsive threshold
                    .onChanged { value in
                        // Immediately mark as user scrolling for better performance
                        if !isUserScrolling {
                            isUserScrolling = true
                        }
                        
                        // Professional keyboard dismissal logic (like iMessage/ChatGPT)
                        let isDownwardSwipe = value.translation.height > 25
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        let hasGoodVelocity = velocity > 50
                        let isFastEnough = hasGoodVelocity || abs(value.translation.height) > 60
                        
                        if isDownwardSwipe && isFastEnough {
                            // Immediate, smooth keyboard dismissal like pro apps
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                    .onEnded { value in
                        // Professional timing for scroll state reset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isUserScrolling = false
                        }
                        
                        // Final velocity-based keyboard dismiss check
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        let isSignificantDownward = value.translation.height > 80
                        let isFastDownward = velocity > 100 && value.translation.height > 30
                        
                        if isSignificantDownward || isFastDownward {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
            )
            // Additional tap gesture for easy keyboard dismiss (like iMessage)
            .onTapGesture {
                let _ = withAnimation(.easeOut(duration: 0.25)) {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .onChange(of: messages.count) {
                // Professional auto-scroll behavior with optimized performance
                let isNewMessage = messages.count > lastMessageCount
                lastMessageCount = messages.count
                
                if isNewMessage && !isUserScrolling {
                    // Ultra-smooth animation matching professional chat apps
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85)) {
                        if let lastMessage = messages.last {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            // Auto-scroll when prompt starters disappear to ensure proper message visibility
            .onChange(of: shouldShowPromptStarters) { _, showingStarters in
                if !showingStarters && !messages.isEmpty && !isUserScrolling {
                    // Smooth scroll to bottom when prompt starters disappear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.9)) {
                            if let lastMessage = messages.last {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .onChange(of: isLoading) {
                if isLoading && !isUserScrolling {
                    // Immediate, smooth scroll to loading indicator
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.9)) {
                        scrollView.scrollTo("loading", anchor: .bottom)
                    }
                }
            }
            // Throttled auto-scroll during typewriter (scroll every ~48 chars, not every word)
            .onChange(of: messages.last?.text ?? "") { _, newText in
                guard let lastMessage = messages.last, lastMessage.isStreaming else { return }
                let delta = abs(newText.count - lastStreamingMessageText.count)
                guard delta >= 40 || newText.count < lastStreamingMessageText.count else { return }
                lastStreamingMessageText = newText
                if !isUserScrolling && !isScrolling {
                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    private var promptStartersView: some View {
        VStack(spacing: GCPTheme.spaceL) {
            Spacer(minLength: 20)
            
            VStack(spacing: 6) {
                Text("What do you need help with?")
                    .font(GCPTheme.title(20))
                    .foregroundStyle(GCPTheme.primary)
                    .multilineTextAlignment(.center)
                Text("Pick a starter or type your own message below.")
                    .font(GCPTheme.caption(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(GCPChatPrompts.starters) { starter in
                    Button {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        // Pass starter id so ContentView can resolve canned replies
                        onPromptHelper(starter.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: starter.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(GCPTheme.primary)
                            Text(starter.title)
                                .font(GCPTheme.bodyMedium(14))
                                .foregroundStyle(GCPTheme.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(starter.subtitle)
                                .font(GCPTheme.caption(11))
                                .foregroundStyle(GCPTheme.primary.opacity(0.55))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                        .background(
                            RoundedRectangle(cornerRadius: GCPTheme.radiusChip, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GCPTheme.radiusChip, style: .continuous)
                                .strokeBorder(GCPTheme.primary.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, shouldUseIPadLayout ? 40 : 4)
            
            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chat Area View with New Chat Button
struct ChatAreaView: View {
    let messages: [ChatMessage]
    let isLoading: Bool
    let isNetworkAvailable: Bool
    let isScrolling: Bool
    let bookmarkedMessages: [ChatMessage]
    
    let onBookmark: (ChatMessage) -> Void
    let onShare: (ChatMessage) -> Void
    let onNewChat: () -> Void
    let onPromptHelper: (String) -> Void
    
    @State private var showNewChatFeedback = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ChatContentView(
                messages: messages,
                isLoading: isLoading,
                isNetworkAvailable: isNetworkAvailable,
                isScrolling: isScrolling,
                bookmarkedMessages: bookmarkedMessages,
                onBookmark: onBookmark,
                onShare: onShare,
                onPromptHelper: onPromptHelper
            )
            
            // New chat FAB
            Button {
                onNewChat()
                showNewChatPopup()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(GCPTheme.primary, in: Circle())
                    .shadow(color: GCPTheme.primary.opacity(0.35), radius: 10, y: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 12)
            .opacity(isScrolling ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.25), value: isScrolling)
            .accessibilityLabel("New chat")
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .overlay(
            // New Chat feedback popup
            VStack {
                Spacer()
                if showNewChatFeedback {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("New chat started!")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                        removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 1.1))
                    ))
                }
            }
            .allowsHitTesting(false)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showNewChatFeedback)
        )
    }
    
    private func showNewChatPopup() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showNewChatFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showNewChatFeedback = false
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Extensions for iOS 18 Compatibility
extension View {
    @ViewBuilder
    func conditionalMatchedTransition(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}

