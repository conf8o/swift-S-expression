public class Closure {
    var env: Env
    var name: Obj.Symbol?
    
    private let params: SCons
    private let body: Obj
    private let isTailRecur: Bool
    
    init(params: SCons, body: Obj, env: Env) {
        self.params = params
        self.body = body
        self.env = env
        
        // 末尾再帰か判定
        isTailRecur = false
        
    }

    func apply(_ args: SCons) -> Obj {
        var env = self.env
        env.extend(symbols: params, vals: args)
        if isTailRecur {
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
        if isTailRecur {
            
        } else {
            name = symbol
            env[env.count-1, symbol] = .closure(self)
        }
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

private func isNotTailRecurOnLet(name: Obj.Symbol, bindings: SCons) -> Bool {
    var bindings = bindings
    while case .cons(let binding, let rest) = bindings {
        // binding [_ (name _)]
        guard case .cons(_, .cons(.cons(.symbol(let funcSymbol), _), .null)) = binding else { return _raiseErrorDev(binding, rest) /* TODO エラーハンドリング */ }
        if funcSymbol == name {
            return true
        }
        bindings = rest
    }
    return false
}
