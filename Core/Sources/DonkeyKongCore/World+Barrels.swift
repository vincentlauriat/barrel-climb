extension World {
    // MARK: Kong

    mutating func stepKong() {
        kong.throwCooldownSteps -= 1
        guard kong.throwCooldownSteps <= 0 else { return }
        kong.throwCooldownSteps = throwInterval
        throwBarrel()
    }

    private mutating func throwBarrel() {
        barrelsThrown += 1
        let kind: BarrelKind = barrelsThrown % Tuning.blueBarrelEvery == 0 ? .blue : .normal
        let spawn = level.barrelSpawn
        let barrel = Barrel(
            id: allocateID(), kind: kind, position: spawn, direction: .right,
            currentGirder: girderIndex(atX: spawn.x, nearY: spawn.y))
        barrels.append(barrel)
        emit(.barrelThrown(id: barrel.id))
    }

    // MARK: Barrels

    mutating func stepBarrels() {
        var i = 0
        while i < barrels.count {
            var b = barrels[i]
            stepBarrel(&b)
            if b.position.y < -Tuning.barrelSize.y || level.oilDrum.intersects(b.bounds) {
                if b.kind == .blue { spawnFireball() }
                barrels.remove(at: i)
            } else {
                barrels[i] = b
                i += 1
            }
        }
    }

    private mutating func stepBarrel(_ b: inout Barrel) {
        switch b.state {
        case .rolling: rollBarrel(&b)
        case .falling: fallBarrel(&b)
        case .onLadder: descendLadder(&b)
        }
    }

    private mutating func rollBarrel(_ b: inout Barrel) {
        guard let gi = b.currentGirder else { b.state = .falling; return }
        let g = level.girders[gi]
        let prevX = b.position.x
        var nx = b.position.x + b.direction.sign * barrelSpeed * Tuning.stepDuration

        // Passing over the top of an intact ladder: one dice roll per ladder.
        if let li = level.ladders.indices.first(where: { li in
            let l = level.ladders[li]
            return l.upperGirder == gi && !l.isBroken && crosses(l.x, from: prevX, to: nx)
        }), random.next(below: Tuning.barrelLadderChanceOneIn) == 0 {
            let l = level.ladders[li]
            b.state = .onLadder
            b.currentLadder = li
            b.currentGirder = nil
            b.position = Vector2(x: l.x, y: l.topY)
            return
        }

        if nx < 0 || nx > Tuning.sceneWidth {  // scene edge: bounce back
            b.direction = b.direction.flipped
            nx = clampX(nx, halfWidth: 0)
        }
        if g.contains(x: nx) {
            b.position = Vector2(x: nx, y: g.surfaceY(at: nx))
        } else if let ni = girderIndex(atX: nx, nearY: g.surfaceY(at: b.position.x)) {
            b.currentGirder = ni  // connected girder, same direction
            b.position = Vector2(x: nx, y: level.girders[ni].surfaceY(at: nx))
        } else {
            b.state = .falling
            b.currentGirder = nil
            b.velocity = .zero
            b.position.x = nx
        }
    }

    private mutating func fallBarrel(_ b: inout Barrel) {
        let prevY = b.position.y
        b.velocity.y -= Tuning.gravityPointsPerSecondSquared * Tuning.stepDuration
        b.position.y += b.velocity.y * Tuning.stepDuration
        if let gi = landingGirder(x: b.position.x, fromY: prevY, toY: b.position.y) {
            b.currentGirder = gi
            b.position.y = level.girders[gi].surfaceY(at: b.position.x)
            b.velocity = .zero
            b.state = .rolling
            b.direction = b.direction.flipped  // every fall reverses
        }
    }

    private mutating func descendLadder(_ b: inout Barrel) {
        guard let li = b.currentLadder else { b.state = .falling; return }
        let l = level.ladders[li]
        b.position.y -= Tuning.climbSpeedPointsPerSecond * Tuning.stepDuration
        if b.position.y <= l.bottomY {
            b.position.y = l.bottomY
            b.currentLadder = nil
            b.currentGirder = l.lowerGirder  // keeps its direction
            b.state = .rolling
        }
    }

    /// Spawns a fireball next to the oil drum, up to `maxFireballs`. (Fireball movement: Task 9.)
    mutating func spawnFireball() {
        guard fireballs.count < Tuning.maxFireballs else { return }
        let x = level.oilDrum.maxX + Tuning.fireballSize.x
        guard let gi = girderIndex(atX: x, nearY: level.oilDrum.minY) else { return }
        fireballs.append(
            Fireball(
                id: allocateID(), position: Vector2(x: x, y: level.girders[gi].surfaceY(at: x)),
                direction: .right, currentGirder: gi))
        emit(.fireballSpawned)
    }

    /// True when `x` lies between `a` and `b` (either order), inclusive of the destination.
    func crosses(_ x: Double, from a: Double, to b: Double) -> Bool {
        (a < x && x <= b) || (b <= x && x < a)
    }
}
