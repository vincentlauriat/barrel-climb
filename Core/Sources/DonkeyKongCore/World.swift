/// The whole simulation. Pure value type; advance it with `step` at exactly 1/60 s.
public struct World: Sendable {
    public let level: LevelLayout
    public internal(set) var player: Player
    public internal(set) var barrels: [Barrel] = []
    public internal(set) var fireballs: [Fireball] = []
    public internal(set) var kong: Kong
    public internal(set) var game = GameState()
    public internal(set) var hammersTaken: Set<Int> = []

    var random: RandomSource
    var nextEntityID = 1
    var events: [GameEvent] = []
    var barrelsThrown = 0
    var jumpedBarrelIDs: Set<Int> = []
    var extraLifeAwarded = false

    public init(level: LevelLayout, random: RandomSource) {
        self.level = level
        self.random = random
        player = Player(position: level.playerSpawn, currentGirder: 0)
        kong = Kong(throwCooldownSteps: Tuning.kongThrowIntervalSteps)
    }

    /// Title / game over → intro. Full reset of the game state.
    public mutating func start() {
        game = GameState()
        extraLifeAwarded = false
        resetLevel()
        enter(.intro)
    }

    public mutating func step(input: Input, dt: Double) -> [GameEvent] {
        precondition(abs(dt - Tuning.stepDuration) < 1e-9, "World.step takes fixed 1/60 s steps")
        events = []
        game.phaseSteps += 1
        game.totalSteps += 1
        switch game.phase {
        case .title, .gameOver:
            if input.jump { start() }
        case .intro:
            if game.phaseSteps >= Tuning.introDurationSteps { enter(.playing) }
        case .playing:
            stepPlaying(input)
        case .playerDied:
            if game.phaseSteps >= Tuning.dyingDurationSteps {
                game.lives -= 1
                if game.lives > 0 { resetLevel(); enter(.playing) } else { enter(.gameOver); emit(.gameOver) }
            }
        case .levelCleared:
            if game.phaseSteps >= Tuning.levelClearedDurationSteps {
                game.loop += 1
                resetLevel()
                enter(.playing)
            }
        }
        return events
    }

    // MARK: - Internal helpers shared by the World+*.swift extensions

    /// One step of live gameplay. Later tasks append their sub-steps here, in this order:
    /// player → barrels → kong → fireballs → bonus → collisions.
    mutating func stepPlaying(_ input: Input) {
    }

    mutating func enter(_ phase: Phase) {
        game.phase = phase
        game.phaseSteps = 0
    }

    /// Puts the level back to its start state. Score, lives and loop are kept.
    mutating func resetLevel() {
        player = Player(position: level.playerSpawn, currentGirder: 0)
        barrels = []
        fireballs = []
        hammersTaken = []
        jumpedBarrelIDs = []
        barrelsThrown = 0
        kong = Kong(throwCooldownSteps: throwInterval)
        game.bonus = Tuning.bonusStart
        game.bonusTickSteps = 0
    }

    mutating func emit(_ e: GameEvent) { events.append(e) }

    mutating func addScore(_ points: Int) {
        game.score += points
        emit(.scoreChanged(game.score))
        if !extraLifeAwarded && game.score >= Tuning.extraLifeScore {
            extraLifeAwarded = true
            game.lives += 1
            emit(.extraLife)
        }
    }

    mutating func allocateID() -> Int { defer { nextEntityID += 1 }; return nextEntityID }

    var throwInterval: Int {
        max(Tuning.kongThrowIntervalMinSteps,
            Tuning.kongThrowIntervalSteps - game.loop * Tuning.kongThrowIntervalLoopDeltaSteps)
    }
    var barrelSpeed: Double {
        Tuning.barrelSpeedPointsPerSecond * (1 + Tuning.barrelSpeedLoopFactor * Double(game.loop))
    }
}
