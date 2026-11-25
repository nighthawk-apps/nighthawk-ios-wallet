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
        let nsFilename = filename as NSString
        let name = nsFilename.deletingPathExtension
        let ext = nsFilename.pathExtension.isEmpty ? "mp3" : nsFilename.pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
