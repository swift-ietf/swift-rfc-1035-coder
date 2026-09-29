public import Binary
public import Byte
public import RFC_1035

extension RFC_1035.CharacterString: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(Byte(bitPattern: UInt8(truncatingIfNeeded: value.bytes.count)))
        buffer.append(contentsOf: value.bytes)
    }
}
