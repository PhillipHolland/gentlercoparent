import SwiftUI

struct NarcissistCoparentView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Double Arrow and Title
            ZStack {
                Color(hex: "388083") // Teal background for top bar
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.2") // Double left arrow
                            .font(.system(size: 24, weight: .bold)) // Larger, bold design
                            .foregroundColor(Color(hex: "BADFE7")) // Light blue color
                    }
                    .padding(.leading, 16)
                    
                    Text("Narcissist Co-Parent")
                        .font(Font.custom("Futura-CondensedExtraBold", size: 28).weight(.regular))
                        .foregroundColor(Color(hex: "BADFE7")) // Same color as arrow
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
            }
            
            // Article Content
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("""
                    Co-parenting’s hard enough—toss in a narcissist, and it’s a whole new beast. Their charm hides a storm of self-focus that can wreck your peace and your kids’ calm. Spotting the signs early lets you brace yourself and protect what matters. Here’s how to tell if your co-parent’s a narcissist—and what it means for you.

                    **They’re Always the Star**  
                    Everything’s about them—always. “I’m the best parent” isn’t just bragging; it’s their gospel. Pickup’s late? “I was busy being amazing.” Gentler Co-Parent logs it—“3/8/25, 6 PM, no-show”—but they’ll spin it: “You’re too strict.” Their shine trumps your kids’ needs every time.

                    **Empathy’s a Ghost**  
                    Your kid’s upset—say, a scraped knee—and they shrug: “Toughen up.” No comfort, no care—just a blank stare. Narcissists don’t feel your pain or your child’s; they’re wired for “me,” not “we.” If “How’s that feel?” never crosses their lips, that’s a red flag.

                    **Manipulation’s Their Game**  
                    They twist words like pros. “You said 7 PM” becomes “I never agreed.” Gaslighting’s their ace—making you doubt your memory or sanity. Gentler Co-Parent’s records—“Confirmed 7 PM, 3/7/25”—foil that, but they’ll still try: “You’re overreacting.” It’s control, not truth.

                    **Boundaries? What Boundaries?**  
                    Rules don’t apply to them. Your “no calls after 9 PM” gets a 10 PM rant: “I needed to talk.” They barge into your time, your space, your kid’s head—think “Tell Mom I’m better.” It’s dominance, not parenting, and it leaves you scrambling.

                    **Kids as Pawns**  
                    Your child’s a tool, not a person. “I’ll take you to Disney if you hate Dad” turns love into leverage. They’ll spoil or guilt-trip—anything to win. Gentler Co-Parent tracks it—“3/8/25, promised trip”—but the damage? That’s on your kid’s heart.

                    **Blame’s Never Theirs**  
                    Fault’s a foreign land. Missed support? “You didn’t remind me.” They’re spotless; you’re the mess. Even with proof—“Payment due 3/1/25, logged”—they dodge: “Your fault for not nagging.” Accountability’s a myth they don’t buy.

                    **Charm Hides the Chaos**  
                    They dazzle outsiders—judges, teachers, your mom. “What a great parent!”—till you’re alone, and it’s “You’re nothing.” That mask slips fast; Gentler Co-Parent’s logs—“3/8/25, yelled 2 PM”—show the real them. Public angel, private storm.

                    Spotting a narcissist co-parent isn’t just about venting—it’s survival. Their game’s rigged for them, not your kids. You can’t fix them, but you can shield yourself: log every move, set iron boundaries, and keep your child’s peace first. It’s a slog, but knowing’s half the fight.
                    """)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                }
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .background(Color(hex: "BADFE7"))
    }
}

struct NarcissistCoparentView_Previews: PreviewProvider {
    static var previews: some View {
        NarcissistCoparentView()
    }
}
