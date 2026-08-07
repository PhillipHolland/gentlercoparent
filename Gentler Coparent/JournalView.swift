import SwiftUI
import CoreLocation
import MapKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif

// MARK: - Journal (native Journal-app inspired + co-parenting tools)
struct JournalView: View {
    @ObservedObject var chatManager: ChatManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchText = ""
    @State private var showCompose = false
    @State private var entryToEdit: JournalEntry?
    @State private var showStarredOnly = false
    @State private var filterTag: JournalTag?
    
    private var filteredEntries: [JournalEntry] {
        chatManager.journalEntries
            .filter { entry in
                if showStarredOnly && !entry.isStarred { return false }
                if let filterTag, !entry.tags.contains(filterTag) { return false }
                guard !searchText.isEmpty else { return true }
                let q = searchText.lowercased()
                if entry.text.localizedCaseInsensitiveContains(searchText) { return true }
                if let title = entry.title, title.localizedCaseInsensitiveContains(searchText) { return true }
                if entry.tags.contains(where: { $0.label.lowercased().contains(q) }) { return true }
                return false
            }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var sections: [(day: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { calendar.startOfDay(for: $0.timestamp) }
        return grouped.keys.sorted(by: >).map { day in
            (day, grouped[day]!.sorted { $0.timestamp > $1.timestamp })
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if filteredEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(sections, id: \.day) { section in
                            Section {
                                ForEach(section.entries) { entry in
                                    Button { entryToEdit = entry } label: {
                                        JournalCard(entry: entry)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation { chatManager.deleteJournalEntry(id: entry.id) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            chatManager.toggleStarForJournalEntry(id: entry.id)
                                        } label: {
                                            Label(
                                                entry.isStarred ? "Unstar" : "Star",
                                                systemImage: entry.isStarred ? "star.slash" : "star.fill"
                                            )
                                        }
                                        .tint(.orange)
                                    }
                                }
                            } header: {
                                Text(Self.dayHeader(section.day))
                                    .font(GCPTheme.bodyMedium(13))
                                    .foregroundStyle(GCPTheme.primary.opacity(0.7))
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            
            Button { showCompose = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(GCPTheme.primary, in: Circle())
                    .shadow(color: GCPTheme.primary.opacity(0.35), radius: 10, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
            .accessibilityLabel("New journal entry")
        }
        .background(GCPTheme.canvas.ignoresSafeArea())
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search entries, tags…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Button("All tags") { filterTag = nil }
                        Divider()
                        ForEach(JournalTag.allCases) { tag in
                            Button {
                                filterTag = tag
                            } label: {
                                Label(tag.label, systemImage: tag.icon)
                            }
                        }
                    } label: {
                        Image(systemName: filterTag == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                            .foregroundStyle(GCPTheme.primary)
                    }
                    
                    Button {
                        showStarredOnly.toggle()
                    } label: {
                        Image(systemName: showStarredOnly ? "star.fill" : "star")
                            .foregroundStyle(showStarredOnly ? Color.orange : GCPTheme.primary)
                    }
                }
            }
        }
        .toolbarBackground(GCPTheme.canvas, for: .navigationBar)
        .sheet(isPresented: $showCompose) {
            JournalComposeSheet(chatManager: chatManager, locationManager: locationManager)
        }
        .sheet(item: $entryToEdit) { entry in
            JournalComposeSheet(chatManager: chatManager, locationManager: locationManager, editing: entry)
        }
        .onAppear { locationManager.requestLocation() }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label(
                showStarredOnly ? "No Starred Entries" : (filterTag != nil ? "No Matching Tags" : "Start Your Journal"),
                systemImage: showStarredOnly ? "star" : "book.closed"
            )
        } description: {
            Text(showStarredOnly
                 ? "Star entries to find them quickly."
                 : "Capture exchanges, feelings, and wins. Add photos, mood, and tags — private to you. Use the pencil button to write.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    static func dayHeader(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}

// MARK: - Entry card
private struct JournalCard: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                if let mood = entry.mood {
                    Text(mood.emoji)
                        .font(.system(size: 18))
                }
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(GCPTheme.caption(12))
                    .foregroundStyle(GCPTheme.primary.opacity(0.55))
                Spacer()
                if entry.isStarred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                }
                if !entry.attachmentFileNames.isEmpty {
                    Image(systemName: "photo")
                        .font(.system(size: 12))
                        .foregroundStyle(GCPTheme.primary.opacity(0.5))
                }
                if entry.location != nil {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(GCPTheme.primary.opacity(0.5))
                }
            }
            
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(GCPTheme.title(16))
                    .foregroundStyle(GCPTheme.primary)
                    .lineLimit(2)
            }
            
            Text(entry.text.streamingMarkdownSafe())
                .font(GCPTheme.body(15))
                .foregroundStyle(GCPTheme.primary.opacity(0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            #if canImport(UIKit)
            if let first = entry.attachmentFileNames.first,
               let img = JournalAttachmentStore.loadImage(fileName: first) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(alignment: .bottomTrailing) {
                        if entry.attachmentFileNames.count > 1 {
                            Text("+\(entry.attachmentFileNames.count - 1)")
                                .font(GCPTheme.caption(11))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.black.opacity(0.55)))
                                .padding(8)
                        }
                    }
            }
            #endif
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.tags) { tag in
                            Text(tag.label)
                                .font(GCPTheme.caption(11))
                                .foregroundStyle(GCPTheme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(GCPTheme.mint.opacity(0.65)))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(GCPTheme.cardFill)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }
}

// MARK: - Compose / edit sheet
struct JournalComposeSheet: View {
    @ObservedObject var chatManager: ChatManager
    @ObservedObject var locationManager: LocationManager
    var editing: JournalEntry? = nil
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var text: String = ""
    @State private var includeLocation = false
    @State private var mood: JournalMood?
    @State private var tags: Set<JournalTag> = []
    @State private var attachmentFileNames: [String] = []
    @State private var previewImages: [String: UIImage] = [:]
    @State private var showPhotoPicker = false
    @State private var showPreview = false
    @State private var showPrompts = false
    @FocusState private var focusedField: Field?
    
    private enum Field { case title, body }
    
    private var isEditing: Bool { editing != nil }
    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private let prompts: [(String, String)] = [
        ("Exchange check-in", "Pickup/drop-off today:\nWhat went well:\nWhat was hard:\nNext time I’ll try:\n"),
        ("Kids moment", "A moment with the kids I want to remember:\n\n"),
        ("Hard message", "What was said:\nHow I felt:\nWhat I need:\nBoundary I want to hold:\n"),
        ("Gratitude", "Three things I’m grateful for today:\n1. \n2. \n3. \n"),
        ("Incident log", "Date/time:\nWho was present:\nWhat happened (facts only):\nHow the kids were affected:\nDocuments/photos attached: \n"),
        ("Self-care", "What I did for myself today:\nWhat I still need:\n")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date + tools
                    HStack {
                        Text((editing?.timestamp ?? Date()).formatted(date: .complete, time: .shortened))
                            .font(GCPTheme.caption(13))
                            .foregroundStyle(.secondary)
                        Spacer()
                        toolChip(
                            icon: includeLocation ? "mappin.circle.fill" : "mappin.circle",
                            label: "Place",
                            active: includeLocation
                        ) {
                            includeLocation.toggle()
                            if includeLocation { locationManager.requestLocation() }
                        }
                        toolChip(
                            icon: showPreview ? "eye.fill" : "eye",
                            label: "Preview",
                            active: showPreview
                        ) {
                            showPreview.toggle()
                            focusedField = nil
                        }
                    }
                    
                    // Title
                    TextField("Title (optional)", text: $title)
                        .font(GCPTheme.title(20))
                        .foregroundStyle(GCPTheme.primary)
                        .focused($focusedField, equals: .title)
                    
                    // Mood
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(GCPTheme.primary.opacity(0.65))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(JournalMood.allCases) { m in
                                    Button {
                                        mood = (mood == m) ? nil : m
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(m.emoji).font(.system(size: 22))
                                            Text(m.label)
                                                .font(GCPTheme.caption(10))
                                                .foregroundStyle(GCPTheme.primary.opacity(0.8))
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(mood == m ? GCPTheme.mint : GCPTheme.cardFill)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(GCPTheme.primary.opacity(mood == m ? 0.25 : 0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Body + formatting
                    VStack(alignment: .leading, spacing: 0) {
                        formatToolbar
                        
                        if showPreview {
                            ScrollView {
                                Group {
                                    if text.isEmpty {
                                        Text("Nothing to preview yet.")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text(text.attributedMarkdown())
                                            .foregroundStyle(GCPTheme.primary)
                                    }
                                }
                                .font(GCPTheme.body(17))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(minHeight: 180)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(GCPTheme.cardFill)
                            )
                        } else {
                            TextEditor(text: $text)
                                .font(GCPTheme.body(17))
                                .focused($focusedField, equals: .body)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 180)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(GCPTheme.cardFill)
                                )
                        }
                    }
                    
                    // Prompts
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation { showPrompts.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb")
                                Text("Writing prompts")
                                    .font(GCPTheme.bodyMedium(14))
                                Spacer()
                                Image(systemName: showPrompts ? "chevron.up" : "chevron.down")
                            }
                            .foregroundStyle(GCPTheme.primary)
                        }
                        if showPrompts {
                            FlowPromptList(prompts: prompts) { prompt in
                                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    text = prompt
                                } else {
                                    text += "\n\n" + prompt
                                }
                                showPreview = false
                                focusedField = .body
                            }
                        }
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(GCPTheme.primary.opacity(0.65))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            ForEach(JournalTag.allCases) { tag in
                                Button {
                                    if tags.contains(tag) { tags.remove(tag) } else { tags.insert(tag) }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: tag.icon)
                                            .font(.system(size: 11))
                                        Text(tag.label)
                                            .font(GCPTheme.caption(11))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(GCPTheme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule().fill(tags.contains(tag) ? GCPTheme.mint : GCPTheme.cardFill)
                                    )
                                    .overlay(
                                        Capsule().stroke(GCPTheme.primary.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Attachments
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Photos")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(GCPTheme.primary.opacity(0.65))
                            Spacer()
                            Button {
                                showPhotoPicker = true
                            } label: {
                                Label("Add", systemImage: "photo.badge.plus")
                                    .font(GCPTheme.bodyMedium(13))
                                    .foregroundStyle(GCPTheme.primary)
                            }
                        }
                        
                        if attachmentFileNames.isEmpty {
                            Text("Screenshots of messages, receipts, school notes — kept on device.")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(attachmentFileNames, id: \.self) { name in
                                        ZStack(alignment: .topTrailing) {
                                            Group {
                                                if let img = previewImages[name] ?? JournalAttachmentStore.loadImage(fileName: name) {
                                                    Image(uiImage: img)
                                                        .resizable()
                                                        .scaledToFill()
                                                } else {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.gray.opacity(0.15))
                                                        .overlay { Image(systemName: "photo") }
                                                }
                                            }
                                            .frame(width: 96, height: 96)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                            
                                            Button {
                                                removeAttachment(name)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .symbolRenderingMode(.palette)
                                                    .foregroundStyle(.white, Color.black.opacity(0.55))
                                            }
                                            .offset(x: 6, y: -6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if includeLocation, let loc = locationManager.currentLocation {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(GCPTheme.primary)
                            Text(String(format: "Location will be saved (%.3f, %.3f)", loc.latitude, loc.longitude))
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .background(GCPTheme.cream.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(GCPTheme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Done") { save() }
                        .font(GCPTheme.bodyMedium(16))
                        .foregroundStyle(canSave ? GCPTheme.primary : GCPTheme.primary.opacity(0.35))
                        .disabled(!canSave)
                }
            }
            .toolbarBackground(GCPTheme.cream, for: .navigationBar)
            .sheet(isPresented: $showPhotoPicker) {
                DocumentPicker(pickerType: .photos) { url in
                    Task { @MainActor in
                        await addPhoto(from: url)
                    }
                }
            }
            .onAppear {
                if let editing {
                    title = editing.title ?? ""
                    text = editing.text
                    includeLocation = editing.location != nil
                    mood = editing.mood
                    tags = Set(editing.tags)
                    attachmentFileNames = editing.attachmentFileNames
                    loadPreviews()
                }
                focusedField = .body
                if includeLocation { locationManager.requestLocation() }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: Format toolbar
    private var formatToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                formatBtn("B", tip: "Bold") { wrapSelectionOrLine(prefix: "**", suffix: "**") }
                formatBtn("I", tip: "Italic", italic: true) { wrapSelectionOrLine(prefix: "*", suffix: "*") }
                formatBtn("H", tip: "Heading") { insertAtCursor("\n### ") }
                formatBtn("•", tip: "Bullet") { insertAtCursor("\n• ") }
                formatBtn("1.", tip: "Numbered") { insertAtCursor("\n1. ") }
                formatBtn("❝", tip: "Quote") { insertAtCursor("\n> ") }
                formatBtn("—", tip: "Divider") { insertAtCursor("\n\n---\n\n") }
                formatBtn("☐", tip: "Checklist") { insertAtCursor("\n- [ ] ") }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func formatBtn(_ title: String, tip: String, italic: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .italic(italic)
                .foregroundStyle(GCPTheme.primary)
                .frame(width: 36, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(GCPTheme.cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(GCPTheme.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tip)
    }
    
    private func toolChip(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(label).font(GCPTheme.caption(12))
            }
            .foregroundStyle(active ? GCPTheme.primary : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(active ? GCPTheme.mint.opacity(0.7) : Color.clear))
        }
        .buttonStyle(.plain)
    }
    
    /// TextEditor doesn't expose selection easily — append/wrap helpers stay elegant & predictable.
    private func wrapSelectionOrLine(prefix: String, suffix: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            text = "\(prefix)text\(suffix)"
        } else if !text.hasSuffix("\n") {
            text += " \(prefix)…\(suffix)"
        } else {
            text += "\(prefix)…\(suffix)"
        }
        showPreview = false
        focusedField = .body
    }
    
    private func insertAtCursor(_ snippet: String) {
        if text.isEmpty {
            text = snippet.trimmingCharacters(in: .newlines)
        } else if text.hasSuffix("\n") {
            text += snippet.trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
        } else {
            text += snippet
        }
        showPreview = false
        focusedField = .body
    }
    
    private func loadPreviews() {
        #if canImport(UIKit)
        for name in attachmentFileNames {
            if let img = JournalAttachmentStore.loadImage(fileName: name) {
                previewImages[name] = img
            }
        }
        #endif
    }
    
    private func addPhoto(from url: URL) async {
        #if canImport(UIKit)
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return }
        if let name = JournalAttachmentStore.saveImage(image) {
            attachmentFileNames.append(name)
            previewImages[name] = image
        }
        #endif
    }
    
    private func removeAttachment(_ name: String) {
        attachmentFileNames.removeAll { $0 == name }
        previewImages.removeValue(forKey: name)
        // Only delete file if not still referenced by saved entry being edited with same name kept elsewhere
        if editing?.attachmentFileNames.contains(name) != true {
            JournalAttachmentStore.delete(fileName: name)
        }
    }
    
    private func save() {
        var body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let headline = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty && !headline.isEmpty {
            body = headline
        }
        guard !body.isEmpty else { return }
        
        let loc: JournalEntry.Location? = includeLocation
            ? (locationManager.currentLocation ?? editing?.location)
            : nil
        
        // Clean up removed attachments that existed on disk from editing
        if let editing {
            let removed = Set(editing.attachmentFileNames).subtracting(attachmentFileNames)
            for name in removed {
                JournalAttachmentStore.delete(fileName: name)
            }
        }
        
        let entry = JournalEntry(
            id: editing?.id ?? UUID(),
            text: body,
            timestamp: editing?.timestamp ?? Date(),
            location: loc,
            isStarred: editing?.isStarred ?? false,
            title: headline.isEmpty ? nil : headline,
            mood: mood,
            tags: Array(tags).sorted { $0.label < $1.label },
            attachmentFileNames: attachmentFileNames
        )
        chatManager.saveJournalEntry(entry)
        
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        dismiss()
    }
}

private struct FlowPromptList: View {
    let prompts: [(String, String)]
    let onPick: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(prompts.enumerated()), id: \.offset) { _, item in
                Button {
                    onPick(item.1)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.0)
                                .font(GCPTheme.bodyMedium(14))
                                .foregroundStyle(GCPTheme.primary)
                            Text(item.1.replacingOccurrences(of: "\n", with: " ").prefix(60) + "…")
                                .font(GCPTheme.caption(11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(GCPTheme.primary.opacity(0.6))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GCPTheme.cardFill)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Location
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: JournalEntry.Location?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = JournalEntry.Location(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DebugLog.print("Failed to get location: \(error.localizedDescription)")
    }
}

#if canImport(UIKit)
struct ShareSheetView: UIViewControllerRepresentable {
    let entry: JournalEntry

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        var text = "Journal — \(formatter.string(from: entry.timestamp))\n"
        if let title = entry.title { text += "\(title)\n" }
        if let mood = entry.mood { text += "Mood: \(mood.emoji) \(mood.label)\n" }
        text += "\n\(entry.text)"
        var items: [Any] = [text]
        for name in entry.attachmentFileNames {
            if let img = JournalAttachmentStore.loadImage(fileName: name) {
                items.append(img)
            }
        }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        JournalView(chatManager: ChatManager())
    }
}
