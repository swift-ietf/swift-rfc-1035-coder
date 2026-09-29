public import Binary
public import Byte
public import RFC_1035
import Binary

extension RFC_1035.ResourceRecord.SOA: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_1035.Wire.appendName(value.mname, into: &buffer)
        RFC_1035.Wire.appendName(value.rname, into: &buffer)
        buffer.append(contentsOf: value.serial.bytes(endianness: .big))
        buffer.append(contentsOf: value.refresh.bytes(endianness: .big))
        buffer.append(contentsOf: value.retry.bytes(endianness: .big))
        buffer.append(contentsOf: value.expire.bytes(endianness: .big))
        buffer.append(contentsOf: value.minimum.bytes(endianness: .big))
    }
}
