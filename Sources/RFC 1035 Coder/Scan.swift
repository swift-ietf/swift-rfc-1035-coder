import Byte
import Cursor

enum Scan {

    static func run<Input: Cursor.`Protocol`<Byte, Never>>(
        _ input: inout Input,
        while predicate: (UInt8) -> Bool
    ) -> [Byte] {
        var bytes: [Byte] = []
        while true {
            let mark = input.checkpoint
            guard let byte = input.next(), predicate(byte.bitPattern) else {
                input.seek(to: mark)
                return bytes
            }
            bytes.append(byte)
        }
    }

    static func drain<Input: Cursor.`Protocol`<Byte, Never>>(_ input: inout Input) -> [Byte] {
        var bytes: [Byte] = []
        while let byte = input.next() {
            bytes.append(byte)
        }
        return bytes
    }

    static func append<Buffer: RangeReplaceableCollection<Byte>>(_ string: String, into buffer: inout Buffer) {
        buffer.append(contentsOf: string.utf8.lazy.map(Byte.init(bitPattern:)))
    }

    static func isPresentationByte(_ byte: UInt8) -> Bool {
        (0x30...0x39).contains(byte) || (0x41...0x5A).contains(byte) || (0x61...0x7A).contains(byte) || byte == 0x2D
    }
}
