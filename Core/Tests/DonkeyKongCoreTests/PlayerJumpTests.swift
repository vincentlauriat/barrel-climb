import XCTest

@testable import DonkeyKongCore

final class PlayerJumpTests: XCTestCase {
    func testJumpPeaksAtJumpHeightAndLandsAfterItsDuration() {
        var w = World.playing()
        let start = w.run(1, .jump)
        XCTAssertEqual(w.player.state, .jumping)
        XCTAssertTrue(start.contains(.jumped))
        w.run(Tuning.jumpDurationSteps / 2)  // the trigger step itself does not move
        XCTAssertEqual(w.player.position.y, 8 + Tuning.jumpHeightPoints, accuracy: 1e-9)
        let landing = w.run(Tuning.jumpDurationSteps / 2)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.position.y, 8, accuracy: 1e-9)
        XCTAssertEqual(w.player.currentGirder, 0)
        XCTAssertTrue(landing.contains(.landed))
    }
    func testJumpDriftIsLockedAtTakeoff() {
        var w = World.playing()
        w.run(1, Input(right: true, jump: true))
        w.run(Tuning.jumpDurationSteps, .left)  // trying to reverse mid-air does nothing
        XCTAssertEqual(w.player.position.x, 40 + Tuning.walkSpeedPointsPerSecond / 2, accuracy: 1e-6)
        XCTAssertEqual(w.player.facing, .right)
    }
    func testHoldingJumpDoesNotChainJumps() {
        var w = World.playing()
        w.run(Tuning.jumpDurationSteps + 1, .jump)
        XCTAssertEqual(w.player.state, .standing, "a held button does not re-trigger")
        w.run(1, .none); w.run(1, .jump)
        XCTAssertEqual(w.player.state, .jumping)
    }
    func testJumpingPastAnOpenEndFallsOntoTheGirderBelow() {
        var w = World.playing()
        w.player.position = Vector2(x: 200, y: Levels.barrels.girders[2].surfaceY(at: 200))
        w.player.currentGirder = 2
        w.run(1, Input(right: true, jump: true))
        w.run(Tuning.jumpDurationSteps)
        XCTAssertEqual(w.player.state, .falling)
        w.run(90)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 1)
    }
    func testCannotJumpWhileHammering() {
        var w = World.playing()
        w.player.state = .hammering; w.player.hammerStepsRemaining = 100
        w.run(1, .jump)
        XCTAssertEqual(w.player.state, .hammering)
    }
}
