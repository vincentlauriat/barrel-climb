.PHONY: test lint
test:
	swift test --package-path Core
lint:
	swift format lint --recursive --strict Core App
