public import Binary
public import Byte
public import RFC_1035
import Binary

extension RFC_1035.Question: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_1035.Wire.appendName(value.name, into: &buffer)
        buffer.append(contentsOf: value.type.rawValue.bytes(endianness: .big))
        buffer.append(contentsOf: value.`class`.rawValue.bytes(endianness: .big))
    }
}
