import SwiftUI

// MARK: - Sync Transparency View (Clean Version)
struct SyncTransparencyView: View {
    @Binding var showSyncTransparency: Bool
    @ObservedObject var syncManager: SyncStatusManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status Header
                    SyncStatusIndicator(syncManager: syncManager)
                        .padding(.horizontal, 16)
                    
                    // Manual Sync Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manual Sync")
                            .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                            .foregroundColor(Color(hex: "388083"))
                            .padding(.horizontal, 16)
                        
                        ManualSyncButton(syncManager: syncManager) {
                            syncManager.performManualSync()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Conflicts Section
                    if !syncManager.syncConflicts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sync Conflicts")
                                .font(Font.custom("Avenir-Book", size: 18).weight(.bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                            
                            Text("\(syncManager.syncConflicts.count) conflicts need your attention")
                                .font(Font.custom("Avenir-Book", size: 14))
                                .foregroundColor(Color(hex: "388083").opacity(0.7))
                                .padding(.horizontal, 16)
                        }
                    }
                    
                    Spacer(minLength: 32)
                }
                .padding(.top, 16)
            }
            .background(Color(hex: "BADFE7"))
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        showSyncTransparency = false
                    }
                }
            }
        }
    }
}

struct SyncTransparencyView_Previews: PreviewProvider {
    static var previews: some View {
        SyncTransparencyView(
            showSyncTransparency: .constant(true),
            syncManager: SyncStatusManager()
        )
    }
}