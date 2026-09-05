import Byte
import RFC_1035

extension RFC_1035.Wire {

    static func appendName<Buffer: RangeReplaceableCollection>(
        _ domain: RFC_1035.Domain,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for label in domain.labels {
            let octets = label.octets
            buffer.append(Byte(bitPattern: UInt8(octets.count)))
            buffer.append(contentsOf: octets)
        }
        buffer.append(Byte(bitPattern: 0))
    }
}
