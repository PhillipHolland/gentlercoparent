import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum HistoryViewType: String, CaseIterable {
    case all = "All"
    case important = "Important"
    case recent = "This Week"
    case thisMonth = "This Month"
}

// Conversation grouping for better organization
struct ConversationGroup: Identifiable {
    let id = UUID()
    let title: String
    let conversations: [ChatConversation]
    let date: Date
    
    static func groupConversations(_ conversations: [ChatConversation]) -> [ConversationGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let thisWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        let thisMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        var groups: [ConversationGroup] = []
        
        // Group by time periods
        let todayConversations = conversations.filter { calendar.isDate($0.timestamp, inSameDayAs: now) }
        let yesterdayConversations = conversations.filter { calendar.isDate($0.timestamp, inSameDayAs: yesterday) }
        let thisWeekConversations = conversations.filter { 
            $0.timestamp >= thisWeek && $0.timestamp < yesterday && !calendar.isDate($0.timestamp, inSameDayAs: yesterday)
        }
        let thisMonthConversations = conversations.filter { 
            $0.timestamp >= thisMonth && $0.timestamp < thisWeek
        }
        let olderConversations = conversations.filter { $0.timestamp < thisMonth }
        
        if !todayConversations.isEmpty {
            groups.append(ConversationGroup(title: "Today", conversations: todayConversations, date: today))
        }
        if !yesterdayConversations.isEmpty {
            groups.append(ConversationGroup(title: "Yesterday", conversations: yesterdayConversations, date: yesterday))
        }
        if !thisWeekConversations.isEmpty {
            groups.append(ConversationGroup(title: "This Week", conversations: thisWeekConversations, date: thisWeek))
        }
        if !thisMonthConversations.isEmpty {
            groups.append(ConversationGroup(title: "This Month", conversations: thisMonthConversations, date: thisMonth))
        }
        if !olderConversations.isEmpty {
            groups.append(ConversationGroup(title: "Older", conversations: olderConversations, date: thisMonth))
        }
        
        return groups
    }
}

// Moved ActivityView above MenuView to ensure it’s in scope
#if canImport(UIKit)
struct ActivityView: UIViewControllerRepresentable {
    let conversation: ChatConversation

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        var formattedText = "Conversation: \(conversation.title ?? "Untitled") (\(formatter.string(from: conversation.timestamp)))\n\n"
        for (index, message) in conversation.messages.enumerated() {
            formattedText += "[\(formatter.string(from: message.timestamp))] \(message.sender): \(message.text)\n"
            if index < conversation.messages.count - 1 {
                formattedText += "\n"
            }
        }
        
        print("ActivityView presenting with content:\n\(formattedText)")
        let controller = UIActivityViewController(activityItems: [formattedText], applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
#else
struct ActivityView: View {
    let conversation: ChatConversation

    var body: some View {
        Text("Sharing is not supported on this platform.")
            .foregroundColor(.gray)
    }
}
#endif

struct MenuView: View {
    let chatManager: ChatManager
    @Binding var message: String
    @Binding var showMenu: Bool
    let onSelectConversation: (UUID) -> Void
    @State private var selectedView: HistoryViewType = .all
    @State private var searchText = ""
    @State private var conversationToShare: ChatConversation?
    @State private var expandedGroups: Set<UUID> = []

    private var displayedHistory: [ChatConversation] {
        let calendar = Calendar.current
        let now = Date()
        
        var filtered = chatManager.chatHistory
        
        // Apply view filter
        switch selectedView {
        case .all:
            break // Show all
        case .important:
            filtered = filtered.filter { $0.isStarred }
        case .recent:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filtered = filtered.filter { $0.timestamp >= oneWeekAgo }
        case .thisMonth:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            filtered = filtered.filter { $0.timestamp >= oneMonthAgo }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { conversation in
                return conversation.title?.lowercased().contains(searchLower) ?? false ||
                       conversation.messages.last?.text.lowercased().contains(searchLower) ?? false ||
                       conversation.messages.contains { $0.text.lowercased().contains(searchLower) }
            }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    private var conversationGroups: [ConversationGroup] {
        return ConversationGroup.groupConversations(displayedHistory)
    }

    // Add the haptic feedback function
    func triggerHapticFeedback() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    var body: some View {
        Group {
            if conversationGroups.isEmpty {
                ContentUnavailableView {
                    Label("No Conversations", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text(searchText.isEmpty
                         ? "Your chat history will show up here."
                         : "No conversations match your search.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(conversationGroups) { group in
                        Section {
                            ForEach(group.conversations) { conversation in
                                ConversationRow(
                                    conversation: conversation,
                                    onTap: {
                                        onSelectConversation(conversation.id)
                                        showMenu = false
                                    },
                                    onToggleStar: {
                                        chatManager.toggleStar(for: conversation.id)
                                        triggerHapticFeedback()
                                    },
                                    onDelete: {
                                        chatManager.deleteConversation(id: conversation.id)
                                    },
                                    onShare: {
                                        conversationToShare = conversation
                                    }
                                )
                                .listRowBackground(GCPTheme.cardFill)
                            }
                        } header: {
                            Text(group.title)
                                .font(GCPTheme.bodyMedium(13))
                                .foregroundStyle(GCPTheme.primary.opacity(0.7))
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(GCPTheme.canvas.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search conversations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(HistoryViewType.allCases, id: \.self) { viewType in
                        Button {
                            selectedView = viewType
                        } label: {
                            HStack {
                                Text(viewType.rawValue)
                                if selectedView == viewType {
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
        .sheet(item: $conversationToShare) { conversation in
            #if canImport(UIKit)
            ActivityView(conversation: conversation)
            #endif
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Enhanced ConversationRow component
struct ConversationRow: View {
    let conversation: ChatConversation
    let onTap: () -> Void
    let onToggleStar: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Star button
            Button(action: onToggleStar) {
                Image(systemName: conversation.isStarred ? "star.fill" : "star")
                    .foregroundColor(conversation.isStarred ? Color(hex: "388083") : .gray)
                    .font(.system(size: 18))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(conversation.title ?? "Untitled")
                        .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(relativeTimeString(from: conversation.timestamp))
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                }
                
                HStack {
                    Text(conversation.messages.last?.text.prefix(40) ?? "No messages")
                        .font(Font.custom("Avenir-Book", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Message count indicator
                    if conversation.messages.count > 1 {
                        Text("\(conversation.messages.count)")
                            .font(Font.custom("Avenir-Book", size: 10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "388083").opacity(0.7))
                            .cornerRadius(8)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "388083").opacity(0.3))
                .font(.system(size: 12))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .font(Font.custom("Avenir-Book", size: 16))
            }
            .tint(.red)
        }
        .swipeActions(edge: .leading) {
            Button(action: onShare) {
                Label("Export", systemImage: "square.and.arrow.up")
                    .font(Font.custom("Avenir-Book", size: 16))
            }
            .tint(.blue)
        }
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    MenuView(
        chatManager: ChatManager(),
        message: .constant(""),
        showMenu: .constant(true),
        onSelectConversation: { _ in }
    )
}
