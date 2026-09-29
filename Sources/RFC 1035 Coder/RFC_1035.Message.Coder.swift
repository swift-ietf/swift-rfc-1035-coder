public import Byte
public import Coder
public import Cursor
public import RFC_1035
import Binary
import Parser
import Serializer

extension RFC_1035.Message {

    public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

        public typealias Output = RFC_1035.Message

        public typealias Failure = RFC_1035.Message.Failure

        public init() {}

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            var reader = RFC_1035.Wire.Reader(Scan.drain(&input))

            do throws(Failure) {
                let id = try reader.uint16()
                let flags = try reader.uint16()
                let qdcount = Int(try reader.uint16())
                let ancount = Int(try reader.uint16())
                let nscount = Int(try reader.uint16())
                let arcount = Int(try reader.uint16())

                let header = try RFC_1035.Message.Header(id: id, flags: flags)

                var questions: [RFC_1035.Question] = []
                questions.reserveCapacity(qdcount)
                for _ in 0..<qdcount { questions.append(try reader.question()) }

                var answers: [RFC_1035.ResourceRecord] = []
                answers.reserveCapacity(ancount)
                for _ in 0..<ancount { answers.append(try reader.resourceRecord()) }

                var authority: [RFC_1035.ResourceRecord] = []
                authority.reserveCapacity(nscount)
                for _ in 0..<nscount { authority.append(try reader.resourceRecord()) }

                var additional: [RFC_1035.ResourceRecord] = []
                additional.reserveCapacity(arcount)
                for _ in 0..<arcount { additional.append(try reader.resourceRecord()) }

                try reader.expectEnd()

                return RFC_1035.Message(
                    header: header,
                    questions: questions,
                    answers: answers,
                    authority: authority,
                    additional: additional
                )
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            RFC_1035.Message.serialize(output, into: &buffer)
        }
    }

    public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
}
