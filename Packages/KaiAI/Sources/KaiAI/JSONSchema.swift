import Foundation

/// A minimal JSON-Schema builder that serializes deterministically for structured-output requests.
public indirect enum JSONSchema: Encodable, Sendable {
    case string
    case stringEnum([String])
    case array(JSONSchema)
    case object([String: JSONSchema], required: [String])

    private enum CodingKeys: String, CodingKey {
        case type, items, properties, required, additionalProperties, `enum`
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string:
            try c.encode("string", forKey: .type)
        case .stringEnum(let values):
            try c.encode("string", forKey: .type)
            try c.encode(values, forKey: .enum)
        case .array(let element):
            try c.encode("array", forKey: .type)
            try c.encode(element, forKey: .items)
        case .object(let properties, let required):
            try c.encode("object", forKey: .type)
            try c.encode(properties, forKey: .properties)
            try c.encode(required, forKey: .required)
            try c.encode(false, forKey: .additionalProperties)
        }
    }
}
