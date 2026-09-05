public import RFC_1035

extension RFC_1035.Message {

    public enum Failure: Swift.Error, Sendable, Equatable {

        case truncated

        case trailingData(_ remaining: Int)

        case reservedLabelBits

        case pointerNotBackward

        case pointerLoop

        case nameTooLong

        case invalidLabel(RFC_1035.Domain.Label.Error)

        case invalidDomain(RFC_1035.Domain.Error)

        case invalidCharacterString(RFC_1035.CharacterString.Error)

        case rdataLengthMismatch

        case nonzeroReserved
    }
}

extension RFC_1035.Message.Failure: CustomStringConvertible {
    public var description: String {
        switch self {
        case .truncated:
            return "DNS message truncated before a field was complete"

        case .trailingData(let remaining):
            return "DNS message has \(remaining) trailing byte(s) after the declared sections"

        case .reservedLabelBits:
            return "Domain name label used a reserved length discriminant (0b01 or 0b10)"

        case .pointerNotBackward:
            return "Compression pointer did not point strictly backward"

        case .pointerLoop:
            return "Compression pointers formed a loop"

        case .nameTooLong:
            return "Assembled domain name exceeded 255 octets"

        case .invalidLabel(let error):
            return "Invalid domain name label on the wire: \(error)"

        case .invalidDomain(let error):
            return "Invalid domain name on the wire: \(error)"

        case .invalidCharacterString(let error):
            return "Invalid character-string on the wire: \(error)"

        case .rdataLengthMismatch:
            return "Decoded RDATA length did not match RDLENGTH"

        case .nonzeroReserved:
            return "Header Z (reserved) bits were nonzero"
        }
    }
}
