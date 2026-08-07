import SwiftUI

struct DomesticViolenceCoparentingView: View {
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
                    
                    Text("After Domestic Violence")
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
                    Co-parenting after domestic violence isn’t just logistics—it’s a tightrope of healing, safety, and fragile collaboration. The scars of abuse linger, yet your kids tie you to your past abuser, demanding a path forward. It’s not about erasing history; it’s about building a future where they thrive. Here’s how to navigate this with pathways to healing and teamwork.

                    **Prioritize Your Healing**  
                    You can’t co-parent well if you’re still broken. Therapy’s your cornerstone—trauma lingers in triggers, not just memories. “I freeze when he texts” needs unpacking with a pro. Self-care—walks, journaling—rebuilds your core. Healing’s your shield; it steadies you for them.

                    **Set Safety First, Always**  
                    Collaboration starts with boundaries—abuse flips trust. If he’s volatile, limit contact: “Email only, via Gentler Co-Parent.” Courts can help—restraining orders, supervised visits: “Kids see him with a monitor.” Safety’s non-negotiable; it’s the base for any teamwork.

                    **Communicate with Control**  
                    Talking’s a minefield—keep it tight, neutral. “Pickup’s 3 PM, confirmed” beats calls that spiral. Apps like Gentler Co-Parent log it—“He agreed, 3/9/25”—cutting “he said, she said.” If he pushes, gray rock it: “I’ll stick to the plan.” Control keeps you sane.

                    **Focus on the Kids’ Healing**  
                    They’ve seen or felt the violence—don’t pretend otherwise. Therapy for them—play-based for little ones, talk for teens—mends what’s cracked. “You’re safe now” isn’t enough; show it: “We both love you, no fighting here.” Their peace is your compass.

                    **Build a Fragile Bridge**  
                    Collaboration’s not friendship—it’s function. Start small: “We both sign the school form.” If he’s changed—therapy, accountability—test it: “Can you stick to this?” No trust? Parallel parent: “I’ll handle my days, you yours.” Bridges bend, don’t break, for the kids.

                    **Lean on Support Systems**  
                    You’re not alone—DV advocates, counselors, friends can steady you. “I need a buffer for drop-offs” gets a volunteer. Legal aid can tweak orders—“Add a no-contact clause.” Support’s your scaffold; it holds you up when he pulls down.

                    **Measure Progress, Not Perfection**  
                    Healing and teamwork grow slow—relapses sting. Note wins: “No blowup this month.” If he slips—threats, guilt—adjust: “Back to supervised.” It’s a marathon—your kids need you whole, not rushed. Progress is the goal; peace is the prize.

                    Co-parenting after domestic violence is a jagged road—safety paves it, healing lights it, collaboration inches it along. It’s not about him; it’s about them—and you. Step carefully, and you’ll all find solid ground.
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

struct DomesticViolenceCoparentingView_Previews: PreviewProvider {
    static var previews: some View {
        DomesticViolenceCoparentingView()
    }
}
