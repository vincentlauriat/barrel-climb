public enum PlayerState: Equatable, Sendable { case standing, walking, jumping, falling, climbing, hammering, dying, dead }

public struct Player: Equatable, Sendable {
    public var position: Vector2                 // bottom-center
    public var velocity = Vector2.zero
    public var facing = Direction.right
    public var state = PlayerState.standing
    public var hammerStepsRemaining = 0
    public var currentGirder: Int?
    public var currentLadder: Int?
    public var jumpSteps = 0
    public var jumpStartY = 0.0
    public var jumpDrift = 0.0                    // -1, 0, 1 locked at takeoff
    public var fallStartY = 0.0
    public var jumpHeld = false
    public var isHammering: Bool { state == .hammering }
    /// Collision box (narrower than the sprite).
    public var bounds: Rect {
        Rect(origin: Vector2(x: position.x - Tuning.playerHitbox.x / 2, y: position.y), size: Tuning.playerHitbox)
    }
    /// The hammer head alternates high / low every `hammerSwingPeriodSteps`.
    public func hammerBounds(step: Int) -> Rect {
        let high = (step / Tuning.hammerSwingPeriodSteps) % 2 == 0
        let dx = facing.sign * (Tuning.playerSize.x / 2 + Tuning.hammerSize.x / 2)
        let y = high ? position.y + Tuning.playerSize.y : position.y
        return Rect(origin: Vector2(x: position.x + dx - Tuning.hammerSize.x / 2, y: y), size: Tuning.hammerSize)
    }
}

public enum BarrelKind: Equatable, Sendable { case normal, blue }
public enum BarrelState: Equatable, Sendable { case rolling, falling, onLadder }

public struct Barrel: Equatable, Sendable {
    public let id: Int
    public var kind: BarrelKind
    public var state = BarrelState.rolling
    public var position: Vector2                 // bottom-center
    public var velocity = Vector2.zero
    public var direction = Direction.right
    public var currentGirder: Int?
    public var currentLadder: Int?
    public var bounds: Rect {
        Rect(origin: Vector2(x: position.x - Tuning.barrelHitbox.x / 2, y: position.y), size: Tuning.barrelHitbox)
    }
}

public struct Fireball: Equatable, Sendable {
    public let id: Int
    public var position: Vector2                 // bottom-center
    public var direction = Direction.right
    public var currentGirder: Int
    public var currentLadder: Int?
    public var climbingUp = true
    public var bounds: Rect {
        Rect(origin: Vector2(x: position.x - Tuning.fireballHitbox.x / 2, y: position.y), size: Tuning.fireballHitbox)
    }
}

public struct Kong: Equatable, Sendable {
    public var throwCooldownSteps: Int
    public var isWindingUp: Bool { throwCooldownSteps <= Tuning.kongWindUpSteps }
}
