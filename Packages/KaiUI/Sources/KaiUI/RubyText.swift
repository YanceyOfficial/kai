import SwiftUI
#if canImport(UIKit)
import UIKit
import CoreText
#endif

public extension EnvironmentValues {
    /// Whether `RubyText` prints readings over annotated bases (the "Show furigana"
    /// setting). Off, it shows the plain text.
    @Entry var showsFurigana: Bool = true

    /// Told when a `RubyText` gains or loses a selection: the text view's identity and
    /// whether it now has one. A container whose own gestures would fight the selection
    /// handles (the flip card's swipe) holds them while any selection is active.
    @Entry var textSelectionChanged: ((AnyHashable, Bool) -> Void)? = nil
}

/// Reading text: selectable, and with furigana when it carries ruby markup
/// (`{漢字|かんじ}`, see `Ruby`).
///
/// It is a read-only TextKit 2 `UITextView`, for two things SwiftUI's `Text` cannot do:
/// - **Ruby.** TextKit 2 lays out Core Text ruby annotations (TextKit 1 ignores them),
///   with the system's own Japanese rules — readings overhanging neighbouring kana,
///   no line starting with closing punctuation, room made at a line's edges.
/// - **Selection.** A long press selects any stretch of the text and brings up the
///   system edit menu — Copy, Look Up, Translate, Share, and Writing Tools where Apple
///   Intelligence is available. (`Text.textSelection` only selects a whole `Text`.)
///
/// Copied text is the plain text, without readings. Where UIKit is unavailable it is a
/// plain `Text`.
public struct RubyText: View {
    private let markup: String
    private let size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design
    private let color: Color
    private let alignment: TextAlignment
    @Environment(\.showsFurigana) private var showsFurigana

    public init(
        _ markup: String,
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        color: Color = KaiColor.sumi,
        alignment: TextAlignment = .leading
    ) {
        self.markup = markup
        self.size = size
        self.weight = weight
        self.design = design
        self.color = color
        self.alignment = alignment
    }

    public var body: some View {
        #if canImport(UIKit)
        SelectableTextView(
            segments: showsFurigana ? Ruby.parse(markup) : [.text(Ruby.plain(markup))],
            size: size, weight: weight, design: design, color: color, alignment: alignment)
        #else
        Text(Ruby.plain(markup))
            .font(.system(size: size, weight: weight, design: design))
            .foregroundStyle(color)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
        #endif
    }
}

#if canImport(UIKit)
private struct SelectableTextView: UIViewRepresentable {
    let segments: [Ruby.Segment]
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let color: Color
    let alignment: TextAlignment

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// Reports selection changes to the environment's `textSelectionChanged`.
    final class Coordinator: NSObject, UITextViewDelegate {
        var onChange: ((AnyHashable, Bool) -> Void)?
        private var selected = false

        func textViewDidChangeSelection(_ textView: UITextView) {
            report(textView.selectedRange.length > 0)
        }

        func report(_ now: Bool) {
            guard now != selected else { return }
            selected = now
            onChange?(ObjectIdentifier(self), now)
        }
    }

    static func dismantleUIView(_ view: UITextView, coordinator: Coordinator) {
        coordinator.report(false)
    }

    func makeUIView(context: Context) -> UITextView {
        // TextKit 2 explicitly: it is the one that draws ruby.
        let view = UITextView(usingTextLayoutManager: true)
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.dataDetectorTypes = []
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.onChange = context.environment.textSelectionChanged
        // Readings sit between lines: give them room above the first line too, so they
        // never touch the text above this view.
        let top = hasRuby ? (size * 0.6).rounded() : 0
        if view.textContainerInset.top != top {
            view.textContainerInset = UIEdgeInsets(top: top, left: 0, bottom: 0, right: 0)
        }
        let resolved = color.resolve(in: context.environment)
        let text = attributedString(color: UIColor(red: CGFloat(resolved.red), green: CGFloat(resolved.green),
                                                   blue: CGFloat(resolved.blue), alpha: CGFloat(resolved.opacity)))
        if view.attributedText != text { view.attributedText = text }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width ?? .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        return CGSize(width: width ?? ceil(fitted.width), height: ceil(fitted.height))
    }

    private func attributedString(color: UIColor) -> NSAttributedString {
        var descriptor = UIFont.systemFont(ofSize: size, weight: uiWeight).fontDescriptor
        if let designed = descriptor.withDesign(uiDesign) { descriptor = designed }
        let font = UIFont(descriptor: descriptor, size: size)

        let paragraph = NSMutableParagraphStyle()
        // Lines with furigana need the gap the readings take, or a reading crowds the
        // line above it.
        paragraph.lineSpacing = size * (hasRuby ? 0.5 : 0.15)
        paragraph.alignment = switch alignment {
        case .center: .center
        case .trailing: .right
        default: .natural
        }
        let base: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]

        let result = NSMutableAttributedString()
        for segment in segments {
            switch segment {
            case .text(let text):
                result.append(NSAttributedString(string: text, attributes: base))
            case .ruby(let text, let reading):
                var attributes = base
                attributes[NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)] =
                    CTRubyAnnotationCreateWithAttributes(
                        .center, .auto, .before, reading as CFString,
                        [kCTRubyAnnotationSizeFactorAttributeName: 0.5,
                         kCTForegroundColorAttributeName: color.withAlphaComponent(0.7).cgColor] as CFDictionary)
                result.append(NSAttributedString(string: text, attributes: attributes))
            }
        }
        return result
    }

    private var hasRuby: Bool {
        segments.contains { if case .ruby = $0 { true } else { false } }
    }

    private var uiWeight: UIFont.Weight {
        switch weight {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }

    private var uiDesign: UIFontDescriptor.SystemDesign {
        switch design {
        case .serif: .serif
        case .rounded: .rounded
        case .monospaced: .monospaced
        default: .default
        }
    }
}
#endif

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        RubyText("{彼|かれ}は{曖昧|あいまい}な{返事|へんじ}しかしなかった。「{本当|ほんとう}に{来|く}るの？」", size: 17)
        RubyText("My uncle is something of an eccentric.", size: 17)
    }
    .padding()
}
