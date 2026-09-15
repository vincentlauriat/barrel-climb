import XCTest

@testable import DonkeyKongCore

final class PlayerMovementTests: XCTestCase {
    func testWalkingRightMovesAtWalkSpeedAndFaces() {
        var w = World.playing()
        w.run(60, .right)  // one second
        XCTAssertEqual(w.player.position.x, 40 + Tuning.walkSpeedPointsPerSecond, accuracy: 1e-6)
        XCTAssertEqual(w.player.position.y, 8)
        XCTAssertEqual(w.player.state, .walking)
        XCTAssertEqual(w.player.facing, .right)
        w.run(1, .none)
        XCTAssertEqual(w.player.state, .standing)
        w.run(1, .left)
        XCTAssertEqual(w.player.facing, .left)
    }
    func testWalkingFollowsAnInclinedGirder() {
        var w = World.playing()
        w.player.position = Vector2(x: 100, y: Levels.barrels.girders[2].surfaceY(at: 100))
        w.player.currentGirder = 2
        w.run(30, .right)  // +20 pt
        XCTAssertEqual(w.player.position.x, 120, accuracy: 1e-6)
        XCTAssertEqual(w.player.position.y, Levels.barrels.girders[2].surfaceY(at: 120), accuracy: 1e-9)
        XCTAssertEqual(w.player.currentGirder, 2)
    }
    func testWalkingTransfersToTheConnectedGirder() {
        var w = World.playing()
        w.player.position = Vector2(x: 100, y: 8); w.player.currentGirder = 0
        w.run(30, .right)  // 100 → 120, crosses x = 112
        XCTAssertEqual(w.player.currentGirder, 1)
        XCTAssertEqual(w.player.position.y, Levels.barrels.girders[1].surfaceY(at: 120), accuracy: 1e-9)
        XCTAssertEqual(w.player.state, .walking)
    }
    func testWalkingOffAnOpenEndFallsAndLandsOnTheGirderBelow() {
        var w = World.playing()
        w.player.position = Vector2(x: 204, y: Levels.barrels.girders[2].surfaceY(at: 204))
        w.player.currentGirder = 2
        w.run(10, .right)  // past x = 208
        XCTAssertEqual(w.player.state, .falling)
        XCTAssertNil(w.player.currentGirder)
        let events = w.run(60, .none)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 1)
        XCTAssertEqual(w.player.position.y, Levels.barrels.girders[1].surfaceY(at: w.player.position.x), accuracy: 1e-9)
        XCTAssertTrue(events.contains(.landed))
        XCTAssertEqual(w.game.phase, .playing)
    }
    func testFallingFurtherThanTheFatalDistanceKills() {
        let g = [
            Girder(from: Vector2(x: 0, y: 8), to: Vector2(x: 224, y: 8)),
            Girder(from: Vector2(x: 0, y: 100), to: Vector2(x: 100, y: 100)),
        ]
        let level = LevelLayout(
            girders: g, ladders: [], playerSpawn: Vector2(x: 90, y: 100),
            kongPosition: .zero, paulinePosition: .zero,
            goal: Rect(origin: Vector2(x: 500, y: 500), size: Vector2(x: 1, y: 1)),
            hammers: [], oilDrum: Rect(origin: Vector2(x: 500, y: 0), size: Vector2(x: 1, y: 1)),
            barrelSpawn: Vector2(x: 500, y: 500))
        var w = World.playing(level: level)
        w.player.currentGirder = 1
        let events = w.run(120, .right)
        XCTAssertEqual(w.player.state, .dying)
        XCTAssertEqual(w.game.phase, .playerDied)
        XCTAssertTrue(events.contains(.playerDied))
    }
    func testPlayerStaysInsideTheScene() {
        var w = World.playing()
        w.player.position = Vector2(x: 8, y: 8)
        w.run(60, .left)
        XCTAssertEqual(w.player.position.x, Tuning.playerSize.x / 2, accuracy: 1e-9)
        XCTAssertEqual(w.player.currentGirder, 0)
    }
    func testDeathCountsDownToRespawnWithOneLifeLess() {
        var w = World.playing()
        w.die()
        w.run(Tuning.dyingDurationSteps)
        XCTAssertEqual(w.game.phase, .playing)
        XCTAssertEqual(w.game.lives, Tuning.livesStart - 1)
        XCTAssertEqual(w.player.position, Levels.barrels.playerSpawn)
        XCTAssertEqual(w.player.state, .standing)
    }
}
