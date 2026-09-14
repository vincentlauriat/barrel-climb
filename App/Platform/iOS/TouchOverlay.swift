import DonkeyKongCore
import UIKit

/// Left third: four-way pad. Right third: jump. Multi-touch so run + jump works together.
final class TouchOverlay: UIView {
    private let inputState: InputState
    private let pad = UIView()
    private let jump = UIView()
    private var padTouch: UITouch?
    private var jumpTouch: UITouch?

    init(inputState: InputState) {
        self.inputState = inputState
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        for (v, label) in [(pad, "✥"), (jump, "A")] {
            v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            v.layer.cornerRadius = 48
            v.isUserInteractionEnabled = false
            v.translatesAutoresizingMaskIntoConstraints = false
            let l = UILabel(); l.text = label; l.textColor = .white.withAlphaComponent(0.6)
            l.font = .systemFont(ofSize: 32, weight: .bold); l.textAlignment = .center
            l.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview(l); addSubview(v)
            NSLayoutConstraint.activate([
                l.centerXAnchor.constraint(equalTo: v.centerXAnchor),
                l.centerYAnchor.constraint(equalTo: v.centerYAnchor),
                v.widthAnchor.constraint(equalToConstant: 96), v.heightAnchor.constraint(equalToConstant: 96),
                v.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -24),
            ])
        }
        NSLayoutConstraint.activate([
            pad.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 24),
            jump.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -24),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let x = t.location(in: self).x
            if x < bounds.width / 2, padTouch == nil {
                padTouch = t
            } else if x >= bounds.width / 2, jumpTouch == nil {
                jumpTouch = t
            }
        }
        refresh()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { refresh() }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { release(touches) }

    private func release(_ touches: Set<UITouch>) {
        if let p = padTouch, touches.contains(p) { padTouch = nil }
        if let j = jumpTouch, touches.contains(j) { jumpTouch = nil }
        refresh()
    }

    /// Direction = the vector from the pad's centre to the finger; dead zone 12 pt, 4-way with diagonal tolerance.
    private func refresh() {
        var input = Input()
        if let t = padTouch {
            let c = pad.center, p = t.location(in: self)
            let dx = p.x - c.x, dy = c.y - p.y  // dy up-positive like the game
            if abs(dx) > 12 || abs(dy) > 12 {
                if abs(dx) >= abs(dy) * 0.6 { input.left = dx < 0; input.right = dx > 0 }
                if abs(dy) >= abs(dx) * 0.6 { input.up = dy > 0; input.down = dy < 0 }
            }
        }
        input.jump = jumpTouch != nil
        inputState.touch = input
    }
}
