import XCTest
@testable import DonkeyKongCore

final class LevelTests: XCTestCase {
    let level = Levels.barrels

    func testGirderSurfaceInterpolatesAndClamps() {
        let g = Girder(from: Vector2(x: 0, y: 48), to: Vector2(x: 208, y: 41))
        XCTAssertEqual(g.surfaceY(at: 0), 48)
        XCTAssertEqual(g.surfaceY(at: 208), 41)
        XCTAssertEqual(g.surfaceY(at: 104), 44.5, accuracy: 1e-9)
        XCTAssertEqual(g.surfaceY(at: 300), 41, "clamped beyond the end")
        XCTAssertTrue(g.contains(x: 100)); XCTAssertFalse(g.contains(x: 209))
    }
    func testGirdersRunLeftToRightAndFitTheScene() {
        for g in level.girders {
            XCTAssertLessThan(g.from.x, g.to.x)
            XCTAssertGreaterThanOrEqual(g.from.x, 0); XCTAssertLessThanOrEqual(g.to.x, Tuning.sceneWidth)
        }
        XCTAssertEqual(level.girders.count, 8)
    }
    func testEveryLadderConnectsTwoGirdersItStandsOn() {
        for l in level.ladders {
            let lower = level.girders[l.lowerGirder], upper = level.girders[l.upperGirder]
            XCTAssertTrue(lower.contains(x: l.x), "ladder at x=\(l.x) misses its lower girder")
            XCTAssertTrue(upper.contains(x: l.x), "ladder at x=\(l.x) misses its upper girder")
            XCTAssertEqual(l.bottomY, lower.surfaceY(at: l.x), accuracy: 1e-9)
            if l.isBroken {
                XCTAssertLessThan(l.topY, upper.surfaceY(at: l.x) - 10)
            } else {
                XCTAssertEqual(l.topY, upper.surfaceY(at: l.x), accuracy: 1e-9)
            }
        }
        XCTAssertEqual(level.ladders.count, 16)
        XCTAssertEqual(level.ladders.filter(\.isBroken).count, 5)
    }
    func testKeyPositionsSitOnGirders() {
        XCTAssertEqual(level.playerSpawn.y, level.girders[0].surfaceY(at: level.playerSpawn.x), accuracy: 1e-9)
        XCTAssertTrue(level.girders[7].contains(x: level.paulinePosition.x))
        XCTAssertTrue(level.goal.contains(level.paulinePosition))
        XCTAssertEqual(level.hammers.count, 2)
        XCTAssertTrue(level.girders[0].contains(x: level.oilDrum.center.x))
    }
}
