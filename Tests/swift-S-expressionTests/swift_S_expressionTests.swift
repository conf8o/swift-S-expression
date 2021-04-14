import XCTest
@testable import swift_S_expression

final class swift_S_expressionTests: XCTestCase {
    func testExample() throws {
        // TODO for WSL2
        let expect = Obj.int(3)
        XCTAssertEqual(unwrapInt(expect), unwrapInt(["'+", 1, 2] as Obj))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

func unwrapInt(_ obj: SInt) -> Int {
    guard case .int(let x) = obj else {
        return Int.max
    }
    return x
}