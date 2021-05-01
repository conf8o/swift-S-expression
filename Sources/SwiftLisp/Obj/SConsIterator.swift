public struct SConsIterator: IteratorProtocol {
    var list: SCons
    
    mutating public func next() -> Obj? {
        switch list {
        case .cons(let x, let xs):
            list = xs
            return x
        case .null:
            return nil
        default:
            return _raiseErrorDev(list)
        }
    }
}
