# feral_stamp

A Flutter reproduction of [FeralUI's Stamp component](https://feralui.dev/stamp): an invoice date
picker where you roll the date on a rubber stamp, press a button, and the stamp physically comes down
and prints the date on the page.

The original is a web component by FeralUI Studio, designed and animated in Figma before any code.
This is a from-scratch Flutter rebuild of that interaction. All credit for the design is theirs.

## The interaction

1. **Pick.** Three wheels (day, month, year) on the face of the stamp. A label chip picks what the
   stamp says, and a swatch picks the ink.
2. **Press.** The camera tilts into perspective, the invoice slides underneath, and the stamp block
   descends onto it.
3. **Print.** On contact the ink lands slightly oversized and contracts as the rubber rebounds. The
   block lifts away and the camera rises back to flat.
4. **Confirm.** A toast offers Undo or Done.

Press `Enter` to stamp. **Hold** the button to stamp `VOID` instead.

## Timings

Taken from the reference component's own control panel, so the motion matches rather than approximates:

| Phase | Duration |
|---|---|
| Camera tilt | 800ms |
| Press | 150ms |
| Bounce | 30% of travel |
| Lift away | 420ms |
| Camera rise | 700ms |

## How it is put together

```
lib/
  main.dart
  src/
    theme.dart              tokens: ink colours, the phase timings, type scale
    invoice.dart            invoice data, wheel ranges, date formatting
    stamp_page.dart         the timeline, the 3D scene, the controls
    widgets/
      date_wheel.dart       one scrollable wheel column
      stamp_head.dart       the block: wheels on top, body, rubber pad
      invoice_sheet.dart    the page being stamped
      stamp_mark.dart       the ink impression
```

Two things carry the illusion and are worth knowing before you change them.

**There is only one stamp.** The picker and the thing that does the stamping are the same widget. It
grows a body and a rubber pad when the camera tilts (`StampHead.solid`). Crossfading between two
separate widgets was tried first and reads as fake immediately.

**The far edge is the top one.** The page is narrow at the top and wide at the bottom, which means the
camera rotates the *opposite* way to the obvious guess, and the hover offset is negative Z. Getting
this backwards produces a page that looks plausible in a still and wrong in motion. There is a test
(`the camera tilts the far edge away from the viewer`) that reads the transform matrix and fails if
the sign flips back.

The ink is drawn with a seeded `Random`, so the border erodes in the same places on every repaint. An
unseeded one makes the stamp crawl while the ink fades in.

## Running it

```bash
flutter pub get
make dev               # build the web bundle and serve it on :8731
make run               # or: hot-reloading run in Chrome (r to reload)
make test
```

`make dev` serves `build/web` through `tool/serve.py`, which sends no-cache headers. A plain
`python -m http.server` doesn't, and Chrome will keep an old `main.dart.js` for a while after a
rebuild, which is a confusing way to lose an afternoon.

The stamp's dimensions live in `lib/src/theme.dart` as `Box.width`, `Box.depth` and `Box.height`.
Change a value, `make dev`, reload.

### Looking at the animation

Driving this through a browser is unreliable: synthetic clicks and key events do not consistently
reach the Flutter canvas. Two things help instead.

`test/press_frames_test.dart` renders the press at fixed points on the timeline:

```bash
flutter test --update-goldens test/press_frames_test.dart
open test/goldens/
```

Those images are a local inspection tool, not a CI gate, which is why they are tagged `goldens` and
excluded above. They use the test font, so the text renders as blocks; it is the geometry you are
looking at.

In the browser, `?slow=12` dilates the whole timeline so the press can be watched frame by frame.

## Deploying

Pushes to `main` build and publish to GitHub Pages via `.github/workflows/pages.yml`. To turn it on:
**Settings → Pages → Source → GitHub Actions**. The workflow sets `--base-href` to the repo name and
drops a `.nojekyll` file, both of which Flutter web needs on Pages.
