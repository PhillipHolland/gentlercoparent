import SwiftUI

struct TransformCommunicationView: View {
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
                    
                    Text("Transform Communication")
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
                    High-conflict divorce turns every exchange into a minefield—words explode, and kids get caught in the blast. Transforming your communication isn’t about peace with your ex; it’s about clarity, control, and keeping them safe. Here’s how to reshape the chaos into something workable.

                    **Narrow the Scope**  
                    Ditch the tangents—focus on kids and logistics. “Pickup’s 6 PM” beats “You’re a liar.” Gentler Co-Parent logs it—“Set, 3/9/25”—no space for rants. Tight focus cuts the noise.

                    **Shift to Digital**  
                    Voice fuels fights—text doesn’t. “School fees due” via app trumps a call that spirals. Gentler Co-Parent’s tone nudge swaps “You suck” for “Can we confirm?” Digital keeps it cold and clear.

                    **Defuse with Neutrality**  
                    They poke—“You’re worthless”—you don’t jab back. “Noted, let’s talk kids” shuts it down. Gray rock style—boring, flat—starves their fire. It’s not surrender; it’s strategy.

                    **Draw the Line**  
                    Rules tame the wild. “Kid stuff only, no insults” via email: “Let’s stick to this.” They cross—“You’re trash”—you hold: “I’ll reply to schedule only.” Lines protect your peace.

                    **Track It All**  
                    High-conflict needs proof—save it. “3/9/25, 3 PM, ‘I’ll ruin you’” in Gentler Co-Parent or screenshots. Courts see patterns, not promises—records win.

                    **Pull in Reinforcements**  
                    You’re not solo—friends, mediators, lawyers help. “He’s raging; can you drop off?” Gentler Co-Parent syncs it—“Uncle Joe’s on, 6 PM.” Backup keeps you steady.

                    **Guard the Kids**  
                    They feel the venom—don’t add yours. “Mom’s mad; we’ll fix it” not “She’s awful.” Direct talk—“Drop-off’s set”—keeps them out. Their calm’s your goal.

                    Transforming communication in a high-conflict divorce is about rewriting the script—less war, more work. You don’t fix your ex; you free yourself and your kids. Start small, stay sharp—it shifts everything.
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

struct TransformCommunicationView_Previews: PreviewProvider {
    static var previews: some View {
        TransformCommunicationView()
    }
}
