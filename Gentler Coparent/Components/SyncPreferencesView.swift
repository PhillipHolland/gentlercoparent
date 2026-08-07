import SwiftUI

// MARK: - Sync Preferences View
struct SyncPreferencesView: View {
    @Binding var showSyncPreferences: Bool
    @ObservedObject var syncManager: SyncStatusManager
    @State private var tempPreferences: SyncPreferences
    
    init(showSyncPreferences: Binding<Bool>, syncManager: SyncStatusManager) {
        self._showSyncPreferences = showSyncPreferences
        self.syncManager = syncManager
        self._tempPreferences = State(initialValue: syncManager.syncPreferences)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // iCloud Status Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("iCloud Status")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                            .foregroundColor(Color(hex: "388083"))
                        
                        iCloudStatusCard
                    }
                    
                    // What to Sync Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What to Sync")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                            .foregroundColor(Color(hex: "388083"))
                        
                        syncItemsList
                    }
                    
                    // Sync Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sync Settings")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                            .foregroundColor(Color(hex: "388083"))
                        
                        syncSettingsList
                    }
                    
                    // Advanced Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Advanced")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                            .foregroundColor(Color(hex: "388083"))
                        
                        advancedOptions
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(hex: "BADFE7"))
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showSyncPreferences = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSyncPreferences()
                        showSyncPreferences = false
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private var iCloudStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iCloudSyncManager.shared.isiCloudAvailable ? "checkmark.icloud" : "exclamationmark.icloud")
                    .font(.system(size: 24))
                    .foregroundColor(iCloudSyncManager.shared.isiCloudAvailable ? Color(hex: "C2EDCE") : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(iCloudSyncManager.shared.isiCloudAvailable ? "iCloud Available" : "iCloud Unavailable")
                        .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text(iCloudSyncManager.shared.isiCloudAvailable ? 
                         "Your data can sync across devices" : 
                         "Please check your iCloud settings")
                        .font(Font.custom("Avenir-Book", size: 14))
                        .foregroundColor(Color(hex: "388083").opacity(0.7))
                }
                
                Spacer()
            }
            
            if let lastSync = syncManager.lastSyncTime {
                Divider()
                HStack {
                    Text("Last sync:")
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                    
                    Text(lastSync, formatter: fullDateFormatter)
                        .font(Font.custom("Avenir-Book", size: 12).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Spacer()
                }
            }
            
            if !syncManager.pendingChanges.isEmpty {
                Divider()
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("\(syncManager.pendingChanges.count) pending change\(syncManager.pendingChanges.count == 1 ? "" : "s")")
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(.orange)
                    
                    Spacer()
                    
                    ManualSyncButton(syncManager: syncManager) {
                        syncManager.performManualSync()
                    }
                    .scaleEffect(0.8)
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
    }
    
    private var syncItemsList: some View {
        VStack(spacing: 12) {
            SyncToggleRow(
                icon: "person.circle",
                title: "Family Profile",
                description: "Your profile and family information",
                isEnabled: $tempPreferences.syncProfile,
                dataSize: getDataSize(.profile)
            )
            
            SyncToggleRow(
                icon: "bookmark.circle",
                title: "Bookmarked Messages",
                description: "Messages you've saved for reference",
                isEnabled: $tempPreferences.syncBookmarks,
                dataSize: getDataSize(.bookmarks)
            )
            
            SyncToggleRow(
                icon: "gearshape.circle",
                title: "App Settings",
                description: "Your preferences and configurations",
                isEnabled: $tempPreferences.syncSettings,
                dataSize: getDataSize(.settings)
            )
            
            SyncToggleRow(
                icon: "message.circle",
                title: "Chat History",
                description: "Your conversation history",
                isEnabled: $tempPreferences.syncChatHistory,
                dataSize: getDataSize(.chatHistory),
                isRecommended: true
            )
            
            SyncToggleRow(
                icon: "book.circle",
                title: "Journal Entries",
                description: "Your personal reflections and notes",
                isEnabled: $tempPreferences.syncJournalEntries,
                dataSize: getDataSize(.journalEntries)
            )
        }
    }
    
    private var syncSettingsList: some View {
        VStack(spacing: 12) {
            SettingsToggleRow(
                icon: "arrow.clockwise.circle",
                title: "Automatic Sync",
                description: "Sync changes automatically in the background",
                isEnabled: $tempPreferences.autoSyncEnabled
            )
            
            SettingsToggleRow(
                icon: "wifi.circle",
                title: "Wi-Fi Only",
                description: "Only sync when connected to Wi-Fi",
                isEnabled: $tempPreferences.syncOnlyOnWiFi
            )
        }
    }
    
    private var advancedOptions: some View {
        VStack(spacing: 12) {
            // Force Sync Button
            Button(action: {
                syncManager.performManualSync()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.icloud")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Force Full Sync")
                            .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                            .foregroundColor(Color(hex: "388083"))
                        
                        Text("Upload all data regardless of sync status")
                            .font(Font.custom("Avenir-Book", size: 12))
                            .foregroundColor(Color(hex: "388083").opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "388083").opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Reset Sync Data Button
            Button(action: {
                // Show confirmation alert for resetting sync data
            }) {
                HStack {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Sync Data")
                            .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                            .foregroundColor(.red)
                        
                        Text("Remove all synced data from iCloud")
                            .font(Font.custom("Avenir-Book", size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func saveSyncPreferences() {
        syncManager.syncPreferences = tempPreferences
    }
    
    private func getDataSize(_ type: SyncDataType) -> String {
        // Simplified data size calculation - in reality you'd check actual file sizes
        switch type {
        case .profile:
            return "< 1 KB"
        case .bookmarks:
            return "< 10 KB"
        case .settings:
            return "< 1 KB"
        case .chatHistory:
            return "~ 100 KB"
        case .journalEntries:
            return "< 50 KB"
        }
    }
}

// MARK: - Supporting Views
struct SyncToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    let dataSize: String
    var isRecommended: Bool = true
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "388083"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    if !isRecommended {
                        Text("NOT RECOMMENDED")
                            .font(Font.custom("Avenir-Book", size: 8).weight(.bold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
                
                Text(description)
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: "388083").opacity(0.7))
                
                Text(dataSize)
                    .font(Font.custom("Avenir-Book", size: 10))
                    .foregroundColor(Color(hex: "388083").opacity(0.5))
            }
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "388083")))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "388083"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom("Avenir-Book", size: 16).weight(.medium))
                    .foregroundColor(Color(hex: "388083"))
                
                Text(description)
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: "388083").opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "388083")))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

private let fullDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

struct SyncPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        SyncPreferencesView(
            showSyncPreferences: .constant(true),
            syncManager: SyncStatusManager()
        )
    }
}