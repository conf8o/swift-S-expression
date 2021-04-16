extension Obj: CustomStringConvertible {
    public var description: String {
        switch self {
            case .cons(let x, let xs):
                return "(\(x) \(xs))"
            case .int(let n):
                return n.description
            case .double(let d):
                return d.description
            case .string(let s):
                return "\"\(s)\""
            case .bool(let b):
                return b ? "#t" : "#f"
            case .symbol(let s):
                return s
            case .lambda:
                return "(Function)"
            case .special:
                return "(SpecialForm)"
            case .null:
                return ""
        }
    }
}