import Foundation
import Testing
@testable import KaiAI

/// A transport that returns a scripted sequence of status codes, counting calls.
private final class ScriptedTransport: HTTPTransport, @unchecked Sendable {
    private var statuses: [Int]
    private(set) var callCount = 0
    init(_ statuses: [Int]) { self.statuses = statuses }
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let status = statuses[min(callCount, statuses.count - 1)]
        callCount += 1
        let resp = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data("body".utf8), resp)
    }
}

private let noSleep: @Sendable (Double) async throws -> Void = { _ in }

@Test("Retries 429 then succeeds on 200")
func retriesOn429() async throws {
    let scripted = ScriptedTransport([429, 200])
    let retrying = RetryingTransport(wrapping: scripted, policy: .init(maxAttempts: 3, baseDelay: 0), sleep: noSleep)
    let (_, resp) = try await retrying.send(URLRequest(url: URL(string: "https://x")!))
    #expect(resp.statusCode == 200)
    #expect(scripted.callCount == 2)
}

@Test("Does not retry 400")
func noRetryOn400() async throws {
    let scripted = ScriptedTransport([400, 200])
    let retrying = RetryingTransport(wrapping: scripted, policy: .init(maxAttempts: 3, baseDelay: 0), sleep: noSleep)
    let (_, resp) = try await retrying.send(URLRequest(url: URL(string: "https://x")!))
    #expect(resp.statusCode == 400)
    #expect(scripted.callCount == 1)
}

@Test("Gives up after maxAttempts on persistent 500")
func gionUpAfterMax() async throws {
    let scripted = ScriptedTransport([500, 500, 500, 500])
    let retrying = RetryingTransport(wrapping: scripted, policy: .init(maxAttempts: 3, baseDelay: 0), sleep: noSleep)
    let (_, resp) = try await retrying.send(URLRequest(url: URL(string: "https://x")!))
    #expect(resp.statusCode == 500)
    #expect(scripted.callCount == 3)
}
