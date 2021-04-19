// 戻り値の型が生っぽい関数などには先頭にアンダースコアをつける。

/// 開発用の簡易クラッシャー
func _raiseErrorDev<T>(_ obj: Obj...) -> T {
    var error = [T]()
    print("Value Error!", obj)
    return error.popLast()!
}

/// リストの最初の二つをタプルで取り出す。
func _take2(list: SCons, default obj: (Obj, Obj))-> (Obj, Obj) {
    guard case .cons(let x, .cons(let y, _)) = list else { return obj }
    return (x, y)
}

/// リストの最初の三つをタプルで取り出す。
func _take3(list: SCons, default obj: (Obj, Obj, Obj))-> (Obj, Obj, Obj) {
    guard case .cons(let x, .cons(let y, .cons(let z, _))) = list else { return obj }
    return (x, y, z)
}

/// ObjのIntをアンラップ
func _unwrapInt(obj: Obj) -> Int {
    guard case .int(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

/// ObjのDoubleをアンラップ
func _unwrapDouble(obj: Obj) -> Double {
    guard case .double(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

/// 組み込み演算子メーカー
class BuiltinOperatorMaker<T> {
    var unwrap: (Obj) -> T
    var wrap: (T) -> Obj
    init(unwrap: @escaping (Obj) -> T, wrap: @escaping (T) -> Obj) {
        self.unwrap = unwrap
        self.wrap = wrap
    }

    func makeOperator(_ ope: @escaping (T, T) -> T) -> (SCons) -> Obj {
        func inner(list: SCons) -> Obj {
            guard case .cons(let x, let xs) = list else {
                return _raiseErrorDev(list) // TODO エラーハンドリング
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

let builtinOpeInt = BuiltinOperatorMaker<Int>(unwrap: _unwrapInt, wrap: Obj.int)
let builtinOpeDouble = BuiltinOperatorMaker<Double>(unwrap: _unwrapDouble, wrap: Obj.double)

/// ディスパッチ用クラス
class DispatchFunction {
    var forInt: (SCons) -> SInt
    var forDouble: (SCons) -> SDouble
    init(int: @escaping (Int, Int) -> Int, double: @escaping (Double, Double) -> Double) {
        self.forInt = builtinOpeInt.makeOperator(int)
        self.forDouble = builtinOpeDouble.makeOperator(double)
    }

    func toSBuiltin() -> SBuiltin {
        return .builtin { list in
            guard case .cons(let x, _) = list else {
                return _raiseErrorDev(list) // TODO エラーハンドリング
            }
            switch x {
            case .int:
                return self.forInt(list)
            case .double:
                return self.forDouble(list)
            default:
                return _raiseErrorDev(x) // TODO エラーハンドリング
            }
        }
    }
}

/// 組み込み演算子
let builtinOperator: [String: SBuiltin] = [
    "'+": DispatchFunction(int: +, double: +).toSBuiltin(),
    "'-": DispatchFunction(int: -, double: -).toSBuiltin(),
    "'*": DispatchFunction(int: *, double: *).toSBuiltin(),
    "'/": DispatchFunction(int: /, double: /).toSBuiltin(),
    "'%": .builtin(builtinOpeInt.makeOperator(%)),
    "'=": .builtin { (obj: SCons) -> SInt in
        let (x, y) = _take2(list: obj, default: (.null, .null))
        // TODO いろんな型
        guard case .int(let n) = x, case .int(let m) = y else { return .bool(false) }
        
        return .bool(n == m)
    }
]

/// lambda式
func lambda(expr: SCons, env: inout Env) -> SClosure {
    switch expr {
    case .cons(let params, .cons(let body, .null)):
        let closure = Closure(params: params, body: body, env: env)
        return .closure(closure)
    default:
        return _raiseErrorDev(expr)
    }
}

/// 定義文
func define(expr: SCons, env: inout Env) -> SNull {
    switch expr {
    // (define (f args) body)
    case .cons(.cons(let symbol, let args), let body):
        extendEnv(
            env: &env, 
            symbols: [symbol], 
            vals: [(["'letrec", [[symbol, ["'lambda", args, body]]],
                        symbol] as Obj).eval(env: &env)]
        )

    // (define f val)
    case .cons(let symbol, .cons(let val, .null)):
        extendEnv(
            env: &env, 
            symbols: [symbol], 
            vals: [(["'letrec", [[symbol, val]], symbol] as Obj).eval(env: &env)]
        )
    default:
        return _raiseErrorDev(expr)
    }
    return .null
}

/// let式
func sLet(expr: SCons, env: inout Env) -> Obj {
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

func letrec(expr: SCons, env: inout Env) -> Obj {
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
        if case .closure(var _closure) = val {
            _closure.env[env.count-1][s] = val
        }
        env[env.count-1][s] = val
    }
    print(env, body)
    return body.eval(env: &env)
}

/// 論理式判定
/// Clojureに則って .null と .bool(false) だけ false
/// それ以外は true
func _logicalTest(obj: Obj) -> Bool {
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
func sIf(expr: SCons, env: inout Env) -> Obj {
    let (p, t, f) = _take3(list: expr, default: (.null, .null, .null))

    return _logicalTest(obj: p.eval(env: &env)) ? t.eval(env: &env) : f.eval(env: &env)
}

let builtinSpecialForm: [String: SSpecial] = [
    "'lambda": .special(lambda),
    "'define": .special(define),
    "'if": .special(sIf),
    "'let": .special(sLet),
    "'letrec": .special(letrec)
]

let builtinFunction: [String: SBuiltin] = [
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
    "'list": .builtin { obj in obj }
]

/// グローバル環境
var globalEnv: Env = [
    builtinOperator
    .merging(builtinSpecialForm) { (_, new) in new }
    .merging(builtinFunction) { (_, new) in new }
]
