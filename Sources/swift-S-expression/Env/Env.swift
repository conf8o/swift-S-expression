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
    func extend<List: Sequence>(symbols: List, vals: List) where List.Element == Obj {
        var newEnv = [Obj.Symbol: Obj]()
        for case (.symbol(let s), let val) in zip(symbols, vals) {
            newEnv[s] = val
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
    
    func getScopeIndex(symbol: Obj.Symbol) -> Int? {
        return stack.lastIndex { $0[symbol] != nil }
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

