import Byte

enum Vectors {

    static let queryExampleA =
        "2b7d01000001000000000000076578616d706c6503636f6d0000010001"
    static let responseExampleA =
        "2b7d81800001000200000000076578616d706c6503636f6d0000010001"
        + "c00c000100010000001d0004ac4293f3"
        + "c00c000100010000001d00046814179a"

    static let queryExampleAAAA =
        "2b7d01000001000000000000076578616d706c6503636f6d00001c0001"
    static let responseExampleAAAA =
        "2b7d81800001000200000000076578616d706c6503636f6d00001c0001"
        + "c00c001c0001000000b30010260647000010000000000000ac4293f3"
        + "c00c001c0001000000b300102606470000100000000000006814179a"

    static let queryWWWExampleA =
        "2b7d0100000100000000000003777777076578616d706c6503636f6d0000010001"
    static let responseWWWExampleA =
        "2b7d8180000100020000000003777777076578616d706c6503636f6d0000010001"
        + "c00c000100010000005100046814179a"
        + "c00c00010001000000510004ac4293f3"

    static func questions(_ names: [String]) -> ArraySlice<Byte> {
        var hex = "00000000" + Hex.string(UInt16(names.count).bigEndianBytes) + "000000000000"
        for name in names {
            hex += name + "00010001"
        }
        return Hex.bytes(hex)[...]
    }
}

extension UInt16 {

    fileprivate var bigEndianBytes: [Byte] {
        [Byte(bitPattern: UInt8(self >> 8)), Byte(bitPattern: UInt8(self & 0xFF))]
    }
}
