import Byte
import Byte
import Coder
import Coder
import Cursor
import Parser
import RFC_1035
import RFC_1035_Coder
import Serializer
import Testing

@Suite
struct `RFC_1035.Domain.Coder Tests` {

    @Test
    func `reads a domain and stops at the first byte outside the presentation syntax`() throws {
        var input: ArraySlice<Byte> = "example.com rest"
        #expect(try RFC_1035.Domain.coder.parse(&input) == (try RFC_1035.Domain("example.com")))
        #expect(input.first == Byte(bitPattern: 0x20))
    }

    @Test
    func `rejects an invalid label and restores the cursor`() {
        var input: ArraySlice<Byte> = "-example.com"
        #expect(throws: RFC_1035.Domain.Error.invalidLabel(.startsWithHyphen("-example"))) {
            try RFC_1035.Domain.coder.parse(&input)
        }
        #expect(input.count == 12)
    }

    @Test
    func `rejects empty input`() {
        var input: ArraySlice<Byte> = ""
        #expect(throws: RFC_1035.Domain.Error.empty) {
            try RFC_1035.Domain.coder.parse(&input)
        }
    }

    @Test
    func `round-trips`() throws {
        let domain = try RFC_1035.Domain("api.example.com")
        #expect(try RFC_1035.Domain.coder.serialize(domain) == "api.example.com")

        var input = try RFC_1035.Domain.coder.serialize(domain)[...]
        #expect(try RFC_1035.Domain.coder.parse(&input) == domain)
    }

    @Test
    func `a label reads and stops at the period`() throws {
        var input: ArraySlice<Byte> = "example.com"
        #expect(try RFC_1035.Domain.Label.coder.parse(&input) == "example")
        #expect(input.first == Byte(bitPattern: 0x2E))
    }

    @Test
    func `a label round-trips`() throws {
        let label = try RFC_1035.Domain.Label("example")
        #expect(try RFC_1035.Domain.Label.coder.serialize(label) == "example")
    }
}
