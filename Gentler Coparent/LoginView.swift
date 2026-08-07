import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import CloudKit

struct LoginView: View {
    @Environment(\.dismiss) var dismiss // For dismissing the sheet
    @EnvironmentObject var appState: AppState // Environment object for app navigation
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var nonce = ""
    @State private var isUserSignedIn = false // Track if a user is signed in
    @State private var showCreateAccount = false // State to control sheet presentation
    @State private var showAccountRestoreSheet = false
    @State private var accountRestoreInProgress = false
    @StateObject private var iCloudSync = iCloudSyncManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Banner Image at Top (Matching ContentView exactly)
                Image("banner") // Ensure "banner" image is in Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20) // Match ContentView padding
                    .padding(.vertical, 10)   // Match ContentView padding

                // Header Text (Updated to match SubscriptionView title style)
                Text("Welcome to Gentler Coparent")
                    .font(.custom("Avenir", size: 18).bold()) // Updated to size 18, bold to match SubscriptionView
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083 (already matching)
                    .textCase(.uppercase) // Added to match SubscriptionView
                    .lineLimit(1)
                    .padding(.bottom, 5) // Reduced margin by 50% (from 10 to 5)

                // Email/Password Sign-In
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .cornerRadius(8) // Less rounded corners for text fields
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .cornerRadius(8) // Less rounded corners for text fields
                    .padding(.horizontal)

                // Continue with Apple
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        let nonce = randomNonceString()
                        self.nonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            signInWithApple(authResults)
                            if isUserSignedIn {
                                dismiss() // Dismiss sheet
                                appState.isAuthenticated = true // Update app state
                            }
                        case .failure(let error): errorMessage = error.localizedDescription
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black) // Keep default black style
                .frame(height: 50)
                .cornerRadius(15) // Keep buttons at 15
                .padding(.horizontal)

                // Continue with Google
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                    signInWithGoogle()
                }) {
                    HStack {
                        Image("google") // Ensure "google" icon is in Assets.xcassets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Changed to match Sign In with Email background
                    .foregroundColor(.black) // Changed to match Sign In with Email text color
                    .cornerRadius(15) // Keep buttons at 15
                }
                .padding(.horizontal)

                // Sign In with Email Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                    signInWithEmail()
                }) {
                    HStack {
                        Image(systemName: "envelope") // System envelope icon
                            .foregroundColor(.black)
                        Text("Sign In with Email")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Already set to this background
                    .foregroundColor(.black)
                    .cornerRadius(15) // Keep buttons at 15
                }
                .padding(.horizontal)

                // Sign-Out Button (Only visible if signed in, with #388083 color)
                if isUserSignedIn {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                        signOut()
                    }) {
                        Text("Sign Out")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                }

                // Button to Present CreateAccountView as a Sheet (Hidden when logged in)
                if !isUserSignedIn {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                        showCreateAccount = true
                    }) {
                        Text("Create an Account")
                            .font(.custom("Avenir", size: 18).bold()) // Updated to match SubscriptionView title
                            .foregroundColor(.blue)
                            .textCase(.uppercase) // Added to match SubscriptionView
                            .padding(.top, 10)
                    }
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding(.top, 150) // Keep content lowered
            .background(Color(red: 186/255, green: 223/255, blue: 231/255)) // Background color #BADFE7
            .ignoresSafeArea(.all, edges: .all)
            // Present CreateAccountView as a full-screen sheet
            .sheet(isPresented: $showCreateAccount) {
                CreateAccountView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            // Present Account Restore confirmation sheet
            .sheet(isPresented: $showAccountRestoreSheet) {
                AccountRestoreSuccessView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .onAppear {
                // Sync isUserSignedIn with Firebase Authentication state
                _ = Auth.auth().addStateDidChangeListener { auth, user in
                    DispatchQueue.main.async {
                        isUserSignedIn = user != nil
                        print("Authentication state changed - isUserSignedIn: \(isUserSignedIn)")
                    }
                }
            }
        }
    }

    // Email Sign-In
    func signInWithEmail() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else {
                    print("User signed in with email: \(result?.user.email ?? "Unknown")")
                    isUserSignedIn = true
                    dismiss()
                    appState.isAuthenticated = true
                }
            }
        }
    }

    // Google Sign-In
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Failed to get Google Client ID"
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Unable to find root view controller"
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            // Extract Sendable values before hopping to MainActor (GID result is not Sendable).
            let signInErrorDescription = error?.localizedDescription
            let idToken = result?.user.idToken?.tokenString
            let accessToken = result?.user.accessToken.tokenString
            
            Task { @MainActor in
                if let signInErrorDescription {
                    errorMessage = signInErrorDescription
                    return
                }
                guard let idToken, let accessToken else {
                    errorMessage = "Failed to get Google ID token"
                    return
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                Auth.auth().signIn(with: credential) { authResult, error in
                    let authErrorDescription = error?.localizedDescription
                    let email = authResult?.user.email
                    Task { @MainActor in
                        if let authErrorDescription {
                            errorMessage = authErrorDescription
                        } else {
                            print("User signed in with Google: \(email ?? "Unknown")")
                            isUserSignedIn = true
                            dismiss()
                            appState.isAuthenticated = true
                        }
                    }
                }
            }
        }
    }

    // Apple Sign-In
    func signInWithApple(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch Apple ID token"
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize Apple ID token"
                return
            }
            let credential = OAuthProvider.credential(providerID: AuthProviderID.apple, idToken: idTokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { authResult, error in
                Task { @MainActor in
                    if let error = error {
                        let nsError = error as NSError
                        errorMessage = "Apple Sign-In Error: \(error.localizedDescription) (Code: \(nsError.code), Domain: \(nsError.domain))"
                        print("Apple Sign-In Error: \(error.localizedDescription), Code: \(nsError.code), Domain: \(nsError.domain), UserInfo: \(nsError.userInfo)")
                    } else {
                        print("User signed in with Apple: \(authResult?.user.email ?? "Unknown")")
                        isUserSignedIn = true
                        self.performAccountRestore()
                        dismiss()
                        appState.isAuthenticated = true
                    }
                }
            }
        }
    }

    // Sign-Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("User signed out")
            isUserSignedIn = false
            errorMessage = "" // Clear any error messages
            email = "" // Clear email field
            password = "" // Clear password field
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }

    // Helper Functions for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        for _ in 0..<length { result.append(charset[Int.random(in: 0..<charset.count)]) }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // MARK: - Account Restore Functions
    func performAccountRestore() {
        guard iCloudSync.isiCloudAvailable else {
            print("iCloud not available for account restore")
            return
        }
        
        accountRestoreInProgress = true
        
        iCloudSync.performFullAccountRestore { result in
            DispatchQueue.main.async {
                self.accountRestoreInProgress = false
                
                switch result {
                case .success(let restoreResult):
                    if restoreResult.hasData {
                        print("Account restore completed successfully")
                        self.handleAccountRestore(restoreResult)
                    } else {
                        print("No previous account data found in iCloud")
                    }
                    
                case .failure(let error):
                    print("Account restore failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleAccountRestore(_ result: RestoreResult) {
        // Restore user profile
        if let profile = result.userProfile {
            // Save restored profile to UserDefaults using safe encoding
            result.safeEncodeAny(profile, forKey: "userProfile")
            print("User profile restored from iCloud")
        }
        
        // Restore chat history
        if !result.conversationsIsEmpty {
            // Save restored conversations to UserDefaults using safe encoding
            result.safeEncodeAny(result.conversations, forKey: "chatHistory")
            print("Chat history restored: \(result.conversationsCount) conversations")
        }
        
        // Restore journal entries
        if !result.journalEntriesIsEmpty {
            // Save restored journal entries to UserDefaults using safe encoding
            result.safeEncodeAny(result.journalEntries, forKey: "journalEntries")
            print("Journal entries restored: \(result.journalEntriesCount) entries")
        }
        
        // Restore bookmarked messages
        if !isAnyEmpty(result.bookmarkedMessages) {
            // Save restored bookmarks to UserDefaults using safe encoding
            result.safeEncodeAny(result.bookmarkedMessages, forKey: "bookmarkedMessages")
            print("Bookmarked messages restored: \(getAnyArrayCount(result.bookmarkedMessages)) bookmarks")
        }
        
        // Settings are already restored directly to UserDefaults in the sync manager
        if result.settingsRestored {
            print("App settings restored from iCloud")
        }
        
        // Show success message to user
        showAccountRestoreSheet = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AppState())
    }
}
