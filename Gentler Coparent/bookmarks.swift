import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Bookmarks (modern list + reliable add/remove/persist via binding)
struct BookmarksView: View {
    @Binding var bookmarkedMessages: [ChatMessage]
    @State private var searchText = ""
    @State private var filter: BookmarkFilter = .all
    @State private var selectedMessage: ChatMessage?
    @State private var messageToShare: ChatMessage?
    
    enum BookmarkFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case replies = "Replies"
        case recent = "This Week"
        var id: String { rawValue }
    }
    
    private var filtered: [ChatMessage] {
        var list = bookmarkedMessages
        switch filter {
        case .all: break
        case .replies:
            list = list.filter { $0.sender == "Gentler Coparent" }
        case .recent:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            list = list.filter { $0.timestamp > weekAgo }
        }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.text.lowercased().contains(q) || $0.sender.lowercased().contains(q)
            }
        }
        return list.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        Group {
            if filtered.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(filtered) { message in
                        Button {
                            selectedMessage = message
                        } label: {
                            bookmarkRow(message)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(GCPTheme.cardFill)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                remove(message)
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                messageToShare = message
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(GCPTheme.primary)
                            
                            Button {
                                UIPasteboard.general.string = message.text
                                #if canImport(UIKit)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                #endif
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .tint(GCPTheme.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        let toRemove = indexSet.map { filtered[$0] }
                        for m in toRemove { remove(m) }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(GCPTheme.canvas.ignoresSafeArea())
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search bookmarks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(BookmarkFilter.allCases) { f in
                        Button {
                            filter = f
                        } label: {
                            HStack {
                                Text(f.rawValue)
                                if filter == f {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(GCPTheme.primary)
                }
            }
        }
        .toolbarBackground(GCPTheme.canvas, for: .navigationBar)
        .sheet(item: $selectedMessage) { message in
            BookmarkDetailSheet(
                message: message,
                onRemove: {
                    remove(message)
                    selectedMessage = nil
                },
                onShare: {
                    messageToShare = message
                }
            )
        }
        .sheet(item: $messageToShare) { message in
            #if canImport(UIKit)
            BookmarkActivityView(message: message)
            #endif
        }
    }
    
    private func bookmarkRow(_ message: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GCPTheme.primary)
                Text(message.sender)
                    .font(GCPTheme.bodyMedium(13))
                    .foregroundStyle(GCPTheme.primary)
                Spacer()
                Text(Self.relativeDate(message.timestamp))
                    .font(GCPTheme.caption(12))
                    .foregroundStyle(GCPTheme.primary.opacity(0.55))
            }
            Text(message.text.streamingMarkdownSafe())
                .font(GCPTheme.body(15))
                .foregroundStyle(Color.primary.opacity(0.85))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Bookmarks", systemImage: "bookmark")
        } description: {
            Text(searchText.isEmpty
                 ? "Tap the bookmark icon on any chat reply to save it here."
                 : "No bookmarks match “\(searchText)”.")
        }
        .foregroundStyle(GCPTheme.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func remove(_ message: ChatMessage) {
        bookmarkedMessages.removeAll { $0.id == message.id }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
    
    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Detail (chat-style card — not a flat monochrome wall of text)
private struct BookmarkDetailSheet: View {
    let message: ChatMessage
    let onRemove: () -> Void
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var copyMode: CopyMode = .full
    
    private enum CopyMode { case full, draft }
    
    private var isAssistant: Bool {
        message.sender == "Gentler Coparent"
    }
    
    private var draftOnly: String? {
        DraftMessageExtractor.extractDraftMessage(from: message.text)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meta header
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(isAssistant ? GCPTheme.mint : GCPTheme.primary.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: isAssistant ? "sparkles" : "person.fill")
                                .foregroundStyle(GCPTheme.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(message.sender)
                                .font(GCPTheme.title(17))
                                .foregroundStyle(GCPTheme.primary)
                            Text(message.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(GCPTheme.primary.opacity(0.45))
                    }
                    
                    // Main content bubble
                    VStack(alignment: .leading, spacing: 12) {
                        Text(message.text.attributedMarkdown())
                            .font(GCPTheme.body(16))
                            .foregroundStyle(Color.black.opacity(0.88))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineSpacing(3)
                    }
                    .padding(16)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 6,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .fill(isAssistant ? GCPTheme.assistantBubble : GCPTheme.primary.opacity(0.10))
                    )
                    .overlay(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 6,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                        .strokeBorder(isAssistant ? GCPTheme.assistantBubbleStroke : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    
                    // Optional draft callout
                    if let draft = draftOnly, !draft.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Send-ready draft", systemImage: "doc.text")
                                .font(GCPTheme.bodyMedium(13))
                                .foregroundStyle(GCPTheme.primary)
                            Text(draft)
                                .font(GCPTheme.body(15))
                                .foregroundStyle(GCPTheme.primary.opacity(0.9))
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(GCPTheme.cream)
                                )
                            Button {
                                UIPasteboard.general.string = draft
                                copied = true
                                copyMode = .draft
                                #if canImport(UIKit)
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                #endif
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                            } label: {
                                Label("Copy draft only", systemImage: "doc.on.doc")
                                    .font(GCPTheme.bodyMedium(14))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(GCPTheme.primary))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(GCPTheme.cardFill)
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        )
                    }
                    
                    if copied {
                        Text(copyMode == .draft ? "Draft copied" : "Full reply copied")
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
            .background(GCPTheme.cream.ignoresSafeArea())
            .navigationTitle("Saved reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .font(GCPTheme.bodyMedium(16))
                        .foregroundStyle(GCPTheme.primary)
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = message.text
                        copied = true
                        copyMode = .full
                        #if canImport(UIKit)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    } label: {
                        Image(systemName: copied && copyMode == .full ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(GCPTheme.primary)
                    }
                    .accessibilityLabel("Copy full reply")
                    
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(GCPTheme.primary)
                    }
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "bookmark.slash")
                    }
                }
            }
            .toolbarBackground(GCPTheme.cream, for: .navigationBar)
        }
    }
}

#if canImport(UIKit)
struct BookmarkActivityView: UIViewControllerRepresentable {
    let message: ChatMessage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let formattedText = "[\(formatter.string(from: message.timestamp))] \(message.sender):\n\n\(message.text)"
        return UIActivityViewController(activityItems: [formattedText], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        BookmarksView(bookmarkedMessages: .constant([
            ChatMessage(sender: "Gentler Coparent", text: "Confirming pickup Friday at 5:00 PM at school.", timestamp: Date())
        ]))
    }
}
