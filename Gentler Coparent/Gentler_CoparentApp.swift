import SwiftUI
import AppIntents

@main
struct GentlerCoparentApp: App {
    private let appState = AppState()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var privacyLockManager = PrivacyLockManager()
    @StateObject private var appleIntelligenceManager = AppleIntelligenceManager()
    @StateObject private var documentStorageManager = DocumentStorageManager()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var hybridAIManager = HybridAIManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
                .environmentObject(audioManager)
                .environmentObject(privacyLockManager)
                .environmentObject(appleIntelligenceManager)
                .environmentObject(documentStorageManager)
                .environmentObject(chatManager)
                .environmentObject(hybridAIManager)
                .preferredColorScheme(.light) // Forces light mode
                .onAppear {
                    // Register App Intents for Siri Shortcuts
                    if #available(iOS 16.0, *) {
                        CoparentingShortcutsProvider.updateAppShortcutParameters()
                    }
                }
        }
    }
}

// The root view that handles navigation
struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var hybridAIManager: HybridAIManager
    @EnvironmentObject var privacyLockManager: PrivacyLockManager
    @State private var refreshID = UUID() // Used to force a view rebuild

    var body: some View {
        ZStack {
            Group {
                if !appState.isAuthenticated {
                    WelcomeView()
                        .onAppear { print("Presenting WelcomeView") }
                } else {
                    ContentView(
                        chatManager: chatManager,
                        hybridAIManager: hybridAIManager
                    )
                    .onAppear { print("Presenting ContentView") }
                }
            }
            .id(refreshID)
            
            // Face ID / passcode gate — covers entire authenticated experience
            if appState.isAuthenticated {
                PrivacyLockGate()
                    .environmentObject(privacyLockManager)
            }
        }
        .onChange(of: appState.isAuthenticated) {
            refreshID = UUID()
            // Re-lock when a session starts if privacy lock is on
            if appState.isAuthenticated {
                privacyLockManager.lockIfEnabled()
            }
        }
    }
}

// Manages the app’s authentication state
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false {
        didSet {
            print("AppState: isAuthenticated changed to \(isAuthenticated)")
        }
    }
    
    init() {
        // Check if a user profile exists in UserDefaults
        let hasUserProfile = UserDefaults.standard.bool(forKey: "hasUserProfile")
        self.isAuthenticated = hasUserProfile
        print("AppState initialized - isAuthenticated: \(isAuthenticated) based on hasUserProfile: \(hasUserProfile)")
    }
}
