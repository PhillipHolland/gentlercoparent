import SwiftUI

struct HarassingCorrespondenceView: View {
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
                    
                    Text("Harassing Correspondence")
                        .font(Font.custom("Futura-CondensedExtraBold", size: 28).weight(.regular))
                        .foregroundColor(Color(hex: "BADFE7")) // Same color as arrow
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer()
                }
            }
            
            // Article Content (Placeholder - Replace with Actual Blog Text)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("""
                    Co-parenting’s tough enough without hostile messages muddying the waters. Harassing or abusive correspondence—think endless texts, threats, or guilt trips—can turn a workable dynamic into a nightmare, especially for your kids. Spotting it and handling it right keeps you sane and them safe. Here’s a comprehensive guide to identifying and managing it.

                    **Know the Signs**  
                    Harassment isn’t just loud—it’s sneaky. Look for patterns: 10 texts in an hour, “You’re a failure” jabs, or “Give me the kids or else.” Even passive digs—“Guess you don’t care”—count. If it’s relentless or controlling, it’s not just venting; it’s abuse.

                    **Trust Your Gut**  
                    That sinking feeling when their name pops up? It’s a clue. If you’re dreading every ping—scared, stressed, or trapped—it’s not normal co-parenting friction. Harassment wears you down; don’t shrug it off as “their style.”

                    **Log Every Word**  
                    Evidence is your armor. Screenshot texts—“3/8/25, 1 PM, ‘You’ll regret this’”—and save emails. Gentler Co-Parent’s logs timestamp it all: “He sent 5 messages, 2 hostile.” Patterns prove intent; one-offs don’t.

                    **Set Hard Lines**  
                    Boundaries stop the bleed. Tell them: “Only kid stuff, no insults.” If they push—“You’re useless”—redirect: “Let’s stick to pickup.” Apps like Gentler Co-Parent filter tone—“Revise this rant”—keeping it civil.

                    **Protect the Kids**  
                    Abusive words aimed at you hit them too. Never let them relay threats—“Tell Mom I’ll fight her”—or see the venom. Shield them: “This stays between us adults.” Their peace trumps your ex’s noise.

                    **Know When to Escalate**  
                    Threats—“I’ll take them away”—or stalking vibes? Call it out. Police or courts step in if it’s “I’ll hurt you” or worse. Log it—“3/8/25, 2 PM, threat”—and file. Safety’s not negotiable.

                    **Lean on Support**  
                    You’re not alone—therapists, lawyers, friends catch you. “I’m drowning in his texts” gets a plan: “Use this app, block his number.” Support turns panic into power.

                    Harassing correspondence in co-parenting isn’t your burden to bear—it’s their failure to fix. Spot it, stop it, and shield your kids. You’ve got the tools; use them to reclaim your calm.
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

struct HarassingCorrespondenceView_Previews: PreviewProvider {
    static var previews: some View {
        HarassingCorrespondenceView()
    }
}
