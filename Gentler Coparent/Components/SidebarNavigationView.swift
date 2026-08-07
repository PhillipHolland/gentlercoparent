import SwiftUI

// MARK: - Sidebar Navigation View for iPad
struct SidebarNavigationView: View {
    @EnvironmentObject var audioManager: AudioManager

    let onSettingsTap: () -> Void
    let onLearningTap: () -> Void
    let onJournalTap: () -> Void
    let onBookmarksTap: () -> Void
    let onHistoryTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "BADFE7"))

                Text("Gentler Coparent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.top, 40)

            Spacer()

            // Navigation Items
            VStack(spacing: 16) {
                NavigationSidebarButton(
                    imageName: "message.fill",
                    title: "Chat",
                    action: {
                        audioManager.triggerHapticFeedback(.success)
                        // Chat is the main view, no action needed
                    }
                )
                .foregroundColor(Color(hex: "BADFE7")) // Highlight current view

                NavigationSidebarButton(
                    imageName: "book.fill",
                    title: "Learning",
                    action: {
                        onLearningTap()
                        audioManager.triggerHapticFeedback(.success)
                    }
                )

                NavigationSidebarButton(
                    imageName: "journal",
                    title: "Journal",
                    action: {
                        onJournalTap()
                        audioManager.triggerHapticFeedback(.success)
                    }
                )

                NavigationSidebarButton(
                    imageName: "bookmark.fill",
                    title: "Bookmarks",
                    action: {
                        onBookmarksTap()
                        audioManager.triggerHapticFeedback(.success)
                    }
                )

                NavigationSidebarButton(
                    imageName: "clock.fill",
                    title: "History",
                    action: {
                        onHistoryTap()
                        audioManager.triggerHapticFeedback(.success)
                    }
                )

                NavigationSidebarButton(
                    imageName: "gear",
                    title: "Settings",
                    action: {
                        onSettingsTap()
                        audioManager.triggerHapticFeedback(.success)
                    }
                )
            }

            Spacer()

            // Footer
            VStack(spacing: 8) {
                Text("v1.1")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Divider()
                    .frame(width: 40)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(.separator)),
            alignment: .trailing
        )
    }
}

// MARK: - Sidebar Navigation Button Component
struct NavigationSidebarButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: imageName)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)

                Text(title)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 60)
            .padding(.vertical, 12)
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SidebarNavigationView(
        onSettingsTap: {},
        onLearningTap: {},
        onJournalTap: {},
        onBookmarksTap: {},
        onHistoryTap: {}
    )
    .environmentObject(AudioManager())
}