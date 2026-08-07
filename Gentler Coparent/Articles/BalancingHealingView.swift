import SwiftUI

struct BalancingHealingView: View {
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
                    
                    Text("Balancing Healing")
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
                    Divorce leaves you raw—grieving a life lost while still steering your kids through theirs. It’s a dual journey: healing yourself and parenting them, two paths that tangle and tug. Balancing both isn’t just survival—it’s reclaiming your strength for their sake and yours. Here’s how to navigate it.

                    **Own Your Wounds First**  
                    You can’t parent well if you’re bleeding out. Name what hurts—anger, guilt, loneliness—and face it. Journal it: “I’m pissed he left.” Therapy’s gold—30 minutes a week can untangle years. Healing’s not a luxury; it’s your fuel to show up steady for them.

                    **Shield Them from Your Storm**  
                    Kids feel your pain—they don’t need to carry it. Vent to a friend, not them: “Your mom’s a mess” stays unsaid. If you slip—“I’m sad today”—keep it light: “But we’re still doing pizza night.” They need your strength, not your shards.

                    **Carve Out Healing Time**  
                    Parenting’s nonstop, but you need breaks. When they’re with your ex, don’t just collapse—use it. Walk, meditate, sob if you must—10 minutes counts. Tag-team with a pal: “Watch them an hour; I need air.” Small doses rebuild you.

                    **Keep Parenting Steady**  
                    Your chaos shouldn’t rock their boat. Stick to routines—school runs, bedtime stories—even when you’re a wreck. If you’re off, fake it: “We’re still reading, kiddo.” Consistency’s their anchor; your healing can’t sink it.

                    **Lean on Your Crew**  
                    You’re not solo—friends, family, a counselor can prop you up. “I’m drowning; can you take them Saturday?” works. Co-parenting apps like Gentler Co-Parent keep your ex in check—“Pickup’s 6 PM”—so you focus on you. Support’s not weakness; it’s smart.

                    **Blend Healing into Parenting**  
                    Turn dual duty into one gig. Deep breaths with a clingy toddler calm you both. Teens asking “You okay?”—say, “Working on it, like you do with tough stuff.” Small wins—laughing at their jokes—heal you while bonding them.

                    **Forgive Yourself the Mess**  
                    You’ll falter—snap at them, miss a pickup. It’s not failure; it’s human. Tell them: “I messed up; I’m sorry.” Tell yourself: “I’m healing, not healed.” Grace keeps you moving, not stuck.

                    Balancing parenting and personal healing post-divorce is a grind with a payoff—your kids get a stronger you, and you get a freer self. It’s not perfect; it’s progress. Step by step, you both mend.
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

struct BalancingHealingView_Previews: PreviewProvider {
    static var previews: some View {
        BalancingHealingView()
    }
}
