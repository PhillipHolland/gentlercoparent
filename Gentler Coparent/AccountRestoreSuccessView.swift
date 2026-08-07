import SwiftUI

struct AccountRestoreSuccessView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.top)
            
            // Title
            Text("Account Restored!")
                .font(.title2.bold())
                .foregroundColor(Color(hex: "388083"))
            
            // Description
            Text("Your profile, chat history, and settings have been successfully restored from iCloud.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            // Features restored
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(Color(hex: "388083"))
                    Text("User Profile")
                        .font(.body)
                }
                
                HStack {
                    Image(systemName: "message.circle.fill")
                        .foregroundColor(Color(hex: "388083"))
                    Text("Chat History")
                        .font(.body)
                }
                
                HStack {
                    Image(systemName: "gear.circle.fill")
                        .foregroundColor(Color(hex: "388083"))
                    Text("App Settings")
                        .font(.body)
                }
            }
            .padding()
            .background(Color(hex: "F6F6F2").opacity(0.5))
            .cornerRadius(10)
            
            Spacer()
            
            // Continue Button
            Button("Continue") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "388083"))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(hex: "F6F6F2"))
    }
}

struct AccountRestoreSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        AccountRestoreSuccessView()
    }
}