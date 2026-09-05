import ASCII
import ASCII_Serializer
import Binary_Serializable
import Byte
import RFC_1035
import RFC_1035_Coder
import Testing

@Suite
struct `Serialization Equivalence` {

    private func expectEquivalent<T: ASCII.Serializable & Binary.Serializable>(
        _ value: T,
        _ label: Comment
    ) {
        var ascii: [ASCII.Code] = []
        T.serialize(value, into: &ascii)
        var wire: [Byte] = []
        T.serialize(value, into: &wire)
        #expect(ascii.map(\.byte) == wire, label)
    }

    @Test
    func `Domain verbs agree`() throws {
        expectEquivalent(try RFC_1035.Domain("example.com"), "example.com")
        expectEquivalent(try RFC_1035.Domain("api.Example.COM"), "api.Example.COM")
    }

    @Test
    func `Label verbs agree`() throws {
        expectEquivalent(try RFC_1035.Domain.Label("example"), "example")
    }

    @Test
    func `A domain parses through ASCII.Parseable`() throws {
        let domain = try RFC_1035.Domain(ascii: [Byte](utf8: "example.com"))
        #expect(domain.serialized == [Byte](utf8: "example.com"))
        #expect(String(ascii: domain) == "example.com")
    }
}
