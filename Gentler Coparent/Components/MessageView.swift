import SwiftUI
import UIKit

// MARK: - Smart Draft Message Extractor
class DraftMessageExtractor {
    static func extractDraftMessage(from fullText: String) -> String? {
        let text = fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Pattern 1: Look for quoted messages (most common for drafts)
        let quotedPattern = #""([^"]*(?:"[^"]*"[^"]*)*)""#
        if let quotedMatch = text.range(of: quotedPattern, options: .regularExpression) {
            let quoted = String(text[quotedMatch])
            let cleaned = quoted.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if !cleaned.isEmpty && cleaned.count > 10 { // Reasonable draft length
                return stripMarkdown(from: cleaned)
            }
        }
        
        // Pattern 2: Look for three-dash delimited messages (highest priority)
        let threeDashPattern = #"---\s*\n([\s\S]*?)\n\s*---"#
        if let match = text.range(of: threeDashPattern, options: .regularExpression) {
            let nsRange = NSRange(match, in: text)
            if let regex = try? NSRegularExpression(pattern: threeDashPattern, options: [.dotMatchesLineSeparators]) {
                if let result = regex.firstMatch(in: text, options: [], range: nsRange) {
                    if result.numberOfRanges > 1 {
                        let range = result.range(at: 1)
                        if let swiftRange = Range(range, in: text) {
                            let extracted = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            if !extracted.isEmpty && extracted.count > 10 {
                                return stripMarkdown(from: extracted)
                            }
                        }
                    }
                }
            }
        }
        
        // Pattern 3: Look for draft indicators
        let draftPatterns = [
            #"(?i)(?:draft message|suggested response|you could say|try saying|here's a response):\s*\n\n?(.+?)(?:\n\n|\n(?=[A-Z])|$)"#,
            #"(?i)(?:draft|response):\s*\n(.+?)(?:\n\n|\n(?=[A-Z])|$)"#,
            #"(?i)(?:try this|consider saying):\s*\n(.+?)(?:\n\n|\n(?=[A-Z])|$)"#
        ]
        
        for pattern in draftPatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let nsRange = NSRange(match, in: text)
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) {
                    if let result = regex.firstMatch(in: text, options: [], range: nsRange) {
                        if result.numberOfRanges > 1 {
                            let range = result.range(at: 1)
                            if let swiftRange = Range(range, in: text) {
                                let extracted = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                if !extracted.isEmpty && extracted.count > 10 {
                                    return stripMarkdown(from: extracted)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Pattern 4: Look for messages that start with common greeting patterns
        let messageStartPatterns = [
            #"^(Hi [^,\n]+,[\s\S]*?)(?:\n\n(?:This|I hope|Let me know)|$)"#,
            #"^(Hello [^,\n]+,[\s\S]*?)(?:\n\n(?:This|I hope|Let me know)|$)"#,
            #"^(Hey [^,\n]+,[\s\S]*?)(?:\n\n(?:This|I hope|Let me know)|$)"#,
            #"^([^.!?]+(?:[.!?]|\n)(?:[^.!?\n]*[.!?\n])*?)(?:\n\n|\n(?=This |I hope |Let me |Remember |Consider ))"#
        ]
        
        for pattern in messageStartPatterns {
            if let match = text.range(of: pattern, options: .regularExpression) {
                let nsRange = NSRange(match, in: text)
                if let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .dotMatchesLineSeparators]) {
                    if let result = regex.firstMatch(in: text, options: [], range: nsRange) {
                        if result.numberOfRanges > 1 {
                            let range = result.range(at: 1)
                            if let swiftRange = Range(range, in: text) {
                                let extracted = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                                if !extracted.isEmpty && extracted.count > 20 {
                                    return stripMarkdown(from: extracted)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return nil // No draft found
    }
    
    static func copyToClipboard(_ text: String) {
        let plainText = stripMarkdown(from: text)
        UIPasteboard.general.string = plainText
    }
    
    // Strip common markdown formatting to get plain text
    private static func stripMarkdown(from text: String) -> String {
        var plainText = text
        
        // Remove bold/italic markdown (**text**, *text*)
        plainText = plainText.replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: #"\*([^*]+)\*"#, with: "$1", options: .regularExpression)
        
        // Process line-by-line for patterns that need line anchors
        let lines = plainText.components(separatedBy: .newlines)
        let processedLines = lines.map { line in
            var processedLine = line
            
            // Remove headers (# ## ### etc.)
            processedLine = processedLine.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression)
            
            // Remove bullet points (- * +)
            processedLine = processedLine.replacingOccurrences(of: #"^[\s]*[-*+]\s+"#, with: "", options: .regularExpression)
            
            // Remove numbered lists (1. 2. etc.)
            processedLine = processedLine.replacingOccurrences(of: #"^[\s]*\d+\.\s+"#, with: "", options: .regularExpression)
            
            // Remove blockquotes (> text)
            processedLine = processedLine.replacingOccurrences(of: #"^>\s+"#, with: "", options: .regularExpression)
            
            // Remove horizontal rules (--- or ***)
            if processedLine.range(of: #"^[-*]{3,}$"#, options: .regularExpression) != nil {
                return ""
            }
            
            return processedLine
        }
        plainText = processedLines.joined(separator: "\n")
        
        // Remove links [text](url) -> text
        plainText = plainText.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        
        // Remove inline code (`code`)
        plainText = plainText.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Remove code blocks (```code```)
        plainText = plainText.replacingOccurrences(of: #"```[^`]*```"#, with: "", options: .regularExpression)
        
        // Clean up multiple newlines and trim
        plainText = plainText.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        plainText = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return plainText
    }
    
    static func hasCleanDraft(from text: String) -> Bool {
        return extractDraftMessage(from: text) != nil
    }
}

// MARK: - Markdown Helper
extension String {
    /// Display text while typewriting — hides raw markdown glyphs (`**`, `#`, etc.).
    /// Keeps readable content; full styled markdown is applied when streaming ends.
    func streamingMarkdownSafe() -> String {
        var t = self
        
        // Drop incomplete trailing open markers so partial `**bold` never flashes stars
        t = t.replacingOccurrences(of: #"(\*\*|__|```|`|#{1,6}\s*|\*|_)+\s*$"#, with: "", options: .regularExpression)
        
        // Closed fenced code / inline code → content only
        t = t.replacingOccurrences(of: #"```[\w]*\n?([\s\S]*?)```"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        
        // Bold / italic / underline pairs → plain content
        t = t.replacingOccurrences(of: #"\*\*([^*]+)\*\*"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"__([^_]+)__"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<![\w*])\*([^*\n]+)\*(?![\w*])"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<![\w_])_([^_\n]+)_(?![\w_])"#, with: "$1", options: .regularExpression)
        
        // Unclosed emphasis still in-flight (e.g. **hello)
        t = t.replacingOccurrences(of: #"\*\*([^*]*)$"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"__([^_]*)$"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?<!\*)\*([^*\n]*)$"#, with: "$1", options: .regularExpression)
        t = t.replacingOccurrences(of: #"`([^`]*)$"#, with: "$1", options: .regularExpression)
        
        // Headers, bullets, blockquotes, horizontal rules
        t = t.replacingOccurrences(of: #"(?m)^#{1,6}\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^>\s?"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^[\s]*[-*+]\s+"#, with: "• ", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^[\s]*\d+\.\s+"#, with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: #"(?m)^[-*_]{3,}\s*$"#, with: "", options: .regularExpression)
        
        // Links [label](url) → label
        t = t.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]*\)?"#, with: "$1", options: .regularExpression)
        
        // Any leftover markdown control chars users shouldn't see mid-stream
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "__", with: "")
        t = t.replacingOccurrences(of: "```", with: "")
        t = t.replacingOccurrences(of: "`", with: "")
        
        // Collapse excess blank lines from stripped headers
        t = t.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        return t
    }
    
    func attributedMarkdown() -> AttributedString {
        // Manual markdown parsing for better control
        let text = self
        var attributedString = AttributedString()
        
        // Process text character by character for basic markdown
        var currentText = ""
        var i = text.startIndex
        
        while i < text.endIndex {
            let char = text[i]
            
            // Handle headers (### Header, ## Header, # Header)
            if char == "#" && (i == text.startIndex || text[text.index(before: i)] == "\n") {
                var headerLevel = 1
                var headerStart = text.index(after: i)
                
                // Count additional # characters
                while headerStart < text.endIndex && text[headerStart] == "#" && headerLevel < 6 {
                    headerLevel += 1
                    headerStart = text.index(after: headerStart)
                }
                
                // Skip space after ###
                if headerStart < text.endIndex && text[headerStart] == " " {
                    headerStart = text.index(after: headerStart)
                }
                
                // Find end of line
                var headerEnd = headerStart
                while headerEnd < text.endIndex && text[headerEnd] != "\n" {
                    headerEnd = text.index(after: headerEnd)
                }
                
                // Add current text if any
                if !currentText.isEmpty {
                    var normalText = AttributedString(currentText)
                    normalText.font = .custom("Avenir-Book", size: 16)
                    attributedString.append(normalText)
                    currentText = ""
                }
                
                // Add header with appropriate styling
                let headerText = String(text[headerStart..<headerEnd])
                var headerAttr = AttributedString(headerText)
                switch headerLevel {
                case 1:
                    headerAttr.font = .custom("Avenir-Heavy", size: 20)
                case 2:
                    headerAttr.font = .custom("Avenir-Heavy", size: 18)
                case 3:
                    headerAttr.font = .custom("Avenir-Medium", size: 17)
                default:
                    headerAttr.font = .custom("Avenir-Medium", size: 16)
                }
                attributedString.append(headerAttr)
                
                // Add newline if there was one
                if headerEnd < text.endIndex && text[headerEnd] == "\n" {
                    attributedString.append(AttributedString("\n"))
                    i = text.index(after: headerEnd)
                } else {
                    i = headerEnd
                }
                continue
            }
            
            if char == "*" && i != text.endIndex {
                // Check for bold (**text**)
                let nextIndex = text.index(after: i)
                if nextIndex < text.endIndex && text[nextIndex] == "*" {
                    // Add current text if any
                    if !currentText.isEmpty {
                        var normalText = AttributedString(currentText)
                        normalText.font = .custom("Avenir-Book", size: 16)
                        attributedString.append(normalText)
                        currentText = ""
                    }
                    
                    // Find closing **
                    let startBold = text.index(nextIndex, offsetBy: 1)
                    if let endBold = text.range(of: "**", range: startBold..<text.endIndex) {
                        let boldText = String(text[startBold..<endBold.lowerBound])
                        var boldAttr = AttributedString(boldText)
                        boldAttr.font = .custom("Avenir-Heavy", size: 16)
                        attributedString.append(boldAttr)
                        i = endBold.upperBound
                        continue
                    }
                }
                // Check for italic (*text*)
                else {
                    // Add current text if any
                    if !currentText.isEmpty {
                        var normalText = AttributedString(currentText)
                        normalText.font = .custom("Avenir-Book", size: 16)
                        attributedString.append(normalText)
                        currentText = ""
                    }
                    
                    // Find closing *
                    let startItalic = text.index(after: i)
                    if let endItalic = text.range(of: "*", range: startItalic..<text.endIndex) {
                        let italicText = String(text[startItalic..<endItalic.lowerBound])
                        var italicAttr = AttributedString(italicText)
                        italicAttr.font = .custom("Avenir-BookOblique", size: 16)
                        attributedString.append(italicAttr)
                        i = endItalic.upperBound
                        continue
                    }
                }
            }
            
            currentText.append(char)
            i = text.index(after: i)
        }
        
        // Add remaining text
        if !currentText.isEmpty {
            var normalText = AttributedString(currentText)
            normalText.font = .custom("Avenir-Book", size: 16)
            attributedString.append(normalText)
        }
        
        // Return result or fallback to plain text
        if attributedString.characters.count > 0 {
            return attributedString
        } else {
            var fallbackString = AttributedString(self)
            fallbackString.font = .custom("Avenir-Book", size: 16)
            return fallbackString
        }
    }
}

// MARK: - MessageView
struct MessageView: View {
    let item: ChatMessage
    @EnvironmentObject var audioManager: AudioManager
    let isBookmarked: Bool
    let onBookmark: () -> Void
    let onShare: () -> Void
    
    @State private var showCopyFeedback = false
    @State private var copyFeedbackText = ""
    @State private var showBookmarkFeedback = false
    @State private var bookmarkFeedbackText = ""
    @State private var lastCopyTime: Date = Date.distantPast
    @State private var lastBookmarkTime: Date = Date.distantPast

    private var hasVisibleText: Bool {
        !item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Actions only after we have real content (never on empty/streaming placeholder).
    private var showActionBar: Bool {
        hasVisibleText && !item.isStreaming
    }
    
    private var bubbleMaxWidth: CGFloat {
        #if canImport(UIKit)
        return min(UIScreen.main.bounds.width * 0.82, 560)
        #else
        return 520
        #endif
    }
    
    var body: some View {
        Group {
            if item.sender == "Gentler Coparent" {
                // Empty streaming placeholder: typing-style pill only (no ghost bubble + actions)
                if !hasVisibleText && item.isStreaming {
                    HStack {
                        TypingIndicator()
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if hasVisibleText {
                    HStack(alignment: .bottom, spacing: 8) {
                        assistantBubble
                            .contextMenu {
                                if showActionBar {
                                    if DraftMessageExtractor.hasCleanDraft(from: item.text) {
                                        Button(action: { copyDraftMessage() }) {
                                            Label("Copy Draft Only", systemImage: "doc.on.doc.fill")
                                        }
                                    }
                                    Button(action: { copyFullMessage() }) {
                                        Label("Copy Full Response", systemImage: "doc.on.clipboard")
                                    }
                                    Button(action: { onShare() }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    Button(action: {
                                        onBookmark()
                                        audioManager.triggerHapticFeedback(.success)
                                    }) {
                                        Label(isBookmarked ? "Remove Bookmark" : "Bookmark",
                                              systemImage: isBookmarked ? "bookmark.fill" : "bookmark")
                                    }
                                }
                            }
                        
                        if showActionBar {
                            actionBar
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // Completely empty non-streaming assistant rows: render nothing
            } else if item.sender == "You" {
                HStack {
                    Spacer(minLength: 40)
                    Text(item.text)
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.userText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 18,
                                bottomLeadingRadius: 18,
                                bottomTrailingRadius: 6,
                                topTrailingRadius: 18,
                                style: .continuous
                            )
                            .fill(GCPTheme.userBubble)
                            .shadow(color: GCPTheme.primary.opacity(0.18), radius: 6, y: 2)
                        )
                        .frame(maxWidth: bubbleMaxWidth, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(item.text)
                    .font(GCPTheme.caption(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .overlay(alignment: .center) {
            VStack(spacing: 8) {
                if showCopyFeedback {
                    feedbackToast(icon: "checkmark.circle.fill", iconColor: .green, text: copyFeedbackText)
                }
                if showBookmarkFeedback {
                    feedbackToast(icon: "bookmark.circle.fill", iconColor: .orange, text: bookmarkFeedbackText)
                }
            }
            .allowsHitTesting(false)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCopyFeedback)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showBookmarkFeedback)
        }
    }
    
    private var assistantBubble: some View {
        HStack(alignment: .bottom, spacing: 2) {
            // Streaming: hide raw markdown glyphs; finished: full styled markdown.
            Group {
                if item.isStreaming {
                    Text(item.text.streamingMarkdownSafe())
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.assistantText)
                } else {
                    Text(item.text.attributedMarkdown())
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.assistantText)
                }
            }
            
            if item.isStreaming {
                TimelineView(.animation(minimumInterval: 0.45, paused: false)) { context in
                    let on = Int(context.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                    Text("▍")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(on ? 0.85 : 0.15))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 18,
                topTrailingRadius: 18,
                style: .continuous
            )
            .fill(GCPTheme.assistantBubble)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 6,
                bottomTrailingRadius: 18,
                topTrailingRadius: 18,
                style: .continuous
            )
            .strokeBorder(GCPTheme.assistantBubbleStroke, lineWidth: 1)
        )
        .frame(maxWidth: bubbleMaxWidth, alignment: .leading)
    }
    
    private var actionBar: some View {
        HStack(spacing: 6) {
            actionButton(
                systemName: DraftMessageExtractor.hasCleanDraft(from: item.text) ? "doc.text" : "doc.on.doc",
                label: "Copy"
            ) {
                if DraftMessageExtractor.hasCleanDraft(from: item.text) {
                    copyDraftMessage()
                } else {
                    copyFullMessage()
                }
            }
            
            actionButton(systemName: isBookmarked ? "bookmark.fill" : "bookmark", label: "Bookmark") {
                let now = Date()
                if now.timeIntervalSince(lastBookmarkTime) < 0.4 { return }
                lastBookmarkTime = now
                // Feedback uses pre-toggle state (onBookmark toggles add/remove)
                let removing = isBookmarked
                onBookmark()
                audioManager.triggerHapticFeedback(.success)
                showBookmarkFeedback(message: removing ? "Removed from bookmarks" : "Saved to bookmarks")
            }
            
            actionButton(systemName: "square.and.arrow.up", label: "Share") {
                audioManager.triggerHapticFeedback(.success)
                onShare()
            }
        }
        .padding(.bottom, 2)
    }
    
    private func actionButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(GCPTheme.primary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.95)))
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
    
    // MARK: - Helper Functions
    private func copyDraftMessage() {
        // Debounce: prevent multiple rapid calls
        let now = Date()
        if now.timeIntervalSince(lastCopyTime) < 0.5 {
            return
        }
        lastCopyTime = now
        
        if let draftText = DraftMessageExtractor.extractDraftMessage(from: item.text) {
            DraftMessageExtractor.copyToClipboard(draftText)
            showCopyFeedback(message: "Draft copied!")
            audioManager.triggerHapticFeedback(.success)
            print("✅ Draft message copied: \(draftText.prefix(50))...")
        } else {
            // Fallback to full message if no draft detected
            copyFullMessage()
        }
    }
    
    private func copyFullMessage() {
        // Debounce: prevent multiple rapid calls
        let now = Date()
        if now.timeIntervalSince(lastCopyTime) < 0.5 {
            return
        }
        lastCopyTime = now
        
        DraftMessageExtractor.copyToClipboard(item.text)
        showCopyFeedback(message: "Message copied!")
        audioManager.triggerHapticFeedback(.success)
        print("📋 Full message copied to clipboard")
    }
    
    private func showCopyFeedback(message: String) {
        copyFeedbackText = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showCopyFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showCopyFeedback = false
            }
        }
    }
    
    private func showBookmarkFeedback(message: String) {
        bookmarkFeedbackText = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showBookmarkFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                showBookmarkFeedback = false
            }
        }
    }
    
    // MARK: - Toast Helper
    @ViewBuilder
    private func feedbackToast(icon: String, iconColor: Color, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
            Text(text)
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
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
    }
}