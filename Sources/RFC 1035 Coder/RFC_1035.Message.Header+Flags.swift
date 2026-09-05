public import RFC_1035

extension RFC_1035.Message.Header {

    static let qrMask: UInt16 = 0x8000

    static let opcodeMask: UInt16 = 0x7800

    static let opcodeShift: UInt16 = 11

    static let reservedMask: UInt16 = 0x0070

    static let rcodeMask: UInt16 = 0x000F
}

extension RFC_1035.Message.Header.Options {

    static let mask: UInt16 = 0x0780
}

extension RFC_1035.Message.Header {

    public var flags: UInt16 {
        var word: UInt16 = 0
        if kind == .response { word |= Self.qrMask }
        word |= (UInt16(opcode.rawValue) << Self.opcodeShift) & Self.opcodeMask
        word |= options.rawValue & Options.mask
        word |= UInt16(rcode.rawValue) & Self.rcodeMask
        return word
    }

    public init(id: UInt16, flags: UInt16) throws(RFC_1035.Message.Failure) {
        guard flags & Self.reservedMask == 0 else {
            throw .nonzeroReserved
        }
        let kind: Kind = (flags & Self.qrMask) != 0 ? .response : .query
        let opcode = Opcode(rawValue: UInt8((flags & Self.opcodeMask) >> Self.opcodeShift))
        let options = Options(rawValue: flags & Options.mask)
        let rcode = Rcode(rawValue: UInt8(flags & Self.rcodeMask))
        self.init(id: id, kind: kind, opcode: opcode, options: options, rcode: rcode)
    }
}
