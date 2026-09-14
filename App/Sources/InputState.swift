import DonkeyKongCore

/// One `Input` per step, OR-merged from every source. Sources write their own field only.
final class InputState {
    var keyboard = Input()
    var controller = Input()
    var touch = Input()
    var current: Input { keyboard.merged(with: controller).merged(with: touch) }
}
