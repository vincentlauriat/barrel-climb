/// Every gameplay number. Units are in the names. Steps are 1/60 s.
public enum Tuning {
    public static let stepDuration = 1.0 / 60.0
    public static let sceneWidth = 224.0
    public static let sceneHeight = 256.0

    // Player
    public static let playerSize = Vector2(x: 12, y: 16)  // sprite
    // collisions — narrower than the sprite so barrels are jumpable
    public static let playerHitbox = Vector2(x: 6, y: 14)
    public static let walkSpeedPointsPerSecond = 40.0
    public static let climbSpeedPointsPerSecond = 30.0
    public static let jumpDurationSteps = 30
    public static let jumpHeightPoints = 16.0
    public static let gravityPointsPerSecondSquared = 300.0
    public static let ladderSnapTolerancePoints = 4.0
    public static let girderTransferTolerancePoints = 2.0
    public static let fatalFallDistancePoints = 48.0
    public static let hammerDurationSteps = 540
    public static let hammerSwingPeriodSteps = 8
    public static let hammerSize = Vector2(x: 10, y: 10)
    public static let dyingDurationSteps = 90

    // Barrels and Kong
    public static let barrelSize = Vector2(x: 10, y: 10)  // sprite
    public static let barrelHitbox = Vector2(x: 6, y: 8)
    public static let barrelSpeedPointsPerSecond = 45.0
    public static let barrelSpeedLoopFactor = 0.1
    public static let barrelLadderChanceOneIn = 4
    public static let blueBarrelEvery = 8
    public static let kongThrowIntervalSteps = 150
    public static let kongThrowIntervalLoopDeltaSteps = 10
    public static let kongThrowIntervalMinSteps = 60
    public static let kongWindUpSteps = 20

    // Fireballs
    public static let fireballSize = Vector2(x: 10, y: 12)  // sprite
    public static let fireballHitbox = Vector2(x: 6, y: 10)
    public static let fireballSpeedFactor = 0.6
    public static let fireballLadderChanceOneIn = 2
    public static let maxFireballs = 2

    // Game
    public static let livesStart = 3
    public static let extraLifeScore = 7000
    public static let bonusStart = 5000
    public static let bonusTickSteps = 150
    public static let bonusTickAmount = 100
    public static let introDurationSteps = 120
    public static let levelClearedDurationSteps = 120
    public static let scoreJumpBarrel = 100
    public static let scoreHammerBarrel = 300
    public static let scoreHammerFireball = 500
    public static let brokenLadderHeightPoints = 20.0
    public static let hammerHeightAboveGirderPoints = 16.0
}
