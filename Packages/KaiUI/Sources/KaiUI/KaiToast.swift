import SwiftUI

/// A small ink pill used for transient feedback (e.g. "deck complete").
public struct KaiToast: View {
    private let message: String
    public init(_ message: String) { self.message = message }

    public var body: some View {
        Text(message)
            .font(KaiFont.body(15, weight: .semibold))
            .foregroundStyle(KaiColor.cardFace)
            .padding(.horizontal, KaiSpacing.l)
            .padding(.vertical, KaiSpacing.m)
            .background(Capsule().fill(KaiColor.sumi))
            .shadow(color: KaiColor.shadow, radius: 12, x: 0, y: 6)
    }
}

public extension View {
    /// Presents a transient toast from the top edge that auto-dismisses.
    func kaiToast(_ message: String, isPresented: Binding<Bool>, duration: Double = 1.8) -> some View {
        overlay(alignment: .top) {
            if isPresented.wrappedValue {
                KaiToast(message)
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
