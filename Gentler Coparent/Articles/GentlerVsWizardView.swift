import SwiftUI

struct GentlerVsWizardView: View {
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
                    
                    Text("Gentler vs. Wizard")
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
                    Co-parenting apps promise smoother communication, but not all tone tools are equal. Gentler Co-Parent and Our Family Wizard (OFW) both offer tone generators to tame heated exchanges—crucial when your ex turns every chat into a sparring match. Let’s break down how these features stack up, so you can pick the one that keeps your cool and your kids first.

                    **What’s a Tone Generator Anyway?**  
                    High-conflict co-parenting thrives on sharp words—think “You’re late again” versus “Can we confirm pickup?” A tone generator flags the snark before you hit send, aiming to keep talks civil. Both apps try this, but their approaches differ big time.

                    **Gentler Co-Parent’s Tone Tool: Empathy on Tap**  
                    Gentler’s AI doesn’t just spot trouble—it rewrites it. Type “You never pay on time,” and it might suggest “Hey, can we sort out the payment schedule?” It’s proactive, not preachy—offering a full response you can tweak or send. The vibe’s collaborative, like a coach whispering, “Try this instead.” It learns your style over time, too, making it feel personal. Downside? It’s baked into the app—no opting out if you don’t vibe with it.

                    **Our Family Wizard’s ToneMeter: Red Light, Your Call**  
                    OFW’s ToneMeter is simpler—it flags hot spots. Write “You’re a deadbeat,” and it lights up red, listing why (e.g., “confrontational”). You decide what to do—edit or send anyway. It’s like a traffic light: warning, not directing. Handy for court-ready logs, since it doesn’t meddle, but it’s passive—you’re on your own to fix it. It’s also optional, costing extra unless you grab a higher plan.

                    **Head-to-Head: How They Work**  
                    Gentler’s all-in—analyzing *and* suggesting, real-time, every message. OFW’s leaner—flagging only, no rewrite help. Gentler feels like a partner; OFW’s a spotter. Gentler’s deeper AI digs into context—“I’m sick of this” gets a thoughtful nudge—while OFW’s broader net catches basics like swears or jabs. Gentler’s free with the app; OFW’s ToneMeter adds $10 yearly unless bundled.

                    **Impact on Your Day-to-Day**  
                    Gentler’s rewrite can shift your whole dynamic—less “me vs. you,” more “us for them.” Users say it’s cut fights by turning snipes into solutions. OFW’s flag keeps you honest—great for court, less for fixing root vibes. Gentler’s push might annoy if you hate hand-holding; OFW’s hands-off style suits the “I’ve got this” crowd but won’t coach you through.

                    **Kids in the Mix**  
                    Both aim to shield your kids from venom. Gentler’s proactive fix might mean fewer blowups they overhear—peace now. OFW’s log-first approach proves civility later—court ammo if your ex escalates. Gentler’s for healing; OFW’s for defending.

                    **Which Wins?**  
                    Gentler Co-Parent’s tone tool takes it if you want active help transforming talks—think less stress, more teamwork. OFW’s ToneMeter fits if you just need a heads-up and proof, keeping it simple and legal. Your call: fix the storm or weather it with records. Either way, your kids win when the shouting stops.
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

struct GentlerVsWizardView_Previews: PreviewProvider {
    static var previews: some View {
        GentlerVsWizardView()
    }
}
