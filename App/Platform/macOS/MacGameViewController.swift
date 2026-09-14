import AppKit
import DonkeyKongCore
import SpriteKit

final class MacGameViewController: NSViewController {
    private var scene: GameScene { (view as! SKView).scene as! GameScene }

    override func loadView() {
        view = GameHost.makeView()
    }
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        apply(event.keyCode, pressed: true)
    }
    override func keyUp(with event: NSEvent) {
        apply(event.keyCode, pressed: false)
    }

    /// Arrows or WASD move, space jumps. Key codes are the ANSI layout-independent ones.
    private func apply(_ keyCode: UInt16, pressed: Bool) {
        var k = scene.inputState.keyboard
        switch keyCode {
        case 123, 0: k.left = pressed  // ← / A
        case 124, 2: k.right = pressed  // → / D
        case 126, 13: k.up = pressed  // ↑ / W
        case 125, 1: k.down = pressed  // ↓ / S
        case 49: k.jump = pressed  // space
        default: return
        }
        scene.inputState.keyboard = k
    }
}
