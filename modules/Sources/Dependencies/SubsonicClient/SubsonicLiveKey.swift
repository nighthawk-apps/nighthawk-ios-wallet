import AVFoundation
import ComposableArchitecture
import Foundation

extension SubsonicClient: DependencyKey {
    public static let liveValue = Self(
        play: { filename in
            SoundEffectPlayer.shared.play(filename: filename)
        }
    )
}

/// One-shot playback for the wallet-created chime. Replaces the Subsonic package.
private final class SoundEffectPlayer {
    static let shared = SoundEffectPlayer()
    private var player: AVAudioPlayer?

    func play(filename: String) {
        let ns = filename as NSString
        let name = ns.deletingPathExtension
        let ext = ns.pathExtension.isEmpty ? "mp3" : ns.pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
