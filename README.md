# swift-S-expression

SwiftのArrayをS式と見立てて評価する。(字句解析実装予定)

## 実行例

```swift
struct Main {
    var env: Env
    mutating func debug(_ objs: Obj...) {
        for (i, obj) in objs.enumerated() {
            print("===--- S:\(i+1) ---===")
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

```

### 結果

```
===--- S:1 ---===
Env: [[:]]
Result: 3
===--- S:2 ---===
Env: [[:]]
Result: 3.0
===--- S:3 ---===
Env: [[:]]
Result: 3.142857142857143
===--- S:4 ---===
Env: [[:]]
Result: 3
===--- S:5 ---===
Env: [["\'x": 3]]
Result: 
===--- S:6 ---===
Env: [["\'x": 3]]
Result: 1
===--- S:7 ---===
Env: [["\'x": 3, "\'f": (Closure)]]
Result: 
===--- S:8 ---===
Env: [["\'x": 3, "\'f": (Closure)]]
Result: 20
===--- S:9 ---===
Env: [["\'x": 3, "\'f": (Closure)]]
Result: 11
===--- S:10 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure)]]
Result: 
===--- S:11 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure)]]
Result: 110
===--- S:12 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure)]]
Result: 120
===--- S:13 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure), "\'fib": (Closure)]]
Result: 
===--- S:14 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure), "\'fib": (Closure)]]
Result: 34
===--- S:15 ---===
Env: [["\'x": 3, "\'sum": 10, "\'f": (Closure), "\'fib": (Closure)]]
Result: 750
===--- S:16 ---===
Env: [["\'x": 3, "\'sum": (Closure), "\'f": (Closure), "\'fib": (Closure)]]
Result: 
===--- S:17 ---===
Env: [["\'x": 3, "\'sum": (Closure), "\'f": (Closure), "\'fib": (Closure)]]
Result: 15
```


## 中身の紹介

列挙型`Obj`にS式で使える型を定義し、リテラルからインスタンスを生成できるプロトコルを`Obj`に実装することにより、イイ感じにS式を記述できる。

atomを示す型は定義していない。

```swift
public enum Obj {
    public typealias Symbol = String
    case int(Int)
    case double(Double)
    case string(String)
    case bool(Bool)
    case symbol(Symbol)
    case builtin((Obj) -> Obj)
    case closure(Closure)
    case special((Obj, inout Env) -> Obj)
    case null
    indirect case cons(Obj, Obj)
}
```

```swift
/// 環境([[変数: オブジェクト]])
public typealias Env = [[String: Obj]]
```

```swift
/// Objのリテラル表記(Int)
extension Obj: ExpressibleByIntegerLiteral {
    public init(integerLiteral: Int) {
        self = .int(integerLiteral)
    }
}

/// Objのリテラル表記(Double)
extension Obj: ExpressibleByFloatLiteral {
    public init(floatLiteral: Double) {
        self = .double(floatLiteral)
    }
}

/// Objのリテラル表記(String, Symbol)
extension Obj: ExpressibleByStringLiteral {
    public init(stringLiteral: String) {
        if let quote = stringLiteral.first, quote == "'" {
            self = .symbol(stringLiteral)
        } else {
            self = .string(stringLiteral)
        }
    }
}

/// Objのリテラル表記(Array)
extension Obj: ExpressibleByArrayLiteral {
    public init(arrayLiteral: Obj...) {
        self = S(arrayLiteral)
    }
}
```