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
        var isNotString = true

        for c in sExpr {
            switch c {
            case "\"":
                isNotString = !isNotString
                textBuffer.append(c)
            case "(", "[":
                tokens.absorbText(&textBuffer)
                tokens.append(.pOpen)
            case ")", "]":
                tokens.absorbText(&textBuffer)
                tokens.append(.pClose)
            case let c where isNotString && (c.isWhitespace || c.isNewline):
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
            case .textBlock(var text):
                let last = stack.count - 1
                
                if let int = Int(text) {
                    stack[last].append(Obj.int(int))
                } else if let double = Double(text) {
                    stack[last].append(Obj.double(double))
                } else if let f = text.first, let l = text.last, f == "\"", l == "\"" {
                    text.removeLast()
                    text.removeFirst()
                    stack[last].append(Obj.string(text))
                } else if text == "#t" {
                    stack[last].append(Obj.bool(true))
                } else if text == "#f" {
                    stack[last].append(Obj.bool(false))
                } else {
                    stack[last].append(Obj.symbol("'" + text))
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
