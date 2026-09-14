.PHONY: test lint sprites sounds
test:
	swift test --package-path Core
lint:
	swift format lint --recursive --strict Core App
sprites:
	python3 Tools/gen_sprites.py App/Resources/sprites
sounds:
	python3 Tools/gen_sounds.py App/Resources/sounds
