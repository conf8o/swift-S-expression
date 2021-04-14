struct Main {
    var env: Env
    mutating func debug(_ objs: Obj...) {
        for (i, obj) in objs.enumerated() {
            print("===--- S:\(i) ---===")
            let res = obj.eval(env: &env)
            print("Env:", env)
            print("Result:", res)
        }
    }
    mutating func run(_ objs: Obj...) -> Obj {
        var last = Obj.null
        for obj in objs {
            last = obj.eval(env: &env)
        }
        return last
    }
}
var main = Main(env: globalEnv)

main.debug(
    ["'+", 1, 2],

    [["'lambda", ["'x", "'y"], ["'+", "'x", "'y"]], 1, 2],

    ["'define", "'x", ["'+", 1, 2]],

    ["'if", ["'=", 1, 2], ["'+", 10, 2], ["'%", 5, 2]],

    ["'define", "'f", ["'lambda", ["'x", "'y"], ["'*", "'x", "'y"]]],
    ["'f", 10, 2],

    ["'let", [["'x", 1],
              ["'y", 10]],
        ["'+", "'x", "'y"]],

    ["'define", "'fact",
        ["'lambda", ["'n"],
            ["'if", ["'=", 1, "'n"],
                1,
                ["'*", "'n", ["'fact", ["'-", "'n", 1]]]]]],
    ["'fact", 5],
    
    ["'define", "'fib",
        ["'lambda", ["'n"],
            ["'if", ["'=", 0, "'n"],
                    0,
                    ["'if", ["'=", 1, "'n"],
                        1,
                        ["'+", ["'fib", ["'-", "'n", 1]],
                               ["'fib", ["'-", "'n", 2]]]]]]],
    ["'fib", 9]    
)
