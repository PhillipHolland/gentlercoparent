import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Binding var showSubscription: Bool
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedSubscription: String = "Annual" // Default to Annual

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // Banner Image at Top (Matching WelcomeView exactly)
                Image("banner")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .task {
                        if subscriptionManager.products.isEmpty {
                            await subscriptionManager.loadProducts()
                        }
                    }

                // Subscription Status Indicator
                if subscriptionManager.hasActiveSubscription() {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("ACTIVE SUBSCRIPTION")
                                .font(.custom("Avenir", size: 16).bold())
                                .foregroundColor(.green)
                                .textCase(.uppercase)
                        }
                        
                        Text(activeSubscriptionDetails())
                            .font(.custom("Avenir", size: 14))
                            .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.1))
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                } else {
                    // Heading (Matching WelcomeView)
                    Text("Try Gentler Coparent for Free")
                        .font(.custom("Avenir", size: 18).bold()) // Match WelcomeView heading font
                        .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083
                        .textCase(.uppercase)
                        .lineLimit(1)
                        // Clamp so GeometryReader zero/partial widths never produce a negative frame.
                        .frame(maxWidth: max(0, geometry.size.width - 60))

                    // Subheading (Matching WelcomeView)
                    Text("The more peaceful path for coparenting")
                        .font(.custom("Avenir", size: 14)) // Match WelcomeView subheading font
                        .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Subscription Buttons in the Middle
                Spacer() // Push buttons to the middle

                // Annual Subscription Button with "Best Value" Label
                Button(action: {
                    selectedSubscription = "Annual" // Update selection without triggering purchase
                }) {
                    ZStack(alignment: .topTrailing) {
                        VStack(spacing: 4) {
                            Text("Annual")
                                .font(.custom("Avenir", size: 18).bold()) // Match WelcomeView heading font
                                .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255)) // #F6F6F2 when selected, #388083 otherwise
                                .frame(maxWidth: .infinity, alignment: .leading) // Left-justify "Annual"
                            if let info = subscriptionManager.subscriptionInfo(for: "com.gentlercoparent.year") {
                                Text("\(info.price) (\(calculateMonthlyPrice(price: 99.99))/month) after \(info.trialPeriod)")
                                    .font(.custom("Avenir", size: 14)) // Match WelcomeView subheading font
                                    .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255)) // #F6F6F2 when selected, #388083 otherwise
                                    .frame(maxWidth: .infinity, alignment: .leading) // Left-justify pricing text
                            } else {
                                Text("$99.99 (\(calculateMonthlyPrice(price: 99.99))/month) after 7 day trial") // Fallback with 2 decimal places
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(selectedSubscription == "Annual" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255))
                                    .frame(maxWidth: .infinity, alignment: .leading) // Left-justify fallback text
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.year") ? Color.gray.opacity(0.5) : (selectedSubscription == "Annual" ? Color(hex: "6FB3B8") : Color(hex: "C2EDCE")))
                        .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083 (overridden by conditional above)
                        .cornerRadius(15)

                        // "Best Value" Label
                        Text("Best Value")
                            .font(.custom("Avenir", size: 12).bold())
                            .foregroundColor(Color(hex: "F6F6F2")) // #F6F6F2 text
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083 background
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(hex: "F6F6F2").opacity(0.5), lineWidth: 1) // Subtle border
                                    )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) // Subtle shadow for depth
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.horizontal)
                .disabled(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.year"))

                // Monthly Subscription Button with "Restore Purchase" Link
                Button(action: {
                    selectedSubscription = "Monthly" // Update selection without triggering purchase
                }) {
                    VStack(spacing: 4) {
                        Text("Monthly")
                            .font(.custom("Avenir", size: 18).bold()) // Match WelcomeView heading font
                            .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255)) // #F6F6F2 when selected, #388083 otherwise
                            .frame(maxWidth: .infinity, alignment: .leading) // Left-justify "Monthly"
                        if let info = subscriptionManager.subscriptionInfo(for: "com.gentlercoparent.month") {
                            Text("\(info.price) after a \(info.trialPeriod)")
                                .font(.custom("Avenir", size: 14)) // Match WelcomeView subheading font
                                .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255)) // #F6F6F2 when selected, #388083 otherwise
                                .frame(maxWidth: .infinity, alignment: .leading) // Left-justify pricing text
                        } else {
                            Text("$15.00/month after a 3 day free trial") // Updated fallback text
                                .font(.custom("Avenir", size: 14))
                                .foregroundColor(selectedSubscription == "Monthly" ? Color(hex: "F6F6F2") : Color(red: 56/255, green: 128/255, blue: 131/255))
                                .frame(maxWidth: .infinity, alignment: .leading) // Left-justify fallback text
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.month") ? Color.gray.opacity(0.5) : (selectedSubscription == "Monthly" ? Color(hex: "6FB3B8") : Color(hex: "C2EDCE")))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083 (overridden by conditional above)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                .disabled(subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.month"))

                // Restore Purchase Link
                Text("Restore Purchase")
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083
                    .underline()
                    .padding(.top, 4)
                    .onTapGesture {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }

                // Purchase Error Message (if any)
                if let error = subscriptionManager.purchaseError {
                    Text(error)
                        .font(.custom("Avenir", size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                Spacer() // Push "Try free and subscribe" button to the bottom

                // Try Free and Subscribe Button / Manage Subscription
                Button(action: {
                    if subscriptionManager.hasActiveSubscription() {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    } else {
                        Task {
                            let productID = selectedSubscription == "Annual"
                                ? SubscriptionManager.yearProductID
                                : SubscriptionManager.monthProductID
                            await subscriptionManager.purchase(productID: productID)
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if subscriptionManager.isPurchasing || subscriptionManager.isLoadingProducts {
                            ProgressView().tint(Color(hex: "F6F6F2"))
                        }
                        Text(
                            subscriptionManager.hasActiveSubscription()
                                ? "Manage Subscription"
                                : (subscriptionManager.isPurchasing ? "Processing…" : "Try free and subscribe")
                        )
                        .font(.headline)
                        .foregroundColor(Color(hex: "F6F6F2"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        Color(red: 56/255, green: 128/255, blue: 131/255)
                            .opacity(subscriptionManager.hasActiveSubscription() ? 0.8 : 1)
                    )
                    .cornerRadius(15)
                }
                .disabled(subscriptionManager.isPurchasing || subscriptionManager.isLoadingProducts)
                .padding(.horizontal)
                
                if subscriptionManager.products.isEmpty && !subscriptionManager.isLoadingProducts {
                    Button("Reload plans") {
                        Task { await subscriptionManager.loadProducts() }
                    }
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                }

                // Spacer for solid #BADFE7 padding below button (matching WelcomeView)
                Spacer()
                    .frame(height: 50)
            }
            .padding(.top, 150) // Lower the content to match WelcomeView
            .background(Color(red: 186/255, green: 223/255, blue: 231/255)) // Background color #BADFE7
            .ignoresSafeArea(.all, edges: .all)
            .toolbar { toolbarContent } // Keep toolbar for "Close" button
        }
    }

    // Toolbar content (Close button)
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: { showSubscription = false }) {
                Text("Close")
                    .font(.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083
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

    // Helper to calculate monthly price for Annual subscription, limited to 2 decimals
    private func calculateMonthlyPrice(price: Double) -> String {
        let monthlyPrice = price / 12
        return String(format: "$%.2f", monthlyPrice) // Limited to 2 decimal places
    }
    
    // Helper to show active subscription details
    private func activeSubscriptionDetails() -> String {
        if subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.year") {
            return "Annual Plan Active • Full access to all features"
        } else if subscriptionManager.purchasedProductIDs.contains("com.gentlercoparent.month") {
            return "Monthly Plan Active • Full access to all features"
        } else {
            return "Premium subscription active"
        }
    }
}

// Color extension removed - using existing Color(hex:) from Extensions.swift

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView(showSubscription: .constant(true))
            .environmentObject(SubscriptionManager())
    }
}
