import XCTest
@testable import DonkeyKongCore

final class BarrelTests: XCTestCase {
    func testKongThrowsAtTheConfiguredInterval() {
        var w = World.playing()
        w.run(Tuning.kongThrowIntervalSteps - 1)
        XCTAssertTrue(w.barrels.isEmpty)
        let e = w.run(1)
        XCTAssertEqual(w.barrels.count, 1)
        XCTAssertEqual(e, [.barrelThrown(id: w.barrels[0].id)])
        XCTAssertEqual(w.barrels[0].position, Levels.barrels.barrelSpawn)
        XCTAssertEqual(w.barrels[0].direction, .right)
        XCTAssertEqual(w.barrels[0].state, .rolling)
        XCTAssertEqual(w.barrels[0].currentGirder, 6)
    }
    func testEveryEighthBarrelIsBlue() {
        var w = World.playing(level: .twoGirders)
        for n in 1...Tuning.blueBarrelEvery {
            w.run(Tuning.kongThrowIntervalSteps)
            XCTAssertEqual(w.barrels.last?.kind, n == Tuning.blueBarrelEvery ? .blue : .normal, "barrel \(n)")
        }
    }
    func testBarrelRollsDownFallsAtTheEndAndReverses() {
        var w = World.playing(level: .twoGirders)
        let g = LevelLayout.twoGirders.girders
        w.run(Tuning.kongThrowIntervalSteps)
        w.run(60)                                                  // +45 pt
        XCTAssertEqual(w.barrels[0].position.x, 20 + Tuning.barrelSpeedPointsPerSecond, accuracy: 1e-6)
        XCTAssertEqual(w.barrels[0].position.y, g[1].surfaceY(at: w.barrels[0].position.x), accuracy: 1e-9)
        w.run(200)                                                 // well past x = 208
        XCTAssertEqual(w.barrels[0].state, .falling)
        w.run(60)
        XCTAssertEqual(w.barrels[0].state, .rolling)
        XCTAssertEqual(w.barrels[0].currentGirder, 0)
        XCTAssertEqual(w.barrels[0].direction, .left)
        XCTAssertEqual(w.barrels[0].position.y, g[0].surfaceY(at: w.barrels[0].position.x), accuracy: 1e-9)
    }
    func testBarrelKeepsDirectionAcrossConnectedGirders() {
        var w = World.playing(seed: 1)
        w.barrels.append(Barrel(id: 99, kind: .normal, position: Vector2(x: 120, y: Levels.barrels.girders[1].surfaceY(at: 120)),
                                direction: .left, currentGirder: 1))
        w.run(20)                                                  // 120 → 105, across the joint at 112
        XCTAssertEqual(w.barrels[0].currentGirder, 0)
        XCTAssertEqual(w.barrels[0].direction, .left)
        XCTAssertEqual(w.barrels[0].position.y, 8, accuracy: 1e-9)
    }
    func testBarrelReversesAtTheSceneEdge() {
        var w = World.playing()
        w.barrels.append(Barrel(id: 99, kind: .normal, position: Vector2(x: 220, y: Levels.barrels.girders[1].surfaceY(at: 220)),
                                direction: .right, currentGirder: 1))
        w.run(20)
        XCTAssertEqual(w.barrels[0].direction, .left)
        XCTAssertLessThanOrEqual(w.barrels[0].position.x, Tuning.sceneWidth)
    }
    func testBarrelIsRemovedInTheOilDrum() {
        var w = World.playing()
        w.barrels.append(Barrel(id: 99, kind: .normal, position: Vector2(x: 40, y: 8), direction: .left, currentGirder: 0))
        w.run(60)
        XCTAssertTrue(w.barrels.isEmpty)
    }
}
