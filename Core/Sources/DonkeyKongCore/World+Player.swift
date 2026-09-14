extension World {
    mutating func stepPlayer(_ input: Input) {
        switch player.state {
        case .standing, .walking, .hammering:
            stepGrounded(input)
        case .falling:
            stepFall()
        case .jumping, .climbing, .dying, .dead:
            break   // jumping: Task 5, climbing: Task 6
        }
    }

    // MARK: Grounded

    private mutating func stepGrounded(_ input: Input) {
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
