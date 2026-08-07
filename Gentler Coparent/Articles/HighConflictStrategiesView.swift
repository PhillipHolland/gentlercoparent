import SwiftUI

struct HighConflictStrategiesView: View {
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
                    
                    Text("High-Conflict Strategies")
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
                    High-conflict co-parenting is a storm—every chat’s a gust, every choice a lightning strike. Your ex thrives on chaos, and your kids are caught in the rain. Effective communication isn’t about calm skies; it’s about steering through with strategies that work. Here’s how to navigate it and keep your focus on them.

                    **Batten Down the Hatches**  
                    Limit talks to essentials—schedules, school, emergencies. “Pickup’s 5 PM” cuts through “You’re a failure.” Gentler Co-Parent locks it in—“Logged, 3/8/25”—no room for storms to brew. Bare bones keep you steady.

                    **Ride the Written Wave**  
                    Calls are thunder—texts or apps are calmer seas. “Dentist Tuesday” via Gentler Co-Parent beats a shouting match. Tone filters nudge “You’re late” to “Can we adjust?” Written words dodge the downpour.

                    **Be the Eye of the Storm**  
                    They rage—“You’re useless”—you stay still. “Noted, let’s focus on the kids” is your anchor. Gray rock it—flat, dull, unmoved. It’s not giving in; it’s riding out their wind.

                    **Set Your Sails Firm**  
                    Boundaries are your rigging. “Kid logistics only, no insults” via email: “Let’s keep it here.” They blow past—“You’re trash”—you hold: “I’ll stick to the plan.” Firm lines weather the gusts.

                    **Chart Every Squall**  
                    Storms leave wreckage—record it. “3/8/25, 7 PM, ‘You’ll pay’” in Gentler Co-Parent or screenshots. Courts need logs, not lore—proof steers you clear when they spin.

                    **Call in the Crew**  
                    Solo sailing’s rough—friends, mediators, lawyers help. “He’s raging; can you swap?” Gentler Co-Parent syncs it—“Aunt Sue’s on, 5 PM.” Crew keeps you afloat when waves hit.

                    **Shield the Cargo**  
                    Kids feel every crash—don’t add yours. “Mom’s upset; we’ll sort it” not “She’s a mess.” Direct talk—“Pickup’s set”—keeps them dry. Their calm’s your north star.

                    Navigating high-conflict co-parenting’s storm isn’t about stopping the rain—it’s about sailing smart. Trim the talk, log the blows, and guard your kids. You can’t calm your ex, but you can steer through—for them.
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

struct HighConflictStrategiesView_Previews: PreviewProvider {
    static var previews: some View {
        HighConflictStrategiesView()
    }
}
