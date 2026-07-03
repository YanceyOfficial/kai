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

        let json = try await send(system: prompt.systemPrompt(),
                                  user: prompt.cardUserPrompt(lemmas: cleaned),
                                  schemaName: "word_cards", schema: CardSchema.cardBatch)
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
                                  schemaName: "daily_story", schema: StorySchema.story)
        do { return try JSONDecoder().decode(GeneratedStory.self, from: json) }
        catch { throw AIError.decoding("Story: \(error)") }
    }

    // MARK: Shared structured-output plumbing

    private func send(system: String, user: String, schemaName: String, schema: JSONSchema) async throws -> Data {
        struct Body: Encodable {
            let model: String
            let messages: [[String: String]]
            let response_format: ResponseFormat
            let max_completion_tokens: Int
        }
        struct ResponseFormat: Encodable { let type = "json_schema"; let json_schema: Schema }
        struct Schema: Encodable { let name: String; let strict = true; let schema: JSONSchema }

        let body = Body(
            model: model,
            messages: [
                ["role": "system", "content": system],
                ["role": "user", "content": user],
            ],
            response_format: ResponseFormat(json_schema: Schema(name: schemaName, schema: schema)),
            max_completion_tokens: maxTokens
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await transportSend(request)

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
        return jsonData
    }

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
