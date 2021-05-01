// 比較演算子メーカー
private class ComparisonOperatorMaker<T> {
    var unwrap: (Obj) -> T
    init(unwrap: @escaping (Obj) -> T) {
        self.unwrap = unwrap
    }

    func makeOperator(_ ope: @escaping (T, T) -> Bool) -> (SCons) -> SBool {
        func inner(args: SCons) -> SBool {
            let (x, y) = _take2(list: args, default: (.null, .null))
            return .bool(ope(unwrap(x), unwrap(y)))
        }
        return inner
    }
}

private let intCompOpe = ComparisonOperatorMaker<Int>(unwrap: _unwrapInt)
private let doubleCompOpe = ComparisonOperatorMaker<Double>(unwrap: _unwrapDouble)
private let stringCompOpe = ComparisonOperatorMaker<String>(unwrap: _unwrapString)

private class DispatchComparisonOperator {
    var opeForInt: (SCons) -> SBool
    var opeForDouble: (SCons) -> SBool
    var opeForString: (SCons) -> SBool

    init(int: @escaping (Int, Int) -> Bool,
         double: @escaping (Double, Double) -> Bool,
         string: @escaping (String, String) -> Bool) {
        self.opeForInt = intCompOpe.makeOperator(int)
        self.opeForDouble = doubleCompOpe.makeOperator(double)
        self.opeForString = stringCompOpe.makeOperator(string)
    }

    func toSBuiltin() -> SBuiltin {
        return .builtin { args in
            switch args {
            case .cons(.int, _):
                return self.opeForInt(args)
            case .cons(.double, _):
                return self.opeForDouble(args)
            case .cons(.string, _):
                return self.opeForString(args)
            default:
                return _raiseErrorDev(args) // TODO エラーハンドリング
            }
        }
    }
}

public let BUILTIN_COMPARISON_OPERATOR: [Obj.Symbol: SBuiltin] = [
    "'=": DispatchComparisonOperator(int: ==, double: ==, string: ==).toSBuiltin(),
    "'<": DispatchComparisonOperator(int: <, double: <, string: <).toSBuiltin(),
    "'<=": DispatchComparisonOperator(int: <=, double: <=, string: <=).toSBuiltin(),
    "'>": DispatchComparisonOperator(int: >, double: >, string: >).toSBuiltin(),
    "'>=": DispatchComparisonOperator(int: >=, double: >=, string: >=).toSBuiltin()
]
