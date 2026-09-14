public struct Vector2: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    public static let zero = Vector2(x: 0, y: 0)
    public static func + (a: Vector2, b: Vector2) -> Vector2 { Vector2(x: a.x + b.x, y: a.y + b.y) }
    public static func - (a: Vector2, b: Vector2) -> Vector2 { Vector2(x: a.x - b.x, y: a.y - b.y) }
    public static func * (a: Vector2, s: Double) -> Vector2 { Vector2(x: a.x * s, y: a.y * s) }
}

public struct Rect: Equatable, Sendable {
    public var origin: Vector2
    public var size: Vector2
    public init(origin: Vector2, size: Vector2) { self.origin = origin; self.size = size }
    public init(center: Vector2, size: Vector2) {
        self.init(origin: Vector2(x: center.x - size.x / 2, y: center.y - size.y / 2), size: size)
    }
    public var minX: Double { origin.x }
    public var maxX: Double { origin.x + size.x }
    public var minY: Double { origin.y }
    public var maxY: Double { origin.y + size.y }
    public var center: Vector2 { Vector2(x: minX + size.x / 2, y: minY + size.y / 2) }
    public func intersects(_ o: Rect) -> Bool {
        minX < o.maxX && o.minX < maxX && minY < o.maxY && o.minY < maxY
    }
    public func contains(_ p: Vector2) -> Bool {
        p.x >= minX && p.x < maxX && p.y >= minY && p.y < maxY
    }
}

public enum Direction: Equatable, Sendable {
    case left, right
    public var sign: Double { self == .left ? -1 : 1 }
    public var flipped: Direction { self == .left ? .right : .left }
}
