import SwiftUI

struct CoparentingFinancesView: View {
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
                    
                    Text("Coparenting and Finances")
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
                    Managing finances as co-parents can feel like navigating a maze—complex, fraught with potential missteps, and requiring clear communication to reach the end successfully. Whether you’re splitting costs for school supplies, extracurriculars, or unexpected medical bills, a solid approach to shared expenses can reduce tension and keep the focus on your children’s well-being. Here’s a guide to best practices for co-parenting finances, designed to bring clarity and cooperation to the table.

                    **Start with a Clear Agreement**  
                    The foundation of co-parenting finances is a well-defined agreement. If you have a divorce decree or parenting plan, revisit it to understand what’s already outlined—child support, shared expenses, or specific responsibilities like healthcare costs. If it’s vague or outdated, sit down with your co-parent to draft a new financial plan. Specify which expenses are shared (e.g., tuition, sports fees) and how they’ll be split—50/50, proportional to income, or otherwise. Put it in writing, whether through a legal update or a mutual email, to avoid future disputes.

                    **Communicate Early and Often**  
                    Money talks can stir emotions, but proactive communication is key. Notify your co-parent as soon as a shared expense arises—don’t wait until resentment festers. For example, if your child needs new shoes for soccer, send a quick message with the cost and a receipt. Agree on a timeline for reimbursement, like within 7 days, to keep things smooth. Regular check-ins—monthly or quarterly—can also preempt surprises, ensuring both of you stay aligned on upcoming costs like summer camp or braces.

                    **Leverage Technology**  
                    Tracking expenses manually is a recipe for confusion. Use tools like co-parenting apps (Gentler Co-Parent, OurFamilyWizard, or 2Houses) to log costs, upload receipts, and even request payments. These platforms provide transparency—who paid what, when, and how much is owed—reducing the “he said, she said” arguments. Alternatively, a shared spreadsheet can work if you’re both disciplined, but apps often streamline the process and keep records court-ready if needed.

                    **Prioritize the Kids, Not the Fight**  
                    It’s easy to get bogged down in who owes $10 for a field trip, but petty battles drain energy. Focus on what benefits your children—agreeing on essentials like education and health over haggling small stuff. If one parent fronts a big cost (say, a laptop for school), the other should reimburse promptly rather than nitpick. A child-centric mindset keeps finances fair and feelings intact.

                    **Be Flexible but Firm**  
                    Life changes—job losses, raises, or new family dynamics—can shift financial realities. Be willing to adjust your agreement when it’s fair, like recalculating splits if incomes change significantly. But hold firm on the agreed process: no paying for unapproved extras without discussion, and no skipping reimbursements. Flexibility works when it’s mutual, not a free-for-all.

                    **Handle Disagreements Constructively**  
                    Disputes happen—maybe you disagree on “necessary” expenses like designer clothes versus basic uniforms. When tensions rise, stick to facts: reference your agreement, share receipts, and propose solutions (e.g., “I’ll cover 75% if you cover 25%”). If that fails, a mediator or co-parenting counselor can step in before it escalates to court. The goal is resolution, not retaliation.

                    **Plan for the Future**  
                    Big-ticket items like college or car insurance loom on the horizon. Start a joint savings plan early, even if it’s small contributions monthly, to ease the burden later. Discuss these long-term costs now—will you split them evenly, or adjust based on future circumstances? Planning ahead prevents last-minute scrambles and builds trust.

                    Co-parenting finances don’t have to be a battleground. With clear rules, open dialogue, and the right tools, you can manage shared expenses in a way that’s fair, efficient, and focused on your kids. It’s less about splitting every penny and more about building a partnership that works—for everyone involved.
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

struct CoparentingFinancesView_Previews: PreviewProvider {
    static var previews: some View {
        CoparentingFinancesView()
    }
}
