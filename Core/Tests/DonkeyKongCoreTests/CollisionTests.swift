import XCTest

@testable import DonkeyKongCore

final class CollisionTests: XCTestCase {
    let level = Levels.barrels

    func testBarrelContactKills() {
        var w = World.playing()
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 42, y: 8), direction: .left, currentGirder: 0))
        let e = w.run(1)
        XCTAssertEqual(w.player.state, .dying)
        XCTAssertEqual(w.game.phase, .playerDied)
        XCTAssertTrue(e.contains(.playerDied))
    }
    func testFireballContactKills() {
        var w = World.playing()
        w.fireballs.append(Fireball(id: 1, position: Vector2(x: 42, y: 8), direction: .left, currentGirder: 0))
        w.run(1)
        XCTAssertEqual(w.player.state, .dying)
    }
    func testJumpingOverABarrelScoresOnceAndSurvives() {
        var w = World.playing()
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 70, y: 8), direction: .left, currentGirder: 0))
        w.run(25)  // barrel now at x ≈ 51
        w.run(1, .jump)
        let e = w.run(40)
        XCTAssertEqual(w.game.phase, .playing)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.game.score, Tuning.scoreJumpBarrel)
        XCTAssertEqual(e.filter { if case .barrelJumped = $0 { return true } else { return false } }.count, 1)
    }
    func testJumpingTooLateIsDeath() {
        var w = World.playing()
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 70, y: 8), direction: .left, currentGirder: 0))
        w.run(30)  // barrel at x ≈ 47.5, not yet touching
        w.run(1, .jump)
        w.run(5)
        XCTAssertEqual(w.player.state, .dying)
    }
    func testLadderMidwayIsSafeFromBarrelsAbove() {
        var w = World.playing()
        let topY = level.ladders[0].topY
        w.player.position = Vector2(x: 184, y: topY - 1); w.player.state = .climbing
        w.player.currentLadder = 0; w.player.currentGirder = nil
        w.barrels.append(
            Barrel(
                id: 1, kind: .normal, position: Vector2(x: 184, y: level.girders[2].surfaceY(at: 184)),
                direction: .right, currentGirder: 2))
        w.run(1)
        XCTAssertEqual(w.player.state, .climbing)  // still below the upper girder: refuge holds
        // Once actually arrived on the girder above, the same barrel is deadly.
        w.player.position = Vector2(x: 184, y: topY); w.player.state = .standing
        w.player.currentLadder = nil; w.player.currentGirder = 2
        w.run(1)
        XCTAssertEqual(w.player.state, .dying)
    }
    func testLadderFootIsNotARefuge() {
        var w = World.playing()
        w.player.position = Vector2(x: 184, y: level.ladders[0].bottomY); w.player.state = .climbing
        w.player.currentLadder = 0; w.player.currentGirder = nil
        w.barrels.append(
            Barrel(
                id: 1, kind: .normal, position: Vector2(x: 184, y: level.girders[1].surfaceY(at: 184)),
                direction: .right, currentGirder: 1))
        w.run(1)
        XCTAssertEqual(w.player.state, .dying)  // sitting at the foot is still on the lower girder's level
    }
    func testHammerDoesNotSwingWhileClimbing() {
        var w = World.playing()
        w.player.position = Vector2(x: 184, y: 25); w.player.state = .climbing
        w.player.currentLadder = 0; w.player.currentGirder = nil
        w.player.hammerStepsRemaining = 200; w.player.facing = .right
        // Sits where `hammerBounds(step:)` would place the (inactive) swing head for this
        // position/facing at the first step — well clear of the player's own hitbox.
        w.barrels.append(
            Barrel(
                id: 1, kind: .normal, position: Vector2(x: 195, y: level.girders[2].surfaceY(at: 195)),
                direction: .right, currentGirder: 2))
        let e = w.run(Tuning.hammerSwingPeriodSteps * 2)
        XCTAssertEqual(w.barrels.count, 1)
        XCTAssertFalse(e.contains { if case .hammerHit = $0 { return true } else { return false } })
    }
    func testHammerPickedWhileClimbingTakesEffectOnArrival() {
        var w = World.playing()
        w.player.position = Vector2(x: 176, y: level.girders[2].surfaceY(at: 176)); w.player.currentGirder = 2
        w.run(100, .up)  // enters ladder 4 (176, girder 2 → 3) and climbs it fully, picking up hammer 1 en route
        XCTAssertEqual(w.hammersTaken, [1])
        XCTAssertEqual(w.player.state, .hammering)
        XCTAssertGreaterThan(w.player.hammerStepsRemaining, 0)
        w.run(1, .jump)
        XCTAssertEqual(w.player.state, .hammering)  // no jump while hammering
        // No ladder starts at x = 176 on girder 3 (the only nearby ladder there is at x = 192,
        // lower girder 3), so a fresh climb attempt here has nothing to refuse into — skipped.
        XCTAssertNil(level.ladders.first { $0.x == 176 && $0.lowerGirder == 3 })
    }
    func testJumpingIntoAHammerPicksItUpOnLanding() {
        var w = World.playing()
        let hx = level.hammers[0].x
        w.player.position = Vector2(x: hx, y: level.girders[4].surfaceY(at: hx)); w.player.currentGirder = 4
        let e = w.run(1, .jump) + w.run(Tuning.jumpDurationSteps)
        XCTAssertTrue(e.contains(.hammerPicked))
        XCTAssertEqual(w.player.state, .hammering)
        // With the lower hammer height (F3), the box already overlaps at takeoff rather than
        // near landing, so all `jumpDurationSteps` tick the hammer down — hence the -2 slack
        // instead of a strict `hammerDurationSteps - jumpDurationSteps`.
        XCTAssertGreaterThan(
            w.player.hammerStepsRemaining, Tuning.hammerDurationSteps - Tuning.jumpDurationSteps - 2)
        XCTAssertLessThan(w.player.hammerStepsRemaining, Tuning.hammerDurationSteps)
        XCTAssertEqual(w.hammersTaken, [0])
    }
    func testWalkingIntoAHammerPicksItUp() {
        var w = World.playing()
        w.player.position = Vector2(x: 12, y: level.girders[4].surfaceY(at: 12)); w.player.currentGirder = 4
        w.run(60, .right)
        XCTAssertEqual(w.hammersTaken, [0])
        XCTAssertEqual(w.player.state, .hammering)
    }
    func testHammerDestroysBarrelsAndFireballs() {
        var w = World.playing()
        w.player.state = .hammering; w.player.hammerStepsRemaining = 200; w.player.facing = .right
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 54, y: 8), direction: .left, currentGirder: 0))
        let e = w.run(Tuning.hammerSwingPeriodSteps * 2)
        XCTAssertTrue(w.barrels.isEmpty)
        XCTAssertEqual(w.game.score, Tuning.scoreHammerBarrel)
        XCTAssertTrue(e.contains(.hammerHit(id: 1, points: Tuning.scoreHammerBarrel)))
        XCTAssertEqual(w.game.phase, .playing)
        w.fireballs.append(Fireball(id: 2, position: Vector2(x: 54, y: 8), direction: .left, currentGirder: 0))
        w.run(Tuning.hammerSwingPeriodSteps * 2)
        XCTAssertTrue(w.fireballs.isEmpty)
        XCTAssertEqual(w.game.score, Tuning.scoreHammerBarrel + Tuning.scoreHammerFireball)
    }
    func testHammerExpires() {
        var w = World.playing()
        w.player.state = .hammering; w.player.hammerStepsRemaining = 5
        let e = w.run(5)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertTrue(e.contains(.hammerExpired))
    }
    func testDyingPlayerIgnoresFurtherHazards() {
        var w = World.playing()
        w.die()
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 40, y: 8), direction: .left, currentGirder: 0))
        let e = w.run(1)
        XCTAssertFalse(e.contains(.playerDied))
    }
}
