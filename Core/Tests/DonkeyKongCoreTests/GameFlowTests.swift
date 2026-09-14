import XCTest

@testable import DonkeyKongCore

final class GameFlowTests: XCTestCase {
    func testBonusTicksDown() {
        var w = World.playing()
        w.run(Tuning.bonusTickSteps - 1)
        XCTAssertEqual(w.game.bonus, Tuning.bonusStart)
        w.run(1)
        XCTAssertEqual(w.game.bonus, Tuning.bonusStart - Tuning.bonusTickAmount)
    }
    func testBonusAtZeroKills() {
        var w = World.playing()
        w.game.bonus = Tuning.bonusTickAmount
        w.run(Tuning.bonusTickSteps)
        XCTAssertEqual(w.game.bonus, 0)
        XCTAssertEqual(w.player.state, .dying)
    }
    func testReachingTheGoalClearsTheLevelAndBanksTheBonus() {
        var w = World.playing()
        let goal = Levels.barrels.goal
        w.player.position = Vector2(x: goal.center.x, y: goal.minY); w.player.currentGirder = 7
        w.game.bonus = 4200
        let e = w.run(1)
        XCTAssertEqual(w.game.phase, .levelCleared)
        XCTAssertEqual(w.game.score, 4200)
        XCTAssertTrue(e.contains(.levelCleared(bonus: 4200)))
        w.run(Tuning.levelClearedDurationSteps)
        XCTAssertEqual(w.game.phase, .playing)
        XCTAssertEqual(w.game.loop, 1)
        XCTAssertEqual(w.game.bonus, Tuning.bonusStart)
        XCTAssertEqual(w.player.position, Levels.barrels.playerSpawn)
        XCTAssertEqual(
            w.kong.throwCooldownSteps, Tuning.kongThrowIntervalSteps - Tuning.kongThrowIntervalLoopDeltaSteps)
        XCTAssertEqual(w.barrelSpeed, Tuning.barrelSpeedPointsPerSecond * 1.1, accuracy: 1e-9)
    }
    func testThrowIntervalHasAFloor() {
        var w = World.playing()
        w.game.loop = 50
        XCTAssertEqual(w.throwInterval, Tuning.kongThrowIntervalMinSteps)
    }
    func testLastLifeLostIsGameOverAndJumpRestarts() {
        var w = World.playing()
        w.game.lives = 1
        w.die()
        let e = w.run(Tuning.dyingDurationSteps)
        XCTAssertEqual(w.game.phase, .gameOver)
        XCTAssertTrue(e.contains(.gameOver))
        XCTAssertEqual(w.game.lives, 0)
        w.run(1, .jump)
        XCTAssertEqual(w.game.phase, .intro)
        XCTAssertEqual(w.game.lives, Tuning.livesStart)
        XCTAssertEqual(w.game.score, 0)
    }
    func testExtraLifeOnceAtThreshold() {
        var w = World.playing()
        let e1 = w.addScoreForTest(Tuning.extraLifeScore)
        XCTAssertEqual(w.game.lives, Tuning.livesStart + 1)
        XCTAssertTrue(e1.contains(.extraLife))
        let e2 = w.addScoreForTest(Tuning.extraLifeScore)
        XCTAssertEqual(w.game.lives, Tuning.livesStart + 1)
        XCTAssertFalse(e2.contains(.extraLife))
    }
    func testDeathClearsBarrelsAndHammers() {
        var w = World.playing()
        w.barrels.append(
            Barrel(id: 1, kind: .normal, position: Vector2(x: 150, y: 8), direction: .left, currentGirder: 0))
        w.hammersTaken = [0]
        w.die(); w.run(Tuning.dyingDurationSteps)
        XCTAssertTrue(w.barrels.isEmpty)
        XCTAssertTrue(w.hammersTaken.isEmpty)
    }
}
