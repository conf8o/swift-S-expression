extension Obj: CustomStringConvertible {
    public var description: String {
        switch self {
        case .cons(let x, let xs):
            var _xs = xs.description
            switch xs {
            case .cons:
                _xs.removeLast()
                _xs.removeFirst()
                _xs = " \(_xs)"
            case .null:
                break
            default:
                _xs = " \(_xs)"
            }
            return "(\(x)\(_xs))"
        case .int(let n):
            return n.description
        case .double(let d):
            return d.description
        case .string(let s):
            return s
        case .bool(let b):
            return b ? "#t" : "#f"
        case .symbol(let s):
            return s
        case .builtin:
            return "(BuiltinFunction)"
        case .closure:
            return "(Closure)"
        case .special:
            return "(SpecialForm)"
        case .null:
            return ""
        }
    }
}