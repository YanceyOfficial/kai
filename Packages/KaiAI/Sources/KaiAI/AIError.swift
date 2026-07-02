import Foundation

/// Typed errors surfaced by the AI layer. Carries enough context for a toast + a log line.
public enum AIError: Error, Equatable, Sendable {
    /// No API key configured for the selected provider.
    case missingAPIKey
    /// Non-success HTTP status with the response body (truncated by the caller if needed).
    case http(status: Int, body: String)
    /// The response could not be decoded into the expected shape.
    case decoding(String)
    /// The provider returned a success status but no usable content.
    case emptyResponse
    /// The operation was cancelled.
    case cancelled
    /// A transport-level failure (no HTTP response), e.g. offline.
    case transport(String)
}
