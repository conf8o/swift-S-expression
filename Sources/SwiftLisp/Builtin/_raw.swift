// 戻り値の型が生っぽい関数などには先頭にアンダースコアをつける。

/// 開発用の簡易クラッシャー
public func _raiseErrorDev<T>(_ obj: Obj...) -> T {
    var error = [T]()
    print("Value Error!", obj)
    return error.popLast()!
}

/// リストの最初の二つをタプルで取り出す。
public func _take2(list: SCons, default obj: (Obj, Obj))-> (Obj, Obj) {
    guard case .cons(let x, .cons(let y, _)) = list else { return obj }
    return (x, y)
}

/// リストの最初の三つをタプルで取り出す。
public func _take3(list: SCons, default obj: (Obj, Obj, Obj))-> (Obj, Obj, Obj) {
    guard case .cons(let x, .cons(let y, .cons(let z, _))) = list else { return obj }
    return (x, y, z)
}

public func _unwrapInt(obj: Obj) -> Int {
    guard case .int(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

public func _unwrapDouble(obj: Obj) -> Double {
    guard case .double(let n) = obj else {
        return _raiseErrorDev(obj)
    }
    return n
}

public func _unwrapString(obj: Obj) -> String {
    guard case .string(let s) = obj else {
        return _raiseErrorDev(obj)
    }
    return s
}

/// 論理式判定
/// Clojureに則って .null と .bool(false) だけ false
/// それ以外は true
public func _logicalTrue(obj: Obj) -> Bool {
    switch obj {
    case .null:
        return false
    case .bool(false):
        return false
    default:
        return true
    }
}
