import SwiftUI

// MARK: - System TabView labels (SF Symbols — reliable on iOS 26)
enum GCPTabIcon {
    @ViewBuilder
    static func label(_ tab: GCPTab) -> some View {
        switch tab {
        case .chat:
            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
        case .journal:
            Label("Journal", systemImage: "book.closed.fill")
        case .bookmarks:
            Label("Bookmarks", systemImage: "bookmark.fill")
        case .history:
            Label("History", systemImage: "clock.arrow.circlepath")
        case .settings:
            Label("Settings", systemImage: "gearshape.fill")
        }
    }
}

// Legacy custom bar — unused.
struct BottomNavigationView: View {
    @EnvironmentObject var audioManager: AudioManager
    let onSettingsTap: () -> Void
    let onLearningTap: () -> Void
    let onJournalTap: () -> Void
    let onBookmarksTap: () -> Void
    let onHistoryTap: () -> Void

    var body: some View {
        EmptyView()
    }
}
