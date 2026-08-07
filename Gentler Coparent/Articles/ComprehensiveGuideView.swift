import SwiftUI

struct ComprehensiveGuideView: View {
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
                    
                    Text("Comprehensive Guide")
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
                    Divorce doesn’t always end the storm—sometimes it’s just the start. Post-divorce abuse, from venomous texts to custody games, keeps the chaos alive, and your kids feel every blow. Managing it means shielding them while keeping your footing. Here’s a comprehensive guide to protecting your children when the ex won’t quit.

                    **Spot the Signs Early**  
                    Abuse after divorce morphs—less fists, more mind games. Endless texts—“You’re a failure”—or “I’ll take the kids” threats. They might skip support payments or twist drop-offs into drama. Gentler Co-Parent logs it—“3/8/25, 2 PM, hostile message”—so you see the pattern. If it’s control, not co-parenting, that’s your cue.

                    **Lock Down Communication**  
                    Cut the noise—stick to facts. “Pickup’s 6 PM” via app, not “Why are you like this?” Gentler Co-Parent’s tone filter swaps rants for “Can we confirm timing?” Email works too—short, kid-only: “School event Tuesday.” Less talk, less fuel for their fire.

                    **Shield the Kids from the Fallout**  
                    They hear “Dad hates Mom” and it cuts deep—don’t let them carry it. “We’re sorting adult stuff” beats “He’s awful.” Never use them as messengers—“Tell her I said no.” Gentler Co-Parent’s direct logs—“3/8/25, pickup set”—keep them out of the fray.

                    **Build a Legal Wall**  
                    Courts can stop the bleed—file for protection if it’s “I’ll ruin you” or worse. “3/8/25, threat logged” in Gentler Co-Parent backs you up. Modify custody if they weaponize visits—“He’s late every time.” Lawyers turn proof into power; don’t wait for escalation.

                    **Track Every Move**  
                    Evidence is your shield. Screenshot “You’ll regret this”—timestamp it. Gentler Co-Parent’s records—“3/8/25, 3 PM, missed payment”—build your case. Patterns beat promises in court; one-offs don’t. Log it all—calmly, consistently.

                    **Lean on Your Crew**  
                    You’re not solo—friends, family, pros hold you up. “He’s raging; can you grab the kids?” Gentler Co-Parent syncs it—“Aunt Jane’s on, 6 PM.” Therapists unpack their baggage—yours too. Support’s not weakness; it’s armor.

                    **Teach Kids Safety, Not Fear**  
                    They need tools, not terror. “If Dad says weird stuff, tell me” keeps it light. Role-play: “What do you do if he yells?” Gentler Co-Parent’s updates—“3/8/25, he shouted”—track impact. Age matters—little ones get “You’re safe”; teens get “I’ve got your back.”

                    Managing post-divorce abuse isn’t fixing your ex—it’s guarding your kids. Log it, lock it, lean on help—every step keeps them steady. You can’t stop their storm, but you can build a shelter. Start now; their peace can’t wait.
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

struct ComprehensiveGuideView_Previews: PreviewProvider {
    static var previews: some View {
        ComprehensiveGuideView()
    }
}
