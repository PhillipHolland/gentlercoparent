import Foundation
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - AudioManager Class
#if canImport(UIKit)

/// Serial queue for session + player ops (never main). File-level so nonisolated callbacks can use it.
private let gentlerAudioQueue = DispatchQueue(label: "com.pbh.gentlercoparent.audio", qos: .userInitiated)

/// UI sound effects for chat. All AVAudioSession / AVAudioPlayer work runs on `gentlerAudioQueue`
/// so we never call `setActive` / `prepareToPlay` on the main thread (hang-risk warnings).
@MainActor
class AudioManager: NSObject, AVAudioPlayerDelegate, ObservableObject {
    
    // Players are only touched on `audioQueue` after bootstrap.
    nonisolated(unsafe) private var sendAudioPlayer: AVAudioPlayer?
    nonisolated(unsafe) private var waitingAudioPlayer: AVAudioPlayer?
    nonisolated(unsafe) private var receiveAudioPlayer: AVAudioPlayer?
    nonisolated(unsafe) private var playersReady = false
    
    private let soundEnabledKey = "SoundEnabled"
    private let hapticsEnabledKey = "HapticsEnabled"
    
    private enum SoundKind {
        case send, waiting, receive
        
        var label: String {
            switch self {
            case .send: return "send.wav"
            case .waiting: return "waiting.wav"
            case .receive: return "receive.wav"
            }
        }
    }
    
    @Published var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: soundEnabledKey)
            if !isSoundEnabled {
                stopAllSounds()
            }
        }
    }
    
    @Published var isHapticsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: hapticsEnabledKey)
        }
    }
    
    override init() {
        super.init()
        if UserDefaults.standard.object(forKey: soundEnabledKey) != nil {
            isSoundEnabled = UserDefaults.standard.bool(forKey: soundEnabledKey)
        }
        if UserDefaults.standard.object(forKey: hapticsEnabledKey) != nil {
            isHapticsEnabled = UserDefaults.standard.bool(forKey: hapticsEnabledKey)
        }
        bootstrapOnAudioQueue()
    }
    
    // MARK: - Bootstrap (audio queue only)
    
    private func bootstrapOnAudioQueue() {
        gentlerAudioQueue.async { [weak self] in
            guard let self else { return }
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                // Activate once off-main so later play() does not block the UI thread.
                try session.setActive(true, options: [])
            } catch {
                print("AVAudioSession setup failed: \(error.localizedDescription)")
            }
            
            let send = Self.makePlayer(resource: "send", loops: 0)
            send?.delegate = self
            send?.prepareToPlay()
            
            let receive = Self.makePlayer(resource: "receive", loops: 0)
            receive?.prepareToPlay()
            
            let waiting = Self.makePlayer(resource: "waiting", loops: -1)
            waiting?.prepareToPlay()
            
            self.sendAudioPlayer = send
            self.receiveAudioPlayer = receive
            self.waitingAudioPlayer = waiting
            self.playersReady = true
            print("AudioManager players ready on audio queue")
        }
    }
    
    nonisolated private static func makePlayer(resource: String, loops: Int) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            print("\(resource).wav not found in bundle")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            return player
        } catch {
            print("Failed to load \(resource).wav: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Playback (audio queue only)
    
    private func play(_ kind: SoundKind) {
        guard isSoundEnabled else {
            print("Sound is disabled, skipping \(kind.label).")
            return
        }
        
        let fallbackToWaiting = (kind == .send)
        gentlerAudioQueue.async { [weak self] in
            guard let self else { return }
            guard self.playersReady else {
                print("Audio not ready yet, skip \(kind.label)")
                return
            }
            
            // Keep session active without hopping to main.
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: [])
            } catch {
                print("AVAudioSession activate failed: \(error.localizedDescription)")
            }
            
            let player: AVAudioPlayer?
            switch kind {
            case .send: player = self.sendAudioPlayer
            case .waiting: player = self.waitingAudioPlayer
            case .receive: player = self.receiveAudioPlayer
            }
            
            guard let player else {
                print("No audio player for \(kind.label)")
                if fallbackToWaiting {
                    self.playWaitingOnAudioQueue()
                }
                return
            }
            
            // Already prepared at bootstrap; avoid prepareToPlay on main.
            player.currentTime = 0
            if !player.play() {
                print("Failed to play \(kind.label)")
                if fallbackToWaiting {
                    self.playWaitingOnAudioQueue()
                }
            } else {
                print("Playing \(kind.label)")
            }
        }
    }
    
    /// Must be called on `gentlerAudioQueue`.
    nonisolated private func playWaitingOnAudioQueue() {
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch { /* best-effort */ }
        waitingAudioPlayer?.currentTime = 0
        if waitingAudioPlayer?.play() == false {
            print("Failed to play waiting.wav")
        }
    }
    
    func playSendSound() { play(.send) }
    
    func playWaitingSound() { play(.waiting) }
    
    func stopWaitingSound() {
        gentlerAudioQueue.async { [weak self] in
            self?.waitingAudioPlayer?.stop()
            print("Stopped waiting.wav")
        }
    }
    
    func playReceiveSound() { play(.receive) }
    
    func stopAllSounds() {
        gentlerAudioQueue.async { [weak self] in
            self?.sendAudioPlayer?.stop()
            self?.waitingAudioPlayer?.stop()
            self?.receiveAudioPlayer?.stop()
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
    
    func triggerHapticFeedback(_ style: UINotificationFeedbackGenerator.FeedbackType = .success) {
        guard isHapticsEnabled else {
            print("Haptics is disabled, skipping feedback.")
            return
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(style)
    }
    
    // AVAudioPlayerDelegate may be invoked off-main; hop to audio queue.
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        gentlerAudioQueue.async { [weak self] in
            guard let self else { return }
            if player === self.sendAudioPlayer {
                self.playWaitingOnAudioQueue()
            }
        }
    }
}
#else
class AudioManager: ObservableObject {
    @Published var isSoundEnabled: Bool = false
    @Published var isHapticsEnabled: Bool = false
    
    func playSendSound() { print("Sound disabled on this platform.") }
    func playWaitingSound() { print("Sound disabled on this platform.") }
    func stopWaitingSound() { print("Sound disabled on this platform.") }
    func playReceiveSound() { print("Sound disabled on this platform.") }
    func stopAllSounds() { print("Sound disabled on this platform.") }
    func triggerHapticFeedback(_ style: Int = 0) { print("Haptics disabled on this platform.") }
}
#endif
