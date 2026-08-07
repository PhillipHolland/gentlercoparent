import SwiftUI

struct BenefitsForAttorneysView: View {
    private let benefits: [(icon: String, title: String, detail: String)] = [
        (
            "bubble.left.and.bubble.right",
            "Less day-to-day triage",
            "Clients get help drafting calm logistics messages so counsel can stay focused on legal strategy instead of every text fight."
        ),
        (
            "arrow.down.right.and.arrow.up.left",
            "Lower conflict volume",
            "Clearer, shorter communication can reduce unnecessary escalation and the motion practice that follows."
        ),
        (
            "building.columns",
            "Court-aware tone",
            "Not legal advice—but drafts emphasize facts, dates, and non-inflammatory language that clients can stand behind later."
        ),
        (
            "person.badge.shield.checkmark",
            "Stronger client care",
            "Position your firm as addressing both the legal file and the practical stress of co-parenting after separation."
        ),
        (
            "clock",
            "Time efficiency",
            "When routine disputes are handled better by clients, your hours go to high-value legal work."
        )
    ]
    
    var body: some View {
        SettingsDetailShell(title: "For Attorneys") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How family-law practices can recommend Gentler Coparent as a client resource.")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(0.85))
                        .padding(.bottom, 4)
                    
                    ForEach(Array(benefits.enumerated()), id: \.offset) { _, item in
                        SettingsInfoCard(icon: item.icon, title: item.title, detail: item.detail)
                    }
                    
                    Text("Gentler Coparent does not replace counsel. Clients should confirm legal rights with their attorney.")
                        .font(GCPTheme.caption(12))
                        .foregroundStyle(GCPTheme.primary.opacity(0.65))
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
    }
}
