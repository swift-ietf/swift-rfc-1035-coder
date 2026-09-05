public import Binary_Endianness
public import Binary_Serializable
public import Byte
public import RFC_1035
import Binary_Standard_Library_Integration

extension RFC_1035.ResourceRecord: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        RFC_1035.Wire.appendName(value.name, into: &buffer)
        buffer.append(contentsOf: value.type.rawValue.bytes(endianness: .big))
        buffer.append(contentsOf: value.`class`.rawValue.bytes(endianness: .big))
        buffer.append(contentsOf: value.ttl.bytes(endianness: .big))

        let rdata = value.data.bytes
        buffer.append(contentsOf: UInt16(rdata.count).bytes(endianness: .big))
        buffer.append(contentsOf: rdata)
    }
}
