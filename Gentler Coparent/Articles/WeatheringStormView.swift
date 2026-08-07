import SwiftUI

struct WeatheringStormView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Weathering the Storm")
                    .font(GCPTheme.title(20))
                    .foregroundStyle(GCPTheme.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Content coming soon...")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .background(Color(hex: "BADFE7"))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Close")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .shadow(color: .gray.opacity(0.2), radius: 2)
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 10)
                }
            }
        }
    }
}

struct WeatheringStormView_Previews: PreviewProvider {
    static var previews: some View {
        WeatheringStormView()
    }
}
