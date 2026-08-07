import SwiftUI
import AVKit
import AuthenticationServices
import CryptoKit
import Firebase
import FirebaseAuth

#if canImport(UIKit)
import UIKit
#endif

struct WelcomeView: View {
    @State private var showPrivacyPolicy = false
    @State private var isTermsAcknowledged = false
    @State private var isVideoPlaying = false
    @State private var player = AVPlayer(url: Bundle.main.url(forResource: "gentler_coparent", withExtension: "mp4")!)
    @State private var errorMessage = ""
    @State private var nonce = ""
    @State private var isUserSignedIn = false
    @State private var showAccountRestoreSheet = false
    @State private var accountRestoreInProgress = false
    @State private var showAccountRestoreAlert = false
    @State private var accountRestoreMessage = ""
    @StateObject private var iCloudSync = iCloudSyncManager.shared
    @EnvironmentObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                Image("banner")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                ZStack {
                    if isVideoPlaying {
                        VideoPlayer(player: player)
                            .frame(width: max(geometry.size.width - 40, 0), height: max(geometry.size.height * 0.25, 0)) // Ensure non-negative dimensions
                            .scaledToFit()
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .onDisappear {
                                player.pause()
                            }
                    } else {
                        // Placeholder for video (replace Image("video") until asset is added)
                        Color.gray
                            .frame(width: max(geometry.size.width - 40, 0), height: max(geometry.size.height * 0.25, 0)) // Ensure non-negative dimensions
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                            .overlay(
                                Button(action: {
                                    isVideoPlaying = true
                                    player.play()
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.white)
                                        .opacity(0.8)
                                }
                            )
                    }
                }

                Text("DISCOVER GENTLER COPARENT")
                    .font(.custom("Avenir", size: 18).bold())
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8) // Allow text to shrink if needed
                    .frame(maxWidth: geometry.size.width - 60)

                Text("The more peaceful path for coparenting")
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8) // Allow text to shrink if needed
                    .padding(.horizontal)

                Spacer()

                Spacer()
                    .frame(height: max(geometry.size.height * 0.05, 0)) // Ensure non-negative height

                HStack(alignment: .center, spacing: 0) {
                    Button(action: {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        isTermsAcknowledged.toggle()
                        print("Terms acknowledged: \(isTermsAcknowledged)")
                    }) {
                        Image(systemName: isTermsAcknowledged ? "checkmark.square.fill" : "square")
                            .foregroundColor(isTermsAcknowledged ? Color(red: 56/255, green: 128/255, blue: 131/255) : .gray)
                            .font(.system(size: 16))
                    }

                    HStack(spacing: 0) {
                        Text("I acknowledge Gentler Coparent's ")
                            .font(.caption)
                            .foregroundColor(.black)

                        Text("Privacy Policy.")
                            .font(.caption)
                            .foregroundColor(Color(red: 56/255, green: 128/255, blue: 131/255))
                            .underline()
                            .onTapGesture {
                                showPrivacyPolicy = true
                            }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Continue with Apple Sign In
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        let nonce = randomNonceString()
                        self.nonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        if isTermsAcknowledged {
                            switch result {
                            case .success(let authResults):
                                handleAppleSignIn(authResults)
                            case .failure(let error): 
                                errorMessage = error.localizedDescription
                            }
                        } else {
                            errorMessage = "Please acknowledge the privacy policy first"
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(15)
                .padding(.horizontal)
                .disabled(!isTermsAcknowledged)
                .opacity(isTermsAcknowledged ? 1.0 : 0.6)
                
                // Continue Without Account Button
                Button(action: {
                    if isTermsAcknowledged {
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        print("Continue without account tapped")
                        // Set the user profile flag in UserDefaults
                        UserDefaults.standard.set(true, forKey: "hasUserProfile")
                        appState.isAuthenticated = true
                    } else {
                        print("Continue without account tapped, but terms not acknowledged")
                    }
                }) {
                    Text("Continue Without Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isTermsAcknowledged ? Color(red: 56/255, green: 128/255, blue: 131/255) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .disabled(!isTermsAcknowledged)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
                    .frame(height: max(geometry.size.height * 0.05, 0)) // Ensure non-negative height
            }
            .padding(.top, max(geometry.size.height * 0.15, 0)) // Ensure non-negative padding
            .background(Color(red: 186/255, green: 223/255, blue: 231/255))
            .ignoresSafeArea(.all, edges: .all)
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
                    .background(Color(red: 186/255, green: 223/255, blue: 231/255))
            }
            .sheet(isPresented: $showAccountRestoreSheet) {
                AccountRestoreSuccessView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert("Account Restore", isPresented: $showAccountRestoreAlert) {
                Button("OK") { }
            } message: {
                Text(accountRestoreMessage)
            }
            .onAppear {
                print("WelcomeView appeared, isAuthenticated: \(appState.isAuthenticated)")
            }
        }
    }

    // Handle Sign in with Apple (Auto-detect new or returning user)
    func handleAppleSignIn(_ authResults: ASAuthorization) {
        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch Apple ID token"
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to serialize Apple ID token"
                return
            }
            let userId = appleIDCredential.user
            let storedUserId = UserDefaults.standard.string(forKey: "appleUserId")

            if storedUserId == nil {
                // New user (sign-up)
                UserDefaults.standard.set(userId, forKey: "appleUserId")
                UserDefaults.standard.set(idTokenString, forKey: "appleIdToken")
                print("New user created with Apple: \(appleIDCredential.email ?? "Unknown")")
            } else if storedUserId == userId {
                // Returning user (sign-in)
                UserDefaults.standard.set(idTokenString, forKey: "appleIdToken")
                print("Returning user signed in with Apple: \(appleIDCredential.email ?? "Unknown")")
            } else {
                // Different user, treat as new sign-up
                UserDefaults.standard.set(userId, forKey: "appleUserId")
                UserDefaults.standard.set(idTokenString, forKey: "appleIdToken")
                print("New user created with Apple (different user): \(appleIDCredential.email ?? "Unknown")")
            }
            // Trigger account restore after successful sign-in
            performAccountRestore()
            
            // Note: hasUserProfile and isAuthenticated will be set after restoration completes
        }
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
                        print("✅ Account restore completed successfully")
                        self.handleAccountRestore(restoreResult)
                        self.accountRestoreMessage = "Your account data has been restored from iCloud!"
                        self.showAccountRestoreAlert = true
                        // Set flags after successful restoration
                        UserDefaults.standard.set(true, forKey: "hasUserProfile")
                        self.appState.isAuthenticated = true
                    } else {
                        print("ℹ️ No previous account data found in iCloud for this Apple ID")
                        self.accountRestoreMessage = "No previous account data found. You can set up your profile in Settings."
                        self.showAccountRestoreAlert = true
                        // Still authenticate user even if no previous data found
                        UserDefaults.standard.set(true, forKey: "hasUserProfile")
                        self.appState.isAuthenticated = true
                    }
                    
                case .failure(let error):
                    print("❌ Account restore failed: \(error.localizedDescription)")
                    self.accountRestoreMessage = "Account restore failed: \(error.localizedDescription)"
                    self.showAccountRestoreAlert = true
                    // Still authenticate user even if restore failed
                    UserDefaults.standard.set(true, forKey: "hasUserProfile")
                    self.appState.isAuthenticated = true
                }
            }
        }
    }
    
    private func handleAccountRestore(_ result: AccountRestoreResult) {
        // Restore user profile
        if let profile = result.userProfile {
            result.safeEncodeAny(profile, forKey: "userProfile")
            print("User profile restored from iCloud")
        }
        
        // Restore chat history
        if !result.conversationsIsEmpty {
            result.safeEncodeAny(result.conversations, forKey: "chatHistory")
            print("Chat history restored: \(result.conversationsCount) conversations")
        }
        
        // Restore journal entries
        if !result.journalEntriesIsEmpty {
            result.safeEncodeAny(result.journalEntries, forKey: "journalEntries")
            print("Journal entries restored: \(result.journalEntriesCount) entries")
        }
        
        // Restore bookmarked messages
        if !isAnyEmpty(result.bookmarkedMessages) {
            result.safeEncodeAny(result.bookmarkedMessages, forKey: "bookmarkedMessages")
            print("Bookmarked messages restored: \(getAnyArrayCount(result.bookmarkedMessages)) bookmarks")
        }
        
        // Settings are already restored directly to UserDefaults in the sync manager
        if result.settingsRestored {
            print("App settings restored from iCloud")
        }
        
        // Show success message to user if desired
        if result.hasData {
            showAccountRestoreSheet = true
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

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(AppState())
    }
}
