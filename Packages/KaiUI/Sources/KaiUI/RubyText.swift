import SwiftUI

public extension EnvironmentValues {
    /// Whether `RubyText` prints readings over annotated bases (the "Show furigana"
    /// setting). Off, it renders the plain text.
    @Entry var showsFurigana: Bool = true
}

/// Text that may carry ruby markup (`{漢字|かんじ}`, see `Ruby`), with each reading
/// printed small above its base.
///
/// SwiftUI's `Text` has no ruby, so annotated text is laid out as a flow of small
/// units (see `Ruby.units`) that each reserve the same reading line — lines stay evenly
/// spaced whether or not they carry readings. Text with no annotations (all English
/// content), or with furigana switched off, is an ordinary `Text` and wraps natively.
/// VoiceOver reads the plain text either way.
public struct RubyText: View {
    private let markup: String
    private let size: CGFloat
    private let weight: Font.Weight
    private let color: Color
    private let alignment: HorizontalAlignment
    @Environment(\.showsFurigana) private var showsFurigana

    public init(
        _ markup: String,
        size: CGFloat,
        weight: Font.Weight = .regular,
        color: Color = KaiColor.sumi,
        alignment: HorizontalAlignment = .leading
    ) {
        self.markup = markup
        self.size = size
        self.weight = weight
        self.color = color
        self.alignment = alignment
    }

    public var body: some View {
        if showsFurigana, Ruby.hasRuby(markup) {
            RubyFlow(lineSpacing: size * 0.2, alignment: alignment) {
                ForEach(Array(Ruby.units(Ruby.parse(markup)).enumerated()), id: \.offset) { _, unit in
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(Array(unit.enumerated()), id: \.offset) { _, part in
                            partView(part)
                        }
                    }
                    .layoutValue(key: RubyHang.self, value: RubyHang(
                        leading: unit.first.map { Ruby.hang(of: $0, size: size) } ?? 0,
                        trailing: unit.last.map { Ruby.hang(of: $0, size: size) } ?? 0))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Ruby.plain(markup))
        } else {
            Text(Ruby.plain(markup))
                .font(KaiFont.body(size, weight: weight))
                .foregroundStyle(color)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func partView(_ part: Ruby.Part) -> some View {
        RubyPart(overhang: size) {
            // Every part reserves the reading line, so bases share one baseline.
            Text(part.reading ?? " ")
                .font(KaiFont.body(size * 0.5, weight: .regular))
                .foregroundStyle(color.opacity(0.7))
                .opacity(part.reading == nil ? 0 : 1)
                .lineLimit(1)
                .fixedSize()
            Text(part.base)
                .font(KaiFont.body(size, weight: weight))
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
        }
    }
}

/// One base with its reading centred above it. A reading wider than its base may
/// overhang the text beside it by up to `overhang` in all (half each side), as
/// Japanese typesetting lets ruby hang over neighbouring kana — so むかし over 昔 does
/// not push 昔 away from the のことが that follows it. Anything wider widens the part.
private struct RubyPart: Layout {
    var overhang: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let reading = subviews[0].sizeThatFits(.unspecified)
        let base = subviews[1].sizeThatFits(.unspecified)
        return CGSize(width: max(base.width, reading.width - overhang), height: reading.height + base.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let reading = subviews[0].sizeThatFits(.unspecified)
        let base = subviews[1].sizeThatFits(.unspecified)
        subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.minY), anchor: .top, proposal: ProposedViewSize(reading))
        subviews[1].place(at: CGPoint(x: bounds.midX, y: bounds.maxY), anchor: .bottom, proposal: ProposedViewSize(base))
    }
}

/// How far a unit's reading hangs past its edges (see `RubyPart`).
private struct RubyHang: LayoutValueKey, Equatable {
    static let defaultValue = RubyHang(leading: 0, trailing: 0)
    var leading: CGFloat
    var trailing: CGFloat
}

/// Lays units left to right, starting a new line when the next would overflow. A
/// reading may hang over a neighbour, but at the start or end of a line there is none,
/// so there the line makes room for it instead of letting the edge clip it.
private struct RubyFlow: Layout {
    var lineSpacing: CGFloat
    var alignment: HorizontalAlignment

    struct Line {
        var indices: [Int] = []
        /// The first unit's leading hang, taken as an inset.
        var inset: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(for width: CGFloat, subviews: Subviews) -> ([Line], [CGSize]) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var lines: [Line] = [Line()]
        for (index, size) in sizes.enumerated() {
            let hang = subviews[index][RubyHang.self]
            var line = lines[lines.count - 1]
            if !line.indices.isEmpty, line.width + size.width + hang.trailing > width {
                lines.append(Line())
                line = Line()
            }
            if line.indices.isEmpty {
                line.inset = hang.leading
                line.width = hang.leading
            }
            line.indices.append(index)
            line.width += size.width
            line.height = max(line.height, size.height)
            lines[lines.count - 1] = line
        }
        return (lines, sizes)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let (lines, _) = lines(for: proposal.width ?? .infinity, subviews: subviews)
        let height = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, lines.count - 1))
        let widest = lines.map(\.width).max() ?? 0
        return CGSize(width: proposal.width.map { $0.isFinite ? $0 : widest } ?? widest, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (lines, sizes) = lines(for: bounds.width, subviews: subviews)
        var y = bounds.minY
        for line in lines {
            var x = bounds.minX + line.inset
            if alignment == .center { x += (bounds.width - line.width) / 2 }
            if alignment == .trailing { x += bounds.width - line.width }
            for index in line.indices {
                let size = sizes[index]
                subviews[index].place(at: CGPoint(x: x, y: y + line.height - size.height), proposal: ProposedViewSize(size))
                x += size.width
            }
            y += line.height + lineSpacing
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        RubyText("{彼|かれ}は{曖昧|あいまい}な{返事|へんじ}しかしなかった。「{本当|ほんとう}に{来|く}るの？」", size: 17)
        RubyText("My uncle is something of an eccentric.", size: 17)
    }
    .padding()
}
