// 戻り値の型が生っぽい関数などには先頭にアンダースコアをつける。

/// 開発用の簡易クラッシャー
public func _raiseErrorDev<T>(_ obj: Obj...) -> T {
    var error = [T]()
    print("Value Error!", obj)
    return error.popLast()!
}

/// リストの最初の二つをタプルで取り出す。
private func _take2(list: SCons, default obj: (Obj, Obj))-> (Obj, Obj) {
    guard case .cons(let x, .cons(let y, _)) = list else { return obj }
    return (x, y)
}

/// リストの最初の三つをタプルで取り出す。
private func _take3(list: SCons, default obj: (Obj, Obj, Obj))-> (Obj, Obj, Obj) {
    guard case .cons(let x, .cons(let y, .cons(let z, _))) = list else { return obj }
    return (x, y, z)
}

private func _unwrapInt(obj: Obj) -> Int {
    guard case .int(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

private func _unwrapDouble(obj: Obj) -> Double {
    guard case .double(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

private func _unwrapString(obj: Obj) -> String {
    guard case .string(let s) = obj else {
        return _raiseErrorDev(obj)
    }
    return s
}

/// 閉じている演算子メーカー
private class ClosedOperatorMaker<T> {
    var unwrap: (Obj) -> T
    var wrap: (T) -> Obj

    init(unwrap: @escaping (Obj) -> T, wrap: @escaping (T) -> Obj) {
        self.unwrap = unwrap
        self.wrap = wrap
    }

    func makeOperator(_ ope: @escaping (T, T) -> T) -> (SCons) -> Obj {
        func inner(args: SCons) -> Obj {
            guard case .cons(let x, let xs) = args else {
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
            var n = unwrap(x)
            var rest = xs
            while case .cons(let y, let ys) = rest {
                let m = unwrap(y)
                n = ope(n, m)
                rest = ys
            }

            return wrap(n)
        }
        return inner
    }
}

private let intClosedOpe = ClosedOperatorMaker<Int>(unwrap: _unwrapInt, wrap: Obj.int)
private let doubleClosedOpe = ClosedOperatorMaker<Double>(unwrap: _unwrapDouble, wrap: Obj.double)

private class DispatchClosedOperator {
    var opeForInt: (SCons) -> SInt
    var opeForDouble: (SCons) -> SDouble

    init(int: @escaping (Int, Int) -> Int, double: @escaping (Double, Double) -> Double) {
        self.opeForInt = intClosedOpe.makeOperator(int)
        self.opeForDouble = doubleClosedOpe.makeOperator(double)
    }

    func toSBuiltin() -> SBuiltin {
        return .builtin { args in
            switch args {
            case .cons(.int, _):
                return self.opeForInt(args)
            case .cons(.double, _):
                return self.opeForDouble(args)
            default:
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
        }
    }
}

// 比較演算子メーカー
private class ComparisonOperatorMaker<T> {
    var unwrap: (Obj) -> T
    init(unwrap: @escaping (Obj) -> T) {
        self.unwrap = unwrap
    }

    func makeOperator(_ ope: @escaping (T, T) -> Bool) -> (SCons) -> SBool {
        func inner(args: SCons) -> SBool {
            let (x, y) = _take2(list: args, default: (.null, .null))
            return .bool(ope(unwrap(x), unwrap(y)))
        }
        return inner
    }
}

private let intCompOpe = ComparisonOperatorMaker<Int>(unwrap: _unwrapInt)
private let doubleCompOpe = ComparisonOperatorMaker<Double>(unwrap: _unwrapDouble)
private let stringCompOpe = ComparisonOperatorMaker<String>(unwrap: _unwrapString)

private class DispatchComparisonOperator {
    var opeForInt: (SCons) -> SBool
    var opeForDouble: (SCons) -> SBool
    var opeForString: (SCons) -> SBool

    init(int: @escaping (Int, Int) -> Bool,
         double: @escaping (Double, Double) -> Bool,
         string: @escaping (String, String) -> Bool) {
        self.opeForInt = intCompOpe.makeOperator(int)
        self.opeForDouble = doubleCompOpe.makeOperator(double)
        self.opeForString = stringCompOpe.makeOperator(string)
    }

    func toSBuiltin() -> SBuiltin {
        return .builtin { args in
            switch args {
            case .cons(.int, _):
                return self.opeForInt(args)
            case .cons(.double, _):
                return self.opeForDouble(args)
            case .cons(.string, _):
                return self.opeForString(args)
            default:
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
        }
    }
}

/// 組み込み演算子
private let builtinOperator: [String: SBuiltin] = [
    "'+": DispatchClosedOperator(int: +, double: +).toSBuiltin(),
    "'-": DispatchClosedOperator(int: -, double: -).toSBuiltin(),
    "'*": DispatchClosedOperator(int: *, double: *).toSBuiltin(),
    "'/": DispatchClosedOperator(int: /, double: /).toSBuiltin(),
    "'%": .builtin(intClosedOpe.makeOperator(%)),
    "'=": DispatchComparisonOperator(int: ==, double: ==, string: ==).toSBuiltin(),
    "'<": DispatchComparisonOperator(int: <, double: <, string: <).toSBuiltin(),
    "'<=": DispatchComparisonOperator(int: <=, double: <=, string: <=).toSBuiltin(),
    "'>": DispatchComparisonOperator(int: >, double: >, string: >).toSBuiltin(),
    "'>=": DispatchComparisonOperator(int: >=, double: >=, string: >=).toSBuiltin()
]

/// lambda式
private func lambda(expr: SCons, env: inout Env) -> SClosure {
    switch expr {
    case .cons(let params, .cons(let body, .null)):
        let closure = Closure(params: params, body: body, env: env)
        return .closure(closure)
    default:
        return _raiseErrorDev(expr)
    }
}

/// 定義文
private func define(expr: SCons, env: inout Env) -> SNull {
    switch expr {
    // (define (f args) body)
    case .cons(.cons(.symbol(let symbol), let args), .cons(let body, .null)):
        env[env.count-1][symbol] = (["'letrec", [[.symbol(symbol), ["'lambda", args, body]]],
                                        .symbol(symbol)] as Obj).eval(env: &env)

    // (define f val)
    case .cons(.symbol(let symbol), .cons(let val, .null)):
        env[env.count-1][symbol] = (["'letrec", [[.symbol(symbol), val]],
                                        .symbol(symbol)] as Obj).eval(env: &env)
    default:
        return _raiseErrorDev(expr)
    }
    return .null
}

/// let式
private func sLet(expr: SCons, env: inout Env) -> Obj {
    var (bindings, body) = _take2(list: expr, default: (.null, .null))
    var env = env

    var symbols = [Obj]()
    var vals = [Obj]()
    while case .cons(let binding, let rest) = bindings {
        guard case .cons(let symbol, let _val) = binding else { return _raiseErrorDev(binding, rest) /* TODO エラーハンドリング */ }
            // _val == (val . null)
            let val = _val.car()
            symbols.append(symbol)
            vals.append(val.eval(env: &env))
            bindings = rest
    }
    extendEnv(env: &env, symbols: symbols, vals: vals)
    return body.eval(env: &env)
}

private func letrec(expr: SCons, env: inout Env) -> Obj {
    var (bindings, body) = _take2(list: expr, default: (.null, .null))
    var env = env

    var symbols = [SSymbol]()
    var valExprs = [Obj]()
    var dummies = [SNull]()
    while case .cons(let binding, let rest) = bindings {
        guard case .cons(let symbol, let _val) = binding else { return _raiseErrorDev(binding, rest) /* TODO エラーハンドリング */ }
            // _val == (val . null)
            let valExpr = _val.car()
            symbols.append(symbol)
            valExprs.append(valExpr)
            dummies.append(.null)
            bindings = rest
    }
    extendEnv(env: &env, symbols: symbols, vals: dummies)
    let vals = valExprs.map { val -> Obj in val.eval(env: &env) }
    for case (.symbol(let s), let val) in zip(symbols, vals) {
        if case .closure(let _closure) = val {
            _closure.env[_closure.env.count-1][s] = val
        }
        env[env.count-1][s] = val
    }
    return body.eval(env: &env)
}

/// 論理式判定
/// Clojureに則って .null と .bool(false) だけ false
/// それ以外は true
private func _logicalTrue(obj: Obj) -> Bool {
    switch obj {
    case .null:
        return false
    case .bool(false):
        return false
    default:
        return true
    }
}

/// if式
private func sIf(expr: SCons, env: inout Env) -> Obj {
    let (p, t, f) = _take3(list: expr, default: (.null, .null, .null))
    return _logicalTrue(obj: p.eval(env: &env)) ? t.eval(env: &env) : f.eval(env: &env)
}

/// cond式
private func cond(expr: SCons, env: inout Env) -> Obj {
    var rest = expr
    while case .cons(.cons(let p, let c), let xs) = rest {
        if _logicalTrue(obj: p.eval(env: &env)) {
            return c.eval(env: &env)
        } else {
            rest = xs
        }
    }
    return .null
}

private let builtinSpecialForm: [String: SSpecial] = [
    "'lambda": .special(lambda),
    "'define": .special(define),
    "'let": .special(sLet),
    "'letrec": .special(letrec),
    "'if": .special(sIf),
    "'cond": .special(cond)
]

private let builtinFunction: [String: SBuiltin] = [
    "'car": .builtin { obj in obj.car().car() },
    "'cdr": .builtin { obj in obj.car().cdr() },
    "'cons": .builtin { obj in Obj.cons(obj.car(), obj.cdr().car()) },
    "'null?": .builtin { obj in 
        if case .null = obj.car() {
            return .bool(true)
        } else {
            return .bool(false)
        }
    },
    "'list": .builtin { obj in obj },
    "'int": .builtin { obj in 
        guard case .string(let x) = obj.car() else {
            return _raiseErrorDev(obj)
        }
        return .int(Int(x)!)
    },
    "'str": .builtin { obj in 
        var args = obj
        var str = ""
        while case .cons(let x, let xs) = args {
            str.append(x.description)
            args = xs
        }
        return .string(str)
    },
    "'string->list": .builtin { obj in 
        guard case .string(let s) = obj.car() else {
            return _raiseErrorDev(obj)
        }
        return Obj.S(s.map { .string(String($0)) })
    },
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
        var args = obj
        var str = ""
        while case .cons(let x, let xs) = args {
            str.append("\(x.description) ")
            args = xs
        }
        str.removeLast()
        print(str)
        return .null
    }
]

private let builtinValue: [Obj.Symbol: Obj] = [
    "'else": .bool(true)
]

/// 組み込み環境
public let BUILTIN_ENV: [Obj.Symbol: Obj] = builtinOperator
    .merging(builtinSpecialForm) { (_, new) in new }
    .merging(builtinFunction) { (_, new) in new }
    .merging(builtinValue) { (_, new) in new }
