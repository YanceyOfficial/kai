import Foundation
import KaiCore

/// Anthropic (Claude) provider using the Messages API with structured output.
public struct ClaudeProvider: LLMProvider {
    private let apiKey: String
    private let model: String
    private let transport: HTTPTransport
    private let maxTokens: Int
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    public init(apiKey: String, model: String = "claude-opus-4-8", transport: HTTPTransport, maxTokens: Int = 8000) {
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

        // Body is assembled as an Encodable so the schema serializes to standard JSON Schema.
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
            model: model,
            max_tokens: maxTokens,
            system: prompt.systemPrompt(),
            messages: [["role": "user", "content": prompt.cardUserPrompt(lemmas: cleaned)]],
            output_config: OutputConfig(format: Format(schema: CardSchema.cardBatch))
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(body)

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

        // Anthropic returns the JSON string inside content[0].text.
        struct Envelope: Decodable { struct Block: Decodable { let type: String; let text: String? }; let content: [Block] }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch { throw AIError.decoding("Envelope: \(error)") }
        guard let text = envelope.content.first(where: { $0.type == "text" })?.text,
              let jsonData = text.data(using: .utf8) else {
            throw AIError.emptyResponse
        }
        do { return try JSONDecoder().decode(GeneratedCardBatch.self, from: jsonData).cards }
        catch { throw AIError.decoding("Cards: \(error)") }
    }
}
