public import Byte
public import Coder
public import Cursor
public import Cursor
public import RFC_1035
import Parser
import Serializer

extension RFC_1035.Domain {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = RFC_1035.Domain

        public typealias Failure = RFC_1035.Domain.Error

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            let bytes = Scan.run(&input) { byte in Scan.isPresentationByte(byte) || byte == 0x2E }
            do throws(Failure) {
                return try RFC_1035.Domain(ascii: bytes)
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            Scan.append(output.rawValue, into: &buffer)
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}

extension RFC_1035.Domain: Coder.Codable {}
