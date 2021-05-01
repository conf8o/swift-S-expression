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
        // (letrec ([symbol (lambda args body)])
        //   symbol)
        env[env.count-1, symbol] = (["'letrec", [[.symbol(symbol),
                                                 ["'lambda", args, body]]],
                                        .symbol(symbol)] as Obj).eval(env: &env)

    // (define f val)
    case .cons(.symbol(let symbol), .cons(let val, .null)):
        // (letrec ([symbol val])
        //   symbol)
        env[env.count-1, symbol] = (["'letrec", [[.symbol(symbol), val]],
                                        .symbol(symbol)] as Obj).eval(env: &env)
    default:
        return _raiseErrorDev(expr)
    }
    return .null
}

/// let式
/// (let ([var1 val1]
///    [var2 va2]
///    ...)
///   body)
private func sLet(expr: SCons, env: inout Env) -> Obj {
    let (bindings, body) = _take2(list: expr, default: (.null, .null))

    var symbols = [Obj]()
    var vals = [Obj]()
    // (symbol val)
    for case .cons(let symbol, .cons(let val, .null)) in bindings {
        symbols.append(symbol)
        vals.append(val.eval(env: &env))
    }
    env.extend(symbols: symbols, vals: vals)
    let ret = body.eval(env: &env)
    env.pop()
    return ret
}

private func letrec(expr: SCons, env: inout Env) -> Obj {
    let (bindings, body) = _take2(list: expr, default: (.null, .null))

    var symbols = [SSymbol]()
    var valExprs = [Obj]()
    var dummies = [SNull]()
    for case .cons(let symbol, .cons(let valExpr, .null)) in bindings {
        symbols.append(symbol)
        valExprs.append(valExpr)
        dummies.append(.null)
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
    // (p c)
    for case .cons(let p, .cons(let c, .null)) in expr {
        if case .symbol(let s) = p, s == "'else" {
            return c.eval(env: &env)
        } else if _logicalTrue(obj: p.eval(env: &env)) {
            return c.eval(env: &env)
        } else {
            continue
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
