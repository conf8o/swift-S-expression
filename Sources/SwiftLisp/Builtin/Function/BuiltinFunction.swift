import Foundation

public let BUILTIN_FUNCTION: [String: SBuiltin] = [
    // identity
    "'identity": .builtin { obj in obj.car() },
    
    // cons
    "'car": .builtin { obj in obj.car().car() },
    "'cdr": .builtin { obj in obj.car().cdr() },
    "'cons": .builtin { obj in Obj.cons(obj.car(), obj.cdr().car()) },
    "'list": .builtin { obj in obj },
    
    // null
    "'null?": .builtin { obj in
        if case .null = obj.car() {
            return .bool(true)
        } else {
            return .bool(false)
        }
    },
    
    // int
    "'int": .builtin { obj in 
        guard case .string(let x) = obj.car() else {
            return _raiseErrorDev(obj)
        }
        return .int(Int(x)!)
    },
    
    // string
    "'str": .builtin { .string($0.map(\.description).joined(separator: "")) },
    "'string->list": .builtin { obj in 
        guard case .string(let s) = obj.car() else {
            return _raiseErrorDev(obj)
        }
        return Obj.S(s.map { .string(String($0)) })
    },
    
    // IO
    "'read-line": .builtin { obj in
        guard case .null = obj else {
            return _raiseErrorDev(obj)
        }
        return .string(readLine()!)
    },
    "'read-ints": .builtin { obj in
        guard case .null = obj else {
            return _raiseErrorDev(obj)
        }
        return Obj.S(readLine()!.split(separator: " ").map { Obj.int(Int($0)!) })
    },
    "'print": .builtin { obj in
        print(obj.map(\.description).joined(separator: " "))
        return .null
    },
    
    // Vector
    "'make-vector": .builtin { obj in
        guard case .int(let n) = obj.car() else {
            return _raiseErrorDev(obj)
        }
        let buffer = [Obj](repeating: .null, count: n)
        return .vector(Vector(buffer))
    },
    "'vec": .builtin { obj in
        guard case let list = obj.car(), case .cons = list else {
            return _raiseErrorDev(obj)
        }
        return .vector(Vector(list))
    },
    "'~": .builtin { obj in
        switch obj {
        case .cons(.vector(let vec), .cons(.int(let i), .null)):
            return vec[i]
        case .cons(.vector(let vec), .cons(.int(let i), .cons(let element, .null))):
            vec[i] = element
            return .null
        default:
            return _raiseErrorDev(obj)
        }
    },
    
    // システム
    "'exit": .builtin { obj in
        guard case .null = obj else {
            return _raiseErrorDev(obj)
        }
        exit(0)
    },
    
    // private
    "'_recur": .builtin { obj in
        return .cons("'recur", obj.cdr())
    }
]
