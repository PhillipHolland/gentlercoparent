import SwiftUI
import SafariServices

struct SettingsView: View {
    @Binding var showSettings: Bool
    /// When Settings is a root tab, hide Done. When presented as a sheet, show it.
    var showsDismissButton: Bool = false
    
    @EnvironmentObject var documentStorageManager: DocumentStorageManager
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var privacyLockManager: PrivacyLockManager
    @EnvironmentObject var appState: AppState
    
    @State private var showProfileSetup = false
    @State private var showSubscription = false
    @State private var showDiscoverGentlerCoparent = false
    @State private var showKeyFeatures = false
    @State private var showPrivacyPolicy = false
    @State private var showSecurityFAQ = false
    @State private var showAppSettings = false
    @State private var showRealWorldExamples = false
    @State private var showBenefitsForAttorneys = false
    @State private var showAboutTheCreators = false
    @State private var showTermsOfUse = false
    @State private var showShareSheet = false
    @State private var showDeleteAllDataAlert = false
    @State private var showSyncPreferences = false
    @State private var showConflictResolution = false
    @StateObject private var syncStatusManager = SyncStatusManager()
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "Version \(version) (\(build))"
    }
    
    private var profileFirstName: String? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data),
              !profile.userFirstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return profile.userFirstName
    }

    var body: some View {
        List {
            // MARK: Profile header
            Section {
                Button {
                    showProfileSetup = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(GCPTheme.mint.opacity(0.7))
                                .frame(width: 56, height: 56)
                            Text(profileInitials)
                                .font(GCPTheme.title(20))
                                .foregroundStyle(GCPTheme.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileFirstName.map { "Hi, \($0)" } ?? "Family profile")
                                .font(GCPTheme.title(18))
                                .foregroundStyle(GCPTheme.primary)
                            Text(profileFirstName == nil
                                 ? "Add names & kids for better guidance"
                                 : "Tap to edit family details")
                                .font(GCPTheme.caption(13))
                                .foregroundStyle(GCPTheme.primary.opacity(0.7))
                        }
                        
                        Spacer(minLength: 8)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(GCPTheme.primary.opacity(0.35))
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(GCPTheme.cardFill)
            }
            
            // MARK: Account
            Section {
                settingsRow(icon: "person.crop.circle", title: "Family Profile", subtitle: "Names, kids, conflict level") {
                    showProfileSetup = true
                }
                settingsRow(icon: "creditcard", title: "Subscription", subtitle: "Manage plan & billing") {
                    showSubscription = true
                }
                settingsRow(icon: "slider.horizontal.3", title: "Preferences", subtitle: "Sounds, haptics & privacy lock") {
                    showAppSettings = true
                }
            } header: {
                sectionHeader("Account")
            }
            
            // MARK: Data & Sync
            Section {
                SyncStatusIndicator(syncManager: syncStatusManager)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(GCPTheme.cardFill)
                
                settingsRow(icon: "gearshape.2", title: "Sync Settings", subtitle: "Choose what syncs with iCloud") {
                    showSyncPreferences = true
                }
                
                Button {
                    syncStatusManager.performManualSync()
                } label: {
                    HStack(spacing: 12) {
                        SettingsIconBadge(systemName: "arrow.clockwise.icloud")
                        Text("Sync Now")
                            .font(GCPTheme.body(16))
                            .foregroundStyle(GCPTheme.primary)
                        Spacer()
                        if syncStatusManager.syncStatus == .syncing {
                            ProgressView()
                                .tint(GCPTheme.primary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .disabled(syncStatusManager.syncStatus == .syncing)
                .listRowBackground(GCPTheme.cardFill)
                
                if !syncStatusManager.syncConflicts.isEmpty {
                    settingsRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Resolve Conflicts",
                        subtitle: "\(syncStatusManager.syncConflicts.count) item\(syncStatusManager.syncConflicts.count == 1 ? "" : "s") need attention",
                        badgeTint: .orange,
                        badgeBackground: Color.orange.opacity(0.15)
                    ) {
                        showConflictResolution = true
                    }
                }
            } header: {
                sectionHeader("Data & Sync")
            } footer: {
                Text("Sync keeps your profile and bookmarks available across your devices signed into the same iCloud account.")
                    .font(GCPTheme.caption(12))
                    .foregroundStyle(GCPTheme.primary.opacity(0.65))
            }
            
            // MARK: Learn
            Section {
                settingsRow(icon: "play.circle.fill", title: "Watch Overview", subtitle: "How Gentler Coparent works") {
                    showDiscoverGentlerCoparent = true
                }
                settingsRow(icon: "sparkles", title: "Key Features", subtitle: "What you can do in the app") {
                    showKeyFeatures = true
                }
                settingsRow(icon: "text.bubble", title: "Real-World Examples", subtitle: "Sample situations & replies") {
                    showRealWorldExamples = true
                }
                settingsRow(icon: "briefcase.fill", title: "For Attorneys", subtitle: "How counsel can use GCP") {
                    showBenefitsForAttorneys = true
                }
                settingsRow(icon: "heart.circle.fill", title: "About the Creators", subtitle: "Why this app exists") {
                    showAboutTheCreators = true
                }
            } header: {
                sectionHeader("Learn")
            }
            
            // MARK: Privacy & Legal
            Section {
                settingsRow(icon: "shield.checkered", title: "Security FAQs", subtitle: "How we protect your data") {
                    showSecurityFAQ = true
                }
                settingsRow(icon: "lock.shield", title: "Privacy Policy") {
                    showPrivacyPolicy = true
                }
                settingsRow(icon: "doc.text", title: "Terms of Use") {
                    showTermsOfUse = true
                }
            } header: {
                sectionHeader("Privacy & Legal")
            }
            
            // MARK: Support
            Section {
                Button {
                    if let url = URL(string: "itms-apps://apps.apple.com/app/id6742896499?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 12) {
                        SettingsIconBadge(
                            systemName: "star.fill",
                            tint: .white,
                            background: GCPTheme.primary
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rate Gentler Coparent")
                                .font(GCPTheme.body(16))
                                .foregroundStyle(GCPTheme.primary)
                            Text("Share feedback on the App Store")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(GCPTheme.primary.opacity(0.65))
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.orange.opacity(0.9))
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(GCPTheme.cardFill)
                
                settingsRow(icon: "square.and.arrow.up", title: "Share with a Friend") {
                    showShareSheet = true
                }
            } header: {
                sectionHeader("Support")
            }
            
            // MARK: Danger zone
            Section {
                Button(role: .destructive) {
                    showDeleteAllDataAlert = true
                } label: {
                    HStack(spacing: 12) {
                        SettingsIconBadge(
                            systemName: "trash.fill",
                            tint: .white,
                            background: Color.red.opacity(0.85)
                        )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete All Data")
                                .font(GCPTheme.body(16))
                                .foregroundStyle(.red)
                            Text("Profile, chats, documents & settings")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(Color.red.opacity(0.7))
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .listRowBackground(GCPTheme.cardFill)
            } header: {
                sectionHeader("Data Management")
            } footer: {
                Text("This permanently erases local data on this device. It cannot be undone.")
                    .font(GCPTheme.caption(12))
            }
            
            // MARK: Version
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Gentler Coparent")
                            .font(GCPTheme.bodyMedium(13))
                            .foregroundStyle(GCPTheme.primary.opacity(0.75))
                        Text(appVersionString)
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(GCPTheme.primary.opacity(0.5))
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(GCPTheme.canvas.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if showsDismissButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSettings = false }
                        .font(GCPTheme.bodyMedium(16))
                        .foregroundStyle(GCPTheme.primary)
                }
            }
        }
        .toolbarBackground(GCPTheme.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showProfileSetup) {
            ProfileSetupView()
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView(showSubscription: $showSubscription)
        }
        .sheet(isPresented: $showDiscoverGentlerCoparent) {
            DiscoverGentlerCoparentView()
        }
        .sheet(isPresented: $showKeyFeatures) {
            KeyFeaturesView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showSecurityFAQ) {
            SecurityFAQView()
        }
        .sheet(isPresented: $showAppSettings) {
            AppSettingsSheet()
                .environmentObject(audioManager)
                .environmentObject(appState)
                .environmentObject(privacyLockManager)
        }
        .sheet(isPresented: $showRealWorldExamples) {
            RealWorldExamplesView()
        }
        .sheet(isPresented: $showBenefitsForAttorneys) {
            BenefitsForAttorneysView()
        }
        .sheet(isPresented: $showAboutTheCreators) {
            AboutTheCreatorsView()
        }
        .sheet(isPresented: $showTermsOfUse) {
            SafariView(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(url: URL(string: "https://apps.apple.com/us/app/gentler-coparent/id6742896499")!)
        }
        .sheet(isPresented: $showSyncPreferences) {
            SyncPreferencesView(
                showSyncPreferences: $showSyncPreferences,
                syncManager: syncStatusManager
            )
        }
        .sheet(isPresented: $showConflictResolution) {
            SyncConflictResolutionView(
                showConflictResolution: $showConflictResolution,
                syncManager: syncStatusManager
            )
        }
        .alert("Delete All Data?", isPresented: $showDeleteAllDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) {
                performDeleteAllData()
            }
        } message: {
            Text("This permanently deletes your family profile, conversation history, stored documents, and app settings on this device. You will need to set up again.")
        }
    }
    
    // MARK: - Row builders
    private var profileInitials: String {
        if let name = profileFirstName, let first = name.first {
            return String(first).uppercased()
        }
        return "GC"
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(GCPTheme.caption(12))
            .foregroundStyle(GCPTheme.primary.opacity(0.7))
            .tracking(0.6)
    }
    
    private func settingsRow(
        icon: String,
        title: String,
        subtitle: String? = nil,
        badgeTint: Color = GCPTheme.primary,
        badgeBackground: Color = GCPTheme.mint.opacity(0.55),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIconBadge(systemName: icon, tint: badgeTint, background: badgeBackground)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(GCPTheme.primary.opacity(0.65))
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GCPTheme.primary.opacity(0.3))
            }
            .contentShape(Rectangle())
        }
        .listRowBackground(GCPTheme.cardFill)
    }
    
    // MARK: - Data Management
    private func performDeleteAllData() {
        let userDefaults = UserDefaults.standard
        let keysToRemove = [
            "userProfile",
            "bookmarkedMessages",
            "chatHistory",
            "conversationContexts",
            "recurringThemes",
            "documentStorage",
            "EnableAppPrivacyLock",
            "onboardingCompleted"
        ]
        for key in keysToRemove {
            userDefaults.removeObject(forKey: key)
        }
        userDefaults.synchronize()
        
        while !documentStorageManager.storedDocuments.isEmpty {
            if let firstDoc = documentStorageManager.storedDocuments.first {
                documentStorageManager.deleteDocument(id: firstDoc.id)
            } else {
                break
            }
        }
        
        clearAppDocumentsDirectory()
        audioManager.isSoundEnabled = true
        audioManager.isHapticsEnabled = true
        privacyLockManager.forceDisable()
        appState.isAuthenticated = false
        showSettings = false
    }
    
    private func clearAppDocumentsDirectory() {
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let contents = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("⚠️ Error clearing Documents directory: \(error)")
        }
    }
}

// MARK: - Legacy row (still used by a few older sheets)
struct SettingsMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIconBadge(systemName: icon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(GCPTheme.body(16))
                        .foregroundStyle(GCPTheme.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(GCPTheme.caption(12))
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GCPTheme.primary.opacity(0.35))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share / Safari
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Real-world examples (modern content)
struct RealWorldExamplesView: View {
    private let examples: [(icon: String, title: String, situation: String, sample: String)] = [
        (
            "clock.arrow.circlepath",
            "Late pickup",
            "The other parent is running late and texts angrily about “your schedule.”",
            "“Thanks for the update. Confirming you’ll drop off at 6:15 at the usual location. Text me when you’re 10 minutes out.”"
        ),
        (
            "dollarsign.circle",
            "Shared expense",
            "You need reimbursement for a medical copay without starting a fight.",
            "“Sharing the $40 copay from Maya’s 3/12 visit (receipt attached). Per our order, half is $20. Venmo or Zelle by Friday works—thanks.”"
        ),
        (
            "calendar",
            "Holiday schedule",
            "You want a clear Thanksgiving plan without reopening old arguments.",
            "“Proposing Thanksgiving: I have the kids Wed 5pm–Fri 10am; you have Fri 10am–Sun 5pm. If that conflicts with the order, tell me which provision to follow.”"
        ),
        (
            "hand.raised",
            "Boundary when baited",
            "A message is full of personal attacks; you only need a logistics answer.",
            "“I’m not going to discuss personal comments. Pickup is Friday at 5:00 at school. Please confirm.”"
        )
    ]
    
    var body: some View {
        SettingsDetailShell(title: "Real-World Examples") {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Practical situations with send-ready sample replies. Adapt names, times, and details to your family.")
                        .font(GCPTheme.body(15))
                        .foregroundStyle(GCPTheme.primary.opacity(0.85))
                        .padding(.bottom, 4)
                    
                    ForEach(Array(examples.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                SettingsIconBadge(systemName: item.icon)
                                Text(item.title)
                                    .font(GCPTheme.title(17))
                                    .foregroundStyle(GCPTheme.primary)
                            }
                            Text(item.situation)
                                .font(GCPTheme.body(14))
                                .foregroundStyle(GCPTheme.primary.opacity(0.8))
                            Text("Sample reply")
                                .font(GCPTheme.caption(12))
                                .foregroundStyle(GCPTheme.primary.opacity(0.55))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text(item.sample)
                                .font(GCPTheme.body(14))
                                .foregroundStyle(GCPTheme.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(GCPTheme.mint.opacity(0.35))
                                )
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                                .fill(GCPTheme.cardFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                                .stroke(GCPTheme.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Security FAQs (modern content, no third-party AI branding)
struct SecurityFAQView: View {
    private let faqs: [(q: String, a: String)] = [
        (
            "Is my co-parenting information kept private?",
            "Yes. Gentler Coparent is built so your family details, documents, and conversations stay tied to your use of the app. We design for privacy-first co-parenting—not public sharing of your situation."
        ),
        (
            "Is my data used to train public AI models?",
            "No. Content you share in Gentler Coparent is used to help you in that conversation. It is not used to train public third-party AI products."
        ),
        (
            "Can other users see what I write?",
            "No. Your chats and profile are for your account and device experience. Other people using Gentler Coparent do not get access to your private conversations."
        ),
        (
            "How is my data protected?",
            "We use modern security practices including encrypted transport, access controls, and careful handling of sensitive documents. You can also enable Face ID / Touch ID lock in Preferences for an extra layer on-device."
        ),
        (
            "What if I want everything removed?",
            "Use Delete All Data in Settings to erase profile, chats, documents, and local settings on this device. Contact support if you need help with account-related questions."
        )
    ]
    
    var body: some View {
        SettingsDetailShell(title: "Security FAQs") {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(faqs.enumerated()), id: \.offset) { _, item in
                        SettingsInfoCard(icon: "shield.lefthalf.filled", title: item.q, detail: item.a)
                    }
                }
                .padding(16)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(showSettings: .constant(true), showsDismissButton: true)
    }
}
