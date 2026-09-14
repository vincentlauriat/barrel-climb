import AVFoundation

/// Preloads every generated WAV; one player per sound, restarted on each play.
final class SoundPlayer {
    private var players: [String: AVAudioPlayer] = [:]

    init() {
        for name in ["jump", "barrel", "hammer", "die", "clear", "pickup", "bonus"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "sounds"),
                let p = try? AVAudioPlayer(contentsOf: url)
            else { continue }
            p.prepareToPlay()
            players[name] = p
        }
        #if os(iOS)
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
        #endif
    }

    func play(_ name: String) {
        guard let p = players[name] else { return }
        p.currentTime = 0
        p.play()
    }
}
