//===--- Obj.swift ---===//

/// オブジェクト
/// S式自体もconsなのでこれで表現する。
enum Obj {
    typealias Symbol = String
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case symbol(Symbol)
    case lambda((Obj) -> Obj)
    case special((Obj, inout Env) -> Obj)
    case null
    indirect case cons(Obj, Obj)
}

// 申し訳程度の型ヒント
typealias SInt = Obj      // .null | .int
typealias SDouble = Obj   // .null | .double
typealias SString = Obj   // .null | .string  
typealias SSymbol = Obj   // .null | .symbol
typealias SBool = Obj     // .null | .bool 
typealias SLambda = Obj   // .null | .lambda
typealias SSpecial = Obj  // .null | .special
typealias SNull = Obj     // .null
typealias SCons = Obj     // .null | .cons

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
func S(_ array: [Obj]) -> Obj {
    var array = array
    guard let obj = array.popLast() else { return .null }
    var list = Obj.cons(obj, .null)
    while let obj = array.popLast() {
        list = Obj.cons(obj, list)
    }
    return list
}

extension Obj {
    /// S式の評価
    func eval(env: inout Env) -> Obj {
        switch self {
        case .symbol:
            return lookupVar(symbol: self, env: env)
        case .cons(let x, let xs):
            let _x = x.eval(env: &env)

            switch _x {
            case .lambda:
                let _xs = xs.evalList(env: &env)
                return apply(f: _x, args: _xs)
            case .special:
                return applySpecialForm(m: _x, args: xs, env: &env)
            default:
                let _xs = xs.evalList(env: &env)
                return Obj.cons(_x, _xs)
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

/// 関数の適用
func apply(f: SLambda, args: SCons) -> Obj {
    guard case .lambda(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f(args)
}

/// 特殊形式の適用
func applySpecialForm(m: SSpecial, args: SCons, env: inout Env) -> Obj {
    guard case .special(let _m) = m else { return _raiseErrorDev(m, args) /* TODO エラーハンドリング */ }
    return _m(args, &env)
}

//===--- Env.swift ---===//

/// 環境([[変数: オブジェクト]])
typealias Env = [[String: Obj]]

/// 環境に変数と値を追加する。
func extendEnv(env: inout Env, symbols: SCons, vals: SCons)  {
    var newEnv = [String: Obj]()
    var _symbols = symbols
    var _vals = vals
    while case .cons(let symbol, let restS) = _symbols,
          case .cons(let val, let restV) = _vals {
        guard case .symbol(let s) = symbol else {
            let _ = newEnv["🦀"]! /* TODO エラーハンドリング */
            return
        }
        newEnv[s] = val
        _symbols = restS
        _vals = restV
    }
    env.append(newEnv)
}

/// 環境から値を取得する。配列の後ろの方が後の環境なので後ろから見る。
func lookupVar(symbol: SSymbol, env: Env) -> Obj {
    guard case .symbol(let s) = symbol else {
        return _raiseErrorDev(symbol) // TODO エラーハンドリング
    }

    guard let localEnv = (env.last { $0[s] != nil }) else {
        print("Not assigned symbol.")
        return _raiseErrorDev(symbol) // TODO エラーハンドリング
    }
    
    return localEnv[s]!
}


//===--- Obj+Literal.swift ---===//

/// Objのリテラル表現(Int)
extension Obj: ExpressibleByIntegerLiteral {
    init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

/// Objのリテラル表現(String, Symbol)
extension Obj: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        if let quote = stringLiteral.first, quote == "'" {
            self = .symbol(stringLiteral)
        } else {
            self = .string(stringLiteral)
        }
    }
}

/// Objのリテラル表現(Array)
extension Obj: ExpressibleByArrayLiteral {
    init(arrayLiteral: Obj...) {
        self = S(arrayLiteral)
    }
}


//===--- bulitin.swift ---===//

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
    "'car": .lambda { obj in obj.car().car() },
    "'cdr": .lambda { obj in obj.car().cdr() },
    "'cons": .lambda { obj in Obj.cons(obj.car(), obj.cdr().car()) },
    "'null?": .lambda { obj in 
        if case .null = obj.car() {
            return .bool(true)
        } else {
            return .bool(false)
        }
    },
    "'list": .lambda { obj in obj }
]

/// グローバル環境
var globalEnv: Env = [
    builtinOperator
    .merging(builtinSpecialForm) { (_, new) in new }
    .merging(builtinFunction) { (_, new) in new }
]
