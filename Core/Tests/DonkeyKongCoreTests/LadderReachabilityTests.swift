import XCTest

@testable import DonkeyKongCore

/// Every ladder in a level must be usable: standing on its lower girder at its x and
/// pressing up must start a climb, and a whole ladder must be climbable end to end.
final class LadderReachabilityTests: XCTestCase {
    private func standing(on girder: Int, atX x: Double, in level: LevelLayout) -> Player {
        Player(position: Vector2(x: x, y: level.girders[girder].surfaceY(at: x)), currentGirder: girder)
    }

    func testEveryLadderCanBeEnteredFromItsLowerGirder() {
        let level = Levels.barrels
        var unusable: [Int] = []
        for (i, l) in level.ladders.enumerated() {
            var w = World.playing()
            w.player = standing(on: l.lowerGirder, atX: l.x, in: level)
            w.run(1, .up)
            if w.player.currentLadder != i { unusable.append(i) }
        }
        XCTAssertEqual(unusable, [], "ladders that cannot be entered from below")
    }

    func testEveryUnbrokenLadderReachesItsUpperGirder() {
        let level = Levels.barrels
        var stuck: [Int] = []
        for (i, l) in level.ladders.enumerated() where !l.isBroken {
            var w = World.playing()
            w.player = standing(on: l.lowerGirder, atX: l.x, in: level)
            let steps = Int((l.topY - l.bottomY) / (Tuning.climbSpeedPointsPerSecond * Tuning.stepDuration)) + 4
            w.run(steps, .up)
            if w.player.currentGirder != l.upperGirder { stuck.append(i) }
        }
        XCTAssertEqual(stuck, [], "ladders that do not deliver the player onto their upper girder")
    }

    /// A hammer sitting at a ladder's foot forces the player into `.hammering` exactly where
    /// they meant to climb, and hammering forbids climbing — the ladder is then unusable for
    /// the whole hammer duration.
    func testNoHammerSitsAtALadderFoot() {
        let level = Levels.barrels
        let clearance = (Tuning.hammerSize.x + Tuning.playerHitbox.x) / 2
        var blocked: [String] = []
        for (h, hammer) in level.hammers.enumerated() {
            for (i, l) in level.ladders.enumerated() where abs(l.x - hammer.x) < clearance {
                let feetY = level.girders[l.lowerGirder].surfaceY(at: l.x)
                if abs(feetY - hammer.y) < Tuning.playerSize.y { blocked.append("hammer \(h) blocks ladder \(i)") }
            }
        }
        XCTAssertEqual(blocked, [], "hammers must not sit where a ladder is entered")
    }

    /// Walking is how the player actually gets to a ladder: the girder they end up standing
    /// on must be the one the ladder expects, or pressing up does nothing.
    func testWalkingToALadderLeavesThePlayerOnItsLowerGirder() {
        let level = Levels.barrels
        var mismatched: [Int] = []
        for (i, l) in level.ladders.enumerated() {
            let g = level.girders[l.lowerGirder]
            let from = max(g.minX + Tuning.playerSize.x / 2, min(g.maxX - Tuning.playerSize.x / 2, l.x - 24))
            var w = World.playing()
            w.hammersTaken = Set(level.hammers.indices)  // this test is about ladders, not hammers
            w.player = standing(on: l.lowerGirder, atX: from, in: level)
            let steps = Int((l.x - from) / (Tuning.walkSpeedPointsPerSecond * Tuning.stepDuration)) + 1
            w.run(steps, .right)
            w.run(1, .up)
            if w.player.currentLadder != i { mismatched.append(i) }
        }
        XCTAssertEqual(mismatched, [], "ladders unreachable by walking to them")
    }
}
