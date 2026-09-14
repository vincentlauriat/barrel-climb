import XCTest
@testable import DonkeyKongCore

final class PlayerLadderTests: XCTestCase {
    let level = Levels.barrels
    /// Ladder 0: x = 184 between girders 1 and 2, intact. Ladder 1: x = 88, girder 0 up, broken.
    func placePlayer(_ w: inout World, x: Double, girder: Int) {
        w.player.position = Vector2(x: x, y: level.girders[girder].surfaceY(at: x))
        w.player.currentGirder = girder
        w.player.state = .standing
    }

    func testClimbingUpAnIntactLadderArrivesOnTheUpperGirder() {
        var w = World.playing()
        placePlayer(&w, x: 186, girder: 1)                        // within the 4 pt snap tolerance
        let e = w.run(1, .up)
        XCTAssertEqual(w.player.state, .climbing)
        XCTAssertEqual(w.player.position.x, 184, "snapped to the ladder")
        XCTAssertEqual(w.player.currentLadder, 0)
        XCTAssertTrue(e.contains(.climbStarted))
        w.run(90, .up)                                            // ~29 pt at 30 pt/s
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 2)
        XCTAssertEqual(w.player.position.y, level.girders[2].surfaceY(at: 184), accuracy: 1e-9)
    }
    func testLadderRequiresAlignment() {
        var w = World.playing()
        placePlayer(&w, x: 184 + 6, girder: 1)
        w.run(1, .up)
        XCTAssertEqual(w.player.state, .standing)
    }
    func testClimbingDownFromTheTopArrivesOnTheLowerGirder() {
        var w = World.playing()
        placePlayer(&w, x: 184, girder: 2)
        w.run(1, .down)
        XCTAssertEqual(w.player.state, .climbing)
        w.run(90, .down)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 1)
    }
    func testBrokenLadderStopsShortAndMustBeDescended() {
        var w = World.playing()
        placePlayer(&w, x: 88, girder: 0)
        w.run(120, .up)
        XCTAssertEqual(w.player.state, .climbing)
        XCTAssertEqual(w.player.position.y, level.ladders[1].topY, accuracy: 1e-9)
        w.run(120, .down)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 0)
    }
    func testBrokenLadderCannotBeEnteredFromAbove() {
        var w = World.playing()
        placePlayer(&w, x: 88, girder: 2)
        w.run(1, .down)
        XCTAssertEqual(w.player.state, .standing)
    }
    func testNoJumpingOrWalkingWhileOnALadder() {
        var w = World.playing()
        placePlayer(&w, x: 184, girder: 1)
        w.run(10, .up)
        w.run(1, .jump); w.run(10, .right)
        XCTAssertEqual(w.player.state, .climbing)
        XCTAssertEqual(w.player.position.x, 184)
    }
    func testNoLaddersWhileHammering() {
        var w = World.playing()
        placePlayer(&w, x: 184, girder: 1)
        w.player.state = .hammering; w.player.hammerStepsRemaining = 100
        w.run(1, .up)
        XCTAssertEqual(w.player.state, .hammering)
    }
}
