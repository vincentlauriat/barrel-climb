import DonkeyKongCore
import SpriteKit

final class GameScene: SKScene {
    let inputState = InputState()

    private var world = World(
        level: Levels.barrels,
        random: SeededRandom(seed: UInt64(Date().timeIntervalSince1970 * 1000)))
    private let atlas = SpriteAtlas()
    private let dynamicLayer = SKNode()
    private var pool: [Int: SKSpriteNode] = [:]
    private var playerNode: SKSpriteNode!
    private var kongNode: SKSpriteNode!
    private var paulineNode: SKSpriteNode!
    private var hammerNodes: [SKSpriteNode] = []
    private let hud = HUDNode()
    private var lastTime: TimeInterval?
    private var accumulator: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = .zero
        let level = world.level
        addChild(LevelNodes.build(level: level, atlas: atlas))

        kongNode = atlas.sprite("kong_idle")
        kongNode.position = CGPoint(x: level.kongPosition.x, y: level.kongPosition.y)
        kongNode.zPosition = 3
        addChild(kongNode)
        paulineNode = atlas.sprite("pauline_1")
        paulineNode.position = CGPoint(x: level.paulinePosition.x, y: level.paulinePosition.y)
        paulineNode.zPosition = 3
        addChild(paulineNode)
        for h in level.hammers {
            let n = atlas.sprite("hammer", anchor: CGPoint(x: 0.5, y: 0.5))
            n.position = CGPoint(x: h.x, y: h.y)
            n.zPosition = 3
            addChild(n)
            hammerNodes.append(n)
        }
        dynamicLayer.zPosition = 5
        addChild(dynamicLayer)
        playerNode = atlas.sprite("player_stand")
        dynamicLayer.addChild(playerNode)
        addChild(hud)
        syncNodes()
    }

    // MARK: Fixed-step loop — the renderer owns the accumulator, the core takes 1/60 steps.

    override func update(_ currentTime: TimeInterval) {
        defer { lastTime = currentTime }
        guard let last = lastTime else { return }
        accumulator += min(currentTime - last, 0.25)
        let input = inputState.current
        var steps = 0
        while accumulator >= Tuning.stepDuration, steps < 4 {
            handle(world.step(input: input, dt: Tuning.stepDuration))
            accumulator -= Tuning.stepDuration
            steps += 1
        }
        if steps == 4 { accumulator = 0 }  // never spiral after a hitch
        syncNodes()
    }

    /// Reacts to what the step reported. Task 17 adds sounds and overlays here.
    func handle(_ events: [GameEvent]) {
        for e in events {
            if case .scoreChanged = e { hud.update(world.game) }
        }
    }

    // MARK: Mirroring the world into nodes

    private func syncNodes() {
        let t = world.game.totalSteps
        syncPlayer(step: t)
        var seen = Set<Int>()
        for b in world.barrels {
            let frame = (t / 6) % 4
            let name = b.kind == .blue ? "barrel_blue_\(frame)" : "barrel_\(frame)"
            place(id: b.id, texture: name, at: b.position, flipped: b.direction == .left)
            seen.insert(b.id)
        }
        for f in world.fireballs {
            place(
                id: f.id, texture: (t / 8) % 2 == 0 ? "fireball_1" : "fireball_2", at: f.position,
                flipped: f.direction == .left)
            seen.insert(f.id)
        }
        for (id, node) in pool where !seen.contains(id) {
            node.removeFromParent()
            pool[id] = nil
        }
        kongNode.texture = atlas.texture(world.kong.isWindingUp ? "kong_throw" : "kong_idle")
        paulineNode.texture = atlas.texture((t / 30) % 2 == 0 ? "pauline_1" : "pauline_2")
        for (i, n) in hammerNodes.enumerated() { n.isHidden = world.hammersTaken.contains(i) }
        hud.update(world.game)
    }

    private func place(id: Int, texture: String, at p: Vector2, flipped: Bool) {
        let node =
            pool[id]
            ?? {
                let n = atlas.sprite(texture)
                dynamicLayer.addChild(n)
                pool[id] = n
                return n
            }()
        node.texture = atlas.texture(texture)
        node.size = node.texture!.size()
        node.position = CGPoint(x: p.x, y: p.y)
        node.xScale = flipped ? -1 : 1
    }

    private func syncPlayer(step t: Int) {
        let p = world.player
        let name: String
        switch p.state {
        case .standing: name = "player_stand"
        case .walking: name = (t / 8) % 2 == 0 ? "player_walk1" : "player_walk2"
        case .jumping, .falling: name = "player_jump"
        case .climbing: name = (t / 10) % 2 == 0 ? "player_climb1" : "player_climb2"
        case .hammering:
            // Same parity as `Player.hammerBounds(step:)` so the drawn head matches the hitbox.
            name =
                (world.game.phaseSteps / Tuning.hammerSwingPeriodSteps) % 2 == 0 ? "player_hammer1" : "player_hammer2"
        case .dying, .dead: name = "player_die"
        }
        playerNode.texture = atlas.texture(name)
        playerNode.size = playerNode.texture!.size()
        playerNode.position = CGPoint(x: p.position.x, y: p.position.y)
        playerNode.xScale = p.facing == .left ? -1 : 1
        playerNode.isHidden = world.game.phase == .title
    }
}
