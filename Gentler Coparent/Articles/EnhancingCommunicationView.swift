import SwiftUI

struct EnhancingCommunicationView: View {
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
                    
                    Text("Enhancing Communication")
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
                    Co-parenting in blended families is a dance—sometimes graceful, often clumsy, and always demanding a keen sense of rhythm. At its core lies communication, the thread that can either weave a supportive tapestry or unravel into chaos. Emotional intelligence (EI) is your secret weapon here: it’s about understanding your feelings, reading others’, and responding with clarity rather than reactivity. Here’s how to harness EI to enhance communication and understanding in your blended family dynamic.

                    **Tune Into Your Emotions**  
                    Before you fire off that text to your ex or snap at a step-kid, pause. What’s driving you—anger, fear, exhaustion? Naming your emotions cools the heat of the moment. If you’re furious about a late pickup, recognize it as frustration, not a personal attack. This self-awareness stops knee-jerk reactions, letting you craft a message like, “I was upset when the kids were late—can we stick to the schedule?” instead of an accusatory rant.

                    **Read the Room**  
                    Blended families are a mix of personalities—your ex, your partner, the kids, maybe step-siblings. EI means picking up on their cues. Is your teen quiet because they’re mad or just tired? Does your ex’s sharp tone signal stress or spite? Observing body language, tone, and context helps you respond with empathy—“I see you’re upset, let’s figure this out”—rather than escalating tension.

                    **Listen Like You Mean It**  
                    Active listening is EI in action. When your co-parent vents about a school issue, don’t just wait for your turn to talk—hear them out. Nod, paraphrase (“So you’re worried about their grades?”), and resist interrupting. Kids need this too: if a step-child feels sidelined, listen to their side without defending yourself first. It builds trust, making them more open to your perspective later.

                    **Keep Your Cool Under Fire**  
                    High-conflict co-parents or moody teens can test your patience. EI helps you regulate your response. If your ex baits you with a snide remark, take a breath—don’t bite. Reply with facts: “The agreement says 6 PM drop-off; let’s stick to that.” Staying calm models emotional stability for your kids and keeps talks productive, not destructive.

                    **Speak with Intention**  
                    Words carry weight, especially in blended setups where loyalties tug. Use “I” statements—“I feel overwhelmed when plans change last-minute”—to express needs without blaming. With step-kids, frame requests positively: “I’d love your help with dishes” beats “You never pitch in.” Intentional language fosters understanding over defensiveness.

                    **Bridge the Gaps**  
                    Misunderstandings thrive in blended families—your ex might see your new partner’s involvement as overstepping, or a kid might feel you favor their sibling. EI lets you spot these rifts and mend them. Ask questions: “What did that feel like for you?” Offer clarity: “My goal’s to support, not replace.” It’s about aligning everyone toward the kids’ well-being, not winning.

                    **Practice, Practice, Practice**  
                    Emotional intelligence isn’t a switch—it’s a muscle. Start small: reflect after a tough talk, note what worked or didn’t. Over time, you’ll catch triggers faster and respond smoother. Tools like Gentler Co-Parent’s tone generator can help soften written exchanges, giving you a head start on EI-friendly communication.

                    Enhancing communication through emotional intelligence turns co-parenting from a battlefield into a collaboration. It’s not about erasing conflict—it’s about navigating it with grace, so your blended family thrives, not just survives.
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

struct EnhancingCommunicationView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancingCommunicationView()
    }
}
