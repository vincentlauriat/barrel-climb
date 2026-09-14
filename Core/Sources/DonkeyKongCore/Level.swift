public struct Girder: Equatable, Sendable {
    /// `from.x < to.x` always; slope direction comes from the y values.
    public let from: Vector2
    public let to: Vector2
    public init(from: Vector2, to: Vector2) { self.from = from; self.to = to }
    public var minX: Double { from.x }
    public var maxX: Double { to.x }
    public func contains(x: Double) -> Bool { x >= minX && x <= maxX }
    public func surfaceY(at x: Double) -> Double {
        let t = max(0, min(1, (x - from.x) / (to.x - from.x)))
        return from.y + (to.y - from.y) * t
    }
}

public struct Ladder: Equatable, Sendable {
    public let x: Double
    public let bottomY: Double
    public let topY: Double
    public let isBroken: Bool
    public let lowerGirder: Int
    public let upperGirder: Int

    /// Builds a ladder whose ends sit exactly on the two girders' surfaces.
    init(x: Double, lower: Int, upper: Int, broken: Bool = false, girders: [Girder]) {
        self.x = x
        lowerGirder = lower; upperGirder = upper; isBroken = broken
        bottomY = girders[lower].surfaceY(at: x)
        topY = broken ? bottomY + Tuning.brokenLadderHeightPoints : girders[upper].surfaceY(at: x)
    }
}

public struct LevelLayout: Sendable {
    public let girders: [Girder]
    public let ladders: [Ladder]
    public let playerSpawn: Vector2
    public let kongPosition: Vector2
    public let paulinePosition: Vector2
    public let goal: Rect
    public let hammers: [Vector2]      // hammer centers
    public let oilDrum: Rect
    public let barrelSpawn: Vector2
}

public enum Levels {
    /// Six alternating girders + Pauline's platform, arcade proportions in a 224 × 256 space.
    /// Barrels start top-left rolling right; each fall reverses them; they end in the oil drum.
    public static let barrels: LevelLayout = {
        let g: [Girder] = [
            Girder(from: Vector2(x: 0,   y: 8),   to: Vector2(x: 112, y: 8)),    // 0 bottom flat
            Girder(from: Vector2(x: 112, y: 8),   to: Vector2(x: 224, y: 15)),   // 1 bottom right rise
            Girder(from: Vector2(x: 0,   y: 48),  to: Vector2(x: 208, y: 41)),   // 2
            Girder(from: Vector2(x: 16,  y: 81),  to: Vector2(x: 224, y: 88)),   // 3
            Girder(from: Vector2(x: 0,   y: 128), to: Vector2(x: 208, y: 121)),  // 4
            Girder(from: Vector2(x: 16,  y: 161), to: Vector2(x: 224, y: 168)),  // 5
            Girder(from: Vector2(x: 0,   y: 208), to: Vector2(x: 208, y: 201)),  // 6 top, Kong
            Girder(from: Vector2(x: 64,  y: 232), to: Vector2(x: 112, y: 232)),  // 7 Pauline
        ]
        let l: [Ladder] = [
            Ladder(x: 184, lower: 1, upper: 2, girders: g),
            Ladder(x: 88,  lower: 0, upper: 2, broken: true, girders: g),
            Ladder(x: 32,  lower: 2, upper: 3, girders: g),
            Ladder(x: 112, lower: 2, upper: 3, broken: true, girders: g),
            Ladder(x: 176, lower: 2, upper: 3, girders: g),
            Ladder(x: 64,  lower: 3, upper: 4, girders: g),
            Ladder(x: 136, lower: 3, upper: 4, girders: g),
            Ladder(x: 192, lower: 3, upper: 4, broken: true, girders: g),
            Ladder(x: 32,  lower: 4, upper: 5, girders: g),
            Ladder(x: 120, lower: 4, upper: 5, broken: true, girders: g),
            Ladder(x: 176, lower: 4, upper: 5, girders: g),
            Ladder(x: 64,  lower: 5, upper: 6, girders: g),
            Ladder(x: 136, lower: 5, upper: 6, girders: g),
            Ladder(x: 192, lower: 5, upper: 6, broken: true, girders: g),
            Ladder(x: 72,  lower: 6, upper: 7, girders: g),
            Ladder(x: 104, lower: 6, upper: 7, girders: g),
        ]
        let hammerY = Tuning.hammerHeightAboveGirderPoints
        return LevelLayout(
            girders: g,
            ladders: l,
            playerSpawn: Vector2(x: 40, y: g[0].surfaceY(at: 40)),
            kongPosition: Vector2(x: 40, y: g[6].surfaceY(at: 40)),
            paulinePosition: Vector2(x: 88, y: 232),
            goal: Rect(origin: Vector2(x: 72, y: 232), size: Vector2(x: 32, y: 20)),
            hammers: [
                Vector2(x: 24,  y: g[4].surfaceY(at: 24) + hammerY),
                Vector2(x: 176, y: g[2].surfaceY(at: 176) + hammerY),
            ],
            oilDrum: Rect(origin: Vector2(x: 2, y: 8), size: Vector2(x: 14, y: 16)),
            barrelSpawn: Vector2(x: 60, y: g[6].surfaceY(at: 60))
        )
    }()
}
