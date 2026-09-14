import XCTest
@testable import DonkeyKongCore

let dt = 1.0 / 60.0

extension World {
    /// Steps `n` times with the same input, returning all events.
    @discardableResult
    mutating func run(_ n: Int, _ input: Input = Input()) -> [GameEvent] {
        var events: [GameEvent] = []
        for _ in 0..<n { events += step(input: input, dt: dt) }
        return events
    }
    /// A world already in `.playing` with no barrels thrown yet.
    static func playing(seed: UInt64 = 1, level: LevelLayout = Levels.barrels) -> World {
        var w = World(level: level, random: SeededRandom(seed: seed))
        w.start()
        w.run(Tuning.introDurationSteps)      // intro → playing
        return w
    }
}

extension Input {
    static let none  = Input()
    static let left  = Input(left: true)
    static let right = Input(right: true)
    static let up    = Input(up: true)
    static let down  = Input(down: true)
    static let jump  = Input(jump: true)
}

/// Returns the queued values in order, then 0 forever (0 = "yes, take the ladder").
struct FixedRandom: RandomSource {
    var values: [Int] = []
    mutating func next(below n: Int) -> Int { values.isEmpty ? 0 : values.removeFirst() % n }
}
/// Always returns the largest value: barrels and fireballs never take a ladder.
struct NeverRandom: RandomSource {
    mutating func next(below n: Int) -> Int { n - 1 }
}

extension LevelLayout {
    /// Two girders, no ladders, hazards parked far away. Top girder is open at x = 208.
    static let twoGirders = LevelLayout(
        girders: [Girder(from: Vector2(x: 16, y: 53), to: Vector2(x: 224, y: 60)),
                  Girder(from: Vector2(x: 0, y: 100), to: Vector2(x: 208, y: 93))],
        ladders: [],
        playerSpawn: Vector2(x: 20, y: 53.13),
        kongPosition: Vector2(x: 10, y: 100), paulinePosition: Vector2(x: 500, y: 500),
        goal: Rect(origin: Vector2(x: 500, y: 500), size: Vector2(x: 1, y: 1)),
        hammers: [], oilDrum: Rect(origin: Vector2(x: 500, y: 0), size: Vector2(x: 1, y: 1)),
        barrelSpawn: Vector2(x: 20, y: 100 - 7 * 20 / 208))
}
