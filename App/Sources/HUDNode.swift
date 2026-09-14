import DonkeyKongCore
import SpriteKit

/// Score, bonus, lives and loop in the 16-point band above the top girder.
final class HUDNode: SKNode {
    private let score = SKLabelNode(fontNamed: "Menlo-Bold")
    private let bonus = SKLabelNode(fontNamed: "Menlo-Bold")
    private let lives = SKLabelNode(fontNamed: "Menlo-Bold")
    private let loop = SKLabelNode(fontNamed: "Menlo-Bold")

    override init() {
        super.init()
        for (label, x, align) in [
            (score, 4.0, SKLabelHorizontalAlignmentMode.left),
            (bonus, 112.0, .center),
            (lives, 220.0, .right),
            (loop, 220.0, .right),
        ] {
            label.fontSize = 7
            label.fontColor = .white
            label.horizontalAlignmentMode = align
            label.verticalAlignmentMode = .top
            label.position = CGPoint(x: x, y: 254)
            addChild(label)
        }
        loop.position.y = 245
        zPosition = 10
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(_ game: GameState) {
        score.text = String(format: "SCORE %06d", game.score)
        bonus.text = String(format: "BONUS %04d", game.bonus)
        lives.text = String(repeating: "♥", count: max(0, game.lives))
        loop.text = String(format: "L=%02d", game.loop + 1)
    }
}
