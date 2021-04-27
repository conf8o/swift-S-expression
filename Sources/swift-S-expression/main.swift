struct Main {
    var env: Env
    mutating func debug(_ objs: Obj...) {
        debug(objs)
    }
    mutating func debug(_ objs: [Obj]) {
        for (i, obj) in objs.enumerated() {
            print("===--- S:\(i+1) ---===")
            print(obj)
            let res = obj.eval(env: &env)
            print("Env:", env)
            print("Result:", res)
        }
    }

    mutating func run(_ objs: Obj...) -> Obj {
        run(objs)
    }
    mutating func run(_ objs: [Obj]) -> Obj {
        var last = Obj.null
        for obj in objs {
            last = obj.eval(env: &env)
        }
        return last
    }
}

func sExprDebug() {
    var debug = Main(env: Env())

    debug.debug(
        ["'+", 1, 2],
        ["'+", 1.0, 2.0],
        ["'/", 22.0, 7.0],

        [["'lambda", ["'x", "'y"], ["'+", "'x", "'y"]], 1, 2],

        ["'define", "'x", ["'+", 1, 2]],

        ["'if", ["'=", 1, 2], ["'+", 10, 2], ["'%", 5, 2]],

        ["'define", "'f", ["'lambda", ["'x", "'y"], ["'*", "'x", "'y"]]],
        ["'f", 10, 2],

        ["'let", [["'x", 1],
                  ["'y", 10]],
            ["'+", "'x", "'y"]],

        ["'define", "'sum", 10],
        [["'lambda", ["'x"], ["'+", "'x", "'sum"]], 100],

        ["'letrec", 
            [["'fact",
             ["'lambda", ["'n"],
                ["'if", ["'=", 1, "'n"],
                    1,
                    ["'*", "'n", ["'fact", ["'-", "'n", 1]]]]]]],
            ["'fact", 5]],

        ["'define", "'fib",
            ["'lambda", ["'n"],
                ["'if", ["'=", 0, "'n"],
                        0,
                        ["'if", ["'=", 1, "'n"],
                            1,
                            ["'+", ["'fib", ["'-", "'n", 1]],
                                   ["'fib", ["'-", "'n", 2]]]]]]],
        ["'fib", 9],

        [["'lambda", ["'f", "'x", "'y"], ["'f", ["'+", "'x", "'y"], ["'*", "'x", "'y"]]],
         "'*", 10, 5],

         ["'define", ["'sum", "'col"],
            ["'if", ["'null?", "'col"],
                0,
                ["'+", ["'car", "'col"], ["'sum", ["'cdr", "'col"]]]]],
        ["'sum", ["'list", 1, 2, 3, 4, 5]],
        ["'cond", [false, 1], [true, "3"]]
    )
}

func lexicalAnalysisDebug() {
    let s = """
(+ 1 2)
(+ 1.0 2.0)
(/ 22.0 7.0)
((lambda (x y) (+ x y)) 1 2)
(define x (+ 1 2))
(if (= 1 2) (+ 10 2) (% 5 2))
(define f (lambda (x y) (* x y)))
(f 10 2)
(let ([x 1]
      [y 10])
    (+ x y))
(define sum 10)
((lambda (x) (+ x sum)) 100)
(letrec
    ([fact
      (lambda (n)
        (if (= 1 n)
            1
            (* n (fact (- n 1)))))])
    (fact 5))
(define fib
    (lambda (n)
        (if (= 0 n)
            0
            (if (= 1 n)
                1
                (+ (fib (- n 1))
                   (fib (- n 2)))))))
(fib 9)
((lambda (f x y) (f (+ x y) (* x y)))
 * 10 5)

(define (sum col)
    (if (null? col)
        0
        (+ (car col) (sum (cdr col)))))
(sum (list 1 2 3 4 5))
(car (list "a" "b"))
(str 2.2 1 "a b")
(cond
    [(= x 2) (* 1 2)]
    [(= x 3) (* 2 3)])
(cond
    [#f (* 1 2)]
    [else (* 2 3)])
(< 1 1)
(<= 1 1)
(> 1 0)
(>= 1 1)
(string->list "abcde")
(define v (make-vector 3))
(~ v 2 100)
(~ v 2)
(~ v 1 50)
(print v)
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

sExprDebug()
lexicalAnalysisDebug()
