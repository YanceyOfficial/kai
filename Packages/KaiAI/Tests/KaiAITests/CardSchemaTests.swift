import Foundation
import Testing
@testable import KaiAI

@Test("Card schema encodes as a JSON-Schema object with a cards array and no additional properties")
func cardSchemaShape() throws {
    let data = try JSONEncoder().encode(CardSchema.cardBatch)
    let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    #expect(obj["type"] as? String == "object")
    #expect(obj["additionalProperties"] as? Bool == false)
    let props = obj["properties"] as! [String: Any]
    let cards = props["cards"] as! [String: Any]
    #expect(cards["type"] as? String == "array")
    let required = obj["required"] as! [String]
    #expect(required.contains("cards"))
}
