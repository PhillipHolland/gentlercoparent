import Foundation
import CloudKit

// MARK: - Single CloudKit container for the whole app
/// Must match `Gentler_Coparent.entitlements` → `com.apple.developer.icloud-container-identifiers`.
/// Using `CKContainer.default()` keeps code aligned with the signed entitlements / provisioning profile
/// (hardcoded IDs that aren't on the App ID cause CKError 10 "Invalid bundle ID for container").
enum GCPCloudKit {
    
    /// Canonical container ID (same string as entitlements).
    static let containerIdentifier = "iCloud.com.pbh.Gentler-Coparent"
    
    /// Prefer the app’s default container (first entitlement = what the provisioning profile allows).
    /// Fall back to the explicit brand ID only if default is empty/wrong target.
    static var container: CKContainer {
        let defaultContainer = CKContainer.default()
        // containerIdentifier is String? on some SDKs
        guard let defaultID = defaultContainer.containerIdentifier, !defaultID.isEmpty else {
            return CKContainer(identifier: containerIdentifier)
        }
        // If default matches our entitlement (or is any valid iCloud.* from this app), use it.
        if defaultID == containerIdentifier || defaultID.hasPrefix("iCloud.") {
            return defaultContainer
        }
        return CKContainer(identifier: containerIdentifier)
    }
    
    static var privateDatabase: CKDatabase {
        container.privateCloudDatabase
    }
    
    /// Account + container probe. `accountStatus == .available` alone is not enough —
    /// a mis-associated container still fails on first query with "Invalid bundle ID for container".
    static func resolveAvailability() async -> (available: Bool, reason: String) {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                break
            case .noAccount:
                return (false, "No iCloud account signed in on device")
            case .restricted:
                return (false, "iCloud restricted (Screen Time / MDM)")
            case .couldNotDetermine:
                return (false, "Could not determine iCloud account status")
            case .temporarilyUnavailable:
                return (false, "iCloud temporarily unavailable")
            @unknown default:
                return (false, "Unknown iCloud account status")
            }
            
            // Touches the real container identity — fails fast if portal/signing is wrong
            _ = try await container.userRecordID()
            
            let id = container.containerIdentifier ?? containerIdentifier
            return (true, "CloudKit ready (\(id))")
            
        } catch let error as CKError {
            let hint = troubleshootingHint(for: error)
            return (false, "CloudKit unavailable: \(error.localizedDescription). \(hint)")
        } catch {
            return (false, "CloudKit unavailable: \(error.localizedDescription)")
        }
    }
    
    static func troubleshootingHint(for error: CKError) -> String {
        switch error.code {
        case .permissionFailure, .notAuthenticated, .networkUnavailable, .networkFailure:
            if error.localizedDescription.localizedCaseInsensitiveContains("bundle")
                || error.localizedDescription.localizedCaseInsensitiveContains("container") {
                return """
                Fix: Xcode → Signing & Capabilities → iCloud → enable CloudKit, \
                select container \(containerIdentifier) (or iCloud.$(CFBundleIdentifier)), \
                then Clean Build Folder, delete app, reinstall. \
                Also confirm this App ID has that iCloud container in the Apple Developer portal.
                """
            }
            return "Check iCloud sign-in and network."
        case .serverRejectedRequest, .invalidArguments:
            return "Deploy CloudKit schema (Development) in CloudKit Dashboard if record types are missing."
        case .quotaExceeded:
            return "iCloud storage full on this account."
        default:
            return "Local storage will be used until CloudKit works."
        }
    }
    
    /// Log once-friendly description of a CKError for memory sync paths.
    static func logFailure(_ prefix: String, error: Error) {
        if let ck = error as? CKError {
            print("❌ \(prefix): \(ck.localizedDescription) [CKError \(ck.code.rawValue)]")
            print("   \(troubleshootingHint(for: ck))")
            print("   Container in use: \(container.containerIdentifier ?? containerIdentifier)")
        } else {
            print("❌ \(prefix): \(error.localizedDescription)")
        }
    }
}
