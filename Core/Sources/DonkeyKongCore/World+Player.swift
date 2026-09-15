extension World {
    mutating func stepPlayer(_ input: Input) {
        tickHammer()
        switch player.state {
        case .standing, .walking, .hammering:
            stepGrounded(input)
        case .falling:
            stepFall()
        case .jumping:
            stepJump()
        case .climbing:
            stepClimb(input)
        case .dying, .dead:
            break
        }
    }

    // MARK: Grounded

    private mutating func stepGrounded(_ input: Input) {
        if !player.isHammering, tryEnterLadder(input) { return }
        let jumpPressed = input.jump && !player.jumpHeld
        player.jumpHeld = input.jump
        if jumpPressed && !player.isHammering {
            startJump(input)
            return
        }
        guard let dir = input.horizontal else {
            if player.state == .walking { player.state = .standing }
            return
        }
        player.facing = dir
        if player.state == .standing { player.state = .walking }
        moveGrounded(toX: player.position.x + dir.sign * Tuning.walkSpeedPointsPerSecond * Tuning.stepDuration)
    }

    /// Moves along the current girder; transfers to a girder whose surface is at the same height
    /// past this one's end, or starts a fall if there is none.
    private mutating func moveGrounded(toX x: Double) {
        guard let gi = player.currentGirder else { return }
        let g = level.girders[gi]
        let nx = clampX(x, halfWidth: Tuning.playerSize.x / 2)
        if g.contains(x: nx) {
            player.position = Vector2(x: nx, y: g.surfaceY(at: nx))
            return
        }
        let y = g.surfaceY(at: player.position.x)
        if let ni = girderIndex(atX: nx, nearY: y) {
            player.currentGirder = ni
            player.position = Vector2(x: nx, y: level.girders[ni].surfaceY(at: nx))
        } else {
            player.state = .falling
            player.currentGirder = nil
            player.fallStartY = player.position.y
            player.position.x = nx
            player.velocity = .zero
        }
    }

    func clampX(_ x: Double, halfWidth: Double) -> Double {
        max(halfWidth, min(Tuning.sceneWidth - halfWidth, x))
    }

    func girderIndex(atX x: Double, nearY y: Double) -> Int? {
        level.girders.indices.first { i in
            let g = level.girders[i]
            return g.contains(x: x) && abs(g.surfaceY(at: x) - y) <= Tuning.girderTransferTolerancePoints
        }
    }

    // MARK: Falling

    private mutating func stepFall() {
        let prevY = player.position.y
        player.velocity.y -= Tuning.gravityPointsPerSecondSquared * Tuning.stepDuration
        player.position.y += player.velocity.y * Tuning.stepDuration
        if let gi = landingGirder(x: player.position.x, fromY: prevY, toY: player.position.y) {
            land(on: gi)
        } else if player.position.y < -Tuning.playerSize.y {
            die()
        }
    }

    /// First girder under `x` whose surface was crossed while moving down from `fromY` to `toY`.
    func landingGirder(x: Double, fromY: Double, toY: Double) -> Int? {
        level.girders.indices.first { i in
            let g = level.girders[i]
            guard g.contains(x: x) else { return false }
            let s = g.surfaceY(at: x)
            return fromY >= s && toY <= s
        }
    }

    mutating func land(on gi: Int) {
        let surface = level.girders[gi].surfaceY(at: player.position.x)
        let drop = player.fallStartY - surface
        player.currentGirder = gi
        player.position.y = surface
        player.velocity = .zero
        if player.state == .falling && drop > Tuning.fatalFallDistancePoints {
            die()
            return
        }
        player.state = player.hammerStepsRemaining > 0 ? .hammering : .standing
        emit(.landed)
    }

    // MARK: Jumping

    private mutating func startJump(_ input: Input) {
        player.state = .jumping
        player.jumpSteps = 0
        player.jumpStartY = player.position.y
        player.jumpDrift = input.horizontal?.sign ?? 0
        if let d = input.horizontal { player.facing = d }
        player.currentGirder = nil
        emit(.jumped)
    }

    /// Fixed parabola: y(t) = y0 + 4·h·t·(1 − t), t ∈ [0, 1] over `jumpDurationSteps`.
    private mutating func stepJump() {
        player.jumpSteps += 1
        let t = Double(player.jumpSteps) / Double(Tuning.jumpDurationSteps)
        let prevY = player.position.y
        player.position.x = clampX(
            player.position.x + player.jumpDrift * Tuning.walkSpeedPointsPerSecond * Tuning.stepDuration,
            halfWidth: Tuning.playerSize.x / 2)
        player.position.y = player.jumpStartY + 4 * Tuning.jumpHeightPoints * t * (1 - t)
        if t > 0.5, let gi = landingGirder(x: player.position.x, fromY: prevY, toY: player.position.y) {
            player.fallStartY = player.jumpStartY
            land(on: gi)
        } else if t >= 1 {
            player.state = .falling
            player.fallStartY = player.jumpStartY
            player.velocity = .zero
        }
    }

    // MARK: Ladders

    /// Enters an aligned ladder: `up` from its lower girder, `down` from its upper girder (never a broken one).
    private mutating func tryEnterLadder(_ input: Input) -> Bool {
        guard input.up != input.down else { return false }
        for (i, l) in level.ladders.enumerated()
        where abs(l.x - player.position.x) <= Tuning.ladderSnapTolerancePoints {
            if input.up, player.currentGirder == l.lowerGirder {
                enterLadder(i, atY: l.bottomY); return true
            }
            if input.down, !l.isBroken, player.currentGirder == l.upperGirder {
                enterLadder(i, atY: l.topY); return true
            }
        }
        return false
    }

    private mutating func enterLadder(_ i: Int, atY y: Double) {
        player.state = .climbing
        player.currentLadder = i
        player.currentGirder = nil
        player.position = Vector2(x: level.ladders[i].x, y: y)
        emit(.climbStarted)
    }

    private mutating func stepClimb(_ input: Input) {
        guard let li = player.currentLadder else { return }
        let l = level.ladders[li]
        let dy = Tuning.climbSpeedPointsPerSecond * Tuning.stepDuration
        if input.up, !input.down {
            player.position.y = min(l.topY, player.position.y + dy)
            if player.position.y >= l.topY, !l.isBroken { leaveLadder(onto: l.upperGirder) }
        } else if input.down, !input.up {
            player.position.y = max(l.bottomY, player.position.y - dy)
            if player.position.y <= l.bottomY { leaveLadder(onto: l.lowerGirder) }
        }
    }

    private mutating func leaveLadder(onto gi: Int) {
        player.currentLadder = nil
        player.currentGirder = gi
        player.position.y = level.girders[gi].surfaceY(at: player.position.x)
        player.state = player.hammerStepsRemaining > 0 ? .hammering : .standing
    }

    // MARK: Hammer

    mutating func tickHammer() {
        guard player.hammerStepsRemaining > 0 else { return }
        player.hammerStepsRemaining -= 1
        if player.hammerStepsRemaining == 0 {
            if player.state == .hammering { player.state = .standing }
            emit(.hammerExpired)
        }
    }

    // MARK: Death

    mutating func die() {
        guard player.state != .dying else { return }
        player.state = .dying
        player.velocity = .zero
        player.currentGirder = nil
        player.currentLadder = nil
        emit(.playerDied)
        enter(.playerDied)
    }
}
