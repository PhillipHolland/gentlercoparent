import SwiftUI

struct EmbracingTechnologyView: View {
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
                    
                    Text("Embracing Technology")
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
                    Co-parenting in today’s world means juggling schedules, emotions, and distance—often across cities or time zones. Technology isn’t just a convenience here; it’s a game-changer, turning fragmented efforts into streamlined teamwork. From apps to video calls, virtual strategies can bridge gaps and keep your kids connected to both parents. Here’s how to wield tech effectively in co-parenting.

                    **Centralize with a Co-parenting App**  
                    Ditch the scattered texts and emails—use one hub like Gentler Co-Parent, OurFamilyWizard, or Cozi. Log schedules, track expenses, share updates—“Dentist at 3 PM Tuesday.” It’s all there, timestamped and transparent, cutting miscommunication. Pick one you both commit to; consistency’s the key.

                    **Make Virtual Visits Count**  
                    Distance doesn’t have to mean disconnection. Set up regular video calls—Zoom, FaceTime, whatever works—for your kids to chat with the other parent. Keep it casual: “Tell Dad/Mom about your day.” Schedule it like a drop-off—“Every Wednesday at 7 PM”—so it’s routine, not random. Tech keeps bonds alive.

                    **Sync Schedules in Real Time**  
                    Teens have sports, therapy’s weekly, holidays flip-flop—calendars get messy. Share a digital one (Google Calendar, Apple Calendar) with your co-parent. Color-code it: blue for your days, red for theirs. Update instantly—“Soccer’s canceled”—and everyone’s on the same page, no excuses.

                    **Track Finances Digitally**  
                    Splitting costs—braces, camp, school fees—gets tricky without proof. Use your app’s expense feature or a shared spreadsheet. Log it: “Paid $200 for books, you owe $100.” Attach receipts—snap a photo, upload. It’s fair, fast, and court-friendly if disputes arise.

                    **Communicate Smart, Not Emotional**  
                    Tech can cool hot tempers. Stick to written updates—“Pickup’s at 5”—over apps with tone filters like Gentler Co-Parent’s. Avoid late-night call rants; type it, tweak it, send it. If it’s big—like a move—Zoom it out with a clear agenda: “Let’s discuss summer plans.” Structure keeps it civil.

                    **Involve the Kids (Age-Appropriately)**  
                    Teens can check the app themselves—“Am I with Mom this weekend?”—easing your load. Younger kids? Show them the calendar: “See, Dad’s calling tonight!” Tech empowers them to know what’s up, reducing their stress. Keep access simple and supervised.

                    **Secure and Backup Everything**  
                    Virtual co-parenting lives online—protect it. Use strong passwords, two-factor authentication. Save key chats—“Agreed to split tutoring”—in a cloud drive or email folder. If your ex twists facts later, you’ve got the record. Tech’s only as good as your safeguards.

                    Embracing technology in co-parenting isn’t about replacing the human stuff—it’s about enhancing it. Done right, it shrinks distance, clarifies chaos, and keeps your kids tied to both of you. It’s the modern family’s toolbox; use it well.
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

struct EmbracingTechnologyView_Previews: PreviewProvider {
    static var previews: some View {
        EmbracingTechnologyView()
    }
}
