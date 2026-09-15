public enum Phase: Equatable, Sendable { case title, intro, playing, playerDied, levelCleared, gameOver }

public struct GameState: Equatable, Sendable {
    public var phase = Phase.title
    public var phaseSteps = 0
    public var lives = Tuning.livesStart
    public var score = 0
    public var bonus = Tuning.bonusStart
    public var bonusTickSteps = 0
    public var loop = 0
    public var totalSteps = 0
}

public enum GameEvent: Equatable, Sendable {
    case jumped, landed, climbStarted
    case barrelThrown(id: Int)
    case barrelJumped(id: Int, points: Int)
    case hammerPicked
    case hammerHit(id: Int, points: Int)
    case hammerExpired
    case fireballSpawned
    case playerDied
    case levelCleared(bonus: Int)
    case gameOver
    case scoreChanged(Int)
    case extraLife
}
