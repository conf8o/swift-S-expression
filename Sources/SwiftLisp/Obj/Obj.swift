/// オブジェクト
/// S式自体もconsなのでこれで表現する。
public enum Obj {
    public typealias Symbol = String
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case symbol(Symbol)
    case builtin((Obj) -> Obj)
    case closure(Closure)
    case special((Obj, inout Env) -> Obj)
    case null
    indirect case cons(Obj, Obj)
    case vector(Vector)
}

// 申し訳程度の型ヒント
public typealias SInt = Obj        // .null | .int
public typealias SDouble = Obj     // .null | .double
public typealias SString = Obj     // .null | .string  
public typealias SSymbol = Obj     // .null | .symbol
public typealias SBool = Obj       // .null | .bool 
public typealias SBuiltin = Obj    // .null | .builtin
public typealias SClosure = Obj    // .null | .closure
public typealias SSpecial = Obj    // .null | .special
public typealias SNull = Obj       // .null
public typealias SCons = Obj       // .null | .cons
public typealias SVector = Obj     // .null | .vector

public extension Obj {
    /// S式の評価
    func eval(env: inout Env) -> Obj {
        switch self {
        case .symbol:
            return env[self]
        case .cons(let x, let xs):
            let _x = x.eval(env: &env)
            switch _x {
            case .builtin:
                return applyBuiltin(f: _x, args: xs.evalList(env: &env))
            case .closure:
                return applyClosure(f: _x, args: xs.evalList(env: &env))
            case .special:
                return applySpecialForm(f: _x, args: xs, env: &env)
            default:
                return Obj.cons(_x, xs.evalList(env: &env))
            }
        default:
            return self
        }
    }

    func evalList(env: inout Env) -> Obj {
        switch self {
        case .cons(let x, let xs):
            return Obj.cons(x.eval(env: &env), xs.evalList(env: &env))
        default:
            return self.eval(env: &env)
        }
    }
}

/// 組み込み関数の適用
public func applyBuiltin(f: SBuiltin, args: SCons) -> Obj {
    guard case .builtin(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f(args)
}

/// ユーザー定義関数(クロージャ(ラムダ式))の適用
public func applyClosure(f: SClosure, args: SCons) -> Obj {
    guard case .closure(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f.apply(args)
}

/// 特殊形式の適用
public func applySpecialForm(f: SSpecial, args: SCons, env: inout Env) -> Obj {
    guard case .special(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f(args, &env)
}

extension Obj: Equatable {
    public static func == (lhs: Obj, rhs: Obj) -> Bool {
        switch (lhs, rhs) {
        case (.int(let x), .int(let y)):
            return x == y
        case (.double(let x), .double(let y)):
            return x == y
        case (.string(let s), .string(let t)):
            return s == t
        case (.bool(let p), .bool(let q)):
            return p == q
        case (.symbol(let s), .symbol(let t)):
            return s == t
        case (.cons, .cons):
            return zip(lhs, rhs).allSatisfy(==)
        case (.vector(let u), .vector(let v)):
            return u == v
        case (.null, .null):
            return true
        default:
            return _raiseErrorDev(lhs, rhs)
        }
    }
}
