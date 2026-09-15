public protocol RandomSource: Sendable {
    /// Uniform integer in `0..<n`. `n` must be > 0.
    mutating func next(below n: Int) -> Int
}

/// xorshift64* — tiny, deterministic, good enough for barrel choices.
public struct SeededRandom: RandomSource {
    private var state: UInt64
    public init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    public mutating func next(below n: Int) -> Int {
        precondition(n > 0)
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        let r = state &* 0x2545_F491_4F6C_DD1D
        return Int(r % UInt64(n))
    }
}
