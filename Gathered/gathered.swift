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
    case builtin((Obj) -> Obj)
    case closure(Closure)
    case special((Obj, inout Env) -> Obj)
    case null
    indirect case cons(Obj, Obj)
    case vector(Vector)
}

// 申し訳程度の型ヒント
typealias SInt = Obj        // .null | .int
typealias SDouble = Obj     // .null | .double
typealias SString = Obj     // .null | .string  
typealias SSymbol = Obj     // .null | .symbol
typealias SBool = Obj       // .null | .bool 
typealias SBuiltin = Obj    // .null | .builtin
typealias SClosure = Obj    // .null | .closure
typealias SSpecial = Obj    // .null | .special
typealias SNull = Obj       // .null
typealias SCons = Obj       // .null | .cons
typealias SVector = Obj     // .null | .vector

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

extension Obj {
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
func applyBuiltin(f: SBuiltin, args: SCons) -> Obj {
    guard case .builtin(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f(args)
}

/// ユーザー定義関数(クロージャ(ラムダ式))の適用
func applyClosure(f: SClosure, args: SCons) -> Obj {
    guard case .closure(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f.apply(args)
}

/// 特殊形式の適用
func applySpecialForm(f: SSpecial, args: SCons, env: inout Env) -> Obj {
    guard case .special(let _f) = f else { return _raiseErrorDev(f, args) /* TODO エラーハンドリング */ }
    return _f(args, &env)
}


//===--- Env.swift ---===//

/// 環境([[変数: オブジェクト]])
typealias Env = [[Obj.Symbol: Obj]]

/// 環境に変数と値を追加する。
func extendEnv(env: inout Env, symbols: [SSymbol], vals: [Obj])  {
    var newEnv = [Obj.Symbol: Obj]()
    for case (.symbol(let s), let val) in zip(symbols, vals) {
        newEnv[s] = val
    }
    env.append(newEnv)
}

/// 環境に変数と値を追加する。
func extendEnv(env: inout Env, symbols: SCons, vals: SCons)  {
    var newEnv = [Obj.Symbol: Obj]()
    var _symbols = symbols
    var _vals = vals
    while case .cons(.symbol(let s), let restS) = _symbols,
          case .cons(let val, let restV) = _vals {
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
    if let localEnv = (env.last { $0[s] != nil }) {
        return localEnv[s]!
    } else if let v = BUILTIN_ENV[s] {
        return v
    } else {
        print("Not assigned symbol.")
        return _raiseErrorDev(symbol) // TODO エラーハンドリング
    }
}


//===--- Closure.swift ---===//

class Closure {
    var params: SCons
    var body: Obj
    var env: Env
    
    init(params: SCons, body: Obj, env: Env) {
        self.params = params
        self.body = body
        self.env = env
    }

    func apply(_ args: SCons) -> Obj {
        var env = self.env
        extendEnv(env: &env, symbols: params, vals: args)
        return body.eval(env: &env)
    }
}

//===--- Obj+CustomStringConvertible.swift ---===//

extension Obj: CustomStringConvertible {
    var description: String {
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
        case .vector(let v):
            return v.description
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

//===--- Obj+LexicalAnalysis.swift ---===//

extension Obj {
    static func S(_ array: [Obj]) -> Obj {
        var array = array
        guard let obj = array.popLast() else { return .null }
        var list = Obj.cons(obj, .null)
        while let obj = array.popLast() {
            list = Obj.cons(obj, list)
        }
        return list
    }
}

extension Obj {
    enum Token {
        case pOpen, pClose, textBlock(String)
    }
}

extension Array where Element == Obj.Token {
    mutating func absorbText(_ textBuffer: inout String) {
        if textBuffer != "" {
            self.append(.textBlock(textBuffer))
            textBuffer = ""
        }
    }
}

extension Obj {
    static func tokenize(_ sExpr: String) -> [Token] {
        var tokens = [Token]()
        var textBuffer = ""
        var isNotString = true

        for c in sExpr {
            switch c {
            case "\"":
                isNotString = !isNotString
                textBuffer.append(c)
            case "(", "[":
                tokens.absorbText(&textBuffer)
                tokens.append(.pOpen)
            case ")", "]":
                tokens.absorbText(&textBuffer)
                tokens.append(.pClose)
            case let c where isNotString && (c.isWhitespace || c.isNewline):
                tokens.absorbText(&textBuffer)
            default:
                textBuffer.append(c)
            }
        }
        return tokens
    }


    static func read(sExpr: String) throws -> [Obj] {
        let tokens = tokenize(sExpr)
        var stack: [[Obj]] = [[]]
        for token in tokens {
            switch token {
            case .pOpen:
                stack.append([])
            case .pClose:
                guard let p = stack.popLast(), stack.count > 0 else {
                    throw LexicalAnalysisError.extraCloseParenthesis
                }
                stack[stack.count-1].append(Obj.S(p))
            case .textBlock(var text):
                let last = stack.count - 1
                
                if let int = Int(text) {
                    stack[last].append(Obj.int(int))
                } else if let double = Double(text) {
                    stack[last].append(Obj.double(double))
                } else if let f = text.first, let l = text.last, f == "\"", l == "\"" {
                    text.removeLast()
                    text.removeFirst()
                    stack[last].append(Obj.string(text))
                } else if text == "#t" {
                    stack[last].append(Obj.bool(true))
                } else if text == "#f" {
                    stack[last].append(Obj.bool(false))
                } else {
                    stack[last].append(Obj.symbol("'" + text))
                }
            }
        }
        guard stack.count == 1 else {
            throw LexicalAnalysisError.notClosedParenthesis
        }
        return stack[0]
    }
}

enum LexicalAnalysisError: Error {
    case extraCloseParenthesis
    case notClosedParenthesis
}


//===--- Obj+Literal.swift ---===//

/// Objのリテラル表記(Int)
extension Obj: ExpressibleByIntegerLiteral {
    init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

/// Objのリテラル表記(Double)
extension Obj: ExpressibleByFloatLiteral {
    init(floatLiteral: Double) {
        self = .double(floatLiteral)
    }
}

/// Objのリテラル表記(Bool)
extension Obj: ExpressibleByBooleanLiteral {
    init(booleanLiteral: Bool) {
        self = .bool(booleanLiteral)
    }
}

/// Objのリテラル表記(String, Symbol)
extension Obj: ExpressibleByStringLiteral {
    init(stringLiteral: String) {
        if let quote = stringLiteral.first, quote == "'" {
            self = .symbol(stringLiteral)
        } else {
            self = .string(stringLiteral)
        }
    }
}

/// Objのリテラル表記(Array)
extension Obj: ExpressibleByArrayLiteral {
    init(arrayLiteral: Obj...) {
        self = Obj.S(arrayLiteral)
    }
}

// 配列(Vector)のリテラル表記は無し


//===--- Vector.swift ---===//

class Vector {
    var buffer: [Obj]

    init(_ list: SCons) {
        self.buffer = []
        var rest = list
        while case .cons(let x, let xs) = rest {
            buffer.append(x)
            rest = xs
        }
    }
    init(_ array: [Obj]) {
        self.buffer = array
    }

    subscript(i: Int) -> Obj {
        get {
            return buffer[i]
        }

        set(obj) {
            buffer[i] = obj
        }
    }
}

extension Vector: CustomStringConvertible {
    var description: String {
        return self.buffer.description
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
    guard case .cons(let x, .cons(let y, _)) = list else { return obj }
    return (x, y)
}

/// リストの最初の三つをタプルで取り出す。
func _take3(list: SCons, default obj: (Obj, Obj, Obj))-> (Obj, Obj, Obj) {
    guard case .cons(let x, .cons(let y, .cons(let z, _))) = list else { return obj }
    return (x, y, z)
}

func _unwrapInt(obj: Obj) -> Int {
    guard case .int(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

func _unwrapDouble(obj: Obj) -> Double {
    guard case .double(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

func _unwrapString(obj: Obj) -> String {
    guard case .string(let s) = obj else {
        return _raiseErrorDev(obj)
    }
    return s
}

/// 閉じている演算子メーカー
class ClosedOperatorMaker<T> {
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

let intClosedOpe = ClosedOperatorMaker<Int>(unwrap: _unwrapInt, wrap: Obj.int)
let doubleClosedOpe = ClosedOperatorMaker<Double>(unwrap: _unwrapDouble, wrap: Obj.double)

class DispatchClosedOperator {
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
class ComparisonOperatorMaker<T> {
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

let intCompOpe = ComparisonOperatorMaker<Int>(unwrap: _unwrapInt)
let doubleCompOpe = ComparisonOperatorMaker<Double>(unwrap: _unwrapDouble)
let stringCompOpe = ComparisonOperatorMaker<String>(unwrap: _unwrapString)

class DispatchComparisonOperator {
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
let builtinOperator: [String: SBuiltin] = [
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
func _logicalTrue(obj: Obj) -> Bool {
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
    return _logicalTrue(obj: p.eval(env: &env)) ? t.eval(env: &env) : f.eval(env: &env)
}

/// cond式
func cond(expr: SCons, env: inout Env) -> Obj {
    var rest = expr
    while case .cons(.cons(let p, .cons(let c, .null)), let xs) = rest {
        if _logicalTrue(obj: p.eval(env: &env)) {
            return c.eval(env: &env)
        } else {
            rest = xs
        }
    }
    return .null
}

let builtinSpecialForm: [String: SSpecial] = [
    "'lambda": .special(lambda),
    "'define": .special(define),
    "'let": .special(sLet),
    "'letrec": .special(letrec),
    "'if": .special(sIf),
    "'cond": .special(cond)
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
    },
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
    }
]

let builtinValue: [Obj.Symbol: Obj] = [
    "'else": .bool(true)
]

/// 組み込み環境
let BUILTIN_ENV: [Obj.Symbol: Obj] = builtinOperator
    .merging(builtinSpecialForm) { (_, new) in new }
    .merging(builtinFunction) { (_, new) in new }
    .merging(builtinValue) { (_, new) in new }
