import SwiftUI
#if canImport(AVKit)
import AVKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// Custom subclass of AVPlayerViewController to force controls visibility
#if canImport(AVKit)
class CustomAVPlayerViewController: AVPlayerViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Force controls to be visible on appearance
        showsPlaybackControls = true
        // Ensure controls don’t auto-hide immediately
        #if canImport(UIKit)
        if let playerLayerView = view.subviews.first?.subviews.first as? UIView {
            playerLayerView.isUserInteractionEnabled = true
            // Simulate a tap to keep controls visible (if needed)
            let tap = UITapGestureRecognizer(target: self, action: nil)
            playerLayerView.addGestureRecognizer(tap)
            playerLayerView.removeGestureRecognizer(tap)
        }
        #endif
    }
}

// Custom wrapper for CustomAVPlayerViewController in SwiftUI
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> CustomAVPlayerViewController {
        let controller = CustomAVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true // Show play/pause, full-screen, etc.
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CustomAVPlayerViewController, context: Context) {
        // No updates needed for static video
    }
}
#else
struct CustomVideoPlayer: View {
    let player: AVPlayer // Placeholder, won’t be used but keeps the struct valid
    
    var body: some View {
        Text("Video playback is not supported on this platform.")
            .foregroundColor(.gray)
            .frame(height: 200)
    }
}
#endif

struct DiscoverGentlerCoparentView: View {
    @State private var player: AVPlayer = {
        if let url = Bundle.main.url(forResource: "gentler_coparent", withExtension: "mp4") {
            return AVPlayer(url: url)
        }
        return AVPlayer()
    }()
    
    private let introBlocks: [(title: String, body: String)] = [
        ("Discover a calmer path",
         "After a high-conflict separation, co-parenting can feel like constant turbulence—misunderstandings, emotional load, and kids caught in the middle."),
        ("Built by people who’ve been there",
         "Gentler Coparent is a companion for rebuilding peaceful, child-focused communication. Not lectures—practical drafts, boundaries, and next steps."),
        ("How to use it",
         "Paste a tough message, upload a screenshot, or describe the situation. Ask for a rewrite, a boundary, an expense request, or a holiday plan. GCP answers as your co-parenting assistant—ready to copy and send.")
    ]

    var body: some View {
        SettingsDetailShell(title: "Watch Overview") {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    #if canImport(AVKit)
                    CustomVideoPlayer(player: player)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous))
                        .onAppear { player.seek(to: .zero) }
                    #endif
                    
                    ForEach(Array(introBlocks.enumerated()), id: \.offset) { _, block in
                        SettingsArticleBlock(block.title, block.body)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: GCPTheme.radiusCard, style: .continuous)
                                    .fill(GCPTheme.cardFill)
                            )
                    }
                }
                .padding(16)
            }
        }
    }
}
