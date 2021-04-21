import Foundation 

extension Obj {
    public static func S(_ array: [Obj]) -> Obj {
        var array = array
        guard let obj = array.popLast() else { return .null }
        var list = Obj.cons(obj, .null)
        while let obj = array.popLast() {
            list = Obj.cons(obj, list)
        }
        return list
    }
}

extension Obj {
    // TODO private
    public enum Token {
        case pOpen, pClose, textBlock(String)
    }

    extension Array where Element == Token {
        mutating func absorbText(textBuffer: inout String) {
            if textBuffer != "" {
                self.append(.textBlock(textBuffer))
                textBuffer = ""
            }
    }

    // TODO private
    public static func tokenize(_ sExpr: String) -> [Token] {
        var tokens = [Token]()
        var textBuffer = ""

        for c in sExpr {
            switch c {
            case "(":
                tokens.absorbText
                tokens.append(.pOpen)
            case ")":
                if textBuffer != "" {
                    tokens.append(.textBlock(textBuffer))
                    textBuffer = ""
                }
                tokens.append(.pClose)
            case let c where c.isWhitespace || c.isNewline:
                if textBuffer != "" {
                    tokens.append(.textBlock(textBuffer))
                    textBuffer = ""
                }
            default:
                textBuffer.append(c)
            }
        }

        return tokens
    }
}
