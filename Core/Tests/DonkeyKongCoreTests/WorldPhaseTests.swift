import XCTest

@testable import DonkeyKongCore

final class WorldPhaseTests: XCTestCase {
    func testStartsOnTitleAndJumpStartsTheGame() {
        var w = World(level: Levels.barrels, random: SeededRandom(seed: 1))
        XCTAssertEqual(w.game.phase, .title)
        w.run(10, .left)
        XCTAssertEqual(w.game.phase, .title, "only jump leaves the title")
        w.run(1, .jump)
        XCTAssertEqual(w.game.phase, .intro)
        XCTAssertEqual(w.game.lives, Tuning.livesStart)
        XCTAssertEqual(w.game.score, 0)
        XCTAssertEqual(w.game.bonus, Tuning.bonusStart)
    }
    func testIntroLeadsToPlayingAfterItsDuration() {
        var w = World(level: Levels.barrels, random: SeededRandom(seed: 1))
        w.start()
        w.run(Tuning.introDurationSteps - 1)
        XCTAssertEqual(w.game.phase, .intro)
        w.run(1)
        XCTAssertEqual(w.game.phase, .playing)
        XCTAssertEqual(w.game.phaseSteps, 0)
    }
    func testPlayerSpawnsStandingOnTheBottomGirder() {
        let w = World.playing()
        XCTAssertEqual(w.player.position, Levels.barrels.playerSpawn)
        XCTAssertEqual(w.player.state, .standing)
        XCTAssertEqual(w.player.currentGirder, 0)
        XCTAssertEqual(w.player.facing, .right)
        XCTAssertTrue(w.barrels.isEmpty); XCTAssertTrue(w.fireballs.isEmpty)
    }
}
