import Foundation

/// Retry configuration for transient failures (429, 5xx).
public struct RetryPolicy: Sendable {
    public var maxAttempts: Int
    public var baseDelay: Double
    public init(maxAttempts: Int, baseDelay: Double) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }
    public static let `default` = RetryPolicy(maxAttempts: 3, baseDelay: 0.5)
}

/// Wraps a transport and retries 429/5xx with exponential backoff + jitter, honoring cancellation.
public struct RetryingTransport: HTTPTransport {
    private let wrapped: HTTPTransport
    private let policy: RetryPolicy
    private let sleep: @Sendable (Double) async throws -> Void

    public init(
        wrapping wrapped: HTTPTransport,
        policy: RetryPolicy = .default,
        sleep: @escaping @Sendable (Double) async throws -> Void = { try await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) }
    ) {
        self.wrapped = wrapped
        self.policy = policy
        self.sleep = sleep
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0
        while true {
            try Task.checkCancellation()
            let (data, response) = try await wrapped.send(request)
            let retriable = response.statusCode == 429 || (500...599).contains(response.statusCode)
            attempt += 1
            if !retriable || attempt >= policy.maxAttempts {
                return (data, response)
            }
            let delay = policy.baseDelay * pow(2.0, Double(attempt - 1)) + Double.random(in: 0...0.1)
            try await sleep(delay)
        }
    }
}
