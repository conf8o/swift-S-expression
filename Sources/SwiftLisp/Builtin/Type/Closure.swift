public class Closure {
    var env: Env
    var name: Obj.Symbol?
    
    private let params: SCons
    private let body: Obj
    
    private var _isTailRecur: Bool = false
    
    init(params: SCons, body: Obj, env: Env) {
        self.params = params
        self.body = body
        self.env = env
    }

    func apply(_ args: SCons) -> Obj {
        var env = self.env
        env.extend(symbols: params, vals: args)
        if _isTailRecur {
            var val = body.eval(env: &env)
            while case .cons(.symbol("'recur"), let newArgs) = val {
                for case (.symbol(let param), let arg) in zip(params, newArgs) {
                    guard let scopeIndex = env.getScopeIndex(symbol: param) else {
                        return _raiseErrorDev(newArgs)
                    }
                    env[scopeIndex, param] = arg
                }
                val = body.eval(env: &env)
            }
            return val
        } else {
            let r = body.eval(env: &env)
            env.pop()
            return r
        }
    }
    
    func putSelfOnEnv(symbol: Obj.Symbol) {
        name = symbol
        _isTailRecur = isTailRecur(name: name!, expr: body)
        env[env.count-1, symbol] = _isTailRecur ? BUILTIN_ENV["'_recur"] : .closure(self)
    }
}

//private func _isTailRecurBody(name: Obj.Symbol?, body: SCons) -> Bool {
//    guard let name = name else { return false }
//
//    // let束縛部、またはif, condの条件部、またはそれ以外のS式の引数にnameがいればアウト、それ以外なら末尾再帰
//    var body = body
//    var queue: [Obj] = []
//    while case .cons(let symbol, let rest) = body {
//        switch symbol {
//        case .symbol("'let"), case .cons(let bidings, _) = rest:
//
//        }
//    }
//}

private func isTailRecur(name: Obj.Symbol, expr: SCons) -> Bool {
    if case .cons(let x, let xs) = expr {
        switch x {
        case .symbol(let s) where s == name:
            return true
        case .symbol("'let"):
            return isTailRecurInLet(name: name, expr: xs)
        case .symbol("'if"):
            return isTailRecurInIf(name: name, expr: xs)
        case .symbol("'cond"):
            return isTailRecurInCond(name: name, expr: xs)
        default:
            return !nameInArgs(name: name, in: xs)
        }
    } else {
        return true
    }
}

private func nameInArgs(name: Obj.Symbol, in expr: SCons) -> Bool {
    for arg in expr {
        switch arg {
        case .symbol(let s) where s == name:
            return true
        case .cons(.symbol(let s), let xs) where s == name || nameInArgs(name: name, in: xs):
            return true
        default:
            break
        }
    }
    return false
}

/// nameを見るべき箇所は束縛部とbody部
private func isTailRecurInLet(name: Obj.Symbol, expr: SCons) -> Bool {
    let (bindings, body) = _take2(list: expr, default: (.null, .null))
    
    // binding [_ (symbol args)]
    for case .cons(_, .cons(.cons(.symbol(let symbol), let args), .null)) in bindings {
        if symbol == name || isTailRecur(name: name, expr: args) {
            return false
        }
    }
    
    return isTailRecur(name: name, expr: body)
}

private func isTailRecurInIf(name: Obj.Symbol, expr: SCons) -> Bool {
    expr.allSatisfy { expr in isTailRecur(name: name, expr: expr)}
}

private func isTailRecurInCond(name: Obj.Symbol, expr: SCons) -> Bool {
    for case .cons(let p, .cons(let c, .null)) in expr {
        if isTailRecur(name: name, expr: p) || isTailRecur(name: name, expr: c) {
            return true
        }
    }
    return false
}
