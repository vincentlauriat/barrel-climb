import SpriteKit

/// Builds the SKView + GameScene both platform view controllers embed.
@MainActor
enum GameHost {
    static let logicalSize = CGSize(width: 224, height: 256)

    static func makeView() -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 448, height: 512)))
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = 60
        #if DEBUG
            view.showsFPS = true
            view.showsNodeCount = true
        #endif
        let scene = GameScene(size: logicalSize)
        scene.scaleMode = .aspectFit
        view.presentScene(scene)
        return view
    }
}
