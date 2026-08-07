import SwiftUI
import Foundation

// MARK: - Isolated Sync UI Components
struct SyncStatusIndicator: View {
    @ObservedObject var syncManager: SyncStatusManager
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text("iCloud Sync")
                    .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
                    .foregroundColor(Color(hex: "388083"))
                
                Text(syncManager.syncStatus.displayText)
                    .font(Font.custom("Avenir-Book", size: 12))
                    .foregroundColor(Color(hex: syncManager.syncStatus.colorHex))
                
                if let lastSync = syncManager.lastSyncTime {
                    Text("Last: \(lastSync, formatter: lastSyncFormatter)")
                        .font(Font.custom("Avenir-Book", size: 10))
                        .foregroundColor(Color(hex: "388083").opacity(0.6))
                }
            }
            
            Spacer()
            
            if syncManager.syncStatus == .syncing {
                progressIndicators
            }
            
            if !syncManager.pendingChanges.isEmpty {
                pendingChangesIndicator
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var statusIcon: some View {
        Group {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "icloud")
            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath.icloud")
                    .foregroundColor(.blue)
            case .completed:
                Image(systemName: "icloud.and.arrow.up")
                    .foregroundColor(Color(hex: "C2EDCE"))
            case .failed:
                Image(systemName: "icloud.slash")
                    .foregroundColor(.red)
            case .conflictsDetected:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundColor(.orange)
            }
        }
        .font(.system(size: 16, weight: .medium))
    }
    
    private var progressIndicators: some View {
        VStack(spacing: 4) {
            ProgressView(value: syncManager.uploadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "388083")))
                .scaleEffect(x: 1, y: 0.5)
                .frame(width: 40)
            
            ProgressView(value: syncManager.downloadProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "C2EDCE")))
                .scaleEffect(x: 1, y: 0.5)
                .frame(width: 40)
        }
    }
    
    private var pendingChangesIndicator: some View {
        Text("\(syncManager.pendingChanges.count)")
            .font(Font.custom("Avenir-Book", size: 11).weight(.bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 18)
            .background(Color.orange)
            .clipShape(Circle())
    }
}

struct ManualSyncButton: View {
    @ObservedObject var syncManager: SyncStatusManager
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                syncIcon
                
                Text(syncManager.syncStatus == .syncing ? "Syncing..." : "Sync Now")
                    .font(Font.custom("Avenir-Book", size: 14).weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [Color(hex: "388083"), Color(hex: "C2EDCE")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(8)
        }
        .disabled(syncManager.syncStatus == .syncing)
        .opacity(syncManager.syncStatus == .syncing ? 0.7 : 1.0)
    }
    
    private var syncIcon: some View {
        Image(systemName: syncManager.syncStatus == .syncing ? "arrow.clockwise" : "arrow.clockwise.icloud")
            .font(.system(size: 16, weight: .medium))
            .rotationEffect(.degrees(syncManager.syncStatus == .syncing ? 360 : 0))
            .animation(
                syncManager.syncStatus == .syncing ? 
                Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                Animation.default,
                value: syncManager.syncStatus
            )
    }
}

// MARK: - Private Helpers
private let lastSyncFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - Preview Provider
struct SyncUIComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SyncStatusIndicator(syncManager: SyncStatusManager())
            ManualSyncButton(syncManager: SyncStatusManager()) {}
        }
        .padding()
        .background(Color(hex: "BADFE7"))
    }
}