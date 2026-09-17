# Day-to-day targets. `make dev` is the loop for tweaking a value in
# lib/src/theme.dart: it rebuilds the web bundle and serves it without caching,
# so a reload of http://localhost:8731 shows the change.

PORT ?= 8731

.PHONY: dev build serve run test frames sounds analyze clean

## Rebuild the web bundle and serve it (Ctrl-C to stop).
dev: build serve

## Compile the web bundle into build/web.
build:
	flutter build web --no-tree-shake-icons

## Serve build/web with caching disabled.
serve:
	python3 tool/serve.py build/web $(PORT)

## Hot-reloading run in Chrome. Press r to reload after an edit, R to restart.
run:
	flutter run -d chrome

## Unit and widget tests (the golden frames are a local tool, not a gate).
test:
	flutter test --exclude-tags goldens

## Render the press at ten points on the timeline into test/goldens/.
frames:
	flutter test --update-goldens test/press_frames_test.dart

## Regenerate the four bundled cues from tool/sounds.py.
sounds:
	python3 tool/sounds.py

analyze:
	flutter analyze

clean:
	flutter clean
