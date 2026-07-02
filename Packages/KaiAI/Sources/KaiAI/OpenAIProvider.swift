import Foundation
import KaiCore

/// OpenAI provider using Chat Completions with structured output (json_schema, strict).
public struct OpenAIProvider: LLMProvider {
    private let apiKey: String
    private let model: String
    private let transport: HTTPTransport
    private let maxTokens: Int
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    public init(apiKey: String, model: String = "gpt-5.5", transport: HTTPTransport, maxTokens: Int = 8000) {
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

        struct Body: Encodable {
            let model: String
            let messages: [[String: String]]
            let response_format: ResponseFormat
            let max_completion_tokens: Int
        }
        struct ResponseFormat: Encodable { let type = "json_schema"; let json_schema: Schema }
        struct Schema: Encodable { let name = "word_cards"; let strict = true; let schema: JSONSchema }

        let body = Body(
            model: model,
            messages: [
                ["role": "system", "content": prompt.systemPrompt()],
                ["role": "user", "content": prompt.cardUserPrompt(lemmas: cleaned)],
            ],
            response_format: ResponseFormat(json_schema: Schema(schema: CardSchema.cardBatch)),
            max_completion_tokens: maxTokens
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

        struct Envelope: Decodable {
            struct Choice: Decodable { struct Message: Decodable { let content: String? }; let message: Message }
            let choices: [Choice]
        }
        let envelope: Envelope
        do { envelope = try JSONDecoder().decode(Envelope.self, from: data) }
        catch { throw AIError.decoding("Envelope: \(error)") }
        guard let text = envelope.choices.first?.message.content,
              let jsonData = text.data(using: .utf8) else {
            throw AIError.emptyResponse
        }
        do { return try JSONDecoder().decode(GeneratedCardBatch.self, from: jsonData).cards }
        catch { throw AIError.decoding("Cards: \(error)") }
    }
}
