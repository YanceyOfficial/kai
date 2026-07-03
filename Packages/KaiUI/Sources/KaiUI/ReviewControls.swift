import SwiftUI

/// A learner's self-rating after seeing the answer (maps to FSRS grades in the app).
public enum ReviewRating: String, CaseIterable, Sendable {
    case again, hard, good, easy

    public var label: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    /// Restrained, difficulty-coded tint per rating (red → amber → pine → blue).
    var tint: Color {
        switch self {
        case .again: return KaiColor.vermilion
        case .hard: return Color(hex: 0xB07A2E)   // muted amber
        case .good: return Color(hex: 0x3E7C63)   // muted pine
        case .easy: return Color(hex: 0x3E6D8C)   // muted slate blue
        }
    }
}

/// The four-way rating row shown once the card is revealed: consistent soft-tinted
/// cards, color-coded by difficulty, each with an optional next-interval caption so the
/// learner knows what each choice schedules.
public struct RatingBar: View {
    private let onRate: (ReviewRating) -> Void
    private let interval: (ReviewRating) -> String?

    /// - Parameter interval: returns the next-review interval caption for a rating
    ///   (e.g. "1d"), or nil to omit it.
    public init(
        interval: @escaping (ReviewRating) -> String? = { _ in nil },
        onRate: @escaping (ReviewRating) -> Void
    ) {
        self.interval = interval
        self.onRate = onRate
    }

    public var body: some View {
        HStack(spacing: KaiSpacing.s) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                Button {
                    // "Again" earns a firmer thud; the rest get a crisp selection tick.
                    if rating == .again { KaiHaptics.impact(.rigid) } else { KaiHaptics.selection() }
                    onRate(rating)
                } label: {
                    VStack(spacing: 2) {
                        Text(rating.label)
                            .font(KaiFont.body(15, weight: .semibold))
                            .foregroundStyle(rating.tint)
                        if let caption = interval(rating), !caption.isEmpty {
                            Text(caption)
                                .font(KaiFont.body(11, weight: .medium))
                                .foregroundStyle(rating.tint.opacity(0.65))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(rating.tint.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(rating.tint.opacity(0.22), lineWidth: 1)
                    )
                }
                .buttonStyle(KaiPressStyle())
            }
        }
    }
}

/// A thin ink track with a vermilion fill showing session progress (0...1).
public struct SessionProgressBar: View {
    private let progress: Double
    public init(progress: Double) { self.progress = min(max(progress, 0), 1) }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(KaiColor.hairline)
                Capsule()
                    .fill(KaiColor.vermilion)
                    .frame(width: max(8, geo.size.width * progress))
            }
        }
        .frame(height: 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
    }
}

/// A full-width ink primary button (e.g. "Show answer").
public struct KaiPrimaryButton: View {
    private let title: String
    private let action: () -> Void
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button {
            KaiHaptics.impact(.light)
            action()
        } label: {
            Text(title)
                .font(KaiFont.body(17, weight: .semibold))
                .foregroundStyle(KaiColor.cardFace)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(KaiColor.sumi)
                )
        }
        .buttonStyle(KaiPressStyle())
    }
}
