import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct CreateAccountView: View {
    @Environment(\.dismiss) var dismiss // For dismissing the sheet
    @EnvironmentObject var appState: AppState // Environment object for app navigation
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var nonce = ""
    @State private var showLogin = false // State for LoginView sheet

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Banner Image at Top (Matching ContentView exactly)
                Image("banner") // Ensure "banner" image is added to Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20) // Match ContentView padding
                    .padding(.vertical, 10)   // Match ContentView padding

                // Header Text (Updated to match SubscriptionView title style)
                Text("Create an account")
                    .font(.custom("Avenir", size: 18).bold()) // Updated to size 18, bold to match SubscriptionView
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255)) // #388083 (already matching)
                    .textCase(.uppercase) // Added to match SubscriptionView
                    .lineLimit(1)
                    .padding(.bottom, 5) // Reduced margin by 50% (from 10 to 5)

                // Email Field
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .cornerRadius(8) // Less rounded corners for text fields
                    .padding(.horizontal)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                // Password Field
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .cornerRadius(8) // Less rounded corners for text fields
                    .padding(.horizontal)

                // Continue with Apple (Reverted to default black style)
                SignInWithAppleButton(
                    .continue,
                    onRequest: { request in
                        let nonce = randomNonceString()
                        self.nonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authResults):
                            createAccountWithApple(authResults)
                            if errorMessage.isEmpty { // Only navigate if no error
                                dismiss() // Dismiss sheet
                                appState.isAuthenticated = true // Update app state
                            }
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black) // Reverted to black style
                .frame(height: 50)
                .cornerRadius(15) // Keep buttons at 15
                .padding(.horizontal)

                // Continue with Google
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                    createAccountWithGoogle()
                }) {
                    HStack {
                        Image("google") // Ensure "google" icon is added to Assets.xcassets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Light gray background
                    .foregroundColor(.black) // Black text/icon
                    .cornerRadius(15) // Keep buttons at 15
                }
                .padding(.horizontal)

                // Continue with Email
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred() // Haptic feedback
                    createAccountWithEmail()
                }) {
                    HStack {
                        Image(systemName: "envelope") // System envelope icon
                            .foregroundColor(.black)
                        Text("Continue with Email")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Light gray background
                    .foregroundColor(.black)
                    .cornerRadius(15) // Keep buttons at 15
                }
                .padding(.horizontal)

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                }

                // Updated Bottom Text with Tappable Link to LoginView
                HStack(spacing: 0) {
                    Text("Already have an account? ")
                        .font(.body)
                        .foregroundColor(.black)
                    Text("Log in.")
                        .font(.body)
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            showLogin = true // Present LoginView sheet
                        }
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding(.top, 150) // Keep content lowered
            .background(Color(red: 186/255, green: 223/255, blue: 231/255)) // Background color #BADFE7
            .ignoresSafeArea(.all, edges: .all)
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .background(Color(red: 186/255, green: 223/255, blue: 231/255)) // #BADFE7 for the sheet
            }
        }
    }

    // Create Account with Apple
    func createAccountWithApple(_ authResults: ASAuthorization) {
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
                        dismiss()
                        appState.isAuthenticated = true
                    }
                }
            }
        }
    }

    // Create Account with Google
    func createAccountWithGoogle() {
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
                            dismiss()
                            appState.isAuthenticated = true
                        }
                    }
                }
            }
        }
    }

    // Create Account with Email
    func createAccountWithEmail() {
        // Use local email and password states
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error {
                    errorMessage = error.localizedDescription
                } else if let user = result?.user {
                    print("User account created: \(user.email ?? "Unknown")")
                    dismiss()
                    appState.isAuthenticated = true
                }
            }
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
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
            .environmentObject(AppState())
    }
}
