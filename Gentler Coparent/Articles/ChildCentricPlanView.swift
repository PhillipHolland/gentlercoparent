import SwiftUI

struct ChildCentricPlanView: View {
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
                    
                    Text("Child-Centric Plan")
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
                    A child-centric parenting plan isn’t just a schedule—it’s a lifeline for your kids, putting their needs above the fray of co-parenting. Divorce or separation shakes their world; a solid plan steadies it, weaving stability and love into split homes. Here’s how to craft one with tips and best practices that work.

                    **Start with Their Rhythm**  
                    Kids thrive on routine—bedtimes, school, play. Map your plan around it: “Weekdays with Mom for school drop-off, weekends with Dad for soccer.” Ask them (age-depending): “What feels good?” A teen might want input on swaps; a toddler needs naps locked in. Their rhythm, not yours, sets the beat.

                    **Balance Time, Not Turf**  
                    Equal splits sound fair—50/50—but fair isn’t always best. Tweak it for them: “More weekdays with me near school, summers with you for camp.” Focus on quality—two solid days of bonding beat four rushed ones. It’s not a score; it’s their security.

                    **Cover the Essentials**  
                    Nail down basics—school, health, activities. “We both get report cards; doctor visits split by who’s free.” Add specifics: “Therapy’s Tuesday—Mom takes; Dad gets updates.” Use Gentler Co-Parent to log it—“Dentist 3/10, $50 each”—so nothing slips. Details keep them cared for.

                    **Build in Flexibility**  
                    Life shifts—sick days, recitals, a grandparent’s visit. Bake in wiggle room: “We swap if work calls, 24-hour notice.” Set rules—“No veto unless it’s big”—to avoid power plays. Flex keeps it real; rigidity breaks it.

                    **Plan Special Moments**  
                    Birthdays, holidays, graduations—they matter most to kids. Split or share: “I get Christmas Eve, you get Day—or we both do the party.” Ask them: “Who’s with you for the play?” Log it early—“Thanksgiving 2025, Dad’s”—to dodge last-minute scrums. Memories trump territory.

                    **Sync Support Systems**  
                    Their world’s bigger than you two—grandmas, coaches, friends. Include them: “Aunt Sue picks up if I’m late.” Share contacts—“Here’s the tutor’s number”—and align: “We both back the IEP.” A team around them cushions the split.

                    **Revisit and Tweak**  
                    Kids grow—preschool’s not high school. Check in yearly: “Still good with weekends?” Adjust as needed—“She’s 13; wants more say.” Document changes—“Switched to 60/40, 4/1/25”—so it’s clear. A living plan grows with them.

                    A child-centric parenting plan isn’t about winning—it’s about them winning. Center their needs, talk it out, write it down. You’re not just co-parents; you’re their anchor. Get it right, and they’ll feel it—safe, loved, whole.
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

struct ChildCentricPlanView_Previews: PreviewProvider {
    static var previews: some View {
        ChildCentricPlanView()
    }
}
