import Byte

enum Hex {

    static func bytes(_ hex: String) -> [Byte] {
        var result: [Byte] = []
        result.reserveCapacity(hex.count / 2)
        var iterator = hex.makeIterator()
        while let high = iterator.next(), let low = iterator.next() {
            guard let value = UInt8(String([high, low]), radix: 16) else {
                continue
            }
            result.append(Byte(bitPattern: value))
        }
        return result
    }

    static func string(_ bytes: [Byte]) -> String {
        var out = ""
        out.reserveCapacity(bytes.count * 2)
        for byte in bytes {
            let value = byte.bitPattern
            out.append(digit(value >> 4))
            out.append(digit(value & 0x0F))
        }
        return out
    }

    private static func digit(_ nibble: UInt8) -> Character {
        nibble < 10
            ? Character(Unicode.Scalar(nibble + 0x30))
            : Character(Unicode.Scalar(nibble - 10 + 0x61))
    }
}

