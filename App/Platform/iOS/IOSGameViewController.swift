import SpriteKit
import UIKit

final class IOSGameViewController: UIViewController {
    override func loadView() {
        view = GameHost.makeView()
        view.backgroundColor = .black
    }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
