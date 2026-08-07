import SwiftUI

struct SpecialOccasionsView: View {
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
                    
                    Text("Special Occasions")
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
                    Special occasions—birthdays, holidays, graduations—shine a spotlight on co-parenting. They’re moments your kids crave joy, not tension, yet split homes can turn them into tug-of-war zones. Navigating these days takes planning, flexibility, and a kid-first mindset. Here’s how to make special occasions work in co-parenting, minus the drama.

                    **Plan Ahead, Way Ahead**  
                    Last-minute scrambles fuel fights. Map out big days—Christmas, their birthday—months out. Check your parenting plan: who gets what? If it’s vague, propose a split: “I’ll take Christmas Eve, you get Christmas Day.” Log it in Gentler Co-Parent or email—“Agreed: you have Thanksgiving 2025”—so it’s locked. Early clarity beats late chaos.

                    **Put the Kids’ Wishes First**  
                    Ask your kids what matters to them: “Where do you want your party?” A teen might want both parents at graduation; a toddler might just need cake. Balance their input with logistics—don’t promise what you can’t pull off. It’s their day, not your battleground.

                    **Split or Share—Decide Early**  
                    Some occasions split clean: you get Easter, they get Passover. Others—like a recital—might mean showing up together. Set the vibe: “We’ll both be at the game, cool?” If sharing’s tense, alternate years—“I’ll do the 2025 party, you take 2026”—and stick to it. Consistency keeps it fair.

                    **Coordinate Gifts Smartly**  
                    Double toys or no gift at all? Avoid it. Chat briefly: “I’m getting the bike; what’s your plan?” Don’t compete—focus on what they’ll love. For big stuff (a phone, a trip), split costs if you can: “$100 each?” Log it—“We agreed on $50 for the jersey”—to dodge “I paid more” spats.

                    **Flex for the Unexpected**  
                    Life happens—a snowstorm, a sick kid. If your ex’s turn gets derailed, roll with it: “Take New Year’s instead?” Offer swaps—“I’ll cover your Halloween if I get an extra day later”—and note it: “Swapped due to flu.” Flexibility shows goodwill, not weakness.

                    **Keep the Peace on the Day**  
                    At shared events, stay civil—smile, nod, no digs. If your ex baits you—“Late again, huh?”—deflect: “Glad we’re here now.” Kids feel tension like radar; don’t let it spike. Separate corners work too: “I’ll sit left, you take right.” Peace trumps pride.

                    **Celebrate Their Way Too**  
                    Your ex’s traditions—Hanukkah latkes, a weird birthday song—matter to your kids. Respect them: “Cool if they do Easter eggs at your place?” Blend yours in—“We’ll do stockings here”—so they get both worlds. It’s not losing; it’s letting them win.

                    Special occasions in co-parenting aren’t about you or your ex—they’re about your kids’ memories. Plan tight, bend a little, and keep the focus where it belongs. You’ll get through the day, and they’ll get the joy they deserve.
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

struct SpecialOccasionsView_Previews: PreviewProvider {
    static var previews: some View {
        SpecialOccasionsView()
    }
}
