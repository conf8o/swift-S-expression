/// 環境([[変数: オブジェクト]])
public typealias Env = [[Obj.Symbol: Obj]]

/// 環境に変数と値を追加する。
public func extendEnv(env: inout Env, symbols: [SSymbol], vals: [Obj])  {
    var newEnv = [Obj.Symbol: Obj]()
    for case (.symbol(let s), let val) in zip(symbols, vals) {
        newEnv[s] = val
    }
    env.append(newEnv)
}

/// 環境に変数と値を追加する。
public func extendEnv(env: inout Env, symbols: SCons, vals: SCons)  {
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
public func lookupVar(symbol: SSymbol, env: Env) -> Obj {
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
