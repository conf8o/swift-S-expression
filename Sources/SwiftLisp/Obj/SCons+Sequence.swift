extension SCons: Sequence {
    public func makeIterator() -> SConsIterator {
        guard case .cons = self else {
            return _raiseErrorDev(self)
        }
        return SConsIterator(list: self)
    }
}
