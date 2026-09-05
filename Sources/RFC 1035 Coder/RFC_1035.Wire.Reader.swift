import Byte
import RFC_1035

extension RFC_1035.Wire {

    struct Reader {

        let bytes: [Byte]

        private(set) var index: Int

        init(_ bytes: [Byte]) {
            self.bytes = bytes
            self.index = 0
        }
    }
}

extension RFC_1035.Wire.Reader {

    var isAtEnd: Bool { index >= bytes.count }

    mutating func byte() throws(RFC_1035.Message.Failure) -> UInt8 {
        guard index < bytes.count else { throw .truncated }
        defer { index += 1 }
        return bytes[index].bitPattern
    }

    mutating func uint16() throws(RFC_1035.Message.Failure) -> UInt16 {
        let hi = try byte()
        let lo = try byte()
        return (UInt16(hi) << 8) | UInt16(lo)
    }

    mutating func uint32() throws(RFC_1035.Message.Failure) -> UInt32 {
        let a = try byte()
        let b = try byte()
        let c = try byte()
        let d = try byte()
        return (UInt32(a) << 24) | (UInt32(b) << 16) | (UInt32(c) << 8) | UInt32(d)
    }

    mutating func take(_ count: Int) throws(RFC_1035.Message.Failure) -> [Byte] {
        guard count >= 0, bytes.count - index >= count else { throw .truncated }
        let slice = bytes[index..<index + count]
        index += count
        return Array(slice)
    }

    func expectEnd() throws(RFC_1035.Message.Failure) {
        guard isAtEnd else { throw .trailingData(bytes.count - index) }
    }
}

extension RFC_1035.Wire.Reader {

    private static var discriminantMask: UInt8 { 0xC0 }

    private static var labelDiscriminant: UInt8 { 0x00 }

    private static var pointerDiscriminant: UInt8 { 0xC0 }

    private static var lengthMask: UInt8 { 0x3F }

    mutating func name() throws(RFC_1035.Message.Failure) -> RFC_1035.Domain {
        var rawLabels: [[Byte]] = []
        var totalLength = 0
        var position = index
        var followedPointer = false
        var cursorAfter = index
        var lowestPointerPosition = Int.max

        while true {
            guard position < bytes.count else { throw .truncated }
            let lengthOctet = bytes[position].bitPattern

            switch lengthOctet & Self.discriminantMask {
            case Self.labelDiscriminant:
                let labelLength = Int(lengthOctet & Self.lengthMask)
                if labelLength == 0 {

                    totalLength += 1
                    if !followedPointer { cursorAfter = position + 1 }
                    index = cursorAfter
                    return try Self.assemble(rawLabels)
                }
                let labelStart = position + 1
                let labelEnd = labelStart + labelLength
                guard labelEnd <= bytes.count else { throw .truncated }
                totalLength += 1 + labelLength
                guard totalLength <= RFC_1035.Domain.Limits.maxLength else {
                    throw .nameTooLong
                }
                rawLabels.append(Array(bytes[labelStart..<labelEnd]))
                position = labelEnd

            case Self.pointerDiscriminant:
                guard position + 1 < bytes.count else { throw .truncated }
                let offset =
                    (Int(lengthOctet & Self.lengthMask) << 8)
                    | Int(bytes[position + 1].bitPattern)
                guard offset < position else { throw .pointerNotBackward }
                guard position < lowestPointerPosition else { throw .pointerLoop }
                lowestPointerPosition = position
                if !followedPointer {
                    cursorAfter = position + 2
                    followedPointer = true
                }
                position = offset

            default:

                throw .reservedLabelBits
            }
        }
    }

    private static func assemble(_ rawLabels: [[Byte]]) throws(RFC_1035.Message.Failure) -> RFC_1035.Domain {
        guard !rawLabels.isEmpty else { return .root }

        var labels: [RFC_1035.Domain.Label] = []
        labels.reserveCapacity(rawLabels.count)
        for raw in rawLabels {
            do throws(RFC_1035.Domain.Label.Error) {
                labels.append(try RFC_1035.Domain.Label(octets: raw))
            } catch {
                throw .invalidLabel(error)
            }
        }

        do throws(RFC_1035.Domain.Error) {
            return try RFC_1035.Domain(labels: labels)
        } catch {
            throw .invalidDomain(error)
        }
    }
}

extension RFC_1035.Wire.Reader {

    mutating func question() throws(RFC_1035.Message.Failure) -> RFC_1035.Question {
        let name = try self.name()
        let type = RFC_1035.RecordType(rawValue: try uint16())
        let recordClass = RFC_1035.RecordClass(rawValue: try uint16())
        return RFC_1035.Question(name: name, type: type, class: recordClass)
    }

    mutating func resourceRecord() throws(RFC_1035.Message.Failure) -> RFC_1035.ResourceRecord {
        let name = try self.name()
        let type = RFC_1035.RecordType(rawValue: try uint16())
        let recordClass = RFC_1035.RecordClass(rawValue: try uint16())
        let ttl = try uint32()
        let rdlength = Int(try uint16())
        let rdataEnd = index + rdlength
        guard rdataEnd <= bytes.count else { throw .truncated }

        let data = try recordData(type: type, rdlength: rdlength, rdataEnd: rdataEnd)
        guard index == rdataEnd else { throw .rdataLengthMismatch }

        return RFC_1035.ResourceRecord(
            name: name,
            type: type,
            class: recordClass,
            ttl: ttl,
            data: data
        )
    }

    mutating func characterString() throws(RFC_1035.Message.Failure) -> RFC_1035.CharacterString {
        let length = Int(try byte())
        let content = try take(length)

        do throws(RFC_1035.CharacterString.Error) {
            return try RFC_1035.CharacterString(bytes: content)
        } catch {
            throw .invalidCharacterString(error)
        }
    }

    private mutating func address(_ rdlength: Int) throws(RFC_1035.Message.Failure) -> RFC_1035.ResourceRecord.A {
        let octets = try take(rdlength)
        do throws(RFC_1035.ResourceRecord.A.Error) {
            return try RFC_1035.ResourceRecord.A(octets: octets)
        } catch {
            throw .rdataLengthMismatch
        }
    }

    private mutating func recordData(
        type: RFC_1035.RecordType,
        rdlength: Int,
        rdataEnd: Int
    ) throws(RFC_1035.Message.Failure) -> RFC_1035.ResourceRecord.Data {
        switch type {
        case .a:
            return .a(try address(rdlength))

        case .ns:
            return .ns(try name())

        case .cname:
            return .cname(try name())

        case .ptr:
            return .ptr(try name())

        case .mx:
            let preference = try uint16()
            let exchange = try name()
            return .mx(preference: preference, exchange: exchange)

        case .soa:
            let mname = try name()
            let rname = try name()
            let serial = try uint32()
            let refresh = try uint32()
            let retry = try uint32()
            let expire = try uint32()
            let minimum = try uint32()
            return .soa(
                RFC_1035.ResourceRecord.SOA(
                    mname: mname,
                    rname: rname,
                    serial: serial,
                    refresh: refresh,
                    retry: retry,
                    expire: expire,
                    minimum: minimum
                )
            )

        case .txt:
            var strings: [RFC_1035.CharacterString] = []
            while index < rdataEnd {
                strings.append(try characterString())
            }
            return .txt(strings)

        default:
            return .opaque(try take(rdlength))
        }
    }
}
