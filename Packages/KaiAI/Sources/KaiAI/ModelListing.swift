import Foundation

/// One model a provider offers, as its list-models API describes it.
public struct ModelInfo: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let displayName: String
    /// The most output tokens the model may produce in one reply, when the provider says
    /// (Anthropic does; OpenAI's list does not).
    public let maxOutputTokens: Int?

    public init(id: String, displayName: String, maxOutputTokens: Int?) {
        self.id = id
        self.displayName = displayName
        self.maxOutputTokens = maxOutputTokens
    }
}

/// Fetches a provider's live model list with the user's key — which doubles as the
/// check that the key works: a refused key fails here, before any card is generated.
/// The same approach as Exodus's settings (`list-models/`).
public enum ModelListing {
    public static func models(
        for kind: LLMProviderKind,
        apiKey: String,
        transport: HTTPTransport = URLSessionTransport()
    ) async throws -> [ModelInfo] {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw AIError.missingAPIKey }
        switch kind {
        case .claude: return try await anthropic(key: key, transport: transport)
        case .openai: return try await openAI(key: key, transport: transport)
        }
    }

    // MARK: Anthropic

    /// `GET /v1/models`, newest first, paged by `after_id`. Each model reports its
    /// output ceiling as `max_tokens`.
    private static func anthropic(key: String, transport: HTTPTransport) async throws -> [ModelInfo] {
        struct Page: Decodable {
            struct Model: Decodable { let id: String; let display_name: String?; let max_tokens: Int? }
            let data: [Model]
            let has_more: Bool?
            let last_id: String?
        }
        var models: [ModelInfo] = []
        var after: String?
        repeat {
            var components = URLComponents(string: "https://api.anthropic.com/v1/models")!
            components.queryItems = [URLQueryItem(name: "limit", value: "1000")]
                + (after.map { [URLQueryItem(name: "after_id", value: $0)] } ?? [])
            var request = URLRequest(url: components.url!)
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let page: Page = try await fetch(request, transport: transport)
            models += page.data.map { ModelInfo(id: $0.id, displayName: $0.display_name ?? $0.id, maxOutputTokens: $0.max_tokens) }
            // Stop unless the page moved the cursor on, so a misbehaving reply can't loop.
            let next = page.has_more == true ? page.last_id : nil
            after = next != after ? next : nil
        } while after != nil
        return models
    }

    // MARK: OpenAI

    /// `GET /v1/models`: the whole catalog, unordered, embeddings and speech models
    /// included. Kept: the chat models (`gpt-…`, `o1`/`o3`/`o4…`), without the audio,
    /// realtime, image, search and transcription variants; newest first.
    private static func openAI(key: String, transport: HTTPTransport) async throws -> [ModelInfo] {
        struct Page: Decodable {
            struct Model: Decodable { let id: String; let created: Int? }
            let data: [Model]
        }
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let page: Page = try await fetch(request, transport: transport)
        return page.data
            .filter { isChatModel($0.id) }
            .sorted { ($0.created ?? 0) > ($1.created ?? 0) }
            .map { ModelInfo(id: $0.id, displayName: $0.id, maxOutputTokens: nil) }
    }

    static func isChatModel(_ id: String) -> Bool {
        let isFamily = id.hasPrefix("gpt-") || id.range(of: #"^o\d"#, options: .regularExpression) != nil
        let excluded = ["audio", "realtime", "transcribe", "tts", "image", "search", "embedding", "instruct"]
        return isFamily && !excluded.contains { id.contains($0) }
    }

    // MARK: Plumbing

    private static func fetch<T: Decodable>(_ request: URLRequest, transport: HTTPTransport) async throws -> T {
        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as AIError {
            throw error
        } catch is CancellationError {
            throw AIError.cancelled
        } catch {
            throw AIError.transport(String(describing: error))
        }
        guard (200...299).contains(response.statusCode) else {
            throw AIError.http(status: response.statusCode, body: String(decoding: data, as: UTF8.self))
        }
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw AIError.decoding("Models: \(error)") }
    }
}
