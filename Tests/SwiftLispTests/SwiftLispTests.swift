import XCTest
@testable import SwiftLisp

final class SwiftLispTests: XCTestCase {
    
    func testBasicFunc() throws {
        let s = """
(+ 1 2)
(+ 1.0 2.0)
(* 2 3)
(/ 22.0 7.0)
(< 1 1)
(<= 1 1)
(> 1 0)
(>= 1 1)
(str 2.2 1 "a b")
(string->list "abcde")
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int(1 + 2),
                             .double(1.0 + 2.0),
                             .int(2 * 3),
                             .double(22.0 / 7.0),
                             .bool(1 < 1),
                             .bool(1 <= 1),
                             .bool(1 > 0),
                             .bool(1 >= 1),
                             .string("2.21a b"),
                             .S(["a", "b", "c", "d", "e"])]))
    }
    
    func testIf() throws {
        let s = """
(if (= 1 1) (+ 10 2) (% 5 2))
(if (= 1 2) (+ 10 2) (% 5 2))
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int(12),
                             .int(1)]))
    }
    func testCond() throws {
        let s = """
(cond
    [(= 1 1) (* 1 2)]
    [(= 2 3) (* 2 3)])
(cond
    [#f (* 1 2)]
    [else (* 2 3)])
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int(2),
                             .int(6)]))
    }
    func testLet() throws {
        let s = """
(let ([x 1]
      [y 10])
    (+ x y))
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int(11)]))
    }
    
    func testLambda() throws {
        let s = """
((lambda (x y) (+ x y)) 1 2)
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int(3)]))
    }
    
    func testDefine() throws {
        let s = """
(define x (+ 1 2))
(identity x)
(define sum 10)
((lambda (x) (+ x sum)) 100)
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.null,
                             .int(1 + 2),
                             .null,
                             .int(110)]))
    }
    
    func testRecur() throws {
        let s = """
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
(define (sum col)
    (if (null? col)
        0
        (+ (car col) (sum (cdr col)))))
(sum (list 1 2 3 4 5))
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int((1...5).reduce(1, *)),
                             .null,
                             .int(34),
                             .null,
                             .int((1...5).reduce(0, +))]))
    }
    
    func testHighOrderFunc() throws {
        let s = """
((lambda (f x y) (f (+ x y) (* x y)))
    * 10 5)
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                            [.int((10 + 5) * (10 * 5))]))
    }
    
    func testVector() throws {
        let s = """
(define v (make-vector 3))
(identity v)
(~ v 1 50)
(~ v 1)
(~ v 2 100)
(identity v)
"""
        XCTAssertTrue(
            evalAndEqualAll(s,
                       [Obj.null,
                        Obj.vector(Vector([.null, .null, .null])),
                        Obj.null,
                        Obj.int(50),
                        Obj.null,
                        Obj.vector(Vector([.null, .int(50), .int(100)]))]))
    }

    static var allTests = [
        ("testBasicFunc", testBasicFunc),
        ("testIf", testIf),
        ("testCond", testCond),
        ("testLet", testLet),
        ("testLambda", testLambda),
        ("testDefine", testDefine),
        ("testRecur", testRecur),
        ("testHighOrderFunc", testHighOrderFunc),
        ("testVector", testVector)
    ]
}

func evalAndEqualAll(_ sEsxpStr: String, _ expects: [Obj]) -> Bool {
    let sExprs = try! Obj.read(sExpr: sEsxpStr)
    var env = Env()
    return zip(sExprs, expects).allSatisfy { (s, e) in s.eval(env: &env) == e }
}
