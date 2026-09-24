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
    /// The model stopped at its output-token limit, so the JSON was cut off.
    case truncated
}

extension AIError: LocalizedError {
    /// A sentence for the toast and the log — what happened and, where there is one,
    /// what to do about it. (Without it the system prints "AIError error 2".)
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key — add one in Settings."
        case .http(let status, let body):
            let detail = body.prefix(200)
            switch status {
            case 401, 403: return "The API key was refused (\(status)). Check it in Settings."
            case 429: return "Rate limited by the provider (429). Try again in a moment."
            default: return "The provider answered \(status): \(detail)"
            }
        case .decoding(let what):
            return "The model's answer could not be read (\(what.prefix(160)))."
        case .emptyResponse:
            return "The model returned nothing."
        case .cancelled:
            return "Cancelled."
        case .transport(let what):
            return "Couldn't reach the provider — \(what.prefix(160))"
        case .truncated:
            return "The answer was too long and got cut off. Try fewer words at once."
        }
    }
}
