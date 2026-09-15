import ImageIO
import SpriteKit

/// Loads the generated PNGs from the bundle's `sprites/` folder, once, with nearest filtering.
final class SpriteAtlas {
    private var cache: [String: SKTexture] = [:]

    func texture(_ name: String) -> SKTexture {
        if let t = cache[name] { return t }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "sprites"),
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            fatalError("missing sprite \(name).png — run `make sprites`")
        }
        let t = SKTexture(cgImage: image)
        t.filteringMode = .nearest
        cache[name] = t
        return t
    }

    /// A sprite anchored at its bottom-centre, matching the core's position convention.
    func sprite(_ name: String, anchor: CGPoint = CGPoint(x: 0.5, y: 0)) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(name))
        node.anchorPoint = anchor
        return node
    }
}
