import SwiftUI

struct BlendedFamilyDynamicsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) { // Main container, no extra bands
            // Top Bar with Double Arrow and Title
            ZStack {
                Color(hex: "388083") // Teal background for top bar
                    .frame(height: 50) // Fixed height for top bar
                    .frame(maxWidth: .infinity)
                
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left.2") // Double left arrow
                            .font(.system(size: 24, weight: .bold)) // Larger, bold design
                            .foregroundColor(Color(hex: "BADFE7")) // Light blue color
                    }
                    .padding(.leading, 16)
                    
                    Text("Blended Family Dynamics")
                        .font(Font.custom("Futura-CondensedExtraBold", size: 28).weight(.regular))
                        .foregroundColor(Color(hex: "BADFE7")) // Same color as arrow
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Spacer() // No Close button, just spacer for alignment
                }
            }
            
            // Article Content
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("""
                    Navigating the waters of a blended family can feel like setting sail on a grand adventure—exciting yet fraught with challenges that test resilience and patience. At the heart of this journey lies the integration of step-parents, a process that requires careful consideration, empathy, and a sprinkle of creativity. Whether you're a step-parent stepping into this role or a biological parent facilitating this transition, understanding the dynamics can transform potential storms into smooth sailing. Here’s a guide to integrating step-parents into blended families with grace and intention.

                    **Start with Open Communication**  
                    The cornerstone of any successful blended family is open, honest communication. Before the step-parent fully steps into the family dynamic, sit down as a couple and discuss expectations, boundaries, and parenting styles. What role will the step-parent play—disciplinarian, friend, or something in between? How will you handle conflicts or differences in approach? Then, bring the children into the conversation at an age-appropriate level. Let them voice their feelings, fears, or excitement about this new family member. This isn’t a one-time chat—keep the lines open as the family evolves.

                    **Take It Slow**  
                    Rome wasn’t built in a day, and neither is a blended family. Rushing the integration can overwhelm children and strain relationships. Introduce the step-parent gradually, perhaps through casual, low-pressure settings like family game nights or outings. Allow time for bonds to form naturally. For younger kids, this might mean shared playtime; for teens, it could be respecting their space while showing consistent interest in their lives. Patience here is your greatest ally.

                    **Respect Existing Relationships**  
                    A step-parent isn’t a replacement but an addition. Honor the child’s bond with their biological parents, even if the other parent isn’t in the picture. Avoid speaking negatively about the other parent in front of the kids—it builds trust and reduces loyalty conflicts. Acknowledge milestones or traditions tied to the original family unit, showing that the step-parent’s presence enhances rather than erases what came before.

                    **Build Trust Through Consistency**  
                    Trust doesn’t sprout overnight; it grows through reliable actions. Step-parents can win over kids by being dependable—showing up to soccer games, helping with homework, or simply being present for daily routines. Small, consistent gestures signal that this new adult isn’t just passing through but is committed to the family’s well-being. Over time, these moments stack up, creating a foundation of security.

                    **Define Roles, Not Rules**  
                    Every blended family is unique, so avoid cookie-cutter approaches to step-parenting. Work together to define the step-parent’s role based on what fits your family’s needs. Maybe they’re the go-to for emotional support rather than discipline, or perhaps they take the lead on weekend adventures. Flexibility is key—roles can shift as relationships deepen. The goal is clarity, not rigidity, so everyone knows where they stand.

                    **Embrace Teamwork**  
                    Blended families thrive when parents and step-parents operate as a united front. Coordinate on decisions like house rules or discipline to avoid confusion or resentment among kids. If disagreements arise, hash them out privately—presenting a cohesive team to the children fosters stability. This teamwork extends to co-parenting with an ex, too; aligning on big-picture goals (like the child’s happiness) smooths the integration process.

                    **Celebrate Small Wins**  
                    Integration is a marathon, not a sprint, so cheer the little victories along the way. Maybe it’s the first time a child seeks the step-parent’s advice, or a shared laugh over a silly moment. These milestones signal progress, reminding everyone that the family is knitting together, stitch by stitch. Keep the mood light when possible—humor and joy are powerful glue.

                    **Seek Support When Needed**  
                    Even the best captains need a crew. If tensions rise or adjustments stall, don’t hesitate to lean on resources. Family counseling can offer tailored strategies, while co-parenting tools like Gentler Co-Parent’s tone generator can ease communication hiccups with an ex. You’re not alone on this voyage—support systems can steady the ship.

                    Blending a family with step-parents isn’t about perfection; it’s about persistence. Each step forward, fueled by empathy and understanding, weaves a stronger tapestry. With time, what starts as a collection of individuals can become a crew sailing together—united, resilient, and ready for whatever lies ahead.
                    """)
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                }
                .padding(.horizontal, 16)
            }

            Spacer()
        }
        .background(Color(hex: "BADFE7")) // Overall background below top bar
    }
}

struct BlendedFamilyDynamicsView_Previews: PreviewProvider {
    static var previews: some View {
        BlendedFamilyDynamicsView()
    }
}
