import XCTest
@testable import DonkeyKongCore

final class FireballTests: XCTestCase {
    func worldWithFireball(x: Double, girder: Int, direction: Direction, random: RandomSource) -> World {
        var w = World(level: Levels.barrels, random: random)
        w.start(); w.run(Tuning.introDurationSteps)
        w.fireballs.append(Fireball(id: 7, position: Vector2(x: x, y: Levels.barrels.girders[girder].surfaceY(at: x)),
                                    direction: direction, currentGirder: girder))
        return w
    }
    func testFireballMovesAtItsOwnSpeedAlongTheGirder() {
        var w = worldWithFireball(x: 40, girder: 0, direction: .right, random: NeverRandom())
        w.run(60)
        XCTAssertEqual(w.fireballs[0].position.x, 40 + Tuning.barrelSpeedPointsPerSecond * Tuning.fireballSpeedFactor, accuracy: 1e-6)
        XCTAssertEqual(w.fireballs[0].position.y, 8)
    }
    func testFireballTurnsAroundAtAnOpenEndInsteadOfFalling() {
        var w = worldWithFireball(x: 200, girder: 2, direction: .right, random: NeverRandom())
        w.run(60)                                                  // 27 pt: would pass x = 208
        XCTAssertEqual(w.fireballs[0].direction, .left)
        XCTAssertEqual(w.fireballs[0].currentGirder, 2)
        XCTAssertLessThanOrEqual(w.fireballs[0].position.x, 208)
    }
    func testFireballCrossesConnectedGirders() {
        var w = worldWithFireball(x: 105, girder: 0, direction: .right, random: NeverRandom())
        w.run(30)                                                  // 105 → 118.5 across x = 112
        XCTAssertEqual(w.fireballs[0].currentGirder, 1)
        XCTAssertEqual(w.fireballs[0].direction, .right)
    }
    func testFireballClimbsAnIntactLadderWhenTheDiceSaysSo() {
        var w = worldWithFireball(x: 176, girder: 1, direction: .right, random: FixedRandom())
        w.run(30)                                                  // reaches the ladder at x = 184
        XCTAssertNotNil(w.fireballs[0].currentLadder)
        XCTAssertEqual(w.fireballs[0].position.x, 184)
        w.run(120)
        XCTAssertNil(w.fireballs[0].currentLadder)
        XCTAssertEqual(w.fireballs[0].currentGirder, 2)
    }
    func testFireballNeverUsesBrokenLadders() {
        var w = worldWithFireball(x: 80, girder: 0, direction: .right, random: FixedRandom())
        w.run(60)                                                  // passes x = 88 (broken)
        XCTAssertNil(w.fireballs[0].currentLadder)
        XCTAssertEqual(w.fireballs[0].currentGirder, 0)
    }
}
