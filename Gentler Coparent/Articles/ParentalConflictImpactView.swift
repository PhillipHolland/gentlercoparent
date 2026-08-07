import SwiftUI

struct ParentalConflictImpactView: View {
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
                    
                    Text("Parental Conflict Impact")
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
                    Parental conflict doesn’t just strain you and your ex—it seeps into your kids, shaping their world in ways you might not see right away. Whether it’s shouting matches or icy silence, the fallout hits them hard—emotionally, socially, even physically. Understanding this impact is step one to dialing it back. Here’s what’s at stake and how to soften the blow.

                    **The Emotional Toll**  
                    Kids soak up tension like sponges—yelling or sniping leaves them anxious, scared, or guilty, thinking it’s their fault. Studies say high-conflict homes breed stress that sticks—teens might hide it with defiance, younger ones with clinginess. They’re not “fine” just because they’re quiet; they’re wired to feel it all.

                    **Social Ripples**  
                    Conflict at home messes with how kids connect outside it. They might pull back—too ashamed to have friends over—or lash out, mimicking the anger they see. School suffers too—focus drops when they’re replaying your last fight. Peers notice; teachers do too. It’s not just home drama; it’s their whole world.

                    **Physical Echoes**  
                    Stress isn’t abstract for kids—it’s headaches, stomach knots, sleepless nights. Chronic conflict can spike cortisol, leaving them jittery or wiped out. Over time, it’s linked to bigger stuff—immune dips, even heart risks down the line. Their bodies bear what their words can’t.

                    **The Loyalty Trap**  
                    When you and your ex clash, kids get caught—torn between loving you both. “If I side with Mom, Dad’s mad” turns into a tightrope they can’t walk. They might lie, shut down, or play peacemaker—roles no kid should carry. It’s not just conflict; it’s a split they feel inside.

                    **What You Can Do**  
                    You can’t erase all tension—co-parenting’s messy—but you can cushion it. Keep fights private—text, don’t yell, and use apps like Gentler Co-Parent to log it coolly: “Let’s settle pickup later.” Don’t vent to them—“Your dad’s a jerk”—or grill them for intel. If it’s heated, pause: “We’ll talk when we’re calm.” Small shifts cut big scars.

                    **Repair the Damage**  
                    They’ve seen the worst—show them better. Apologize if they catch a row: “I’m sorry you heard that; we’re working it out.” Reassure them: “We both love you, even if we argue.” Therapy’s a lifeline—solo for you, family for them—to untangle what’s stuck. Action heals more than words.

                    **Focus on the Long Game**  
                    Conflict’s impact compounds—today’s blowup could echo in their relationships years out. Dialing it back isn’t about your ex; it’s about their future. Agree on one rule—“No trash-talk in earshot”—and build from there. Every calm step is a gift to them.

                    Parental conflict hits kids where they’re softest—their sense of safety. You can’t undo every fight, but you can shrink its shadow. Understand it, own it, fix it—for their sake, not just yours.
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

struct ParentalConflictImpactView_Previews: PreviewProvider {
    static var previews: some View {
        ParentalConflictImpactView()
    }
}
