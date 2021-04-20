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
}

// 申し訳程度の型ヒント
public typealias SInt = Obj      // .null | .int
public typealias SDouble = Obj   // .null | .double
public typealias SString = Obj   // .null | .string  
public typealias SSymbol = Obj   // .null | .symbol
public typealias SBool = Obj     // .null | .bool 
public typealias SBuiltin = Obj  // .null | .builtin
public typealias SClosure = Obj  // .null | .closure
public typealias SSpecial = Obj  // .null | .special
public typealias SNull = Obj     // .null
public typealias SCons = Obj     // .null | .cons

extension SCons {
    func car() -> Obj {
        guard case .cons(let a, _) = self else {
            return _raiseErrorDev(self) /* TODO エラーハンドリング */
        }
        return a
    }

    func cdr() -> Obj {
        guard case .cons(_, let d) = self else {
            return _raiseErrorDev(self) /* TODO エラーハンドリング */
        }
        return d
    }
}

/// 配列からS式へ変換
public func S(_ array: [Obj]) -> Obj {
    var array = array
    guard let obj = array.popLast() else { return .null }
    var list = Obj.cons(obj, .null)
    while let obj = array.popLast() {
        list = Obj.cons(obj, list)
    }
    return list
}

public extension Obj {
    /// S式の評価
    func eval(env: inout Env) -> Obj {
        switch self {
        case .symbol:
            return lookupVar(symbol: self, env: env)
        case .cons(let x, let xs):
            let _x = x.eval(env: &env)
            switch _x {
            case .builtin:
                return applyBuiltin(f: _x, args: xs.evalList(env: &env))
            case .closure:
                return applyClosure(f: _x, args: xs.evalList(env: &env))
            case .special:
                return applySpecialForm(m: _x, args: xs, env: &env)
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
public func applySpecialForm(m: SSpecial, args: SCons, env: inout Env) -> Obj {
    guard case .special(let _m) = m else { return _raiseErrorDev(m, args) /* TODO エラーハンドリング */ }
    return _m(args, &env)
}
