import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Which accent to pronounce an English word in. Maps to the Youdao dictvoice `type` param.
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

/// The voice a pronunciation is spoken in: English in an accent, or Japanese.
public enum PronunciationVoice: Equatable, Sendable {
    case english(Accent)
    case japanese

    /// The BCP 47 language of the on-device fallback voice.
    var speechLanguage: String {
        switch self {
        case .english(.us): return "en-US"
        case .english(.uk): return "en-GB"
        case .japanese: return "ja-JP"
        }
    }
}

/// Builds the audio URL for a pronunciation. Pure and testable — the network and
/// playback live in `PronunciationPlayer`.
///
/// Uses NetEase Youdao's public `dictvoice` endpoint, which streams an MP3 with no key
/// required: English through `type` (1 = British, 2 = American), Japanese through
/// `le=jap`. For Japanese it voices words and short phrases, not whole sentences (it
/// answers those with a 500), which is why the player falls back to the on-device voice.
public enum PronunciationURL {
    /// The Youdao dictvoice endpoint for `text` in the given `accent`, or `nil` if
    /// `text` is blank / cannot be encoded into a URL.
    public static func youdao(for text: String, accent: Accent) -> URL? {
        youdao(for: text, voice: .english(accent))
    }

    /// The Youdao dictvoice endpoint for `text` in `voice`, or `nil` if `text` is blank.
    public static func youdao(for text: String, voice: PronunciationVoice) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents(string: "https://dict.youdao.com/dictvoice")
        switch voice {
        case .english(let accent):
            components?.queryItems = [
                URLQueryItem(name: "audio", value: trimmed),
                URLQueryItem(name: "type", value: String(accent.youdaoType)),
            ]
        case .japanese:
            components?.queryItems = [
                URLQueryItem(name: "audio", value: trimmed),
                URLQueryItem(name: "le", value: "jap"),
            ]
        }
        return components?.url
    }
}

/// What to say for a Japanese headword. The kana reading when the entry has one
/// (a phonetic like `なつかしい ④` — the reading, then its pitch accent), since a kana
/// reading cannot be misread, the way `生物` can be せいぶつ or なまもの; otherwise the
/// word itself.
public enum JapaneseSpeech {
    public static func text(word: String, phonetic: String) -> String {
        let reading = phonetic.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
        return !reading.isEmpty && isKana(reading) ? reading : word
    }

    /// Hiragana, katakana, and the long-vowel mark only.
    static func isKana(_ text: String) -> Bool {
        text.unicodeScalars.allSatisfy { scalar in
            (0x3041...0x309F).contains(scalar.value)      // hiragana
                || (0x30A0...0x30FF).contains(scalar.value) // katakana, incl. ー and ・
        }
    }
}

/// Plays a word's pronunciation. A protocol so the UI can be driven by a test double.
@MainActor
public protocol PronunciationPlaying {
    /// Fetch and play `text` in `voice`. Failures are handled internally (logged, and
    /// spoken on device instead) so callers can fire-and-forget.
    func play(_ text: String, voice: PronunciationVoice)
}

public extension PronunciationPlaying {
    /// An English word in `accent`.
    func play(_ text: String, accent: Accent) {
        play(text, voice: .english(accent))
    }
}

#if canImport(AVFoundation)
/// Streams a pronunciation from Youdao via `AVPlayer`, and falls back to the system's
/// own voice (`AVSpeechSynthesizer`, on device, free, offline) whenever Youdao has no
/// audio for it — a Japanese sentence, no network. Compiled for the app; not
/// unit-tested (the testable URL logic lives in `PronunciationURL`).
///
/// The audio session uses `.playback`, so pronunciations are audible even when the
/// ringer switch is set to silent — the norm for language-learning apps.
@MainActor
public final class PronunciationPlayer: PronunciationPlaying {
    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private let synthesizer = AVSpeechSynthesizer()
    private let logger: AppLogger
    private var sessionConfigured = false

    public init(logger: AppLogger = AppLogger(sink: OSLogSink())) {
        self.logger = logger
    }

    public func play(_ text: String, voice: PronunciationVoice) {
        configureSessionIfNeeded()
        stop()
        guard let url = PronunciationURL.youdao(for: text, voice: voice) else {
            logger.warning("No pronunciation URL for '\(text)'", category: "audio")
            return
        }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        // Youdao answers what it cannot voice with an error body, which fails the item.
        statusObservation = item.observe(\.status) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor [weak self] in
                guard let self, self.player === player else { return }
                self.logger.info("Youdao had no audio for '\(text)'; speaking on device", category: "audio")
                self.speak(text, voice: voice)
            }
        }
        player.play()
        self.player = player
    }

    /// Speaks `text` with the system voice for `voice`'s language.
    private func speak(_ text: String, voice: PronunciationVoice) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voice.speechLanguage)
        synthesizer.speak(utterance)
    }

    private func stop() {
        statusObservation = nil
        player?.pause()
        player = nil
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
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
