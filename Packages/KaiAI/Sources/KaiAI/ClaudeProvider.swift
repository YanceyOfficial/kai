import Foundation
import KaiCore

/// Anthropic (Claude) provider using the Messages API with structured output.
public struct ClaudeProvider: LLMProvider {
    private let apiKey: String
    private let model: String
    private let transport: HTTPTransport
    private let maxTokens: Int?
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    /// `maxTokens` is the model's own output ceiling from its list entry (`ModelListing`).
    /// The Messages API requires one; without it a request fails with `noOutputLimit`
    /// rather than guessing.
    public init(apiKey: String, model: String, transport: HTTPTransport, maxTokens: Int?) {
        self.apiKey = apiKey
        self.model = model
        self.transport = transport
        self.maxTokens = maxTokens
    }

    public func generateCards(lemmas: [String], language: LanguageDomain, literaryExamples: Bool) async throws -> [GeneratedCard] {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let cleaned = lemmas.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return [] }
        let prompt = PromptBuilder(language: language, literaryExamples: literaryExamples)

        let json = try await send(system: prompt.systemPrompt(),
                                  user: prompt.cardUserPrompt(lemmas: cleaned),
                                  schema: CardSchema.cardBatch)
        do { return try JSONDecoder().decode(GeneratedCardBatch.self, from: json).cards }
        catch { throw AIError.decoding("Cards: \(error)") }
    }

    public func generateStory(words: [String], language: LanguageDomain) async throws -> GeneratedStory {
        guard !apiKey.isEmpty else { throw AIError.missingAPIKey }
        let cleaned = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { throw AIError.emptyResponse }
        let prompt = PromptBuilder(language: language, literaryExamples: false)

        let json = try await send(system: prompt.storySystemPrompt(),
                                  user: prompt.storyUserPrompt(words: cleaned),
                                  schema: StorySchema.story)
        do { return try JSONDecoder().decode(GeneratedStory.self, from: json) }
        catch { throw AIError.decoding("Story: \(error)") }
    }

    // MARK: Shared structured-output plumbing

    /// Builds the Messages request, sends it, and returns the inner JSON string (which the
    /// caller decodes against its schema type).
    private func send(system: String, user: String, schema: JSONSchema) async throws -> Data {
        guard let maxTokens else { throw AIError.noOutputLimit(model) }
        struct Body: Encodable {
            let model: String
            let max_tokens: Int
            let system: String
            let messages: [[String: String]]
            let output_config: OutputConfig
        }
        struct OutputConfig: Encodable { let format: Format }
        struct Format: Encodable { let type = "json_schema"; let schema: JSONSchema }

        let body = Body(
            model: model, max_tokens: maxTokens, system: system,
            messages: [["role": "user", "content": user]],
            output_config: OutputConfig(format: Format(schema: schema))
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        // A non-streaming reply arrives all at once, when the model has written it —
        // a batch of cards can take minutes, well past URLSession's 60-second default.
        request.timeoutInterval = 600
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await transportSend(request)

        // Anthropic returns the JSON string inside content[0].text.
        struct Envelope: Decodable {
            struct Block: Decodable { let type: String; let text: String? }
            let content: [Block]
            let stop_reason: String?
        }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch { throw AIError.decoding("Envelope: \(error)") }
        // Cut off at the token limit: the JSON is incomplete, and would only fail to decode.
        if envelope.stop_reason == "max_tokens" { throw AIError.truncated }
        guard let text = envelope.content.first(where: { $0.type == "text" })?.text,
              let jsonData = text.data(using: .utf8) else {
            throw AIError.emptyResponse
        }
        return jsonData
    }

    /// Sends the request through the transport, mapping errors and non-2xx responses.
    private func transportSend(_ request: URLRequest) async throws -> Data {
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
        return data
    }
}
