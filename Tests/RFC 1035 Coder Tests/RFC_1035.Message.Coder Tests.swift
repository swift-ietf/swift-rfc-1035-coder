import Binary_Serializable
import Byte
import Byte_Standard_Library_Integration
import Coder
import Coder_Standard_Library_Integration
import Cursor_Standard_Library_Integration
import Parser
import RFC_1035
import RFC_1035_Coder
import Serializer
import Testing

@Suite
struct `RFC_1035.Message.Coder Tests` {
    @Suite struct `Captured Vectors` {}
    @Suite struct `RDATA` {}
    @Suite struct `Structure` {}
    @Suite struct `Name Compression` {}
    @Suite struct `Wire Labels` {}
}

extension `RFC_1035.Message.Coder Tests`.`Captured Vectors` {

    @Test
    func `example.com A query serializes byte-exactly`() throws {
        let question = RFC_1035.Question(name: try RFC_1035.Domain("example.com"), type: .a)
        let header = RFC_1035.Message.Header(id: 0x2b7d, kind: .query, options: [.recursionDesired])
        let message = RFC_1035.Message(header: header, questions: [question])

        #expect(try message.encoded() == Hex.bytes(Vectors.queryExampleA))

        var input = try message.encoded()[...]
        #expect(try RFC_1035.Message.coder.parse(&input) == message)
        #expect(input.isEmpty)
    }

    @Test
    func `example.com AAAA query serializes byte-exactly`() throws {
        let question = RFC_1035.Question(
            name: try RFC_1035.Domain("example.com"),
            type: RFC_1035.RecordType(rawValue: 28)
        )
        let header = RFC_1035.Message.Header(id: 0x2b7d, kind: .query, options: [.recursionDesired])
        let message = RFC_1035.Message(header: header, questions: [question])

        #expect(try message.encoded() == Hex.bytes(Vectors.queryExampleAAAA))
    }

    @Test
    func `www.example.com A query serializes byte-exactly`() throws {
        let question = RFC_1035.Question(name: try RFC_1035.Domain("www.example.com"), type: .a)
        let header = RFC_1035.Message.Header(id: 0x2b7d, kind: .query, options: [.recursionDesired])
        let message = RFC_1035.Message(header: header, questions: [question])

        #expect(try message.encoded() == Hex.bytes(Vectors.queryWWWExampleA))

        var input = try message.encoded()[...]
        #expect(try RFC_1035.Message(decoding: &input) == message)
    }

    @Test
    func `example.com A response parses with resolved answer names`() throws {
        var input = Hex.bytes(Vectors.responseExampleA)[...]
        let message = try RFC_1035.Message.coder.parse(&input)

        #expect(message.header.id == 0x2b7d)
        #expect(message.header.kind == .response)
        #expect(message.header.opcode == .query)
        #expect(message.header.rcode == .noError)
        #expect(message.header.options.contains(.recursionDesired))
        #expect(message.header.options.contains(.recursionAvailable))
        #expect(!message.header.options.contains(.authoritativeAnswer))

        #expect(message.questions.count == 1)
        #expect(message.answers.count == 2)
        #expect(message.authority.isEmpty)
        #expect(message.additional.isEmpty)

        let expectedName = try RFC_1035.Domain("example.com")
        #expect(message.questions[0].name == expectedName)
        #expect(message.questions[0].type == .a)
        #expect(message.questions[0].`class` == .internet)

        #expect(message.answers[0].name == expectedName)
        #expect(message.answers[1].name == expectedName)
        #expect(message.answers[0].ttl == 29)
        #expect(message.answers[0].data == .a(RFC_1035.ResourceRecord.A(172, 66, 147, 243)))
        #expect(message.answers[1].data == .a(RFC_1035.ResourceRecord.A(104, 20, 23, 154)))
    }

    @Test
    func `example.com AAAA response parses AAAA answers as opaque`() throws {
        var input = Hex.bytes(Vectors.responseExampleAAAA)[...]
        let message = try RFC_1035.Message.coder.parse(&input)

        #expect(message.answers.count == 2)
        #expect(message.answers[0].type == RFC_1035.RecordType(rawValue: 28))
        #expect(message.answers[0].data == .opaque(Hex.bytes("260647000010000000000000ac4293f3")))
    }

    @Test
    func `www.example.com A response parses with resolved answer names`() throws {
        var input = Hex.bytes(Vectors.responseWWWExampleA)[...]
        let message = try RFC_1035.Message.coder.parse(&input)

        let expectedName = try RFC_1035.Domain("www.example.com")
        #expect(message.questions[0].name == expectedName)
        #expect(message.answers.count == 2)
        #expect(message.answers[0].name == expectedName)
        #expect(message.answers[1].name == expectedName)
        #expect(message.answers[0].ttl == 0x51)
        #expect(message.answers[0].data == .a(RFC_1035.ResourceRecord.A(104, 20, 23, 154)))
        #expect(message.answers[1].data == .a(RFC_1035.ResourceRecord.A(172, 66, 147, 243)))
    }

    @Test
    func `responses round-trip logically through uncompressed re-serialization`() throws {
        for hex in [
            Vectors.responseExampleA,
            Vectors.responseExampleAAAA,
            Vectors.responseWWWExampleA,
        ] {
            let original = Hex.bytes(hex)
            var input = original[...]
            let message = try RFC_1035.Message.coder.parse(&input)

            let reserialized = try message.encoded()
            var reinput = reserialized[...]
            #expect(try RFC_1035.Message.coder.parse(&reinput) == message)

            #expect(reserialized.count > original.count)
            #expect(reserialized != original)
        }
    }
}

extension `RFC_1035.Message.Coder Tests`.`RDATA` {

    private typealias Record = RFC_1035.ResourceRecord

    @Test
    func `every typed RDATA format round-trips through the wire`() throws {
        let owner = try RFC_1035.Domain("example.com")

        let ns = Record(
            name: owner,
            type: .ns,
            class: .internet,
            ttl: 3600,
            data: .ns(try RFC_1035.Domain("ns1.example.com"))
        )
        let cname = Record(
            name: try RFC_1035.Domain("www.example.com"),
            type: .cname,
            class: .internet,
            ttl: 300,
            data: .cname(owner)
        )
        let ptr = Record(
            name: owner,
            type: .ptr,
            class: .internet,
            ttl: 60,
            data: .ptr(try RFC_1035.Domain("host.example.com"))
        )
        let mx = Record(
            name: owner,
            type: .mx,
            class: .internet,
            ttl: 3600,
            data: .mx(preference: 10, exchange: try RFC_1035.Domain("mail.example.com"))
        )
        let txt = Record(
            name: owner,
            type: .txt,
            class: .internet,
            ttl: 3600,
            data: .txt([
                try RFC_1035.CharacterString("v=spf1 -all"), try RFC_1035.CharacterString("hello"),
            ])
        )
        let soa = Record(
            name: owner,
            type: .soa,
            class: .internet,
            ttl: 3600,
            data: .soa(
                RFC_1035.ResourceRecord.SOA(
                    mname: try RFC_1035.Domain("ns1.example.com"),
                    rname: try RFC_1035.Domain("hostmaster.example.com"),
                    serial: 2_021_010_101,
                    refresh: 7200,
                    retry: 3600,
                    expire: 1_209_600,
                    minimum: 3600
                )
            )
        )
        let a = Record(
            name: owner,
            type: .a,
            class: .internet,
            ttl: 3600,
            data: .a(RFC_1035.ResourceRecord.A(93, 184, 216, 34))
        )
        let opaque = Record(
            name: owner,
            type: RFC_1035.RecordType(rawValue: 99),
            class: .internet,
            ttl: 3600,
            data: .opaque(Hex.bytes("deadbeef"))
        )

        let message = RFC_1035.Message(
            header: RFC_1035.Message.Header(id: 0x1234, kind: .response),
            answers: [ns, cname, ptr, mx, txt, soa, a, opaque]
        )

        var input = try message.encoded()[...]
        let parsed = try RFC_1035.Message.coder.parse(&input)
        #expect(parsed == message)
        #expect(parsed.answers.count == 8)

        #expect(parsed.answers[0].data == .ns(try RFC_1035.Domain("ns1.example.com")))
        #expect(parsed.answers[1].data == .cname(owner))
        #expect(parsed.answers[2].data == .ptr(try RFC_1035.Domain("host.example.com")))
        #expect(
            parsed.answers[3].data
                == .mx(preference: 10, exchange: try RFC_1035.Domain("mail.example.com"))
        )
        #expect(parsed.answers[6].data == .a(RFC_1035.ResourceRecord.A(93, 184, 216, 34)))

        #expect(parsed.answers[7].type == RFC_1035.RecordType(rawValue: 99))
        #expect(parsed.answers[7].data == .opaque(Hex.bytes("deadbeef")))
    }

    @Test
    func `TXT preserves multiple character-strings`() throws {
        let owner = try RFC_1035.Domain("example.com")
        let strings = [
            try RFC_1035.CharacterString("first"),
            try RFC_1035.CharacterString(""),
            try RFC_1035.CharacterString("third chunk"),
        ]
        let record = Record(
            name: owner,
            type: .txt,
            class: .internet,
            ttl: 3600,
            data: .txt(strings)
        )
        let message = RFC_1035.Message(
            header: RFC_1035.Message.Header(id: 1, kind: .response),
            answers: [record]
        )

        var input = try message.encoded()[...]
        let parsed = try RFC_1035.Message.coder.parse(&input)
        #expect(parsed.answers[0].data == .txt(strings))
    }

    @Test
    func `an A record whose RDLENGTH is not four is rejected`() throws {
        var input = Hex.bytes(
            "00008180000000010000000000" + "000100010000001d0003ac4293"
        )[...]
        #expect(throws: RFC_1035.Message.Failure.rdataLengthMismatch) {
            try RFC_1035.Message.coder.parse(&input)
        }
    }
}

extension `RFC_1035.Message.Coder Tests`.`Structure` {

    @Test
    func `truncation at every offset is rejected and the cursor is restored`() throws {
        let full = Hex.bytes(Vectors.queryExampleA)
        for cut in [0, 4, 11, 12, 15, 20, full.count - 1] {
            var input = full.prefix(cut)
            #expect(throws: RFC_1035.Message.Failure.truncated) {
                try RFC_1035.Message.coder.parse(&input)
            }
            #expect(input.count == cut)
        }
    }

    @Test
    func `trailing bytes after a complete message are rejected`() {
        var input = (Hex.bytes(Vectors.queryExampleA) + [Byte(bitPattern: 0xFF)])[...]
        #expect(throws: RFC_1035.Message.Failure.trailingData(1)) {
            try RFC_1035.Message.coder.parse(&input)
        }
    }

    @Test
    func `an ANCOUNT smaller than the records present leaves trailing data`() {
        var bytes = Hex.bytes(Vectors.responseExampleA)
        bytes[7] = Byte(bitPattern: 0x01)
        var input = bytes[...]
        #expect(throws: RFC_1035.Message.Failure.trailingData(16)) {
            try RFC_1035.Message.coder.parse(&input)
        }
    }

    @Test
    func `an ANCOUNT larger than the records present truncates`() {
        var bytes = Hex.bytes(Vectors.responseExampleA)
        bytes[7] = Byte(bitPattern: 0x03)
        var input = bytes[...]
        #expect(throws: RFC_1035.Message.Failure.truncated) {
            try RFC_1035.Message.coder.parse(&input)
        }
    }

    @Test
    func `a nonzero Z bit in the header is rejected`() {
        var bytes = Hex.bytes(Vectors.queryExampleA)
        bytes[3] = Byte(bitPattern: 0x10)
        var input = bytes[...]
        #expect(throws: RFC_1035.Message.Failure.nonzeroReserved) {
            try RFC_1035.Message.coder.parse(&input)
        }
    }
}

extension `RFC_1035.Message.Coder Tests`.`Name Compression` {

    private func names(_ hexNames: [String]) throws -> [RFC_1035.Domain] {
        var input = Vectors.questions(hexNames)
        return try RFC_1035.Message.coder.parse(&input).questions.map(\.name)
    }

    @Test
    func `reads an uncompressed name`() throws {
        #expect(try names(["03666f6f00"]) == [try RFC_1035.Domain("foo")])
    }

    @Test
    func `resolves a multi-level pointer chase`() throws {
        let read = try names(["03666f6f00", "03626172c00c", "c015"])
        #expect(read[0] == (try RFC_1035.Domain("foo")))
        #expect(read[1] == (try RFC_1035.Domain("bar.foo")))
        #expect(read[2] == (try RFC_1035.Domain("bar.foo")))
    }

    @Test
    func `rejects a forward pointer`() {
        #expect(throws: RFC_1035.Message.Failure.pointerNotBackward) {
            try names(["c020"])
        }
    }

    @Test
    func `rejects a self-pointer`() {
        #expect(throws: RFC_1035.Message.Failure.pointerNotBackward) {
            try names(["c00c"])
        }
    }

    @Test
    func `rejects a pointer loop`() {
        #expect(throws: RFC_1035.Message.Failure.pointerLoop) {
            try names(["03626172c00c"])
        }
    }

    @Test
    func `rejects the reserved 0b01 label discriminant`() {
        #expect(throws: RFC_1035.Message.Failure.reservedLabelBits) {
            try names(["40"])
        }
    }

    @Test
    func `rejects the reserved 0b10 label discriminant`() {
        #expect(throws: RFC_1035.Message.Failure.reservedLabelBits) {
            try names(["80"])
        }
    }

    @Test
    func `rejects a name exceeding 255 octets`() {
        let label = "3f" + String(repeating: "61", count: 63)
        #expect(throws: RFC_1035.Message.Failure.nameTooLong) {
            try names([String(repeating: label, count: 4)])
        }
    }

    @Test
    func `decodes the root name`() throws {
        #expect(try names(["00"]) == [RFC_1035.Domain.root])
    }

    @Test
    func `rejects a truncated label`() {
        #expect(throws: RFC_1035.Message.Failure.truncated) {
            try names(["056162"])
        }
    }
}

extension `RFC_1035.Message.Coder Tests`.`Wire Labels` {

    private func name(_ hex: String) throws -> RFC_1035.Domain {
        var input = Vectors.questions([hex])
        let message = try RFC_1035.Message.coder.parse(&input)
        return try #require(message.questions.first).name
    }

    @Test
    func `decodes a digit-first label`() throws {
        let domain = try name("0433636f6d03636f6d00")
        #expect(domain.labels.map(\.rawValue) == ["3com", "com"])
    }

    @Test
    func `decodes an underscore label`() throws {
        let domain = try name("065f646d617263076578616d706c6500")
        #expect(domain.labels.map(\.rawValue) == ["_dmarc", "example"])
        #expect(domain.name == "_dmarc.example")
    }

    @Test
    func `escapes a period inside a label`() throws {
        let domain = try name("03612e6200")
        #expect(domain.labels.map(\.rawValue) == [#"a\.b"#])
    }

    @Test
    func `decodes the root name`() throws {
        let domain = try name("00")
        #expect(domain.labels.isEmpty)
        #expect(domain.rawValue == ".")
    }

    @Test
    func `round-trips a wire-legal name through the writer`() throws {
        let hex = "065f646d617263076578616d706c6500"
        let question = RFC_1035.Question(name: try name(hex), type: .a)
        #expect(Hex.string(question.bytes) == hex + "00010001")
    }

    @Test
    func `round-trips the root name through the writer`() throws {
        let question = RFC_1035.Question(name: RFC_1035.Domain.root, type: .a)
        #expect(Hex.string(question.bytes) == "0000010001")
    }
}
