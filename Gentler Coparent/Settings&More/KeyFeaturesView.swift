import SwiftUI

struct KeyFeaturesView: View {
    private let features: [(icon: String, title: String, detail: String)] = [
        (
            "text.badge.checkmark",
            "Message rewrite & tone",
            "Turn heated drafts into calm, BIFF-style messages you can send—brief, informative, friendly, and firm."
        ),
        (
            "person.2.badge.gearshape",
            "High-conflict coaching",
            "Parallel parenting, boundaries, gray rock, and documentation guidance when cooperation isn’t realistic."
        ),
        (
            "doc.text.magnifyingglass",
            "Documents & screenshots",
            "Upload decrees and messages for context so advice matches your real schedule, orders, and history."
        ),
        (
            "bookmark.fill",
            "Bookmarks & history",
            "Save strong replies and revisit past conversations when the same issue comes up again."
        ),
        (
            "book.closed.fill",
            "Journal",
            "Capture what happened, how you felt, and what you’ll try next—without putting kids in the middle."
        ),
        (
            "icloud",
            "iCloud sync",
            "Keep profile and bookmarks available across your devices signed into the same Apple ID."
        )
    ]
    
    var body: some View {
        SettingsDetailShell(title: "Key Features") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tools built for calmer co-parenting communication—especially when conflict is high.")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(0.85))
                        .padding(.bottom, 4)
                    
                    ForEach(Array(features.enumerated()), id: \.offset) { _, item in
                        SettingsInfoCard(icon: item.icon, title: item.title, detail: item.detail)
                    }
                }
                .padding(16)
            }
        }
    }
}
