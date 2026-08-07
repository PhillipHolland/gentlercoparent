import Foundation
import SwiftUI

// MARK: - Sync Data Models (Isolated from SwiftUI-Introspect)
enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed
    case failed(String)
    case conflictsDetected
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Sync completed"
        case .failed(let error):
            return "Sync failed: \(error)"
        case .conflictsDetected:
            return "Conflicts detected"
        }
    }
    
    var colorHex: String {
        switch self {
        case .idle:
            return "388083"
        case .syncing:
            return "007AFF" // Blue
        case .completed:
            return "C2EDCE"
        case .failed:
            return "FF3B30" // Red
        case .conflictsDetected:
            return "FF9500" // Orange
        }
    }
}

struct SyncConflict: Identifiable {
    let id: UUID
    let type: SyncDataType
    let localModified: Date
    let remoteModified: Date
    let description: String
}

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}

enum SyncDataType: String, CaseIterable, Codable {
    case profile = "Profile"
    case bookmarks = "Bookmarks" 
    case settings = "Settings"
    case chatHistory = "Chat History"
    case journalEntries = "Journal Entries"
}

struct SyncPreferences: Codable {
    var syncProfile: Bool = true
    var syncBookmarks: Bool = true
    var syncSettings: Bool = true
    var syncChatHistory: Bool = true
    var syncJournalEntries: Bool = true
    var autoSyncEnabled: Bool = true
    var syncOnlyOnWiFi: Bool = true
}

struct PendingChange: Identifiable {
    let id = UUID()
    let type: SyncDataType
    let modifiedAt: Date
}