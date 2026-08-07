import SwiftUI

struct AppSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var privacyLockManager: PrivacyLockManager
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    AppSettingToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "Sound Effects",
                        subtitle: "Waiting tones and interaction sounds",
                        isOn: Binding(
                            get: { audioManager.isSoundEnabled },
                            set: { audioManager.isSoundEnabled = $0 }
                        )
                    )
                    AppSettingToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptic Feedback",
                        subtitle: "Light vibration on key actions",
                        isOn: Binding(
                            get: { audioManager.isHapticsEnabled },
                            set: { audioManager.isHapticsEnabled = $0 }
                        )
                    )
                } header: {
                    Text("Audio & Haptics")
                } footer: {
                    Text("Sounds play while Gentler Coparent is thinking. Turn them off anytime.")
                }
                
                Section {
                    Toggle(isOn: Binding(
                        get: { privacyLockManager.isPrivacyLockEnabled },
                        set: { newValue in
                            Task {
                                let ok = await privacyLockManager.setPrivacyLockEnabled(newValue)
                                if !ok && newValue {
                                    // Toggle stays off; error shown below
                                }
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            SettingsIconBadge(
                                systemName: privacyLockManager.canUseBiometrics() ? "faceid" : "lock.fill"
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("App Privacy Lock")
                                    .font(GCPTheme.body(16))
                                    .foregroundStyle(GCPTheme.primary)
                                Text(privacyLockManager.canAuthenticate()
                                      ? "Require \(privacyLockManager.biometryLabel) when opening the app"
                                      : "Set up Face ID, Touch ID, or a passcode in iOS Settings first")
                                    .font(GCPTheme.caption(12))
                                    .foregroundStyle(GCPTheme.primary.opacity(0.65))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .tint(GCPTheme.primary)
                    .disabled(!privacyLockManager.canAuthenticate() && !privacyLockManager.isPrivacyLockEnabled)
                    .listRowBackground(GCPTheme.cardFill)
                    
                    if let err = privacyLockManager.lastErrorMessage, !privacyLockManager.isPrivacyLockEnabled {
                        Text(err)
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(.red)
                            .listRowBackground(GCPTheme.cardFill)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("When enabled, Gentler Coparent locks when you leave the app and asks for \(privacyLockManager.biometryLabel) before showing chats and documents.")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(GCPTheme.canvas.ignoresSafeArea())
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(GCPTheme.bodyMedium(16))
                        .foregroundStyle(GCPTheme.primary)
                }
            }
            .toolbarBackground(GCPTheme.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Supporting Views
struct AppSettingToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isOn: Binding<Bool>
    
    var body: some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                SettingsIconBadge(systemName: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.primary)
                    Text(subtitle)
                        .font(GCPTheme.caption(12))
                        .foregroundStyle(GCPTheme.primary.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(GCPTheme.primary)
        .listRowBackground(GCPTheme.cardFill)
    }
}

#Preview {
    AppSettingsSheet()
        .environmentObject(AudioManager())
        .environmentObject(AppState())
        .environmentObject(PrivacyLockManager())
}