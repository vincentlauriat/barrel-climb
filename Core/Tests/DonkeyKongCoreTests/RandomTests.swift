import XCTest

@testable import DonkeyKongCore

final class RandomTests: XCTestCase {
    func testSameSeedSameSequence() {
        var a = SeededRandom(seed: 42), b = SeededRandom(seed: 42)
        let sa = (0..<20).map { _ in a.next(below: 4) }
        let sb = (0..<20).map { _ in b.next(below: 4) }
        XCTAssertEqual(sa, sb)
    }
    func testValuesStayBelowBound() {
        var r = SeededRandom(seed: 7)
        for _ in 0..<1000 { XCTAssertLessThan(r.next(below: 4), 4) }
    }
    func testDifferentSeedsDiffer() {
        var a = SeededRandom(seed: 1), b = SeededRandom(seed: 2)
        XCTAssertNotEqual(
            (0..<20).map { _ in a.next(below: 100) },
            (0..<20).map { _ in b.next(below: 100) })
    }
}
