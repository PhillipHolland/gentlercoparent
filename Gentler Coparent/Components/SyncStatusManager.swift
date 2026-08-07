import Foundation
import Combine

// MARK: - Isolated Sync Status Manager (No SwiftUI dependencies)
@MainActor
final class SyncStatusManager: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var syncConflicts: [SyncConflict] = []
    @Published var syncPreferences = SyncPreferences()
    @Published var uploadProgress: Double = 0.0
    @Published var downloadProgress: Double = 0.0
    @Published var pendingChanges: [PendingChange] = []
    
    private let iCloudSync = iCloudSyncManager.shared
    
    init() {
        loadSyncPreferences()
        detectPendingChanges()
    }
    
    func performManualSync() {
        guard syncStatus != .syncing else { return }
        
        syncStatus = .syncing
        uploadProgress = 0.0
        downloadProgress = 0.0
        
        Task {
            do {
                if syncPreferences.syncProfile && pendingChanges.contains(where: { $0.type == .profile }) {
                    await updateUploadProgress(to: 0.25)
                    try await uploadProfileChanges()
                }
                
                if syncPreferences.syncBookmarks && pendingChanges.contains(where: { $0.type == .bookmarks }) {
                    await updateUploadProgress(to: 0.5)
                    try await uploadBookmarkChanges()
                }
                
                if syncPreferences.syncSettings && pendingChanges.contains(where: { $0.type == .settings }) {
                    await updateUploadProgress(to: 0.75)
                    try await uploadSettingsChanges()
                }
                
                await updateUploadProgress(to: 1.0)
                await updateDownloadProgress(to: 0.33)
                
                let conflicts = try await detectConflicts()
                
                await updateDownloadProgress(to: 0.66)
                if conflicts.isEmpty {
                    try await downloadAllChanges()
                } else {
                    await MainActor.run {
                        self.syncConflicts = conflicts
                        self.syncStatus = .conflictsDetected
                    }
                    return
                }
                
                await updateDownloadProgress(to: 1.0)
                
                await MainActor.run {
                    self.syncStatus = .completed
                    self.lastSyncTime = Date()
                    self.pendingChanges.removeAll()
                    self.saveSyncPreferences()
                }
                
                try await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    self.syncStatus = .idle
                }
                
            } catch {
                await MainActor.run {
                    self.syncStatus = .failed(error.localizedDescription)
                }
                
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    self.syncStatus = .idle
                }
            }
        }
    }
    
    func resolveConflict(_ conflict: SyncConflict, resolution: ConflictResolution) {
        switch resolution {
        case .useLocal:
            Task {
                do {
                    try await uploadSpecificChange(conflict.type)
                    self.syncConflicts.removeAll { $0.id == conflict.id }
                    if self.syncConflicts.isEmpty {
                        self.syncStatus = .idle
                    }
                } catch {
                    self.syncStatus = .failed(error.localizedDescription)
                }
            }
        case .useRemote:
            Task {
                do {
                    try await downloadSpecificChange(conflict.type)
                    self.syncConflicts.removeAll { $0.id == conflict.id }
                    if self.syncConflicts.isEmpty {
                        self.syncStatus = .idle
                    }
                } catch {
                    self.syncStatus = .failed(error.localizedDescription)
                }
            }
        case .merge:
            Task {
                do {
                    try await performMerge(conflict)
                    self.syncConflicts.removeAll { $0.id == conflict.id }
                    if self.syncConflicts.isEmpty {
                        self.syncStatus = .idle
                    }
                } catch {
                    self.syncStatus = .failed(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func updateUploadProgress(to value: Double) async {
        await MainActor.run {
            self.uploadProgress = value
        }
    }
    
    private func updateDownloadProgress(to value: Double) async {
        await MainActor.run {
            self.downloadProgress = value
        }
    }
    
    private func uploadProfileChanges() async throws {
        try await withCheckedThrowingContinuation { continuation in
            iCloudSync.syncUserProfile(UserDefaults.standard.data(forKey: "userProfile") ?? Data()) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func uploadBookmarkChanges() async throws {
        try await withCheckedThrowingContinuation { continuation in
            iCloudSync.syncBookmarkedMessages(UserDefaults.standard.data(forKey: "bookmarkedMessages") ?? Data()) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func uploadSettingsChanges() async throws {
        try await withCheckedThrowingContinuation { continuation in
            iCloudSync.syncAppSettings(UserDefaults.standard.data(forKey: "appSettings") ?? Data()) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    private func detectConflicts() async throws -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        if pendingChanges.contains(where: { $0.type == .profile }) {
            conflicts.append(SyncConflict(
                id: UUID(),
                type: .profile,
                localModified: Date(),
                remoteModified: Date().addingTimeInterval(-300),
                description: "Profile has been modified on both this device and in iCloud"
            ))
        }
        
        return conflicts
    }
    
    private func downloadAllChanges() async throws {
        if syncPreferences.syncProfile {
            try await downloadSpecificChange(.profile)
        }
        if syncPreferences.syncBookmarks {
            try await downloadSpecificChange(.bookmarks)
        }
        if syncPreferences.syncSettings {
            try await downloadSpecificChange(.settings)
        }
    }
    
    private func downloadSpecificChange(_ type: SyncDataType) async throws {
        switch type {
        case .profile:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.restoreUserProfile { result in
                    continuation.resume(with: result.map { _ in () })
                }
            }
        case .bookmarks:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.restoreBookmarkedMessages { result in
                    continuation.resume(with: result.map { _ in () })
                }
            }
        case .settings:
            break
        case .chatHistory:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.restoreChatHistory { result in
                    continuation.resume(with: result.map { _ in () })
                }
            }
        case .journalEntries:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.restoreJournalEntries { result in
                    continuation.resume(with: result.map { _ in () })
                }
            }
        }
    }
    
    private func uploadSpecificChange(_ type: SyncDataType) async throws {
        switch type {
        case .profile:
            try await uploadProfileChanges()
        case .bookmarks:
            try await uploadBookmarkChanges()
        case .settings:
            try await uploadSettingsChanges()
        case .chatHistory:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.syncChatHistory(UserDefaults.standard.data(forKey: "chatHistory") ?? Data()) { result in
                    continuation.resume(with: result)
                }
            }
        case .journalEntries:
            try await withCheckedThrowingContinuation { continuation in
                iCloudSync.syncJournalEntries(UserDefaults.standard.data(forKey: "journalEntries") ?? Data()) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    private func performMerge(_ conflict: SyncConflict) async throws {
        switch conflict.type {
        case .profile:
            try await mergeProfiles()
        case .bookmarks:
            try await mergeBookmarks()
        default:
            try await uploadSpecificChange(conflict.type)
        }
    }
    
    private func mergeProfiles() async throws {
        try await uploadProfileChanges()
    }
    
    private func mergeBookmarks() async throws {
        try await uploadBookmarkChanges()
    }
    
    private func detectPendingChanges() {
        pendingChanges.removeAll()
        
        if let lastSync = lastSyncTime {
            if let profileModified = UserDefaults.standard.object(forKey: "userProfileLastModified") as? Date,
               profileModified > lastSync {
                pendingChanges.append(PendingChange(type: .profile, modifiedAt: profileModified))
            }
            
            if let bookmarksModified = UserDefaults.standard.object(forKey: "bookmarksLastModified") as? Date,
               bookmarksModified > lastSync {
                pendingChanges.append(PendingChange(type: .bookmarks, modifiedAt: bookmarksModified))
            }
        }
    }
    
    private func loadSyncPreferences() {
        if let data = UserDefaults.standard.data(forKey: "syncPreferences"),
           let preferences = try? JSONDecoder().decode(SyncPreferences.self, from: data) {
            syncPreferences = preferences
        }
        lastSyncTime = UserDefaults.standard.object(forKey: "lastSyncTime") as? Date
    }
    
    private func saveSyncPreferences() {
        if let data = try? JSONEncoder().encode(syncPreferences) {
            UserDefaults.standard.set(data, forKey: "syncPreferences")
        }
        UserDefaults.standard.set(lastSyncTime, forKey: "lastSyncTime")
    }
}