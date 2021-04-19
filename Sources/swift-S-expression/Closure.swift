public class Closure {
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