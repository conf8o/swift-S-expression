/// 閉じている演算子メーカー
private class ClosedOperatorMaker<T> {
    var unwrap: (Obj) -> T
    var wrap: (T) -> Obj

    init(unwrap: @escaping (Obj) -> T, wrap: @escaping (T) -> Obj) {
        self.unwrap = unwrap
        self.wrap = wrap
    }

    func makeOperator(_ ope: @escaping (T, T) -> T) -> (SCons) -> Obj {
        func inner(args: SCons) -> Obj {
            guard case .cons(let x, let xs) = args else {
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
            var n = unwrap(x)
            var rest = xs
            while case .cons(let y, let ys) = rest {
                let m = unwrap(y)
                n = ope(n, m)
                rest = ys
            }

            return wrap(n)
        }
        return inner
    }
}

private let intClosedOpe = ClosedOperatorMaker<Int>(unwrap: _unwrapInt, wrap: Obj.int)
private let doubleClosedOpe = ClosedOperatorMaker<Double>(unwrap: _unwrapDouble, wrap: Obj.double)

private class DispatchClosedOperator {
    var opeForInt: (SCons) -> SInt
    var opeForDouble: (SCons) -> SDouble

    init(int: @escaping (Int, Int) -> Int, double: @escaping (Double, Double) -> Double) {
        self.opeForInt = intClosedOpe.makeOperator(int)
        self.opeForDouble = doubleClosedOpe.makeOperator(double)
    }

    func toSBuiltin() -> SBuiltin {
        return .builtin { args in
            switch args {
            case .cons(.int, _):
                return self.opeForInt(args)
            case .cons(.double, _):
                return self.opeForDouble(args)
            default:
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
        }
    }
}

public let BUILTIN_CLOSED_OPERATOR: [Obj.Symbol: SBuiltin] = [
    "'+": DispatchClosedOperator(int: +, double: +).toSBuiltin(),
    "'-": DispatchClosedOperator(int: -, double: -).toSBuiltin(),
    "'*": DispatchClosedOperator(int: *, double: *).toSBuiltin(),
    "'/": DispatchClosedOperator(int: /, double: /).toSBuiltin(),
    "'%": .builtin(intClosedOpe.makeOperator(%))
]
