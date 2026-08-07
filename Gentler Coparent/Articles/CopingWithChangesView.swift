import SwiftUI

struct CopingWithChangesView: View {
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
                    
                    Text("Coping with Major Life Changes")
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
                    Life doesn’t pause for co-parenting—it throws curveballs like job changes, moves, remarriages, or health shifts that ripple through your carefully laid plans. For co-parents, these major changes can feel like a storm hitting a fragile ship—disruptive, stressful, and testing your ability to keep the kids steady. Coping isn’t about avoiding the waves; it’s about navigating them with resilience and teamwork. Here’s a guide to managing life’s big shifts in co-parenting.

                    **Assess the Impact Together**  
                    When a change hits—say, you’re relocating for work or your ex is blending a new family—start by gauging its effect on the kids and your setup. Sit down (virtually or otherwise) with your co-parent to map it out: How will schedules shift? Are finances affected? Does the parenting plan need tweaking? A joint assessment—“This move means longer commutes; let’s adjust pickups”—keeps you aligned, not at odds.

                    **Communicate Clearly and Early**  
                    Surprises breed conflict. If you’re facing a big change, give your co-parent a heads-up ASAP—weeks or months ahead, not days. Lay out the facts: “I’m starting a new job next month; it’ll change my availability.” Use a tool like Gentler Co-Parent to log it in writing, avoiding missteps. Early notice gives everyone time to adapt, not react.

                    **Flex the Plan, Not the Principles**  
                    Your parenting agreement isn’t carved in stone—life demands wiggle room. If a move cuts into your ex’s time, propose a new split or virtual check-ins. If a health issue sidelines you, ask for temporary support. Keep the core goal—kids’ stability—intact, but bend the details. Flexibility shows good faith, not weakness.

                    **Shield the Kids from Turbulence**  
                    Change rattles kids most when it’s chaotic. Keep their routines as steady as possible—same bedtimes, same school chats—even if your world’s flipping. Tell them what’s shifting in simple terms: “Mom’s moving closer to work, so weekends might look different.” Don’t vent adult stress to them; save that for a friend or therapist.

                    **Lean on Your Tools**  
                    Big changes can strain communication—don’t wing it. Apps like Gentler Co-Parent track schedules, expenses, and messages, keeping you organized when life’s messy. If a job loss hits your budget, log shared costs there for transparency. Tech isn’t a cure-all, but it’s a lifeline when focus falters.

                    **Revisit and Revise as Needed**  
                    One change often sparks others—your new partner’s kid joins the mix, or a promotion shifts your hours. Treat your co-parenting plan as a living document. Check in after a month: “Is this working? What’s off?” Tweak it—maybe more FaceTime, fewer in-person swaps—until it fits the new normal. Adaptability beats stubbornness.

                    **Take Care of You**  
                    You can’t steer the ship if you’re sinking. A move might mean new schools to research; a health scare might drain your energy. Carve out time—even 10 minutes—to breathe, walk, or vent. Self-care keeps you sharp for the kids and sane for the talks with your ex.

                    Major life changes in co-parenting test your grit, but they don’t have to break you. With open lines, a flexible mindset, and a focus on the kids, you can weather the storm—and come out stronger on the other side.
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

struct CopingWithChangesView_Previews: PreviewProvider {
    static var previews: some View {
        CopingWithChangesView()
    }
}
