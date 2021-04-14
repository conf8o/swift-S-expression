/// Objのリテラル表現(Int)
extension Obj: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

/// Objのリテラル表現(String, Symbol)
extension Obj: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        if let quote = stringLiteral.first, quote == "'" {
            self = .symbol(stringLiteral)
        } else {
            self = .string(stringLiteral)
        }
    }
}

/// Objのリテラル表現(Array)
extension Obj: ExpressibleByArrayLiteral {
    public init(arrayLiteral: Obj...) {
        self = S(arrayLiteral)
    }
}
