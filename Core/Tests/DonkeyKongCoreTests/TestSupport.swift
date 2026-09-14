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
