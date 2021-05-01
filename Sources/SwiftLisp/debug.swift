struct Main {
    var env: Env
    mutating func debug(_ objs: [Obj]) {
        for (i, obj) in objs.enumerated() {
            print("===--- S:\(i+1) ---===")
            print(obj)
            let res = obj.eval(env: &env)
            print("Env:", env)
            print("Result:", res)
        }
    }
    mutating func run(_ objs: [Obj]) -> Obj {
        var last = Obj.null
        for obj in objs {
            last = obj.eval(env: &env)
        }
        return last
    }
}

func lexicalAnalysisDebug() {
    let s = """
(define (loop1 i)
  (if (= i 1000)
    "done"
    (loop1 (+ i 1))))
(loop1 0)
(define (loop2 i s)
  (if (= i 10)
    s
    (let ([a (loop1 0)])
      (loop2 (+ i 1) a))))
(loop2 0)
"""
    let exprs = try! Obj.read(sExpr: s)
    print(exprs)

    var debug = Main(env: Env())
    debug.debug(exprs)
}
