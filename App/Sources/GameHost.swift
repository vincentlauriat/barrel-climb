import SpriteKit

/// The SKView both platforms embed. `SKView` overrides `keyDown:`/`keyUp:` to route key
/// events to the presented scene and never calls `super`, so they die there instead of
/// reaching the view controller. Forwarding to `nextResponder` — the view controller —
/// restores the normal responder chain.
final class GameView: SKView {
    #if os(macOS)
        override func keyDown(with event: NSEvent) {
            nextResponder?.keyDown(with: event)
        }

        override func keyUp(with event: NSEvent) {
            nextResponder?.keyUp(with: event)
        }
    #endif
}

/// Builds the SKView + GameScene both platform view controllers embed.
@MainActor
enum GameHost {
    static let logicalSize = CGSize(width: 224, height: 256)

    static func makeView() -> SKView {
        let view = GameView(frame: CGRect(origin: .zero, size: CGSize(width: 448, height: 512)))
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
