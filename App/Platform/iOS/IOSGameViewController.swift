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
        // The iOS Simulator advertises a phantom MFi controller at launch, which would hide the
        // touch overlay with no real controller present. Real devices keep the auto-hide.
        #if !targetEnvironment(simulator)
            overlay.isHidden = scene.controllerInput?.isConnected ?? false
            scene.controllerInput?.onConnectionChange = { [weak self] connected in
                self?.overlay.isHidden = connected
            }
        #endif
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
