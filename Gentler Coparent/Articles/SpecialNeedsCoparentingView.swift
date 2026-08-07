import SwiftUI

struct SpecialNeedsCoparentingView: View {
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
                    
                    Text("Special Needs Co-parenting")
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
                    Co-parenting a child with special needs—whether autism, ADHD, a physical disability, or a chronic condition—adds a layer of complexity that demands more than the usual teamwork. It’s a marathon of advocacy, care, and coordination, where your child’s unique needs shape every decision. Success lies in syncing up with your co-parent while leaning on support systems. Here’s how to navigate it with strategies that work.

                    **Unify Your Approach**  
                    Consistency is gold for special needs kids—routines, therapies, and rules need to match across homes. Sit with your co-parent to align on the big stuff: medication schedules, sensory triggers, IEP goals. Use a shared tool like Gentler Co-Parent to log it—“Meds at 8 AM, OT on Tuesdays”—so there’s no guesswork. A united front cuts confusion and keeps your child steady.

                    **Master the Details**  
                    Special needs mean extra logistics—appointments, equipment, insurance battles. Split the load: maybe you handle doctor visits, they tackle school meetings. Share updates fast—“PT says he’s progressing; here’s the report”—via app or email. Details matter more here; dropping them risks your kid’s progress.

                    **Advocate as a Team**  
                    Your child’s needs—school accommodations, therapy funding—often require a fight. Tag-team it: both of you at IEP meetings or doctor consults show strength. Prep together: “We’ll push for more speech sessions.” If your ex skips, step up but log it—“I met with the school; here’s the plan”—to keep them in the loop. Unity amplifies your voice.

                    **Support Their Emotional World**  
                    Special needs kids feel the strain of split homes harder—transitions can spark meltdowns or withdrawal. Ease it with predictability: same bedtime story at both houses, a heads-up before swaps. Talk to your co-parent about cues—“He’s off after loud days”—so you’re both tuned in. A therapist or counselor can guide you if behaviors spike.

                    **Tap Your Resources**  
                    You’re not superhuman—neither’s your ex. Lean on pros: occupational therapists, support groups, respite care. Share finds—“This autism group meets Thursdays; it’s free”—and split costs like adaptive gear fairly. If your co-parent’s checked out, don’t burn out; ask family or a caseworker to step in. Resources lighten the load.

                    **Flex for the Unexpected**  
                    A flare-up, a new diagnosis, or a therapy shift can upend plans. Be ready to pivot: “She’s sick; can you take Friday?” Keep it civil, even if they balk—focus on the kid, not the fight. Document changes—“Swapped days due to ER visit”—to avoid later spats. Flexibility here is survival.

                    **Care for Yourselves Too**  
                    The grind of special needs co-parenting wears you down—missed sleep, endless calls. Tag out when you can: “I need a breather; can you cover?” If they can’t, grab a break anyway—a walk, a nap. You’re no good to your kid if you’re a wreck, and neither’s your ex.

                    Co-parenting a special needs child isn’t about perfection—it’s about persistence. Syncing strategies and leaning on support keeps your kid thriving, even when the road’s rough. You’re their anchor; together, you’re their rock.
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

struct SpecialNeedsCoparentingView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialNeedsCoparentingView()
    }
}
