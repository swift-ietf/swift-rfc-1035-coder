public import Binary_Endianness
public import Binary_Serializable
public import Byte
public import RFC_1035
import Binary_Standard_Library_Integration

extension RFC_1035.Message: @retroactive Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.header.id.bytes(endianness: .big))
        buffer.append(contentsOf: value.header.flags.bytes(endianness: .big))
        buffer.append(contentsOf: UInt16(value.questions.count).bytes(endianness: .big))
        buffer.append(contentsOf: UInt16(value.answers.count).bytes(endianness: .big))
        buffer.append(contentsOf: UInt16(value.authority.count).bytes(endianness: .big))
        buffer.append(contentsOf: UInt16(value.additional.count).bytes(endianness: .big))

        for question in value.questions {
            RFC_1035.Question.serialize(question, into: &buffer)
        }
        for record in value.answers {
            RFC_1035.ResourceRecord.serialize(record, into: &buffer)
        }
        for record in value.authority {
            RFC_1035.ResourceRecord.serialize(record, into: &buffer)
        }
        for record in value.additional {
            RFC_1035.ResourceRecord.serialize(record, into: &buffer)
        }
    }
}
