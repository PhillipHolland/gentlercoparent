import SwiftUI

struct AdolescentChallengesView: View {
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
                    
                    Text("The Adolescent Years")
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
                    Co-parenting teens is like herding cats—except the cats have phones, hormones, and opinions that could out-debate a lawyer. The adolescent years bring a seismic shift: your once-compliant kids now crave independence, test boundaries, and navigate a world you can barely keep up with. For co-parents, this stage demands a blend of flexibility, unity, and grit. Here are effective strategies and tips to tackle the unique challenges of co-parenting during the teen years.

                    **Sync Up on the Big Stuff**  
                    Teens exploit gaps—tell one parent “yes” and the other “no” to get their way. Align with your co-parent on non-negotiables: curfews, screen time, dating rules. Use a shared app like Gentler Co-Parent to log decisions—“We agreed: home by 10 PM”—so there’s no wiggle room. Consistency across households cuts the chaos and keeps you both in the loop.

                    **Let Them Steer (a Little)**  
                    Adolescence is about autonomy. Give your teen a voice in the parenting plan—where they spend holidays, how transitions work. Ask, “What feels fair to you?” then balance it with reality. They’ll push back less if they’re heard, and it teaches them responsibility. Just don’t cave to every whim—structure still rules.

                    **Brace for Emotional Storms**  
                    Mood swings are teen trademarks—one day you’re their hero, the next you’re the enemy. Don’t take it personally, and don’t let it spark co-parent fights. If they vent about your ex, listen without piling on: “I get it’s tough—let’s work it out.” Stay steady; they need your calm more than your commentary.

                    **Tag-Team the Tough Talks**  
                    Sex, drugs, mental health—teen years bring big topics. Divide and conquer with your co-parent: maybe you handle school stress, they tackle dating. Back each other up—“Dad/Mom and I both think therapy could help”—to show a united front. Teens respect strength in numbers, even if they grumble.

                    **Adapt to Their World**  
                    Teens live online—TikTok, Discord, Snapchat. You don’t need to master it, but know it. Set tech rules together (e.g., “Phones off by 11 PM”) and monitor loosely—privacy matters, but safety trumps. If they’re at your ex’s and glued to screens, a quick message—“Hey, how’s screen time going?”—keeps you synced without nagging.

                    **Support, Don’t Smother**  
                    Homework’s harder, friendships shift, and college looms—teens juggle a lot. Offer help—tutors, rides, a listening ear—but don’t hover. Coordinate with your co-parent on extras like SAT prep costs or car insurance. Split the load so they feel backed, not buried, by both homes.

                    **Weather the Rebellion Together**  
                    Teens test limits—skipping curfew, mouthing off. Don’t let it pit you against your co-parent. Agree on consequences upfront—“One week grounded for sneaking out”—and enforce them evenly. If your ex goes soft, resist the urge to overcorrect; a calm chat—“Let’s keep this fair”—can realign you.

                    Co-parenting teens is a wild ride, but it’s not about perfection—it’s about presence. Stay connected with your co-parent, give your teen room to grow, and hold the line when it counts. They’ll emerge from the storm, and you’ll have steered them through—together.
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

struct AdolescentChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        AdolescentChallengesView()
    }
}
