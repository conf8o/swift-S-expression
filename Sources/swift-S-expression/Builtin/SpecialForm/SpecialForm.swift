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
        env[env.count-1, symbol] = (["'letrec", [[.symbol(symbol), ["'lambda", args, body]]],
                                        .symbol(symbol)] as Obj).eval(env: &env)

    // (define f val)
    case .cons(.symbol(let symbol), .cons(let val, .null)):
        env[env.count-1, symbol] = (["'letrec", [[.symbol(symbol), val]],
                                        .symbol(symbol)] as Obj).eval(env: &env)
    default:
        return _raiseErrorDev(expr)
    }
    return .null
}

/// let式
private func sLet(expr: SCons, env: inout Env) -> Obj {
    var (bindings, body) = _take2(list: expr, default: (.null, .null))

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
    env.extend(symbols: symbols, vals: vals)
    let ret = body.eval(env: &env)
    env.pop()
    return ret
}

private func letrec(expr: SCons, env: inout Env) -> Obj {
    var (bindings, body) = _take2(list: expr, default: (.null, .null))

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
    env.extend(symbols: symbols, vals: dummies)
    let vals = valExprs.map { val -> Obj in val.eval(env: &env) }
    for case (.symbol(let s), let val) in zip(symbols, vals) {
        if case .closure(let _closure) = val {
            _closure.putSelfOnEnv(symbol: s)
        }
        env[env.count-1, s] = val
    }
    let ret = body.eval(env: &env)
    env.pop()
    return ret
}

/// if式
private func sIf(expr: SCons, env: inout Env) -> Obj {
    let (p, t, f) = _take3(list: expr, default: (.null, .null, .null))
    return _logicalTrue(obj: p.eval(env: &env)) ? t.eval(env: &env) : f.eval(env: &env)
}

/// cond式
private func cond(expr: SCons, env: inout Env) -> Obj {
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

public let BUILTIN_SPECIAL_FORM: [Obj.Symbol: SSpecial] = [
    "'lambda": .special(lambda),
    "'define": .special(define),
    "'let": .special(sLet),
    "'letrec": .special(letrec),
    "'if": .special(sIf),
    "'cond": .special(cond)
]
