import DonkeyKongCore
import SpriteKit

/// Centre-screen banners for the non-playing phases.
final class OverlayNode: SKNode {
    private let title = SKLabelNode(fontNamed: "Menlo-Bold")
    private let subtitle = SKLabelNode(fontNamed: "Menlo")

    override init() {
        super.init()
        zPosition = 20
        for (l, y, size) in [(title, 140.0, 12.0), (subtitle, 120.0, 7.0)] {
            l.fontSize = size; l.fontColor = .white
            l.horizontalAlignmentMode = .center
            l.position = CGPoint(x: 112, y: y)
            addChild(l)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func show(_ game: GameState) {
        switch game.phase {
        case .title:
            title.text = "BARREL CLIMB"; subtitle.text = "PRESS JUMP"
        case .gameOver:
            title.text = "GAME OVER"; subtitle.text = String(format: "SCORE %06d  -  PRESS JUMP", game.score)
        case .levelCleared:
            title.text = "RESCUED!"; subtitle.text = String(format: "BONUS %04d", game.bonus)
        case .intro, .playing, .playerDied:
            title.text = nil; subtitle.text = nil
        }
        subtitle.isHidden = game.phase == .title && (game.totalSteps / 30) % 2 == 1  // blink
    }
}
