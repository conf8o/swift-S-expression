public class Vector {
    private var buffer: [Obj]

    init(_ list: SCons) {
        self.buffer = Array(list)
    }
    init(_ array: [Obj]) {
        self.buffer = array
    }

    subscript(i: Int) -> Obj {
        get {
            return buffer[i]
        }

        set(obj) {
            buffer[i] = obj
        }
    }
}

extension Vector: CustomStringConvertible {
    public var description: String {
        return self.buffer.description
    }
}

extension Vector: Equatable {
    public static func == (lhs: Vector, rhs: Vector) -> Bool {
        return lhs.buffer == rhs.buffer
    }
}
