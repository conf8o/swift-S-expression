/// 環境
public class Env {
    var stack: [[Obj.Symbol: Obj]]
    var count: Int { stack.count }

    init() {
        self.stack = [[:]]
    }

    func append(_ env: [Obj.Symbol: Obj]) {
        stack.append(env)
    }

    func pop() {
        stack.removeLast()
    }
}

extension Env: CustomStringConvertible {
    public var description: String {
        stack.description
    }
}

public extension Env {
    /// 環境に変数と値を追加する。
    func set(symbols: SCons, vals: SCons)  {
        var _symbols = symbols
        var _vals = vals
        while case .cons(.symbol(let s), let restS) = _symbols,
              case .cons(let val, let restV) = _vals {
            self[count-1, s] = val
            _symbols = restS
            _vals = restV
        }
    }

    /// 環境に変数と値を追加する。
    func extend(symbols: [SSymbol], vals: [Obj])  {
        var newEnv = [Obj.Symbol: Obj]()
        for case (.symbol(let s), let val) in zip(symbols, vals) {
            newEnv[s] = val
        }
        append(newEnv)
    }

    /// 環境に変数と値を追加する。
    func extend(symbols: SCons, vals: SCons)  {
        var newEnv = [Obj.Symbol: Obj]()
        var _symbols = symbols
        var _vals = vals
        while case .cons(.symbol(let s), let restS) = _symbols,
              case .cons(let val, let restV) = _vals {
            newEnv[s] = val
            _symbols = restS
            _vals = restV
        }
        append(newEnv)
    }

    /// 環境から値を取得する。配列の後ろの方が後の環境なので後ろから見る。
    func lookupVar(symbol: SSymbol) -> Obj {
        guard case .symbol(let s) = symbol else {
            return _raiseErrorDev(symbol) // TODO エラーハンドリング
        }
        if let localEnv = (stack.last { $0[s] != nil }) {
            return localEnv[s]!
        } else if let v = BUILTIN_ENV[s] {
            return v
        } else {
            print("Not assigned symbol.")
            return _raiseErrorDev(symbol) // TODO エラーハンドリング
        }
    }

    subscript(i: Int, symbol: Obj.Symbol) -> Obj? {
        get {
            return stack[i][symbol]
        }
        set(obj) {
            stack[i][symbol] = obj
        }
    }

    subscript(symbol: SSymbol) -> Obj {
        lookupVar(symbol: symbol)
    }
}

