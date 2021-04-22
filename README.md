# swift-S-expression

SwiftでS式を評価

Swift製Lisp

## 実行例

```swift
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
            (if (= 1 n))
                1
                (+ (fib (- n 1))
                   (fib (- n 2))))))
(fib 9)
((lambda (f x y) (f (+ x y) (* x y)))
 * 10 5)

(define (sum col)
    (if (null? col)
        0
        (+ (car col) (sum (cdr col)))))
(sum (list 1 2 3 4 5))
(car (list "a" "b"))
"""
    let exprs = try! Obj.read(sExpr: s)
    print(exprs)

    var debug = Main(env: [[:]])
    debug.debug(exprs)
}

```

### 結果
```
[(+ 1 2), (+ 1.0 2.0), (/ 22.0 7.0), ((lambda (x y) (+ x y)) 1 2), (define x (+ 1 2)), (if (= 1 2) (+ 10 2) (% 5 2)), (define f (lambda (x y) (* x y))), (f 10 2), (let ((x 1) (y 10)) (+ x y)), (define sum 10), ((lambda (x) (+ x sum)) 100), (letrec ((fact (lambda (n) (if (= 1 n) 1 (* n (fact (- n 1))))))) (fact 5)), (define fib (lambda (n) (if (= 0 n) 0 (if (= 1 n)) 1 (+ (fib (- n 1)) (fib (- n 2)))))), (fib 9), ((lambda (f x y) (f (+ x y) (* x y))) * 10 5), (define (sum col) (if (null? col) 0 (+ (car col) (sum (cdr col))))), (sum (list 1 2 3 4 5)), (car (list "a" "b"))]
===--- S:1 ---===
(+ 1 2)
Env: [[:]]
Result: 3
===--- S:2 ---===
(+ 1.0 2.0)
Env: [[:]]
Result: 3.0
===--- S:3 ---===
(/ 22.0 7.0)
Env: [[:]]
Result: 3.142857142857143
===--- S:4 ---===
((lambda (x y) (+ x y)) 1 2)
Env: [[:]]
Result: 3
===--- S:5 ---===
(define x (+ 1 2))
Env: [["\'x": 3]]
Result: 
===--- S:6 ---===
(if (= 1 2) (+ 10 2) (% 5 2))
Env: [["\'x": 3]]
Result: 1
===--- S:7 ---===
(define f (lambda (x y) (* x y)))
Env: [["\'f": (Closure), "\'x": 3]]
Result: 
===--- S:8 ---===
(f 10 2)
Env: [["\'f": (Closure), "\'x": 3]]
Result: 20
===--- S:9 ---===
(let ((x 1) (y 10)) (+ x y))
Env: [["\'f": (Closure), "\'x": 3]]
Result: 11
===--- S:10 ---===
(define sum 10)
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 
===--- S:11 ---===
((lambda (x) (+ x sum)) 100)
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 110
===--- S:12 ---===
(letrec ((fact (lambda (n) (if (= 1 n) 1 (* n (fact (- n 1))))))) (fact 5))
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 120
===--- S:13 ---===
(define fib (lambda (n) (if (= 0 n) 0 (if (= 1 n)) 1 (+ (fib (- n 1)) (fib (- n 2))))))
Env: [["\'x": 3, "\'f": (Closure), "\'sum": 10, "\'fib": (Closure)]]
Result: 
===--- S:14 ---===
(fib 9)
Env: [["\'x": 3, "\'f": (Closure), "\'sum": 10, "\'fib": (Closure)]]
Result: 
===--- S:15 ---===
((lambda (f x y) (f (+ x y) (* x y))) * 10 5)
Env: [["\'x": 3, "\'f": (Closure), "\'sum": 10, "\'fib": (Closure)]]
Result: 750
===--- S:16 ---===
(define (sum col) (if (null? col) 0 (+ (car col) (sum (cdr col)))))
Env: [["\'x": 3, "\'f": (Closure), "\'sum": (Closure), "\'fib": (Closure)]]
Result: 
===--- S:17 ---===
(sum (list 1 2 3 4 5))
Env: [["\'x": 3, "\'f": (Closure), "\'sum": (Closure), "\'fib": (Closure)]]
Result: 15
===--- S:18 ---===
(car (list "a" "b"))
Env: [["\'x": 3, "\'f": (Closure), "\'sum": (Closure), "\'fib": (Closure)]]
Result: "a"
```

## 実行例(Arrayバージョン)

```swift
func sExprDebug() {
    var debug = Main(env: [[:]])

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
        ["'sum", ["'list", 1, 2, 3, 4, 5]]
    )
}

sExprDebug()
```

### 結果

```
===--- S:1 ---===
(+ 1 2)
Env: [[:]]
Result: 3
===--- S:2 ---===
(+ 1.0 2.0)
Env: [[:]]
Result: 3.0
===--- S:3 ---===
(/ 22.0 7.0)
Env: [[:]]
Result: 3.142857142857143
===--- S:4 ---===
((lambda (x y) (+ x y)) 1 2)
Env: [[:]]
Result: 3
===--- S:5 ---===
(define x (+ 1 2))
Env: [["\'x": 3]]
Result: 
===--- S:6 ---===
(if (= 1 2) (+ 10 2) (% 5 2))
Env: [["\'x": 3]]
Result: 1
===--- S:7 ---===
(define f (lambda (x y) (* x y)))
Env: [["\'f": (Closure), "\'x": 3]]
Result: 
===--- S:8 ---===
(f 10 2)
Env: [["\'f": (Closure), "\'x": 3]]
Result: 20
===--- S:9 ---===
(let ((x 1) (y 10)) (+ x y))
Env: [["\'f": (Closure), "\'x": 3]]
Result: 11
===--- S:10 ---===
(define sum 10)
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 
===--- S:11 ---===
((lambda (x) (+ x sum)) 100)
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 110
===--- S:12 ---===
(letrec ((fact (lambda (n) (if (= 1 n) 1 (* n (fact (- n 1))))))) (fact 5))
Env: [["\'f": (Closure), "\'x": 3, "\'sum": 10]]
Result: 120
===--- S:13 ---===
(define fib (lambda (n) (if (= 0 n) 0 (if (= 1 n) 1 (+ (fib (- n 1)) (fib (- n 2)))))))
Env: [["\'fib": (Closure), "\'sum": 10, "\'f": (Closure), "\'x": 3]]
Result: 
===--- S:14 ---===
(fib 9)
Env: [["\'fib": (Closure), "\'sum": 10, "\'f": (Closure), "\'x": 3]]
Result: 34
===--- S:15 ---===
((lambda (f x y) (f (+ x y) (* x y))) * 10 5)
Env: [["\'fib": (Closure), "\'sum": 10, "\'f": (Closure), "\'x": 3]]
Result: 750
===--- S:16 ---===
(define (sum col) (if (null? col) 0 (+ (car col) (sum (cdr col)))))
Env: [["\'fib": (Closure), "\'sum": (Closure), "\'f": (Closure), "\'x": 3]]
Result: 
===--- S:17 ---===
(sum (list 1 2 3 4 5))
Env: [["\'fib": (Closure), "\'sum": (Closure), "\'f": (Closure), "\'x": 3]]
Result: 15
```

## 組み込み関数一覧

TODO
