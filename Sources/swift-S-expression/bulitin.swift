// 戻り値の型が生っぽい関数などには先頭にアンダースコアをつける。

/// 開発用の簡易クラッシャー
func _raiseErrorDev<T>(_ obj: Obj...) -> T {
    var error = [T]()
    print("Value Error!", obj)
    return error.popLast()!
}

/// リストの最初の二つをタプルで取り出す。
func _take2(list: SCons, default obj: (Obj, Obj))-> (Obj, Obj) {
    guard case .cons(let x, let rest) = list else { return obj }
    guard case .cons(let y, _) = rest else { return obj }
    return (x, y)
}

/// リストの最初の三つをタプルで取り出す。
func _take3(list: SCons, default obj: (Obj, Obj, Obj))-> (Obj, Obj, Obj) {
    guard case .cons(let x, let xrest) = list else { return obj }
    guard case .cons(let y, let yrest) = xrest else { return obj }
    guard case .cons(let z, _) = yrest else { return obj }
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

    func toSLambda() -> SLambda {
        return .lambda { list in
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
let builtinOperator: [String: SLambda] = [
    "'+": DispatchFunction(int: +, double: +).toSLambda(),
    "'-": DispatchFunction(int: -, double: -).toSLambda(),
    "'*": DispatchFunction(int: *, double: *).toSLambda(),
    "'/": DispatchFunction(int: /, double: /).toSLambda(),
    "'%": .lambda(builtinOpeInt.makeOperator(%)),
    "'=": .lambda { (obj: SCons) -> SInt in
        let (x, y) = _take2(list: obj, default: (.null, .null))
        // TODO いろんな型
        guard case .int(let n) = x, case .int(let m) = y else { return .bool(false) }
        
        return .bool(n == m)
    }
]

// 予約語
/// 自身を示すシンボル TODO 正当かどうか。
let _SELF = "'self"
func _selfSymbol(env: Env) -> SSymbol? { 
    env.last { $0[_SELF] != nil }.flatMap { $0[_SELF] } 
}

/// lambda式
func lambda(expr: SCons, env: inout Env) -> SLambda {
    let (params, body) = _take2(list: expr, default: (.null, .null))
    var env = env
    func closure(args: SCons) -> Obj {
        extendEnv(env: &env, symbols: params, vals: args)
        // TODO selfは正当かどうか確かめる。
        if let selfSymbol = _selfSymbol(env: env) {
            extendEnv(env: &env, symbols: [selfSymbol], vals: [(["'lambda", params, body] as Obj).eval(env: &env)])
        }
        return body.eval(env: &env)
    }
    return .lambda(closure)
}

/// 定義文
func define(expr: SCons, env: inout Env) -> SNull {
    let (symbol, val) = _take2(list: expr, default: (.null, .null))
    // TODO selfは正当かどうか確かめる。
    extendEnv(env: &env, symbols: [.symbol(_SELF)], vals: [symbol])
    extendEnv(env: &env, symbols: [symbol], vals: [val.eval(env: &env)])
    return .null
}

/// let式
func sLet(expr: SCons, env: inout Env) -> Obj {
    var (bindings, body) = _take2(list: expr, default: (.null, .null))
    var env = env

    var symbols = Obj.null
    var vals = Obj.null
    while case .cons(let binding, let rest) = bindings {
        guard case .cons(let symbol, let _val) = binding else { return _raiseErrorDev(binding, rest) /* TODO エラーハンドリング */ }
            // _val == (val . null)
            let val = _val.car()
            symbols = Obj.cons(symbol, symbols)
            vals = Obj.cons(val.eval(env: &env), vals)
            bindings = rest
    }
    extendEnv(env: &env, symbols: symbols, vals: vals)
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
    "'let": .special(sLet)
]

let builtinFunction: [String: SLambda] = [
    "'car": .lambda { obj in obj.car() },
    "'cdr": .lambda { obj in obj.cdr() },
    "'cons": .lambda { obj in obj }
]

/// グローバル環境
var globalEnv: Env = [
    builtinOperator
    .merging(builtinSpecialForm) { (_, new) in new }
    .merging(builtinFunction) { (_, new) in new }
]
