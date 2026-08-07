import SwiftUI

// MARK: - Sync Conflict Resolution View
struct SyncConflictResolutionView: View {
    @Binding var showConflictResolution: Bool
    @ObservedObject var syncManager: SyncStatusManager
    @State private var selectedResolutions: [UUID: ConflictResolution] = [:]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header explanation
                    conflictExplanationHeader
                    
                    // Conflicts list
                    LazyVStack(spacing: 16) {
                        ForEach(syncManager.syncConflicts) { conflict in
                            ConflictResolutionCard(
                                conflict: conflict,
                                selectedResolution: binding(for: conflict.id),
                                onResolve: { resolution in
                                    resolveConflict(conflict, with: resolution)
                                }
                            )
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(hex: "BADFE7"))
            .navigationTitle("Sync Conflicts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showConflictResolution = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    resolveAllButton
                }
            }
        }
    }
    
    private var conflictExplanationHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conflicts Detected")
                        .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text("Your data has been modified on multiple devices")
                        .font(Font.custom("Avenir-Book", size: 14))
                        .foregroundColor(Color(hex: "388083").opacity(0.7))
                }
                
                Spacer()
            }
            
            Text("Please choose how to resolve each conflict. Your choice will determine which version of the data to keep.")
                .font(Font.custom("Avenir-Book", size: 12))
                .foregroundColor(Color(hex: "388083").opacity(0.6))
                .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var resolveAllButton: some View {
        Button("Resolve All") {
            resolveAllConflicts()
        }
        .fontWeight(.bold)
        .disabled(selectedResolutions.count != syncManager.syncConflicts.count)
    }
    
    private func binding(for conflictId: UUID) -> Binding<ConflictResolution?> {
        Binding(
            get: { selectedResolutions[conflictId] },
            set: { selectedResolutions[conflictId] = $0 }
        )
    }
    
    private func resolveConflict(_ conflict: SyncConflict, with resolution: ConflictResolution) {
        syncManager.resolveConflict(conflict, resolution: resolution)
        selectedResolutions.removeValue(forKey: conflict.id)
        
        // Close if no more conflicts
        if syncManager.syncConflicts.isEmpty {
            showConflictResolution = false
        }
    }
    
    private func resolveAllConflicts() {
        for conflict in syncManager.syncConflicts {
            if let resolution = selectedResolutions[conflict.id] {
                syncManager.resolveConflict(conflict, resolution: resolution)
            }
        }
        selectedResolutions.removeAll()
        showConflictResolution = false
    }
}

// MARK: - Conflict Resolution Card
struct ConflictResolutionCard: View {
    let conflict: SyncConflict
    @Binding var selectedResolution: ConflictResolution?
    let onResolve: (ConflictResolution) -> Void
    
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Conflict header
            conflictHeader
            
            // Resolution options
            resolutionOptions
            
            // Details toggle
            detailsSection
            
            // Action button
            if selectedResolution != nil {
                actionButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private var conflictHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForDataType(conflict.type))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "388083"))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conflict.type.rawValue)
                        .font(Font.custom("Avenir-Book", size: 16).weight(.bold))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Text(conflict.description)
                        .font(Font.custom("Avenir-Book", size: 12))
                        .foregroundColor(Color(hex: "388083").opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CONFLICT")
                        .font(Font.custom("Avenir-Book", size: 8).weight(.bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Device")
                        .font(Font.custom("Avenir-Book", size: 10).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    Text(conflict.localModified, formatter: conflictDateFormatter)
                        .font(Font.custom("Avenir-Book", size: 9))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("iCloud")
                        .font(Font.custom("Avenir-Book", size: 10).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    Text(conflict.remoteModified, formatter: conflictDateFormatter)
                        .font(Font.custom("Avenir-Book", size: 9))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var resolutionOptions: some View {
        VStack(spacing: 8) {
            ResolutionOptionButton(
                title: "Use This Device",
                description: "Keep the version on this device",
                icon: "iphone",
                isSelected: selectedResolution == .useLocal,
                onTap: { selectedResolution = .useLocal }
            )
            
            ResolutionOptionButton(
                title: "Use iCloud Version",
                description: "Keep the version from iCloud",
                icon: "icloud",
                isSelected: selectedResolution == .useRemote,
                onTap: { selectedResolution = .useRemote }
            )
            
            if canMerge(conflict.type) {
                ResolutionOptionButton(
                    title: "Merge Both",
                    description: "Combine data from both versions",
                    icon: "arrow.triangle.merge",
                    isSelected: selectedResolution == .merge,
                    onTap: { selectedResolution = .merge }
                )
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { showDetails.toggle() }) {
                HStack {
                    Text("View Details")
                        .font(Font.custom("Avenir-Book", size: 12).weight(.medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "388083"))
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if showDetails {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This Device Version:")
                            .font(Font.custom("Avenir-Book", size: 11).weight(.medium))
                            .foregroundColor(Color(hex: "388083"))
                        
                        Text(getPreviewText(for: conflict.type, isLocal: true))
                            .font(Font.custom("Avenir-Book", size: 10))
                            .foregroundColor(Color(hex: "388083").opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "C2EDCE").opacity(0.2))
                            .cornerRadius(6)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iCloud Version:")
                            .font(Font.custom("Avenir-Book", size: 11).weight(.medium))
                            .foregroundColor(Color(hex: "388083"))
                        
                        Text(getPreviewText(for: conflict.type, isLocal: false))
                            .font(Font.custom("Avenir-Book", size: 10))
                            .foregroundColor(Color(hex: "388083").opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showDetails)
    }
    
    private var actionButton: some View {
        Button(action: {
            if let resolution = selectedResolution {
                onResolve(resolution)
            }
        }) {
            Text("Resolve Conflict")
                .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "388083"), Color(hex: "C2EDCE")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func iconForDataType(_ type: SyncDataType) -> String {
        switch type {
        case .profile:
            return "person.circle"
        case .bookmarks:
            return "bookmark.circle"
        case .settings:
            return "gearshape.circle"
        case .chatHistory:
            return "message.circle"
        case .journalEntries:
            return "book.circle"
        }
    }
    
    private func canMerge(_ type: SyncDataType) -> Bool {
        // Only certain data types support merging
        switch type {
        case .bookmarks, .journalEntries:
            return true
        case .profile, .settings, .chatHistory:
            return false
        }
    }
    
    private func getPreviewText(for type: SyncDataType, isLocal: Bool) -> String {
        // This would show actual data previews in a real implementation
        switch type {
        case .profile:
            return isLocal ? "Profile updated on this device with new address" : "Profile updated in iCloud with new phone number"
        case .bookmarks:
            return isLocal ? "3 bookmarks, last added: \"Effective Communication\"" : "5 bookmarks, last added: \"Conflict Resolution\""
        case .settings:
            return isLocal ? "Notifications: ON, Auto-sync: OFF" : "Notifications: OFF, Auto-sync: ON"
        case .chatHistory:
            return "Chat history differences detected"
        case .journalEntries:
            return isLocal ? "2 entries, last: \"Reflection on custody meeting\"" : "4 entries, last: \"Thoughts on co-parenting progress\""
        }
    }
}

// MARK: - Resolution Option Button
struct ResolutionOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "388083"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                        .foregroundColor(isSelected ? .white : Color(hex: "388083"))
                    
                    Text(description)
                        .font(Font.custom("Avenir-Book", size: 11))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : Color(hex: "388083").opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          LinearGradient(colors: [Color(hex: "388083"), Color(hex: "C2EDCE")], startPoint: .leading, endPoint: .trailing) :
                          LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.clear : Color(hex: "388083").opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private let conflictDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct SyncConflictResolutionView_Previews: PreviewProvider {
    static var previews: some View {
        SyncConflictResolutionView(
            showConflictResolution: .constant(true),
            syncManager: SyncStatusManager()
        )
    }
}