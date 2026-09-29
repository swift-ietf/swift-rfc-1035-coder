public import Binary
public import Byte
public import RFC_1035

extension RFC_1035.ResourceRecord.A: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.octets)
    }
}
