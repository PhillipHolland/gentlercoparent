import SwiftUI

struct LegalComplexitiesView: View {
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
                    
                    Text("Legal Complexities")
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
                    Co-parenting’s tough enough without legal tangles turning every decision into a standoff. Custody disputes, support payments, and court orders can feel like a maze—step wrong, and it’s war. Navigating these complexities without escalation means staying sharp, calm, and kid-focused. Here’s how to keep the peace while tackling the legal side.

                    **Know Your Orders Cold**  
                    Court orders—custody, visitation, support—are your rulebook. Read them, memorize them, live them. “Every other weekend, 6 PM drop-off” isn’t a suggestion; it’s law. Gentler Co-Parent logs compliance—“Picked up 3/8/25, 6 PM”—so there’s no “I forgot” excuse. Clarity kills confusion; confusion breeds fights.

                    **Talk Less, Document More**  
                    Verbal deals with your ex? Risky. “We agreed to swap days” turns into “I never said that.” Put it in writing—email, app, whatever: “Swapped 3/15 for 3/22, confirmed.” Gentler Co-Parent timestamps it—“Agreed, 3/7/25, 2 PM.” Paper trails dodge he-said-she-said blowups.

                    **Stay Ahead of Changes**  
                    Life shifts—new job, move, kid’s needs. Don’t wing it; update the plan legally. File a motion: “I’m relocating; let’s adjust visitation.” Mediation beats court—“We settled it, logged 3/9/25.” Proactive tweaks stop small snags from exploding.

                    **Handle Disputes Low-Key**  
                    Ex won’t budge on pickup? Don’t storm in—de-escalate. “Let’s stick to the order; can we talk?” If it’s hot, use a neutral channel—Gentler Co-Parent: “Proposed 6:30 PM, thoughts?” Lawyers or mediators jump in if it’s stuck—“We mediated, 3/10/25.” Calm moves beat court clashes.

                    **Keep Kids Out of It**  
                    Legal stuff’s adult turf—don’t drag them in. “Tell Mom I’m fighting this” is a no-go; say “We’re sorting it out.” Shield them from filings—“Custody motion, 3/8/25”—and rants. Their peace trumps your point.

                    **Lean on Pros Wisely**  
                    Lawyers aren’t for every spat—save them for biggies: “He’s violating support.” Paralegals or apps like Gentler Co-Parent handle routine—“Filed payment, 3/9/25.” Pros guide, but you steer—overkill escalates.

                    **Play by the Rules**  
                    Tempted to dodge an order you hate? Don’t. “I kept them extra” risks contempt—“Court note, 3/8/25.” Follow it, then fix it legally: “Petition to modify filed.” Compliance keeps you clean; defiance fuels fire.

                    Legal complexities in co-parenting don’t have to mean war. Know the rules, write it down, stay cool, and keep your kids clear. It’s not about winning—it’s about working it out so they win. Steady steps beat showdowns every time.
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

struct LegalComplexitiesView_Previews: PreviewProvider {
    static var previews: some View {
        LegalComplexitiesView()
    }
}
