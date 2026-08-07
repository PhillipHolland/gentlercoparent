// SubscriptionCard.swift
import SwiftUI
import StoreKit

struct SubscriptionCard: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Binding var showSubscription: Bool
    @State private var userFirstName: String = "" // To store user's first name
    @State private var showConfetti = false // State for confetti animation
    @State private var selectedSubscription: String = "Annual" // Default to Annual
    @State private var scale: CGFloat = 0.8 // For scale animation

    var body: some View {
        ZStack {
            // Blurred background with slightly darker and more blurred dimming
            BlurView(style: .light, alpha: 0.7)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.2)) // Darker dimming
                .onTapGesture {
                    showSubscription = false
                }

            // Centered Card with enhanced shadow
            VStack {
                Spacer()
                VStack(spacing: 8) { // Increased spacing for taller card
                    // Banner Image (adjusted to fit better)
                    Image("banner")
                        .resizable()
                        .scaledToFit() // Scale proportionally to fit width
                        .frame(maxWidth: .infinity, maxHeight: 70) // Adjusted height
                        .padding(.horizontal, 10) // Increased horizontal padding
                        .padding(.vertical, 10)

                    // Heading
                    Text("FIND PEACE IN COPARENTING!") // New title
                        .font(.custom("Avenir", size: 20).bold()) // Increased font size
                        .foregroundColor(Color(hex: "388083"))
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 5)

                    // Annual Subscription Button with "Best Value" Label
                    Button(action: {
                        selectedSubscription = "Annual"
                    }) {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 4) {
                                Text("Annual")
                                    .font(.custom("Avenir", size: 18).bold())
                                    .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if let info = subscriptionManager.subscriptionInfo(for: "com.gentlercoparent.year") {
                                    Text("\(info.price) (\(calculateMonthlyPrice(price: 99.99))/month) after \(info.trialPeriod)")
                                        .font(.custom("Avenir", size: 14))
                                        .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text("$99.99 (\(calculateMonthlyPrice(price: 99.99))/month) after 7 day trial")
                                        .font(.custom("Avenir", size: 14))
                                        .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .frame(maxWidth: 300) // Fixed width to match other buttons
                            .padding(.leading, 10) // Increased left padding for text
                            .padding(.trailing, 5)
                            .padding(.vertical, 5)
                            .background(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.year") ? Color.gray.opacity(0.5) : (selectedSubscription == "Annual" ? Color(hex: "6FB3B8") : Color(hex: "C2EDCE")))
                            .cornerRadius(15)

                            // "Best Value" Label
                            Text("Best Value")
                                .font(.custom("Avenir", size: 12).bold())
                                .foregroundColor(Color(hex: "F6F6F2"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: "388083"))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "F6F6F2").opacity(0.5), lineWidth: 1)
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                .padding(.top, 5)
                                .padding(.trailing, 5)
                        }
                    }
                    .frame(maxWidth: .infinity) // Ensure tap area spans the card's width
                    .padding(.horizontal, 15) // Increased padding on both sides
                    .disabled(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.year"))

                    // Monthly Subscription Button
                    Button(action: {
                        selectedSubscription = "Monthly"
                    }) {
                        VStack(spacing: 4) {
                            Text("Monthly")
                                .font(.custom("Avenir", size: 18).bold())
                                .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if let info = subscriptionManager.subscriptionInfo(for: "com.gentlercoparent.month") {
                                Text("\(info.price) after a \(info.trialPeriod)")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text("$15.00 after a 3 day free trial")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(hex: "388083"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: 300) // Fixed width to match other buttons
                        .padding(.leading, 10) // Increased left padding for text
                        .padding(.trailing, 5)
                        .padding(.vertical, 5)
                        .background(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.month") ? Color.gray.opacity(0.5) : (selectedSubscription == "Monthly" ? Color(hex: "6FB3B8") : Color(hex: "C2EDCE")))
                        .cornerRadius(15)
                    }
                    .frame(maxWidth: .infinity) // Ensure tap area spans the card's width
                    .padding(.horizontal, 15) // Increased padding on both sides
                    .disabled(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.month"))

                    // Restore Purchase Link
                    Text("Restore Purchase")
                        .font(.custom("Avenir", size: 14))
                        .foregroundColor(Color(hex: "388083"))
                        .underline()
                        .padding(.top, 2)
                        .onTapGesture {
                            Task {
                                await subscriptionManager.restorePurchases()
                            }
                        }

                    // Purchase Error Message
                    if let error = subscriptionManager.purchaseError {
                        Text(error)
                            .font(.custom("Avenir", size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 5)
                    }

                    // Start Free Trial Button
                    Button(action: {
                        Task {
                            let productID = selectedSubscription == "Annual"
                                ? SubscriptionManager.yearProductID
                                : SubscriptionManager.monthProductID
                            await subscriptionManager.purchase(productID: productID)
                        }
                    }) {
                        VStack {
                            Text("Start my free trial")
                                .font(.custom("Avenir", size: 16).bold())
                                .foregroundColor(Color(hex: "F6F6F2"))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: 300) // Fixed width to match other buttons
                        .padding(.leading, 10) // Increased left padding for text
                        .padding(.trailing, 5)
                        .padding(.vertical, 8)
                        .background(Color(hex: "388083"))
                        .cornerRadius(15)
                    }
                    .frame(maxWidth: .infinity) // Ensure tap area spans the card's width
                    .padding(.horizontal, 15) // Increased padding on both sides
                    .padding(.bottom, 10)
                }
                .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4) // Increased height to 40%
                .background(Color(hex: "BADFE7").opacity(0.9)) // Light teal background
                .cornerRadius(15)
                .shadow(color: .gray.opacity(0.6), radius: 12, x: 0, y: 4)
                .scaleEffect(scale)
                .transition(.scale)
                .onAppear {
                    // Load user's first name from UserProfile
                    if let data = UserDefaults.standard.data(forKey: "userProfile"),
                       let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                        userFirstName = profile.userFirstName
                    }
                    // Trigger confetti and scale animation
                    showConfetti = true
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        scale = 1.0
                    }
                }
                Spacer()
            }

            // Confetti Animation
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
    }

    // Helper to calculate monthly price for Annual subscription, limited to 2 decimals
    private func calculateMonthlyPrice(price: Double) -> String {
        let monthlyPrice = price / 12
        return String(format: "$%.2f", monthlyPrice) // Limited to 2 decimal places
    }
}

// BlurView to apply UIBlurEffect with adjustable alpha
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    let alpha: CGFloat

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.alpha = alpha
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.alpha = alpha
    }
}

// Confetti Animation View (unchanged)
struct ConfettiView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { _ in
                Circle()
                    .fill([Color.red, Color.blue, Color.green, Color.yellow, Color.purple].randomElement()!)
                    .frame(width: 10, height: 10)
                    .offset(x: animate ? .random(in: -150...150) : 0,
                            y: animate ? .random(in: -300...300) : -400)
                    .animation(
                        Animation.easeOut(duration: 3)
                            .repeatCount(1)
                            .delay(.random(in: 0...1)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct SubscriptionCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Simulate chat layer for preview
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(0..<5) { _ in
                        Text("Hi Phil, let's make coparenting a breeze for Dax today—how can I help?")
                            .padding()
                            .background(Color.teal.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
            .background(Color.blue.opacity(0.1))

            SubscriptionCard(showSubscription: .constant(true))
                .environmentObject(SubscriptionManager())
        }
    }
}
