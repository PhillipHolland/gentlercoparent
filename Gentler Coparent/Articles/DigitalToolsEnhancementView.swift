import SwiftUI

struct DigitalToolsEnhancementView: View {
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
                    
                    Text("Digital Tools Enhancement")
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
                    Co-parenting’s a juggling act—schedules, costs, emotions—and it’s easy to drop the ball. Digital tools like Gentler Co-Parent turn that chaos into clarity, smoothing dynamics with your ex and keeping your kids front and center. Here’s how tech can lift your co-parenting game with practical, everyday wins.

                    **Streamline the Schedule**  
                    No more “I forgot” excuses—shared calendars sync it up. Gentler Co-Parent’s calendar logs “Pickup 6 PM, Mom’s” and pings you both. Google Calendar works too—color-code your days, their days. Real-time updates—“Game’s at 3 now”—keep you aligned, not arguing.

                    **Tame the Money Mess**  
                    Splitting expenses—shoes, camp, doctor bills—gets messy fast. Digital tools track it: “I paid $75 for meds, you owe $37.50” with a receipt snap in Gentler Co-Parent. Venmo ties in—send cash, log it. Transparency cuts the “You didn’t pay” back-and-forth.

                    **Cool the Communication**  
                    Texts turn snarky quick—tech keeps it chill. Gentler Co-Parent’s tone filter flags “You’re late again” and nudges “Pickup was delayed, can we adjust?” Email works too—short, to-the-point: “School meeting Tuesday.” Less heat, more focus on the kids.

                    **Log the Big Stuff**  
                    Agreements fade in memory—digital tools lock them in. “We split summer camp 50/50, 3/9/25” sits in Gentler Co-Parent, timestamped. If courts peek, it’s there—no he-said-she-said. It’s not just proof; it’s peace of mind.

                    **Bridge the Distance**  
                    Far apart? Tech shrinks it. Video calls—FaceTime, Zoom—let kids chat: “Show Dad your drawing.” Gentler Co-Parent’s updates—“She aced her test”—keep you in the loop. Virtual connection’s not perfect, but it’s close enough to count.

                    **Sync the Team**  
                    It’s not just you and your ex—grandparents, tutors, coaches play too. Share a digital hub: “Nana picks up Thursday” in the app. Everyone sees the plan—no frantic calls. Co-parenting’s a village; tech keeps it tight.

                    **Build Trust, Bit by Bit**  
                    Tools don’t fix bad vibes, but they ease them. Consistent logs—“Paid on time, every time”—show good faith. Shared visibility—“We both see the schedule”—cuts suspicion. It’s not instant trust, but it’s a start your kids feel.

                    Digital tools like Gentler Co-Parent don’t rewrite your co-parenting story—they refine it. Less friction, more flow, all for your kids’ sake. Plug in, sync up, and watch the dynamics shift—smoother, smarter, stronger.
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

struct DigitalToolsEnhancementView_Previews: PreviewProvider {
    static var previews: some View {
        DigitalToolsEnhancementView()
    }
}
