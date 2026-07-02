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

    /// Restrained tint per rating, staying within the Ink & Paper palette.
    var tint: Color {
        switch self {
        case .again: return KaiColor.vermilion
        case .hard: return Color(hex: 0xB07A2E)   // muted amber
        case .good: return KaiColor.sumi          // ink (the expected default)
        case .easy: return Color(hex: 0x3E7C63)   // muted pine
        }
    }
}

/// The four-way rating row shown once the card is revealed. "Good" is filled ink;
/// the others are outlined in their tint.
public struct RatingBar: View {
    private let onRate: (ReviewRating) -> Void
    public init(onRate: @escaping (ReviewRating) -> Void) { self.onRate = onRate }

    public var body: some View {
        HStack(spacing: KaiSpacing.s) {
            ForEach(ReviewRating.allCases, id: \.self) { rating in
                Button {
                    // "Again" earns a firmer thud; the rest get a crisp selection tick.
                    if rating == .again { KaiHaptics.impact(.rigid) } else { KaiHaptics.selection() }
                    onRate(rating)
                } label: {
                    Text(rating.label)
                        .font(KaiFont.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .foregroundStyle(rating == .good ? KaiColor.cardFace : rating.tint)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(rating == .good ? rating.tint : KaiColor.cardFace)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(rating.tint.opacity(0.55), lineWidth: 1.5)
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
