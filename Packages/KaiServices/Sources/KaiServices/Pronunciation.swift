import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Which accent to pronounce a word in. Maps to the Youdao dictvoice `type` param.
public enum Accent: String, Sendable, CaseIterable {
    case us, uk

    /// Youdao's `type` query value: 1 = British, 2 = American.
    var youdaoType: Int {
        switch self {
        case .uk: return 1
        case .us: return 2
        }
    }
}

/// Builds the audio URL for a word's pronunciation. Pure and testable — the network
/// and playback live in `PronunciationPlayer`.
///
/// Uses NetEase Youdao's public `dictvoice` endpoint, which streams an MP3 for a
/// word or phrase with no key required. Phrases are percent-encoded automatically.
public enum PronunciationURL {
    /// The Youdao dictvoice endpoint for `text` in the given `accent`, or `nil` if
    /// `text` is blank / cannot be encoded into a URL.
    public static func youdao(for text: String, accent: Accent) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents(string: "https://dict.youdao.com/dictvoice")
        components?.queryItems = [
            URLQueryItem(name: "audio", value: trimmed),
            URLQueryItem(name: "type", value: String(accent.youdaoType)),
        ]
        return components?.url
    }
}

/// Plays a word's pronunciation. A protocol so the UI can be driven by a test double.
@MainActor
public protocol PronunciationPlaying {
    /// Fetch and play `text` in `accent`. Failures are handled internally (logged,
    /// no crash) so callers can fire-and-forget.
    func play(_ text: String, accent: Accent)
}

#if canImport(AVFoundation)
/// Streams and plays a word's pronunciation via `AVPlayer`. Compiled for the app;
/// not unit-tested (the testable URL logic lives in `PronunciationURL`).
///
/// The audio session uses `.playback`, so pronunciations are audible even when the
/// ringer switch is set to silent — the norm for language-learning apps.
@MainActor
public final class PronunciationPlayer: PronunciationPlaying {
    private var player: AVPlayer?
    private let logger: AppLogger
    private var sessionConfigured = false

    public init(logger: AppLogger = AppLogger(sink: OSLogSink())) {
        self.logger = logger
    }

    public func play(_ text: String, accent: Accent) {
        guard let url = PronunciationURL.youdao(for: text, accent: accent) else {
            logger.warning("No pronunciation URL for '\(text)'", category: "audio")
            return
        }
        configureSessionIfNeeded()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.play()
        self.player = player
    }

    /// Activate a playback audio session once, lazily. Best-effort: a failure here
    /// only means the sound may respect the mute switch, never a crash.
    private func configureSessionIfNeeded() {
        #if os(iOS)
        guard !sessionConfigured else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
            sessionConfigured = true
        } catch {
            logger.error("Audio session setup failed: \(error.localizedDescription)", category: "audio")
        }
        #endif
    }
}
#endif
