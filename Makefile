.PHONY: generate test build-mac build-ios run-mac lint sprites sounds icon clean

XCODEBUILD = xcodebuild -project DonkeyKong.xcodeproj -scheme DonkeyKong CODE_SIGNING_ALLOWED=NO -quiet
DERIVED    = build/DerivedData

generate:
	xcodegen generate

test:
	swift test --package-path Core

build-mac: generate
	$(XCODEBUILD) -destination 'platform=macOS' -derivedDataPath $(DERIVED) build

build-ios: generate
	$(XCODEBUILD) -destination 'generic/platform=iOS Simulator' -derivedDataPath $(DERIVED) build

run-mac: build-mac
	open "$(DERIVED)/Build/Products/Debug/Barrel Climb.app"

lint:
	swift format lint --recursive --strict Core App

sprites:
	python3 Tools/gen_sprites.py App/Resources/sprites

sounds:
	python3 Tools/gen_sounds.py App/Resources/sounds

icon:
	python3 Tools/gen_icon.py App/Resources/Assets.xcassets/AppIcon.appiconset

clean:
	rm -rf build DonkeyKong.xcodeproj
	swift package clean --package-path Core
