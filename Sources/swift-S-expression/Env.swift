/// 環境([[変数: オブジェクト]])
public typealias Env = [[String: Obj]]

/// 環境に変数と値を追加する。
public func extendEnv(env: inout Env, symbols: SCons, vals: SCons)  {
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
public func lookupVar(symbol: SSymbol, env: Env) -> Obj {
    guard case .symbol(let s) = symbol else {
        return _raiseErrorDev(symbol) // TODO エラーハンドリング
    }

    guard let localEnv = (env.last { $0[s] != nil }) else {
        print("Not assigned symbol.")
        return _raiseErrorDev(symbol) // TODO エラーハンドリング
    }
    
    return localEnv[s]!
}
