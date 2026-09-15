extension World {
    mutating func stepFireballs() {
        for i in fireballs.indices {
            var f = fireballs[i]
            stepFireball(&f)
            fireballs[i] = f
        }
    }

    private mutating func stepFireball(_ f: inout Fireball) {
        if let li = f.currentLadder {
            climbLadder(&f, li)
            return
        }
        let g = level.girders[f.currentGirder]
        let speed = barrelSpeed * Tuning.fireballSpeedFactor
        let prevX = f.position.x
        var nx = f.position.x + f.direction.sign * speed * Tuning.stepDuration

        // Any intact ladder touching this girder, up or down, one roll each.
        if let (li, up) = ladderCrossing(girder: f.currentGirder, from: prevX, to: nx),
            random.next(below: Tuning.fireballLadderChanceOneIn) == 0
        {
            let l = level.ladders[li]
            f.currentLadder = li
            f.climbingUp = up
            f.position = Vector2(x: l.x, y: up ? l.bottomY : l.topY)
            return
        }

        if !g.contains(x: nx) || nx < 0 || nx > Tuning.sceneWidth {
            if let ni = girderIndex(atX: nx, nearY: g.surfaceY(at: f.position.x)), nx >= 0, nx <= Tuning.sceneWidth {
                f.currentGirder = ni
            } else {
                f.direction = f.direction.flipped  // fireballs never fall
                nx = f.position.x
            }
        }
        f.position = Vector2(x: nx, y: level.girders[f.currentGirder].surfaceY(at: nx))
    }

    private func ladderCrossing(girder gi: Int, from a: Double, to b: Double) -> (Int, Bool)? {
        for li in level.ladders.indices {
            let l = level.ladders[li]
            guard !l.isBroken, crosses(l.x, from: a, to: b) else { continue }
            if l.lowerGirder == gi { return (li, true) }
            if l.upperGirder == gi { return (li, false) }
        }
        return nil
    }

    private mutating func climbLadder(_ f: inout Fireball, _ li: Int) {
        let l = level.ladders[li]
        let dy = Tuning.climbSpeedPointsPerSecond * Tuning.stepDuration
        if f.climbingUp {
            f.position.y += dy
            if f.position.y >= l.topY { arrive(&f, on: l.upperGirder) }
        } else {
            f.position.y -= dy
            if f.position.y <= l.bottomY { arrive(&f, on: l.lowerGirder) }
        }
    }

    private mutating func arrive(_ f: inout Fireball, on gi: Int) {
        f.currentLadder = nil
        f.currentGirder = gi
        f.position.y = level.girders[gi].surfaceY(at: f.position.x)
    }
}
