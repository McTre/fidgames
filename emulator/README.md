# FidGames Lab

Windowed Godot tool for testing FidGames game ideas and creating pixel sprites. Built with **Godot 4.7.2 stable**, GDScript, and the GL Compatibility renderer.

## Run

Import `project.godot` in Godot and press F6 with `main.tscn` open, or F5 to run the project. Disable Godot's embedded game preview to see the intended separate desktop window.

From a terminal with Godot on PATH:

```text
godot --path emulator
```

The device renders to a **170 x 320** SubViewport. The default 2x preview displays that texture at **340 x 640**, using nearest filtering. The 1x option shows the native pixel dimensions. The **1380 x 900** desktop window includes the workbench and a separate drawing area; it does not enter fullscreen. Pixel dimensions are not a simulation of the screen's physical size in inches, which depends on the desktop monitor and OS scaling.

## Pixel Studio

1. Choose the object's display size: 8 x 8, 16 x 16, 24 x 24, **32 x 32 (default)**, **64 x 64**, 16 x 8, or 32 x 8 pixels. New artwork uses **4 x 4 display pixels per drawing cell**, so the default drawing grid is only **8 x 8 cells**. The 64 x 64 preset uses a **16 x 16** drawing grid; smaller presets scale proportionally. Changing size creates a blank animation after confirmation; Undo can recover the previous document.
2. Choose one of eight palette colors. Draw with the left mouse button; erase with the right mouse button or Eraser. Checkerboard means transparent. One click colors an entire logical cell; the preview, device comparison, and PNG export all expand it without smoothing. Desktop preview zoom remains separate: a 32 x 32 object occupies 64 x 64 desktop pixels at 2x.
3. Select frames in the thumbnail strip. Add blank frames, duplicate, or delete. The limit is six frames and the minimum is one; all frames share the same dimensions.
4. Set the total loop duration in milliseconds and press Play. The preview loops independently from game FPS with equal time per frame. Drawing or selecting a frame stops playback. Undo restores drawing strokes and frame edits.
5. Drag the sprite under **DRAG TO DEVICE** onto the device display. The display switches to comparison mode, pausing the game. Drag again to place more independent copies, or draw/open another sprite to compare different sizes.

Comparison objects animate at their saved duration. Drag objects to move them, optionally snapping to the 8-pixel grid relative to the playfield origin (5, 32). Objects stay inside the 170 x 320 display; edge clamping takes priority over snapping. Click an object to select it and use Remove selected object to remove it. Turn off Sprite comparison to return to the game; placed objects remain available for the next comparison. Each drop captures the entire animation as it was at that moment; later drawing does not alter existing copies. Comparison layout is temporary and is not saved with the sprite.

### Saving artwork

- **Save sprite PNG** exports the currently selected frame at native pixel size with transparency.
- **Export frames** asks for a parent folder, creates a new uniquely named subfolder, and saves `frame_01.png` through `frame_06.png` (as many as the animation contains), plus `animation.fidsprite` with editable palette indices, dimensions, and total loop duration. PNGs themselves do not store playback timing.
- **Save editable / Open editable** saves or restores the entire animation as a `.fidsprite` file including its drawing-cell scale. Older files retain their original 1-pixel cells without losing artwork. New documents use 4-pixel cells. Open accepts this format, not arbitrary PNG imports.

Save artwork before closing the app. The editor's document and comparison layout are not automatically persisted. Game Save/Restore buttons apply only to Reactor state, separately from artwork.

## Controls

| Control | Action |
| --- | --- |
| A/D or left/right arrows | Move the analog slider; release to return to center |
| Mouse drag on slider | Set analog position directly; release to return to center |
| Space or Trigger button | Rear trigger |
| L or Lock button | Freeze / resume the device |
| R or Restart button | Start a fresh game |
| Save / Restore | Write a snapshot / recreate the game from that snapshot |
| Show 8 px grid | Overlay the asset grid inside the play area |

Reactor: press the trigger to start, position the white marker in the green zone, then press the trigger to score. Each successful hit chooses a new target and increases difficulty. A miss or expired timer ends the run. Trigger starts another attempt.

Reactor uses the artwork in `Sprites/`: `cursor.png` (16 x 16), `goal.png` (32 x 32), and five native-size copies of `Line.png` (32 x 32) for the track. Images retain their transparency and original pixel sizes. The hit area stays fixed at the full 32-pixel goal width; only the round timer becomes shorter as the score increases. The display shows RACTOR and the score at the top, START before playing, and MISSED after a miss or timeout. Instructions stay in the desktop workbench. Cursor and target centers move over a 128-pixel span so the artwork remains inside the 160-pixel playfield.

Losing window focus automatically locks the game. Unlock explicitly to continue. Lock freezes game time and recreates the game from its in-memory snapshot on resume. Save/Restore separately persists a snapshot under Godot's `user://` application data directory. Saved random generator state preserves subsequent targets. Held trigger input is suppressed across resume until released.

## Add a game

Extend `scripts/game_module.gd`, following `scripts/reactor.gd`:

- `advance(delta, input)` receives game time and device input: slider (-100 to +100), direction (-1/0/+1 with a dead zone), and trigger pressed/released/held flags.
- Draw inside 170 x 320 pixels. Recommended playfield: x=5..164, y=32..319.
- `save_state()` returns versioned plain data; `restore_state(state)` validates and restores it.
- Emit `haptic` with a named feedback event; the shell displays the latest events.
- `diagnostics()` supplies development telemetry.
- Keep keyboard/mouse access and desktop UI out of game modules.

Register a replacement game in the shell's `_new_game` method. A multi-game launcher, motion controls, replay recording, and firmware export are not implemented yet. This tool does not emulate ESP32 performance or the physical feel of the controls.

The display uses Godot's [SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html) with a separate texture preview so desktop scaling does not change the game's pixel dimensions.

## Verification

```text
godot --headless --path emulator --editor --import --quit
godot --headless --path emulator --script res://tests/smoke.gd
godot --headless --path emulator --script res://tests/studio.gd
```
