import Foundation

/// Recognizes text lines from an encoded image (PNG/JPEG data).
public protocol TextRecognizer: Sendable {
    func recognizeLines(in imageData: Data) async throws -> [String]
}
