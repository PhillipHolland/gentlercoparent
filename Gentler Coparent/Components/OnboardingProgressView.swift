import SwiftUI

// MARK: - Onboarding Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: IntroStep
    @State private var animationProgress: Double = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Progress header
            HStack {
                Text("Profile Setup")
                    .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                    .foregroundColor(Color(hex: "388083"))
                
                Spacer()
                
                if currentStep != .none && currentStep != .finalMessage {
                    Button(action: {
                        // Skip onboarding action
                        showSkipOnboardingConfirmation()
                    }) {
                        Text("Skip for now")
                            .font(Font.custom("Avenir-Book", size: 12))
                            .foregroundColor(Color(hex: "388083").opacity(0.7))
                            .underline()
                    }
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Step \(currentStep.stepNumber) of \(currentStep.totalSteps)")
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083").opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(animationProgress * 100))%")
                        .font(Font.custom("Avenir-Book", size: 12).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                }
                
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "C2EDCE").opacity(0.3))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "388083"),
                                    Color(hex: "C2EDCE")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, UIScreen.main.bounds.width * 0.8 * animationProgress), height: 6)
                        .animation(.easeInOut(duration: 0.8), value: animationProgress)
                }
                
                // Current step title
                if !currentStep.stepTitle.isEmpty {
                    Text(currentStep.stepTitle)
                        .font(Font.custom("Avenir-Book", size: 11))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animationProgress = currentStep.progressPercentage
            }
        }
        .onChange(of: currentStep) { oldValue, newValue in
            withAnimation(.easeInOut(duration: 0.6)) {
                animationProgress = newValue.progressPercentage
            }
        }
    }
    
    private func showSkipOnboardingConfirmation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let alert = UIAlertController(
            title: "Skip Profile Setup?",
            message: "You can complete your profile anytime in Settings. However, Gentler Coparent provides much better guidance when it knows about your family.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue Setup", style: .default))
        alert.addAction(UIAlertAction(title: "Skip for Now", style: .default) { _ in
            // Skip onboarding by marking as completed
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            NotificationCenter.default.post(name: .skipOnboarding, object: nil)
        })
        
        rootViewController.present(alert, animated: true)
    }
}

// MARK: - Completion Celebration View
struct OnboardingCompletionView: View {
    @State private var showCelebration = false
    @State private var confettiOpacity: Double = 0
    @State private var celebrationScale: Double = 0.5
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)
                .onTapGesture { dismissCelebration() }
            
            // Celebration card
            VStack(spacing: 24) {
                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "388083"), Color(hex: "C2EDCE")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(celebrationScale)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(celebrationScale)
                }
                
                VStack(spacing: 12) {
                    Text("🎉 Profile Complete!")
                        .font(Font.custom("Futura-CondensedExtraBold", size: 24))
                        .foregroundColor(Color(hex: "388083"))
                        .textCase(.uppercase)
                    
                    Text("Gentler Coparent is now personalized for your family. You're ready to start having more peaceful conversations!")
                        .font(Font.custom("Avenir-Book", size: 16))
                        .foregroundColor(Color(hex: "388083").opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: { dismissCelebration() }) {
                        Text("Start Chatting")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.medium))
                            .foregroundColor(.white)
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
                    }
                    
                    Button(action: {
                        // Open settings to review profile
                        dismissCelebration()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .openSettings, object: nil)
                        }
                    }) {
                        Text("Review Profile")
                            .font(Font.custom("Avenir-Book", size: 16))
                            .foregroundColor(Color(hex: "388083"))
                            .underline()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .scaleEffect(celebrationScale)
            
            // Confetti overlay
            if showCelebration {
                OnboardingConfettiView()
                    .opacity(confettiOpacity)
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCelebration = true
                celebrationScale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                confettiOpacity = 1.0
            }
            
            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.3)) {
            celebrationScale = 0.9
            confettiOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Onboarding Confetti Animation View
struct OnboardingConfettiView: View {
    @State private var particles: [OnboardingConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createConfetti()
        }
    }
    
    private func createConfetti() {
        let colors = [
            Color(hex: "388083"),
            Color(hex: "C2EDCE"),
            Color(hex: "BADFE7"),
            Color.yellow,
            Color.orange,
            Color.pink
        ]
        
        for _ in 0..<50 {
            let particle = OnboardingConfettiParticle(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -50,
                color: colors.randomElement() ?? Color(hex: "388083"),
                size: Double.random(in: 4...8),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // Animate particles
        for (index, _) in particles.enumerated() {
            withAnimation(.linear(duration: Double.random(in: 3...6)).delay(Double.random(in: 0...1))) {
                particles[index].y = UIScreen.main.bounds.height + 100
                particles[index].opacity = 0
            }
        }
    }
}

struct OnboardingConfettiParticle {
    let id = UUID()
    var x: Double
    var y: Double
    let color: Color
    let size: Double
    var opacity: Double
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let skipOnboarding = Notification.Name("skipOnboarding")
    static let openSettings = Notification.Name("openSettings")
    static let startChatOnboarding = Notification.Name("startChatOnboarding")
}

// Color extension is defined in Extensions.swift

#Preview {
    VStack {
        OnboardingProgressView(currentStep: .childName)
            .padding()
        
        Spacer()
        
        OnboardingCompletionView(onDismiss: {})
    }
    .background(Color(hex: "BADFE7"))
}