import SwiftUI

/// Visual intent of a toast.
public enum KaiToastStyle: Sendable {
    case success
    case error

    var background: Color {
        switch self {
        case .success: return KaiColor.sumi
        case .error: return KaiColor.danger
        }
    }

    var symbol: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

/// A small pill used for transient feedback (e.g. "Note added", "Couldn't save").
public struct KaiToast: View {
    private let message: String
    private let style: KaiToastStyle

    public init(_ message: String, style: KaiToastStyle = .success) {
        self.message = message
        self.style = style
    }

    public var body: some View {
        HStack(spacing: KaiSpacing.s) {
            Image(systemName: style.symbol)
            Text(message)
        }
        .font(KaiFont.body(15, weight: .semibold))
        .foregroundStyle(KaiColor.cardFace)
        .padding(.horizontal, KaiSpacing.l)
        .padding(.vertical, KaiSpacing.m)
        .background(Capsule().fill(style.background))
        .shadow(color: KaiColor.shadow, radius: 12, x: 0, y: 6)
    }
}

public extension View {
    /// Presents a transient toast from the top edge that auto-dismisses.
    func kaiToast(_ message: String, style: KaiToastStyle = .success, isPresented: Binding<Bool>, duration: Double = 1.8) -> some View {
        overlay(alignment: .top) {
            if isPresented.wrappedValue {
                KaiToast(message, style: style)
                    .padding(.top, KaiSpacing.xl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                        withAnimation(.easeInOut) { isPresented.wrappedValue = false }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented.wrappedValue)
    }
}
