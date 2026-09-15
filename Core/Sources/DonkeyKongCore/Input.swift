public struct Input: Equatable, Sendable {
    public var left = false, right = false, up = false, down = false, jump = false
    public init(left: Bool = false, right: Bool = false, up: Bool = false, down: Bool = false, jump: Bool = false) {
        self.left = left; self.right = right; self.up = up; self.down = down; self.jump = jump
    }
    /// Field-wise OR — used by the app to merge keyboard, controller and touch.
    public func merged(with o: Input) -> Input {
        Input(left: left || o.left, right: right || o.right, up: up || o.up, down: down || o.down, jump: jump || o.jump)
    }
    var horizontal: Direction? { left == right ? nil : (left ? .left : .right) }
}
