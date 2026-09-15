import XCTest

@testable import DonkeyKongCore

final class GeometryTests: XCTestCase {
    func testVectorArithmetic() {
        let v = Vector2(x: 1, y: 2) + Vector2(x: 3, y: 4) * 2
        XCTAssertEqual(v, Vector2(x: 7, y: 10))
        XCTAssertEqual(Vector2(x: 5, y: 5) - Vector2(x: 1, y: 2), Vector2(x: 4, y: 3))
    }
    func testRectIntersection() {
        let a = Rect(origin: Vector2(x: 0, y: 0), size: Vector2(x: 10, y: 10))
        let b = Rect(origin: Vector2(x: 9, y: 9), size: Vector2(x: 5, y: 5))
        let c = Rect(origin: Vector2(x: 10, y: 0), size: Vector2(x: 5, y: 5))
        XCTAssertTrue(a.intersects(b))
        XCTAssertFalse(a.intersects(c), "touching edges do not intersect")
        XCTAssertEqual(a.maxX, 10); XCTAssertEqual(b.minY, 9)
    }
    func testRectCentered() {
        let r = Rect(center: Vector2(x: 10, y: 10), size: Vector2(x: 4, y: 6))
        XCTAssertEqual(r.origin, Vector2(x: 8, y: 7))
    }
    func testDirection() {
        XCTAssertEqual(Direction.left.sign, -1); XCTAssertEqual(Direction.right.sign, 1)
        XCTAssertEqual(Direction.left.flipped, .right)
    }
}
