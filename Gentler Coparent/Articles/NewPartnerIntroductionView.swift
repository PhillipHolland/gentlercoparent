import SwiftUI

struct NewPartnerIntroductionView: View {
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
                    
                    Text("New Partner Introduction")
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
                    Bringing a new romantic partner into your co-parenting world is like adding a wildcard—exciting for you, tricky for the kids, and potentially explosive with your ex. Done wrong, it’s a mess; done right, it’s a step toward a blended, happy life. Here’s a guide to introducing a new partner in co-parenting with care and strategy.

                    **Time It Right**  
                    Rushing kills trust—don’t parade a fling past your kids or ex. Wait till it’s serious—six months, maybe more—and stable. Check your parenting plan; some mandate a heads-up: “No new partners overnight for a year.” Timing’s not just courtesy; it’s respect for their world.

                    **Prep Your Co-Parent**  
                    Blindside your ex, and you’ve got a fight. Give notice—not permission: “I’m dating someone; they’ll meet the kids next month.” Keep it brief, factual, via email or Gentler Co-Parent—“Her name’s Jen, been together 8 months.” If they flip, stay calm: “This is about our kids, not us.” Early word cools the shock.

                    **Ease the Kids In**  
                    Kids don’t need a new “parent” day one—they need a friend. Start slow: “This is Mom’s pal, Mike—he likes soccer too.” Casual hangouts—park, pizza—beat forced family vibes. Watch their cues; if they’re icy, back off: “We’ll take it easy.” Their pace rules.

                    **Set the Role Clear**  
                    Your partner’s not a co-parent—yet. Define it: “You’re support, not discipline.” Tell your ex: “She’s not making rules; that’s us.” Tell the kids: “Dad and I decide; Jen’s here to help.” Clarity cuts jealousy and power grabs—everyone knows their lane.

                    **Brace for Pushback**  
                    Your ex might seethe—“Who’s this stranger?”—or kids might sulk—“I don’t like him.” Don’t bite back. Acknowledge it: “I get it’s weird; let’s talk.” If your ex escalates—texts, threats—log it: “3/9/25, 6 PM, ‘You’ll pay.’” Stay steady; it’s their storm, not yours.

                    **Blend, Don’t Replace**  
                    Your partner’s an add-on, not a swap for your ex. Reinforce it: “Mom’s still Mom; I’m just here too.” Keep old traditions—Friday movie night—while adding new: “Jen bakes cookies Sundays.” Kids need both histories, not a rewrite.

                    **Check In and Adjust**  
                    After intros, gauge it—kids moody? Ex hostile? Ask: “How’s this feel?” Tweak if needed: “We’ll slow down meetups.” Log changes—“Cut visits to once a week, 4/1/25”—to track what works. It’s a dance; keep stepping till it fits.

                    Introducing a new partner in co-parenting isn’t seamless—it’s deliberate. Time it, talk it, ease it in, and you’ll weave them into your kids’ lives without unraveling the rest. It’s not about your love story; it’s about their stability.
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

struct NewPartnerIntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        NewPartnerIntroductionView()
    }
}
