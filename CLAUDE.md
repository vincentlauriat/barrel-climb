# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

Sub-project 1 is merged on `main` (2026-09-15): the barrels stage is playable on
macOS and iOS, `Core/` holds 76 deterministic tests, and the app ships a generated
icon for the Dock and both iOS home screens. Published at
https://github.com/vincentlauriat/barrel-climb with a landing page on GitHub Pages
(`main:/docs`). **v1.0.0 has shipped**: a signed, notarized, stapled DMG on the
releases page, with Sparkle reading `docs/appcast.xml` from the same Pages site.
Next sub-projects: pie factory, elevators, rivets.

## What this is

An original arcade platformer reproducing the *mechanics* of the 1981 barrels stage
(then pie factory, elevators, rivets as later sub-projects), for **macOS 14+** and
**iOS 26+ including the iPhone Duo in both fold states**. Working display name
"Barrel Climb"; `DonkeyKong` is only the internal codename. No Nintendo sprites, audio,
level data or trademarks — ever. All art comes from `Tools/gen_sprites.py`.

## Stack

Two worlds, deliberately separated:

- `Core/` — SwiftPM package **`DonkeyKongCore`**, pure Swift simulation. Must never
  import AppKit, UIKit, SpriteKit, wall-clock APIs or `SystemRandomNumberGenerator`.
- `App/` — one XcodeGen-generated Xcode target with `supportedDestinations: [macOS, iOS]`,
  SpriteKit renderer, depending on the local `Core` package. `project.yml` is the source
  of truth; the `.xcodeproj` is generated and git-ignored.

A pure SwiftPM executable cannot target iOS — that is why the app lives in Xcode and
the logic lives in a package.

## Commands

The root `Makefile` is the command surface — use it rather than raw invocations.

```sh
make generate    # xcodegen generate (run after editing project.yml)
make test        # swift test --package-path Core   — seconds, no simulator
make build-mac   # xcodebuild … -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
make build-ios   # xcodebuild … -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
make run-mac     # build-mac, then open the .app
make lint        # swift format lint --recursive --strict Core App
make sprites     # regenerate App/Resources/sprites from Tools/gen_sprites.py
make sounds      # regenerate App/Resources/sounds from Tools/gen_sounds.py
make icon        # regenerate the AppIcon.appiconset from Tools/gen_icon.py
```

Releasing the Mac build:

```sh
./Scripts/release.sh 1.0.0   # build, Developer ID sign, notarize, staple, DMG, appcast
```

Bump `MARKETING_VERSION` **and** `CURRENT_PROJECT_VERSION` in `project.yml` first: Sparkle
compares the appcast's `sparkle:version` against the installed app's `CFBundleVersion`, not
against the marketing string, so two releases sharing a build number leave every install
convinced it is up to date. The EdDSA key lives in the login keychain under the account
`BarrelClimb` and must never be regenerated. Both steps need an unlocked Mac: notarytool
reads its keychain profile and `sign_update` puts up an authorization panel the first time.

Single core test (regex over `Target.Suite/test`):

```sh
swift test --package-path Core --filter DonkeyKongCoreTests.BarrelTests
swift test --package-path Core --filter 'barrelTakesLadderWhenRandomSaysSo'
```

After any code change run `make test` **and** both `make build-mac` and `make build-ios`
— the two destinations compile different platform shells and one routinely breaks
without the other noticing.

## Architecture rules that shape every change

**The simulation is a pure function of (input, step).** `World.step(input:dt:)` is
called only with `dt == 1/60`; the renderer owns the time accumulator (max 4 steps per
frame). Randomness comes from an injected `RandomSource` seeded in tests. This is what
makes every gameplay rule unit-testable in `Core` without a window.

**The renderer never owns game state.** `GameScene.syncNodes()` mirrors `World` into
`SKSpriteNode`s (pool keyed by entity id) after each step. Sounds and HUD react to the
`[GameEvent]` returned by `step`, never to node state.

**Input is merged, not routed.** `InputState` ORs keyboard (macOS), `GameController`
(both) and touch overlay (iOS) into one `Input` struct per step. The core does not know
which source produced it. Touch overlay hides when a controller connects.

**Logical space is 224 × 256, origin bottom-left, y up** — arcade portrait and
SpriteKit's own convention, so no coordinate transform exists anywhere. The scene uses
`scaleMode = .aspectFit`; that single setting is the entire iPhone Duo fold handling.
Do not add fold-specific code paths.

**Tuning lives in one file.** Every speed, duration, score value and probability is a
named constant in `Core/Sources/DonkeyKongCore/Tuning.swift`, with units in the name
(`barrelSpeedPointsPerSecond`, `hammerDurationSteps`). Never inline a magic number in a
rule.

## Layout

```
Core/Sources/DonkeyKongCore/   simulation — group by concept (Player, Barrel, Level…)
Core/Tests/DonkeyKongCoreTests/ mirrors the source file names
App/Sources/                   shared macOS + iOS SpriteKit code
App/Platform/{macOS,iOS}/      thin shells: window/scene delegates, keyboard, touch overlay
App/Resources/                 sprites/*.png (generated), sounds/*.wav (generated)
Tools/                         gen_sprites.py, gen_sounds.py, gen_icon.py — stdlib only, deterministic
docs/superpowers/specs/        design specs, one per sub-project
```

Sibling project `../FlightSim` is the reference for the SwiftPM/Makefile conventions.
Its `AGENTS.md` mentions `src/`/`tests/` but the real tree uses SwiftPM's
`Sources/`/`Tests/` — the code is authoritative, the prose is stale.

## Naming

`PascalCase` types, `camelCase` members, units in names. Test names describe observable
behavior (`barrelRollsDownSlopeUntilLadder`), never the method under test.

## Inherited rules

`~/DevApps/CLAUDE.md` governs doc maintenance (`COMMANDS.md`, `CHANGES.md`, `MEMORY.md`,
`TODOS.md`, `PLAN.md` updated in the same turn as any change), French communication with
English code and commits, conventional commits, and the no `Co-Authored-By: Claude`
rule. Not repeated here.
