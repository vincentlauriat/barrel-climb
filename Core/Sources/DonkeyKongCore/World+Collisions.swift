extension World {
    mutating func checkCollisions() {
        guard player.state != .dying, player.state != .dead else { return }
        pickUpHammer()
        if player.hammerStepsRemaining > 0 { swingHammer() }
        awardJumpBonuses()
        if hazardTouchesPlayer() { die() }
    }

    private mutating func pickUpHammer() {
        guard player.hammerStepsRemaining == 0 else { return }
        for (i, center) in level.hammers.enumerated() where !hammersTaken.contains(i) {
            let box = Rect(center: center, size: Tuning.hammerSize)
            guard box.intersects(player.bounds) else { continue }
            hammersTaken.insert(i)
            player.hammerStepsRemaining = Tuning.hammerDurationSteps
            if player.state == .standing || player.state == .walking { player.state = .hammering }
            emit(.hammerPicked)  // mid-jump: `land(on:)` switches to .hammering
            return
        }
    }

    /// Only the hammer's own animation state swings it — a held hammer that is climbing or
    /// jumping (impossible mid-air/mid-ladder in normal play, but reachable via a stale
    /// `hammerStepsRemaining`) must not invisibly kill barrels while the sprite shows otherwise.
    private mutating func swingHammer() {
        guard player.state == .hammering else { return }
        let head = player.hammerBounds(step: game.phaseSteps)
        var i = 0
        while i < barrels.count {
            if head.intersects(barrels[i].bounds) {
                let id = barrels[i].id
                barrels.remove(at: i)
                addScore(Tuning.scoreHammerBarrel)
                emit(.hammerHit(id: id, points: Tuning.scoreHammerBarrel))
            } else {
                i += 1
            }
        }
        i = 0
        while i < fireballs.count {
            if head.intersects(fireballs[i].bounds) {
                let id = fireballs[i].id
                fireballs.remove(at: i)
                addScore(Tuning.scoreHammerFireball)
                emit(.hammerHit(id: id, points: Tuning.scoreHammerFireball))
            } else {
                i += 1
            }
        }
    }

    /// Airborne and above a barrel that is horizontally under us: 100 points, once per barrel.
    private mutating func awardJumpBonuses() {
        guard player.state == .jumping else { return }
        for b in barrels where !jumpedBarrelIDs.contains(b.id) {
            let horizontallyUnder =
                abs(b.position.x - player.position.x) < (Tuning.playerHitbox.x + Tuning.barrelHitbox.x) / 2
            let above = player.position.y > b.bounds.maxY
            if horizontallyUnder && above {
                jumpedBarrelIDs.insert(b.id)
                addScore(Tuning.scoreJumpBarrel)
                emit(.barrelJumped(id: b.id, points: Tuning.scoreJumpBarrel))
            }
        }
    }

    /// Barrels do not hit a player who is on a ladder below the upper girder's surface — a
    /// deliberate refuge. It only applies once actually above the ladder's foot: sitting at
    /// `bottomY` (having just entered, or about to leave) is still on the lower girder's level
    /// and must not grant permanent immunity there. The refuge is shelter from the girders
    /// above, not from the ladder itself: a barrel coming down the very ladder being climbed
    /// still hits. Fireballs are not affected: they can enter ladders themselves.
    private func hazardTouchesPlayer() -> Bool {
        let p = player.bounds
        if player.state == .climbing, let li = player.currentLadder {
            let ladder = level.ladders[li]
            let top = level.girders[ladder.upperGirder].surfaceY(at: player.position.x)
            if player.position.y > ladder.bottomY, player.position.y < top {
                return barrels.contains { $0.currentLadder == li && $0.bounds.intersects(p) }
                    || fireballs.contains { $0.bounds.intersects(p) }
            }
        }
        return barrels.contains { $0.bounds.intersects(p) } || fireballs.contains { $0.bounds.intersects(p) }
    }
}
