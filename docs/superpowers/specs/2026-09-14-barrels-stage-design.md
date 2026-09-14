# Barrels Stage — Design (sub-project 1 of 4)

**Date:** 2026-09-14
**Status:** approved in chat, pending written review
**Scope:** foundation (simulation core, multiplatform app shell, rendering, input) plus
the complete barrels stage. Sub-projects 2–4 (pie factory, elevators, rivets) reuse this
foundation and get their own specs.

## Goal

An original arcade-style platformer for macOS 14+ and iOS 26+ (iPhone Duo, both fold
states) that reproduces the *mechanics* of the 1981 barrels stage: inclined girders,
ladders, rolling barrels, hammers, a rescue at the top. Playable end to end with lives,
score, bonus timer and game over.

**IP boundary.** Mechanics only. No Nintendo sprites, audio, level data, names or
trademarks. All art is original pixel art produced by `Tools/gen_sprites.py`; all sounds
are synthesized. The app display name is a working title, "Barrel Climb"; the repo,
module and directory name stay `DonkeyKong` as an internal codename.

## Repository layout

```
DonkeyKong/
├── project.yml                 # XcodeGen — one multiplatform target
├── Makefile                    # generate · test · build-mac · build-ios · run-mac · lint · sprites
├── Core/                       # SwiftPM package "DonkeyKongCore" — pure Swift simulation
│   ├── Package.swift
│   ├── Sources/DonkeyKongCore/
│   └── Tests/DonkeyKongCoreTests/
├── App/
│   ├── Sources/                # shared macOS + iOS: SpriteKit scene, nodes, input merging
│   ├── Platform/macOS/         # AppDelegate, window, keyboard
│   ├── Platform/iOS/           # SceneDelegate, touch overlay
│   └── Resources/              # sprites/*.png, sounds/*.wav, Assets.xcassets
├── Tools/gen_sprites.py        # deterministic pixel-art generator; output committed
└── docs/superpowers/specs/
```

`Core` is a *local package dependency* of the app target. It must never import AppKit,
UIKit, SpriteKit, Foundation date/time APIs, or `SystemRandomNumberGenerator`.

### XcodeGen target

```yaml
name: DonkeyKong
options:
  bundleIdPrefix: fr.lauriat
  deploymentTarget: { macOS: "14.0", iOS: "26.0" }
packages:
  DonkeyKongCore: { path: Core }
targets:
  DonkeyKong:
    type: application
    supportedDestinations: [macOS, iOS]
    sources:
      - App/Sources
      - { path: App/Platform/macOS, destinationFilters: [macOS] }
      - { path: App/Platform/iOS,   destinationFilters: [iOS] }
      - App/Resources
    dependencies:
      - package: DonkeyKongCore
    info:
      path: App/Info.plist
      properties:
        CFBundleDisplayName: Barrel Climb
        UIRequiresFullScreen: true
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
        GCSupportsControllerUserInteraction: true
```

`CODE_SIGNING_ALLOWED=NO` for local builds; signing/notarization is out of scope here
(see `macos-app-release` skill when it becomes relevant).

### Makefile

| Target | Command |
| --- | --- |
| `generate` | `xcodegen generate` |
| `test` | `swift test --package-path Core` |
| `build-mac` | `xcodebuild -scheme DonkeyKong -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build` |
| `build-ios` | `xcodebuild -scheme DonkeyKong -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` |
| `run-mac` | `build-mac` then `open` the built `.app` |
| `lint` | `swift format lint --recursive --strict Core App` |
| `sprites` | `python3 Tools/gen_sprites.py App/Resources/sprites` |

## Simulation core (`DonkeyKongCore`)

### Coordinate space and time

Logical space is **224 × 256 points**, origin bottom-left, y up — the arcade's portrait
format and SpriteKit's native convention, so the renderer applies no transform.

The world advances in **fixed steps of 1/60 s**. `World.step(input:dt:)` is only ever
called with `dt == 1/60`; the renderer owns the accumulator. Time inside the core is a
step counter, never a wall clock.

### Types

```swift
public struct Vector2 { var x, y: Double }
public struct Rect    { var origin: Vector2; var size: Vector2 }

public struct Girder  { let from: Vector2; let to: Vector2 }      // inclined segment
public struct Ladder  { let x: Double; let bottomY, topY: Double; let isBroken: Bool }

public struct LevelLayout {
    let girders: [Girder]        // 6 girders, alternating slope, arcade-style
    let ladders: [Ladder]
    let playerSpawn: Vector2
    let kongPosition: Vector2
    let paulinePosition: Vector2
    let goal: Rect               // reaching it clears the level
    let hammers: [Vector2]       // two
    let oilDrum: Rect            // bottom-left; blue barrels falling in spawn a fireball
    let barrelSpawn: Vector2     // next to Kong
}
public enum Levels { public static let barrels: LevelLayout }

public struct Input: Equatable { var left, right, up, down, jump: Bool }

public enum PlayerState { case standing, walking, jumping, climbing, hammering, dying, dead }
public struct Player {
    var position: Vector2; var velocity: Vector2
    var facing: Direction; var state: PlayerState
    var hammerStepsRemaining: Int; var currentLadder: Int?; var currentGirder: Int?
}

public enum BarrelKind  { case normal, blue }
public enum BarrelState { case rolling, falling, onLadder }
public struct Barrel { let id: Int; var kind: BarrelKind; var state: BarrelState
                       var position: Vector2; var velocity: Vector2; var direction: Direction }

public struct Fireball { let id: Int; var position: Vector2; var direction: Direction; var ladderTarget: Int? }

public struct Kong { var throwCooldownSteps: Int; var isWindingUp: Bool }

public enum Phase { case title, intro, playing, playerDied, levelCleared, gameOver }
public struct GameState {
    var phase: Phase; var lives: Int; var score: Int
    var bonus: Int; var bonusTickSteps: Int; var loop: Int; var phaseSteps: Int
}

public enum GameEvent: Equatable {
    case jumped, landed, climbStarted
    case barrelThrown(id: Int), barrelJumped(id: Int, points: Int)
    case hammerPicked, hammerHit(id: Int, points: Int), hammerExpired
    case fireballSpawned, playerDied, levelCleared(bonus: Int), gameOver, scoreChanged(Int)
}

public protocol RandomSource { mutating func next(below n: Int) -> Int }
public struct SeededRandom: RandomSource   // xorshift, deterministic

public struct World {
    public private(set) var level: LevelLayout
    public private(set) var player: Player
    public private(set) var barrels: [Barrel]
    public private(set) var fireballs: [Fireball]
    public private(set) var kong: Kong
    public private(set) var game: GameState
    public init(level: LevelLayout, random: RandomSource)
    public mutating func step(input: Input, dt: Double) -> [GameEvent]
    public mutating func start()          // title → intro → playing
}
```

Direction is `enum Direction { case left, right }`.

### Tuning constants (`Tuning.swift`, one place)

| Constant | Value | Note |
| --- | --- | --- |
| `walkSpeed` | 40 pt/s | |
| `climbSpeed` | 30 pt/s | |
| `jumpDurationSteps` | 30 (0.5 s) | fixed parabola, horizontal speed = walk speed if a direction is held |
| `jumpHeight` | 12 pt | just clears a 10 pt barrel |
| `gravity` | 300 pt/s² | only for falling barrels / falling player death |
| `barrelSpeed` | 45 pt/s | ×(1 + 0.1·loop) |
| `barrelLadderChance` | 1/4 | evaluated once per ladder top |
| `blueBarrelEvery` | 8 | every 8th barrel is blue |
| `kongThrowIntervalSteps` | 150 (2.5 s) | −10 per loop, floor 60 |
| `hammerDurationSteps` | 540 (9 s) | |
| `bonusStart` | 5000 | −100 every 150 steps; player dies at 0 |
| `livesStart` | 3 | extra life at 7000 (once) |
| `scoreJumpBarrel` | 100 | |
| `scoreHammerBarrel` | 300 | |
| `scoreHammerFireball` | 500 | |

### Player rules

- **Grounded** on a girder: `position.y = girder.surfaceY(at: x)`; left/right move along the
  girder; leaving a girder's x-range at its open end causes a fall (death if the drop is
  more than one girder height).
- **Jump** (`jump` pressed while grounded): fixed parabola of `jumpDurationSteps`;
  horizontal drift at `walkSpeed` if a direction is held at takeoff (locked for the whole
  jump, arcade-style). Lands on the first girder whose surface is crossed downward.
- **Ladder**: if a ladder's x is within ±4 pt and `up` (at bottom) or `down` (at top) is
  pressed, the player snaps to the ladder's x and enters `.climbing`. A broken ladder can
  be climbed only up to its `topY` (which is short of the girder) and then forces a climb
  down. No jumping from a ladder. Barrels do not hit a player who is on a ladder *below*
  the girder surface (arcade quirk kept deliberately — it makes ladders a refuge).
- **Hammer**: touching a hammer pickup starts `.hammering` for `hammerDurationSteps`;
  no jumping or climbing while hammering; the hammer hitbox alternates high/low every
  8 steps and destroys barrels/fireballs it touches.
- **Death**: AABB overlap with a barrel/fireball (not hammering), a fall of more than one
  girder height, or `bonus == 0`. `.dying` lasts 90 steps, then `lives -= 1`; `.playerDied`
  phase resets the level (barrels cleared) or transitions to `.gameOver` at 0 lives.
- **Goal**: player AABB intersects `level.goal` → `.levelCleared`, bonus added to score,
  `loop += 1`, level restarts with faster barrels/Kong.

### Barrel rules

- Kong throws a barrel every `kongThrowIntervalSteps`; it appears at `barrelSpawn`
  rolling right on the top girder. Every `blueBarrelEvery`-th barrel is blue.
- **Rolling**: follows `surfaceY(x)` of its girder at `barrelSpeed` in `direction`. At a
  girder's open end it enters `.falling` (gravity), lands on the next girder and reverses
  direction.
- **Ladder**: when a rolling barrel's x passes over a ladder top, `random.next(below: 4) == 0`
  makes it descend the ladder (`.onLadder`, `climbSpeed`) and continue on the girder
  below in the *same* direction it had — this is what makes them unpredictable. Broken
  ladders are never taken.
- Barrels that reach the oil drum region at the bottom-left are removed; a **blue**
  barrel doing so spawns a `Fireball` (max 2 alive).
- **Jump bonus**: a barrel whose x crosses the player's x while the player is
  `.jumping` and above it awards `scoreJumpBarrel` once per barrel (tracked by id).

### Fireball rules

Wanders on girders at 0.6 × `barrelSpeed`, reverses at girder ends, takes any ladder
(up or down) with probability 1/2 when passing one, kills on contact, worth
`scoreHammerFireball` when hammered.

### Phase machine

```
title ──start()──▶ intro (120 steps, Kong climbs, barrels stacked) ──▶ playing
playing ──death──▶ playerDied (90 steps) ──lives>0──▶ playing (level reset)
                                          ──lives==0─▶ gameOver ──start()──▶ intro
playing ──goal───▶ levelCleared (120 steps) ──▶ playing (loop+1, level reset)
```

Input is ignored outside `.playing` except `jump` on `title`/`gameOver`, which calls
`start()`.

## Rendering and platforms (`App`)

### `GameScene: SKScene`

- `size = CGSize(width: 224, height: 256)`, `scaleMode = .aspectFit`, black background.
  **This alone handles the iPhone Duo fold:** `SKView` resizes on fold/unfold, SpriteKit
  rescales the scene with letterboxing. `didChangeSize(_:)` repositions the touch overlay,
  which lives in the *view's* coordinate space, not the scene's.
- All textures `filteringMode = .nearest`.
- `update(_ currentTime:)`: accumulate real elapsed time (clamped to 4 steps max), run
  `world.step` per 1/60 slice, collect events, then `syncNodes()`.
- `syncNodes()`: static nodes (girders as tiled sprites, ladders, oil drum, hammers,
  Kong, Pauline) built once from `LevelLayout` in `didMove(to:)`. Dynamic nodes
  (player, barrels, fireballs) live in a `[Int: SKSpriteNode]` pool keyed by entity id:
  create on first sight, remove when the id disappears, else set position/texture/xScale.
  Player texture chosen from `PlayerState` + a step-based animation frame.
- Events → `SKAction.playSoundFileNamed` (`jump`, `barrel`, `hammer`, `die`, `clear`) and
  HUD updates. HUD: four `SKLabelNode` (score, bonus, lives, loop) in a system
  monospaced font, drawn in the top band above the top girder.
- Overlay screens (`title`, `gameOver`, `levelCleared`) are `SKNode`s toggled by phase.

### Input merging

```swift
@MainActor final class InputState {
    var keyboard = Input()       // macOS
    var controller = Input()     // both
    var touch = Input()          // iOS
    var current: Input { keyboard || controller || touch }   // field-wise OR
}
```

- **Keyboard** (macOS): arrows or WASD, space = jump. `keyDown`/`keyUp` on the
  `NSViewController`'s view (first responder).
- **Controller** (both): `GCController` notifications; map `dpad`, `leftThumbstick`
  (dead zone 0.5) and `buttonA`. On connect hide the touch overlay; on disconnect show it.
- **Touch** (iOS): `TouchOverlayNode` added to the `SKView`'s own overlay `SKScene`
  (not the game scene, so it never scales with the game): a four-way pad on the left
  third, a jump button on the right third, ~40 % alpha, multi-touch tracked per
  `UITouch` so run + jump works. Hidden on macOS and when a controller is present.

### Platform shells

- **macOS**: `AppDelegate` creates one `NSWindow` (initial 448 × 512, aspect ratio
  locked to 7:8, resizable) hosting `GameViewController: NSViewController` with an
  `SKView`. Menu: Quit only.
- **iOS**: `SceneDelegate` sets a full-screen `GameViewController: UIViewController`,
  status bar and home indicator hidden, portrait only.

Both `GameViewController`s share the scene setup in `App/Sources/GameHost.swift`.

## Assets

`Tools/gen_sprites.py` (Python 3, no dependencies beyond the standard library — writes
PNG via `zlib` by hand) produces 16-colour pixel art into `App/Resources/sprites/`:
player (stand, walk ×2, jump, climb ×2, hammer ×2, die), barrel (normal ×4 rotation,
blue ×4), fireball ×2, Kong (idle, throw), Pauline ×2, hammer, oil drum, girder tile,
ladder tile, broken-ladder tile. Deterministic output, committed; regenerate with
`make sprites`. Sounds are short `.wav` files synthesized by `Tools/gen_sounds.py`
(square-wave beeps), also committed.

## Testing

**Core** (`swift test --package-path Core`, deterministic, seeded RNG, no simulator):

- walking left/right follows an inclined girder's surface
- walking off a girder's open end starts a fall; a one-girder drop lands, a larger one kills
- jump peaks at `jumpHeight` and lands after `jumpDurationSteps`; direction is locked
- ladder entry needs alignment and `up`/`down`; climbing arrives on the girder above
- broken ladder stops at `topY` and cannot be completed
- Kong throws at the configured interval; every 8th barrel is blue
- barrel rolls, falls at the end, lands and reverses
- barrel takes a ladder when the RNG says so and keeps its direction
- jumping over a barrel scores 100 exactly once
- barrel contact kills; contact while hammering destroys it for 300
- hammer expires after `hammerDurationSteps`
- blue barrel into the oil drum spawns a fireball, max 2
- bonus ticks and kills at 0
- reaching the goal clears the level and adds the bonus
- three deaths → `gameOver`; extra life at 7000

**App**: `make build-mac` and `make build-ios` after every change; manual play on
macOS and on the iOS Simulator (iPhone Duo simulator if Xcode 27 provides it, otherwise
iPhone 18 Pro plus an iPad to exercise the second aspect ratio).

## Out of scope for this sub-project

Pie factory, elevators, rivets stages; persistent high scores; music; attract mode;
Game Center; App Store distribution; code signing and notarization.
