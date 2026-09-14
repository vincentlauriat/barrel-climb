import DonkeyKongCore
import SpriteKit

enum LevelNodes {
    static let tile = 8.0

    /// Girders, ladders and the oil drum. Kong, Pauline and hammers are placed by the scene.
    static func build(level: LevelLayout, atlas: SpriteAtlas) -> SKNode {
        let root = SKNode()
        for g in level.girders {
            let count = Int(((g.maxX - g.minX) / tile).rounded(.up))
            for i in 0..<count {
                let x = g.minX + Double(i) * tile + tile / 2
                let n = atlas.sprite("girder", anchor: CGPoint(x: 0.5, y: 1))  // hangs below the surface line
                n.position = CGPoint(x: x, y: g.surfaceY(at: x))
                n.zPosition = 0
                root.addChild(n)
            }
        }
        for l in level.ladders {
            var y = l.bottomY
            while y < l.topY {
                let n = atlas.sprite("ladder")
                n.position = CGPoint(x: l.x, y: y)
                n.zPosition = 1
                root.addChild(n)
                y += tile
            }
            if l.isBroken {  // a stub under the upper girder
                let top = level.girders[l.upperGirder].surfaceY(at: l.x)
                let n = atlas.sprite("ladder_broken")
                n.position = CGPoint(x: l.x, y: top - tile)
                n.zPosition = 1
                root.addChild(n)
            }
        }
        let drum = atlas.sprite("oil_drum", anchor: .zero)
        drum.position = CGPoint(x: level.oilDrum.minX, y: level.oilDrum.minY)
        drum.zPosition = 2
        root.addChild(drum)
        return root
    }
}
