import SwiftUI

struct AboutTheCreatorsView: View {
    private let blocks: [(title: String, body: String)] = [
        ("Our journey",
         "We founded Gentler Coparent as a couple from Texas whose lives were shaped by high-conflict divorce and co-parenting. Living through communication that never seemed to get easier made one thing clear: parents need a specialized tool built for real conflict—not generic advice."),
        ("Why we built this",
         "We wanted to lighten the load for people stuck in post-separation conflict. Ongoing hostility hurts parents and children. Gentler Coparent exists to help you communicate more calmly, document clearly, and keep kids out of adult battles."),
        ("Our mission",
         "1) Constructive communication — practical, child-focused wording you can actually send.\n2) Emotional steadiness — support that reduces reactivity and loyalty binds so families can heal."),
        ("Faith & values",
         "Our work is also rooted in a Christian walk: compassion, patience, and a commitment to healing. That ethic shapes how we design guidance—firm when needed, never cruel."),
        ("Our commitment",
         "We’ve walked this road ourselves. We’re dedicated to refining Gentler Coparent so it stays useful for the messiest, most human co-parenting days."),
        ("Privacy of our family",
         "To protect our children, we remain anonymous until they are all 18. That choice prioritizes their safety—not a lack of commitment to you. Thank you for respecting it.")
    ]
    
    var body: some View {
        SettingsDetailShell(title: "About the Creators") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome to Gentler Coparent—your starting point for a calmer co-parenting journey.")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(0.9))
                    
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        SettingsArticleBlock(block.title, block.body)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                                    .fill(GCPTheme.cardFill)
                            )
                    }
                }
                .padding(16)
            }
        }
    }
}
