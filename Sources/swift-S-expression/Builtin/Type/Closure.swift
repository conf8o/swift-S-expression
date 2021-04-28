public class Closure {
    let params: SCons
    let body: Obj
    var env: Env
    var name: Obj.Symbol?
    
    init(params: SCons, body: Obj, env: Env) {
        self.params = params
        self.body = body
        self.env = env
    }

    func apply(_ args: SCons) -> Obj {
        var env = self.env
        env.extend(symbols: params, vals: args)
        let r = body.eval(env: &env)
        env.pop()
        return r
    }
    
    func putSelfOnEnv(symbol: Obj.Symbol) {
        name = symbol
        env[env.count-1, symbol] = .closure(self)
    }
}
