import DonkeyKongCore
import GameController

/// Maps the first connected controller onto `InputState.controller`.
final class ControllerInput {
    private let inputState: InputState
    private var observers: [NSObjectProtocol] = []
    var onConnectionChange: ((Bool) -> Void)?
    private(set) var isConnected = false

    init(inputState: InputState) {
        self.inputState = inputState
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] n in
                self?.attach(n.object as? GCController)
            })
        observers.append(
            center.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
                self?.detach()
            })
        attach(GCController.controllers().first)
        GCController.startWirelessControllerDiscovery {}
    }

    private func attach(_ controller: GCController?) {
        guard let pad = controller?.extendedGamepad else { return }
        isConnected = true
        onConnectionChange?(true)
        pad.valueChangedHandler = { [weak self] pad, _ in
            self?.read(pad)  // GameController delivers on the main queue by default
        }
    }

    private func detach() {
        isConnected = false
        inputState.controller = Input()
        onConnectionChange?(false)
        attach(GCController.controllers().first)  // another one may still be there
    }

    private func read(_ pad: GCExtendedGamepad) {
        let dead: Float = 0.5
        let x = pad.leftThumbstick.xAxis.value, y = pad.leftThumbstick.yAxis.value
        inputState.controller = Input(
            left: pad.dpad.left.isPressed || x < -dead,
            right: pad.dpad.right.isPressed || x > dead,
            up: pad.dpad.up.isPressed || y > dead,
            down: pad.dpad.down.isPressed || y < -dead,
            jump: pad.buttonA.isPressed)
    }
}
