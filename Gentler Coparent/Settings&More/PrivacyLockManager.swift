import LocalAuthentication
import SwiftUI

@MainActor
final class PrivacyLockManager: ObservableObject {
    /// Whether the privacy lock feature is turned on in Preferences.
    @Published private(set) var isPrivacyLockEnabled: Bool
    /// Whether the app content is currently covered by the lock screen.
    @Published private(set) var isLocked: Bool
    @Published var lastErrorMessage: String?
    @Published var isAuthenticating = false
    
    private let userDefaultsKey = "EnableAppPrivacyLock"
    private var authInFlight = false
    
    init() {
        let enabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        self.isPrivacyLockEnabled = enabled
        // If lock is on, start locked until Face ID / passcode succeeds.
        self.isLocked = enabled
    }
    
    /// Biometrics (Face ID / Touch ID) available and enrolled.
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Device owner auth available (biometrics and/or device passcode).
    func canAuthenticate() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }
    
    var biometryLabel: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Device Passcode"
        }
    }
    
    /// Call when app returns to background so the next open requires unlock.
    func lockIfEnabled() {
        guard isPrivacyLockEnabled else { return }
        isLocked = true
        lastErrorMessage = nil
    }
    
    /// Hard-off without auth (e.g. Delete All Data).
    func forceDisable() {
        UserDefaults.standard.set(false, forKey: userDefaultsKey)
        isPrivacyLockEnabled = false
        isLocked = false
        lastErrorMessage = nil
    }
    
    /// Turn privacy lock on/off from Preferences. Enabling requires a successful auth first.
    func setPrivacyLockEnabled(_ enabled: Bool) async -> Bool {
        lastErrorMessage = nil
        if enabled {
            guard canAuthenticate() else {
                lastErrorMessage = "Set up Face ID, Touch ID, or a device passcode in iOS Settings first."
                return false
            }
            let ok = await authenticate(reason: "Enable \(biometryLabel) lock for Gentler Coparent.")
            guard ok else { return false }
            UserDefaults.standard.set(true, forKey: userDefaultsKey)
            isPrivacyLockEnabled = true
            isLocked = false // just authenticated
            return true
        } else {
            UserDefaults.standard.set(false, forKey: userDefaultsKey)
            isPrivacyLockEnabled = false
            isLocked = false
            return true
        }
    }
    
    /// Prompt Face ID / Touch ID / passcode and unlock on success.
    @discardableResult
    func authenticate(reason: String = "Unlock Gentler Coparent to access your data.") async -> Bool {
        guard canAuthenticate() else {
            lastErrorMessage = "Authentication isn’t available. Add Face ID/Touch ID or a passcode in iOS Settings."
            return false
        }
        guard !authInFlight else { return false }
        authInFlight = true
        isAuthenticating = true
        lastErrorMessage = nil
        defer {
            authInFlight = false
            isAuthenticating = false
        }
        
        // Fresh context required for each evaluation.
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode"
        
        // Prefer biometrics when available; fall back to device passcode policy.
        let policy: LAPolicy = canUseBiometrics()
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication
        
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            if success {
                isLocked = false
                lastErrorMessage = nil
                return true
            }
            lastErrorMessage = "Authentication failed. Try again."
            return false
        } catch let error as LAError {
            // If biometrics-only failed (lockout / cancel), offer full device owner auth once.
            if policy == .deviceOwnerAuthenticationWithBiometrics,
               [.biometryLockout, .userFallback, .biometryNotAvailable].contains(error.code) {
                return await authenticateWithDeviceOwner(reason: reason)
            }
            lastErrorMessage = friendlyMessage(for: error)
            return false
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }
    
    private func authenticateWithDeviceOwner(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            if success {
                isLocked = false
                lastErrorMessage = nil
                return true
            }
            lastErrorMessage = "Authentication failed. Try again."
            return false
        } catch let error as LAError {
            lastErrorMessage = friendlyMessage(for: error)
            return false
        } catch {
            lastErrorMessage = error.localizedDescription
            return false
        }
    }
    
    private func friendlyMessage(for error: LAError) -> String {
        switch error.code {
        case .userCancel:
            return "Authentication cancelled."
        case .userFallback:
            return "Use your device passcode to unlock."
        case .biometryNotEnrolled:
            return "No Face ID / Touch ID is set up on this device."
        case .biometryLockout:
            return "Biometrics locked. Unlock with your device passcode."
        case .biometryNotAvailable:
            return "Biometrics unavailable. Use your device passcode."
        case .passcodeNotSet:
            return "Set a device passcode in iOS Settings to use app lock."
        case .authenticationFailed:
            return "Didn’t recognize you. Try again."
        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Full-screen lock UI
struct PrivacyLockGate: View {
    @EnvironmentObject private var privacyLockManager: PrivacyLockManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var didAutoPrompt = false
    
    var body: some View {
        Group {
            if privacyLockManager.isPrivacyLockEnabled && privacyLockManager.isLocked {
                lockScreen
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                privacyLockManager.lockIfEnabled()
                didAutoPrompt = false
            case .active:
                if privacyLockManager.isPrivacyLockEnabled && privacyLockManager.isLocked && !didAutoPrompt {
                    didAutoPrompt = true
                    Task { await privacyLockManager.authenticate() }
                }
            default:
                break
            }
        }
        .onAppear {
            if privacyLockManager.isPrivacyLockEnabled && privacyLockManager.isLocked {
                Task { await privacyLockManager.authenticate() }
            }
        }
    }
    
    private var lockScreen: some View {
        ZStack {
            GCPTheme.canvas.ignoresSafeArea()
            
            VStack(spacing: 28) {
                Spacer()
                
                Image(systemName: privacyLockManager.canUseBiometrics() ? "faceid" : "lock.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(GCPTheme.primary)
                
                VStack(spacing: 8) {
                    Text("Gentler Coparent is Locked")
                        .font(GCPTheme.title(22))
                        .foregroundStyle(GCPTheme.primary)
                    Text("Use \(privacyLockManager.biometryLabel) to unlock your chats and documents.")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let err = privacyLockManager.lastErrorMessage {
                    Text(err)
                        .font(GCPTheme.caption(13))
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                
                Button {
                    Task { await privacyLockManager.authenticate() }
                } label: {
                    HStack(spacing: 8) {
                        if privacyLockManager.isAuthenticating {
                            ProgressView().tint(.white)
                        }
                        Text(privacyLockManager.isAuthenticating ? "Waiting…" : "Unlock with \(privacyLockManager.biometryLabel)")
                            .font(GCPTheme.bodyMedium(16))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(GCPTheme.primary))
                }
                .disabled(privacyLockManager.isAuthenticating)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}
