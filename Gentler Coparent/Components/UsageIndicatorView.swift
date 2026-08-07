import SwiftUI

// MARK: - Usage Indicator View
struct UsageIndicatorView: View {
    let usage: UsageInfo
    let trialStatus: TrialStatus
    @Binding var showSubscription: Bool
    @State private var isAnimating = false
    @State private var isDismissed = false
    
    var body: some View {
        Group {
            if !isDismissed {
                usageIndicatorContent
            }
        }
    }
    
    private var usageIndicatorContent: some View {
        HStack(spacing: 8) {
            // Usage icon with animation
            Image(systemName: usage.urgencyLevel == .critical ? "exclamationmark.circle.fill" : "chart.pie.fill")
                .font(.system(size: 16))
                .foregroundColor(usage.urgencyLevel.color)
                .scaleEffect(isAnimating && usage.urgencyLevel == .critical ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(usage.promptsRemaining)")
                        .font(Font.custom("Avenir-Book", size: 14).weight(.semibold))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text("messages left")
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083").opacity(0.7))
                    
                    if case .active(let days) = trialStatus, days > 0 {
                        Text("• \(days)d trial")
                            .font(Font.custom("Avenir-Book", size: 11))
                            .foregroundColor(Color(hex: "388083").opacity(0.6))
                    }
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "C2EDCE").opacity(0.3))
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [usage.urgencyLevel.color, usage.urgencyLevel.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * usage.percentageUsed, height: 3)
                            .animation(.easeInOut(duration: 0.5), value: usage.percentageUsed)
                    }
                }
                .frame(height: 3)
            }
            
            Spacer()
            
            // Upgrade button for approaching limit - styled to match subscription sheet
            if usage.promptsRemaining <= 3 {
                Button(action: {
                    showSubscription = true
                }) {
                    Text("Upgrade")
                        .font(.custom("Avenir", size: 14).weight(.semibold))
                        .foregroundColor(Color(hex: "F6F6F2"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(red: 56/255, green: 128/255, blue: 131/255)) // Match subscription sheet #388083
                        .cornerRadius(15) // Match subscription sheet corner radius
                }
            }
            
            // Dismiss button
            Button(action: {
                withAnimation(.easeOut(duration: 0.3)) {
                    isDismissed = true
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255).opacity(0.6))
                    .padding(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .stroke(Color(red: 56/255, green: 128/255, blue: 131/255).opacity(0.2), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            if usage.urgencyLevel == .critical {
                isAnimating = true
            }
        }
        .onChange(of: usage.urgencyLevel) { _, newLevel in
            isAnimating = (newLevel == .critical)
        }
    }
}

// MARK: - Subscription Value Banner
struct SubscriptionValueBanner: View {
    let subscriptionValue: SubscriptionValue
    let trigger: PaywallTrigger
    @Binding var showSubscription: Bool
    @State private var showBanner = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trigger.title)
                        .font(Font.custom("Avenir-Book", size: 16).weight(.semibold))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text(subscriptionValue.primaryBenefit)
                        .font(Font.custom("Avenir-Book", size: 14))
                        .foregroundColor(Color(hex: "388083").opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: subscriptionValue.featureHighlight.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "388083"))
            }
            
            // Feature highlight
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "C2EDCE"))
                    .font(.system(size: 14))
                
                Text(subscriptionValue.featureHighlight.description)
                    .font(Font.custom("Avenir-Book", size: 13))
                    .foregroundColor(Color(hex: "388083").opacity(0.7))
                
                Spacer()
            }
            
            // CTA button - styled to match subscription sheet
            Button(action: {
                showSubscription = true
            }) {
                HStack {
                    Text(buttonText)
                        .font(.custom("Avenir", size: 16).weight(.semibold))
                        .foregroundColor(Color(hex: "F6F6F2"))
                    
                    if case .trialOffer = trigger {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "F6F6F2"))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(red: 56/255, green: 128/255, blue: 131/255)) // Match subscription sheet #388083
                .cornerRadius(15) // Match subscription sheet corner radius
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .scaleEffect(showBanner ? 1.0 : 0.95)
        .opacity(showBanner ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showBanner = true
            }
        }
    }
    
    private var buttonText: String {
        switch trigger {
        case .trialOffer:
            return "Start Free Trial"
        case .usageExceeded, .approachingLimit:
            return "Upgrade Now"
        case .trialExpired:
            return "Continue with Premium"
        case .featureGated:
            return "Unlock Feature"
        }
    }
}

// MARK: - Enhanced Subscription View
struct EnhancedSubscriptionView: View {
    @Binding var showSubscription: Bool
    @EnvironmentObject var trialManager: EnhancedSubscriptionManager
    @EnvironmentObject var store: SubscriptionManager
    let trigger: PaywallTrigger
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isPurchasing = false
    @State private var showFeatures = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if case .trialOffer = trigger {
                        trialOfferSection
                    } else {
                        upgradeSection
                    }
                    
                    subscriptionPlansSection
                    featuresSection
                    socialProofSection
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .background(Color(hex: "BADFE7"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        showSubscription = false
                    }
                    .foregroundColor(Color(hex: "388083"))
                }
            }
            .overlay(alignment: .bottom) {
                ctaButtonSection
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image("banner")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
            
            Text(trigger.title)
                .font(Font.custom("Futura-CondensedExtraBold", size: 28))
                .foregroundColor(Color(hex: "388083"))
                .textCase(.uppercase)
                .multilineTextAlignment(.center)
            
            Text(trigger.message)
                .font(Font.custom("Avenir-Book", size: 16))
                .foregroundColor(Color(hex: "388083").opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var trialOfferSection: some View {
        VStack(spacing: 16) {
            Text("🎉 Try Everything Free")
                .font(Font.custom("Avenir-Book", size: 20).weight(.semibold))
                .foregroundColor(Color(hex: "388083"))
            
            VStack(spacing: 8) {
                Text("7 days completely free")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
                
                Text("Cancel anytime • No commitment")
                    .font(Font.custom("Avenir-Book", size: 14))
                    .foregroundColor(Color(hex: "388083").opacity(0.6))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var upgradeSection: some View {
        VStack(spacing: 12) {
            if trialManager.remainingUsage.promptsRemaining > 0 {
                let usage = trialManager.remainingUsage
                Text("You have \(usage.promptsRemaining) messages remaining")
                    .font(Font.custom("Avenir-Book", size: 16))
                    .foregroundColor(Color(hex: "388083"))
            }
            
            Text(trialManager.subscriptionValue.costComparison)
                .font(Font.custom("Avenir-Book", size: 14))
                .foregroundColor(Color(hex: "388083").opacity(0.7))
                .italic()
        }
    }
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(Font.custom("Avenir-Book", size: 18).weight(.semibold))
                .foregroundColor(Color(hex: "388083"))
            
            HStack(spacing: 12) {
                SubscriptionPlanCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    onSelect: { selectedPlan = .monthly }
                )
                
                SubscriptionPlanCard(
                    plan: .annual,
                    isSelected: selectedPlan == .annual,
                    onSelect: { selectedPlan = .annual }
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFeatures.toggle()
                }
            }) {
                HStack {
                    Text("Premium Features")
                        .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Spacer()
                    
                    Image(systemName: showFeatures ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: "388083"))
                        .font(.system(size: 14))
                        .rotationEffect(.degrees(showFeatures ? 180 : 0))
                }
                .padding(.horizontal, 20)
            }
            
            if showFeatures {
                VStack(spacing: 12) {
                    ForEach(PremiumFeature.allCases, id: \.self) { feature in
                        FeatureRow(feature: feature)
                    }
                }
                .padding(.horizontal, 20)
                .transition(.slide)
            }
        }
    }
    
    private var socialProofSection: some View {
        VStack(spacing: 8) {
            Text(trialManager.subscriptionValue.socialProof)
                .font(Font.custom("Avenir-Book", size: 14))
                .foregroundColor(Color(hex: "388083").opacity(0.7))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.orange)
                }
                Text("4.8 • App Store")
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: "388083").opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var ctaButtonSection: some View {
        Button(action: {
            Task {
                await handleSubscription()
            }
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isPurchasing ? "Processing..." : ctaButtonText)
                    .font(Font.custom("Avenir-Book", size: 18).weight(.medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "388083"), Color(hex: "C2EDCE")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .disabled(isPurchasing)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(
            Color(hex: "BADFE7")
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
        )
    }
    
    private var ctaButtonText: String {
        switch trigger {
        case .trialOffer:
            return "Start 7-Day Free Trial"
        case .usageExceeded, .approachingLimit, .trialExpired:
            return selectedPlan == .annual ? "Subscribe Annual" : "Subscribe Monthly"
        case .featureGated:
            return "Unlock Premium"
        }
    }
    
    private func handleSubscription() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        if case .trialOffer = trigger {
            trialManager.startFreeTrial()
            showSubscription = false
            return
        }
        
        let productID = selectedPlan == .annual
            ? SubscriptionManager.yearProductID
            : SubscriptionManager.monthProductID
        await store.purchase(productID: productID)
        if store.hasActiveSubscription() {
            showSubscription = false
        }
    }
}

// MARK: - Supporting Views
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if plan == .annual {
                    HStack {
                        Text("SAVE 40%")
                            .font(Font.custom("Avenir-Book", size: 10).weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                        Spacer()
                    }
                }
                
                Text(plan.title)
                    .font(Font.custom("Avenir-Book", size: 16).weight(.semibold))
                    .foregroundColor(Color(hex: "388083"))
                
                Text(plan.price)
                    .font(Font.custom("Avenir-Book", size: 20).weight(.bold))
                    .foregroundColor(Color(hex: "388083"))
                
                Text(plan.subtitle)
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: "388083").opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "C2EDCE").opacity(0.3) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color(hex: "388083") : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

struct FeatureRow: View {
    let feature: PremiumFeature
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: feature.icon)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "388083"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                    .foregroundColor(Color(hex: "388083"))
                
                Text(feature.description)
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: "388083").opacity(0.7))
            }
            
            Spacer()
        }
    }
}

enum SubscriptionPlan {
    case monthly, annual
    
    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
    
    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual: return "$29.99"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return "per month"
        case .annual: return "per year\n($2.50/month)"
        }
    }
}

#Preview {
    UsageIndicatorView(
        usage: UsageInfo(promptsRemaining: 3, daysRemaining: 2, percentageUsed: 0.8),
        trialStatus: .active(daysRemaining: 2),
        showSubscription: .constant(false)
    )
}