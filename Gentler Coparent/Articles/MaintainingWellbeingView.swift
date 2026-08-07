import SwiftUI

struct MaintainingWellbeingView: View {
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
                    
                    Text("Maintaining Your Well-being")
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
                    Co-parenting, especially in blended families, can feel like juggling flaming torches while riding a unicycle—exhilarating when it works, exhausting when it doesn’t. Amid the chaos of schedules, emotions, and step-family dynamics, your well-being often takes a backseat. But here’s the truth: prioritizing self-care isn’t selfish—it’s essential for your kids’ sake. A steady, grounded you means a steadier, happier them. Here are practical strategies to maintain your well-being while co-parenting in a blended family.

                    **Carve Out “You” Time—Guilt-Free**  
                    Between drop-offs, negotiations, and step-parenting, your calendar fills fast. Block off time—even 20 minutes a day—for yourself. Read a book, take a walk, or just sit with a coffee and breathe. It’s not indulgence; it’s recharging. Tell your kids, “Mom/Dad needs this to be their best for you,” and stick to it. Consistency turns it into a norm, not a battle.

                    **Set Boundaries with Your Co-Parent**  
                    High-conflict exes or over-involved step-parents can drain you dry. Limit interactions to what’s necessary—use email or a co-parenting app like Gentler Co-Parent for logistics only. Say no to guilt trips or last-minute demands that disrupt your peace. Clear boundaries protect your energy, letting you focus on parenting rather than fighting.

                    **Lean on Your Village**  
                    Blended families come with extra layers—step-kids, exes, new partners. You don’t have to carry it solo. Tap your support network—friends, family, or a therapist—to vent, strategize, or just laugh. If your partner’s in the mix, tag-team parenting duties to share the load. A strong village keeps you sane.

                    **Move Your Body**  
                    Stress festers when it’s trapped inside. Exercise—yoga, a run, or dancing with your kids—releases it. Even a quick stretch during a tense call with your ex can reset you. It’s not about fitness goals; it’s about feeling good in your skin, which ripples out to your family.

                    **Process the Emotional Baggage**  
                    Divorce, abuse, or step-family tension leaves scars. Journaling, meditation, or therapy can unpack that weight so it doesn’t spill onto your kids. If your ex’s barbs still sting, write them down, then shred them—literally. Letting go isn’t weakness; it’s strength for the long haul.

                    **Celebrate Small Wins**  
                    Co-parenting victories—like a smooth handoff or a step-kid’s smile—can get buried under the grind. Pause to savor them. Treat yourself to a little reward: a treat, a nap, a silly dance. These moments fuel resilience, reminding you you’re doing better than you think.

                    **Sleep Like It’s Your Job**  
                    Exhaustion amplifies every co-parenting hiccup. Aim for 7-8 hours, even if it means saying no to late-night scrolling. Nap when the kids are with the other parent. Sleep isn’t a luxury—it’s your secret weapon for patience and clarity.

                    You can’t pour from an empty cup, and co-parenting in a blended family demands a full one. Self-care isn’t a detour from your kids’ needs—it’s the road to meeting them. With these strategies, you’re not just surviving the juggle; you’re thriving in it, for their sake and yours.
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

struct MaintainingWellbeingView_Previews: PreviewProvider {
    static var previews: some View {
        MaintainingWellbeingView()
    }
}
