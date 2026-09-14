import XCTest

@testable import DonkeyKongCore

final class BarrelLadderTests: XCTestCase {
    /// Girder 2 has two ladders going down: x = 88 (broken) and x = 184 (intact, to girder 1).
    func barrelOnGirder2(random: RandomSource) -> World {
        var w = World(level: Levels.barrels, random: random)
        w.start(); w.run(Tuning.introDurationSteps)
        w.barrels.append(
            Barrel(
                id: 99, kind: .normal, position: Vector2(x: 80, y: Levels.barrels.girders[2].surfaceY(at: 80)),
                direction: .right, currentGirder: 2))
        return w
    }
    func testBarrelTakesAnIntactLadderWhenTheDiceSaysSoAndKeepsItsDirection() {
        var w = barrelOnGirder2(random: FixedRandom())  // always 0 → take
        w.run(20)  // crosses the broken ladder at 88
        XCTAssertEqual(w.barrels[0].state, .rolling, "broken ladders are never taken")
        w.run(140)  // reaches x = 184
        XCTAssertEqual(w.barrels[0].state, .onLadder)
        XCTAssertEqual(w.barrels[0].position.x, 184)
        w.run(90)  // ~30 pt of ladder at 30 pt/s
        XCTAssertEqual(w.barrels[0].state, .rolling)
        XCTAssertEqual(w.barrels[0].currentGirder, 1)
        XCTAssertEqual(w.barrels[0].direction, .right)
    }
    func testBarrelIgnoresLaddersWhenTheDiceSaysNo() {
        var w = barrelOnGirder2(random: NeverRandom())
        w.run(180)
        XCTAssertNotEqual(w.barrels[0].state, .onLadder)
        XCTAssertTrue(
            w.barrels[0].state == .falling || w.barrels[0].currentGirder == 1,
            "went past x = 208 and fell instead")
    }
    func testOneDiceRollPerLadder() {
        // The broken ladder at x = 88 never rolls; the only roll happens at x = 184.
        var w = barrelOnGirder2(random: FixedRandom(values: [3, 0]))  // first roll says no
        w.run(160)
        XCTAssertNotEqual(w.barrels[0].state, .onLadder)
        var w2 = barrelOnGirder2(random: FixedRandom(values: [0]))  // first roll says yes
        w2.run(160)
        XCTAssertEqual(w2.barrels[0].state, .onLadder)
    }
    func testBlueBarrelsIntoTheOilDrumSpawnAtMostTwoFireballs() {
        var w = World.playing()
        // out of the barrels' path (task 10: barrel contact now kills)
        w.player.position = Vector2(x: 200, y: w.player.position.y)
        for (i, x) in [40.0, 50.0, 60.0].enumerated() {
            w.barrels.append(
                Barrel(id: 100 + i, kind: .blue, position: Vector2(x: x, y: 8), direction: .left, currentGirder: 0))
        }
        let e = w.run(90)
        XCTAssertTrue(w.barrels.isEmpty)
        XCTAssertEqual(w.fireballs.count, Tuning.maxFireballs)
        XCTAssertEqual(e.filter { $0 == .fireballSpawned }.count, Tuning.maxFireballs)
        XCTAssertEqual(w.fireballs[0].currentGirder, 0)
    }
}
