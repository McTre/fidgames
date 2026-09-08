# FidGames Game Development Tool Plan

## Purpose

Build a Godot-based desktop tool for developing and testing FidGames game ideas before implementing them on the physical device.

The tool simulates the player-facing behavior of FidGames: its display, controls, game lifecycle, and feedback events. It is not an ESP32 emulator and does not run device firmware.

Related plans:

- [Master Plan](MasterPlan.md)
- [Hardware Plan](HardwarePlan.md)
- [Software Plan](SoftwarePlan.md)

## Goals

- Quickly prototype short, replayable games.
- Test whether games work with the planned physical controls.
- Preview readability on a small portrait display.
- Test instant lock and resume without losing game progress.
- Tune difficulty, controls, and haptic events during development.
- Keep game rules and state easy to reimplement in device firmware.

## Platform

- Godot desktop application.
- Windows as the initial development platform.
- Implemented starting point: Godot 4.7.2 stable with GDScript and 2D scenes.
- Target 60 FPS where practical, consistent with the software plan.

## Device Preview

- A portrait game viewport surrounded by a simple device outline.
- Slider below the display, plus visible trigger and lock controls.
- Fixed 170 x 320 logical display resolution for the planned T-Display-S3.
- Integer scaling for inspecting pixel readability at different window sizes.
- Development panels outside the device display so they do not consume game screen space.

## Input Simulation

All games receive input through a shared interface rather than reading keyboard or mouse events directly.

### Magnetic Analog Slider

- Expose position from -100 to +100, with 0 as the center.
- Expose left, center, and right regions with a configurable dead zone.
- Mouse dragging provides analog position control.
- Releasing the slider returns it to center with a tunable return speed.
- A/D or left/right arrow keys provide a convenient keyboard approximation.
- Optional gamepad axis support can follow later.
- Show the current value in the development panel.

Keyboard input is useful for testing game rules, but the feel of the magnetic mechanism must be evaluated on physical hardware.

### Buttons

- Space simulates the rear trigger.
- L toggles device lock.
- Provide clickable equivalents in the device preview.
- Expose trigger press, release, and held state.
- Handle lock at the system layer so every game behaves consistently.

### Motion

- Add manual tilt controls and a shake event button in a later phase.
- Keep motion optional and secondary to the slider and trigger.

## Architecture

### Device Shell

Owns the preview, input mapping, launcher, lock state, and development panels.

### Shared Game Services

- Input state and button events.
- Game time that stops while locked or paused.
- Rendering inside the device viewport.
- Save and restore operations.
- Named haptic events.
- High score and statistics storage.

### Game Modules

Each game provides initialization, update, rendering, and state serialization through a common contract. Exact method signatures will be defined during the first prototype.

Keep gameplay rules separate from Godot UI and device simulation. Save data should use explicit values rather than references to scene nodes.

Godot scripts and scenes are desktop prototypes. Firmware implementation remains a separate step; automatic export to ESP32 is not part of this plan.

## Lock and Resume

- Lock immediately stops gameplay updates and game time.
- Save enough state to restore the same gameplay situation, including timers and random generator state where relevant.
- Unlock restores the game without advancing time for the locked interval.
- Clear transient input events so unlocking cannot accidentally trigger an action.
- Provide a separate development command to recreate a game from its saved state, verifying restoration rather than only hiding a paused scene.
- Version saved data so incompatible states can be detected.

## Haptic Preview

- Use the software plan's events: score, combo, collision, warning, and high score.
- Show events as a brief visual indicator and in an event log.
- Allow event intensity and duration to be inspected where specified.
- Keep audio optional.

Visual feedback validates when an event occurs. Actual vibration feel requires the physical actuator.

## Development Controls

Initial controls:

- Select and restart a game.
- Lock and unlock the simulated device.
- Inspect slider position and trigger state.
- Inspect score, game state, and haptic events.
- Save and restore the current game.

Later additions:

- Pause and single-step simulation.
- Adjust game parameters without changing source code.
- Set a random seed for reproducible sessions.
- Record and replay inputs with simulation timestamps.
- Export tuning values and game specifications for firmware implementation.

## First Implementation

Use Reactor as the proposed first game because it directly exercises slider accuracy, reaction timing, scoring, and feedback.

1. Create the Godot project and device preview.
2. Implement the slider, trigger, and lock input interface.
3. Define the shared game contract and implement a minimal Reactor prototype.
4. Add haptic event visualization and score display.
5. Implement state saving and restoration.
6. Add a basic launcher as more games become available.

### Completion Criteria

- Reactor is playable using only the simulated slider and trigger.
- Gameplay stays within the configured device viewport.
- Lock freezes gameplay, and unlock continues from the same state.
- Recreating a game from saved data preserves its score, timers, and gameplay state.
- Haptic events are visible during the relevant actions.
- A second game can use the shared services without duplicating device controls.

## Limits and Open Decisions

- Recheck display settings if the board variant changes.
- Tune slider dead zone and centering behavior against a physical prototype.
- Decide the firmware-side game API before attempting shared game code.
- Measure performance, memory usage, power consumption, and wake latency on actual hardware; desktop behavior does not validate these.

## Current Prototype

The first implementation is in [emulator/project.godot](emulator/project.godot), with usage instructions in [emulator/README.md](emulator/README.md).

- Separate desktop window with a native 170 x 320 game viewport.
- Default 2x preview (340 x 640); optional 1x preview, no fullscreen.
- Keyboard and mouse slider controls, trigger, and system lock.
- Playable Reactor prototype with increasing difficulty and haptic event log.
- Lock snapshots and disk save/restore, including random generator state.
- Shared game module contract and optional 8-pixel grid overlay.
- A 1380 x 900 development window with a separate pixel art studio, while the device stays at 1x or 2x.
- Preset sprite sizes, an eight-color palette plus transparency, pencil/eraser, and undo.
- Default sprite size is 32 x 32 display pixels on an 8 x 8 drawing grid. Each cell expands to 4 x 4 display pixels in previews, comparisons, and exported PNGs. Legacy artwork retains its original resolution.
- One to six animation frames with duplication, deletion, and timed looping playback.
- Native-size sprite PNG export, animation frame PNG export, and editable `.fidsprite` save/open including timing.
- Drag-and-drop comparison objects on the device display, independent animated copies, optional 8-pixel snapping, and selection/removal. Comparison pauses the game; the layout is currently temporary.
- Automated checks cover resolution, scoring, timers, centering, lock/resume, input suppression, and state restoration.

The launcher, motion simulation, tuning panel, and additional games remain future work. The shared module contract is implemented, but reuse by a second game has not yet been validated.
