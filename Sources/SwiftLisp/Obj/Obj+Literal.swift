/// Objのリテラル表記(Int)
extension Obj: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

/// Objのリテラル表記(Double)
extension Obj: ExpressibleByFloatLiteral {
    public init(floatLiteral: Double) {
        self = .double(floatLiteral)
    }
}

/// Objのリテラル表記(Bool)
extension Obj: ExpressibleByBooleanLiteral {
    public init(booleanLiteral: Bool) {
        self = .bool(booleanLiteral)
    }
}

/// Objのリテラル表記(String, Symbol)
extension Obj: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        if let quote = stringLiteral.first, quote == "'" {
            self = .symbol(stringLiteral)
        } else {
            self = .string(stringLiteral)
        }
    }
}

/// Objのリテラル表記(Array)
extension Obj: ExpressibleByArrayLiteral {
    public init(arrayLiteral: Obj...) {
        self = Obj.S(arrayLiteral)
    }
}

// 配列(Vector)のリテラル表記は無し
