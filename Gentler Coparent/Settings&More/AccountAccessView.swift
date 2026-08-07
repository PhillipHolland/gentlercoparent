import SwiftUI
import AuthenticationServices
import CryptoKit

struct AccountAccessView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var errorMessage = ""
    @State private var nonce = ""
    @State private var isUserSignedIn = false
    @State private var showCreateAccount = false
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var isDeleting = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("banner")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .clipped()

                Text("Account Access")
                    .font(.custom("Avenir", size: 18).bold())
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .padding(.bottom, 5)

                if !isUserSignedIn {
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
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: 375)
                    .cornerRadius(15)
                    .padding(.horizontal)
                }

                if isUserSignedIn {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showDeleteConfirmation = true
                    }) {
                        Text("Delete User Data")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete User Data"),
                            message: Text("Are you sure you want to delete your user data? This action cannot be undone, and all your data will be permanently removed."),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteUserData()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }

                if !isUserSignedIn {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showCreateAccount = true
                    }) {
                        Text("Create an Account")
                            .font(.custom("Avenir", size: 18).bold())
                            .foregroundColor(.blue)
                            .textCase(.uppercase)
                            .padding(.top, 10)
                    }
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding(.top, 150)
            .background(Color(red: 186/255, green: 223/255, blue: 231/255))
            .ignoresSafeArea(.all, edges: .all)
            .sheet(isPresented: $showCreateAccount) {
                CreateAccountView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .onAppear {
                isUserSignedIn = appState.isAuthenticated
            }
            .onChange(of: appState.isAuthenticated) { _, newValue in
                isUserSignedIn = newValue
            }
        }
    }

    // Sign in with Apple
    func signInWithApple(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch Apple ID token"
                isLoading = false
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize Apple ID token"
                isLoading = false
                return
            }
            let userId = appleIDCredential.user
            UserDefaults.standard.set(userId, forKey: "appleUserId")
            UserDefaults.standard.set(idTokenString, forKey: "appleIdToken")
            print("User signed in with Apple: \(appleIDCredential.email ?? "Unknown")")
            isUserSignedIn = true
            appState.isAuthenticated = true
            dismiss()
        }
    }

    // Delete User Data
    func deleteUserData() {
        guard !isDeleting else {
            errorMessage = "Deletion is already in progress. Please wait."
            return
        }
        isDeleting = true
        isLoading = true
        errorMessage = ""

        // Step 1: Delete all local user data (family profile, journal entries, conversation history)
        // Clear UserDefaults (family profile, settings, etc.)
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            print("Cleared UserDefaults data for bundle: \(bundleID)")
        }

        // Delete local files (journal entries, conversation history)
        let fileManager = FileManager.default
        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                for fileURL in fileURLs {
                    try fileManager.removeItem(at: fileURL)
                    print("Deleted local file: \(fileURL.path)")
                }
            } catch {
                print("Failed to delete local files: \(error.localizedDescription)")
                errorMessage = "Failed to delete local data: \(error.localizedDescription)"
                isLoading = false
                isDeleting = false
                return
            }
        }

        // Step 2: Revoke Apple Sign in token (requires backend)
        // Placeholder: Call your backend to revoke the token
        // Example API call: POST https://appleid.apple.com/auth/revoke
        // Parameters: client_id, client_secret, token (idTokenString from UserDefaults)
        print("Revoking Apple Sign in token (placeholder - requires backend implementation)")

        // Step 3: Clear Apple account association locally
        UserDefaults.standard.removeObject(forKey: "appleUserId")
        UserDefaults.standard.removeObject(forKey: "appleIdToken")
        print("Cleared Apple account association locally")

        // Step 4: Update app state
        isUserSignedIn = false
        appState.isAuthenticated = false
        isLoading = false
        isDeleting = false
        dismiss()
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

struct AccountAccessView_Previews: PreviewProvider {
    static var previews: some View {
        AccountAccessView()
            .environmentObject(AppState())
    }
}
