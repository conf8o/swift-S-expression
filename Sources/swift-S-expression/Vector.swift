public class Vector {
    var buffer: [Obj]

    init(_ list: SCons) {
        self.buffer = []
        var rest = list
        while case .cons(let x, let xs) = rest {
            buffer.append(x)
            rest = xs
        }
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
