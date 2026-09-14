import AppKit
import SpriteKit

final class MacGameViewController: NSViewController {
    override func loadView() {
        view = GameHost.makeView()
    }
    override var acceptsFirstResponder: Bool { true }
}
