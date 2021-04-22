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
    fileprivate enum Token {
        case pOpen, pClose, textBlock(String)
    }
}

extension Array where Element == Obj.Token {
    fileprivate mutating func absorbText(_ textBuffer: inout String) {
        if textBuffer != "" {
            self.append(.textBlock(textBuffer))
            textBuffer = ""
        }
    }
}

extension Obj {
    private static func tokenize(_ sExpr: String) -> [Token] {
        var tokens = [Token]()
        var textBuffer = ""

        for c in sExpr {
            switch c {
            case "(", "[":
                tokens.absorbText(&textBuffer)
                tokens.append(.pOpen)
            case ")", "]":
                tokens.absorbText(&textBuffer)
                tokens.append(.pClose)
            case let c where c.isWhitespace || c.isNewline:
                tokens.absorbText(&textBuffer)
            default:
                textBuffer.append(c)
            }
        }
        return tokens
    }

    public static func read(sExpr: String) throws -> [Obj] {
        let tokens = tokenize(sExpr)
        var stack: [[Obj]] = [[]]
        for token in tokens {
            switch token {
            case .pOpen:
                stack.append([])
            case .pClose:
                guard let p = stack.popLast(), stack.count > 0 else {
                    throw LexicalAnalysisError.extraCloseParenthesis
                }
                stack[stack.count-1].append(Obj.S(p))
            case .textBlock(let text):
                // to int
                if let int = Int(text) {
                    stack[stack.count-1].append(Obj.int(int))
                }
                // to double
                else if let double = Double(text) {
                    stack[stack.count-1].append(Obj.double(double))
                }
                // to string
                else if let f = text.first, let l = text.last, f == "\"", l == "\"" {
                    var string = text
                    string.removeLast()
                    string.removeFirst()
                    stack[stack.count-1].append(Obj.string(string))
                }
                //to bool(true)
                else if text == "#t" {
                    stack[stack.count-1].append(Obj.bool(true))
                }
                // to bool(false)
                else if text == "#f" {
                    stack[stack.count-1].append(Obj.bool(false))
                }
                // to symbol
                else {
                    stack[stack.count-1].append(Obj.symbol("'" + text))
                }
            }
        }
        guard stack.count == 1 else {
            throw LexicalAnalysisError.notClosedParenthesis
        }
        return stack[0]
    }
}

enum LexicalAnalysisError: Error {
    case extraCloseParenthesis
    case notClosedParenthesis
}
