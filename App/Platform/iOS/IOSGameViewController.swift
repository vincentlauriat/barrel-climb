import SpriteKit
import UIKit

final class IOSGameViewController: UIViewController {
    private var overlay: TouchOverlay!

    override func loadView() {
        view = GameHost.makeView()
        view.backgroundColor = .black
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = (view as! SKView).scene as! GameScene
        overlay = TouchOverlay(inputState: scene.inputState)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        overlay.isHidden = scene.controllerInput?.isConnected ?? false
        scene.controllerInput?.onConnectionChange = { [weak self] connected in
            self?.overlay.isHidden = connected
        }
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
