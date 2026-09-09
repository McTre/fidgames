# FidEngine Plan

## Purpose

FidEngine is the portable game layer used by FidGames games.

Its main purpose is to allow the same C++ game code to run inside FidGames Lab on desktop and on the ESP32-S3 hardware. The game should not need to know which platform it is running on.

## Design Goal

A FidEngine game must be written against a small, stable API instead of Godot APIs or ESP32-specific APIs.

Portable gameplay code must not directly depend on Godot runtime classes, Arduino functions, ESP-IDF drivers, GPIO APIs, ST7789 APIs, motion-sensor APIs, or haptic-driver APIs. Those belong in platform adapters.

## Initial API Areas

The first FidEngine API should stay intentionally small:

- FidGame lifecycle
- FidInput
- FidRenderer
- FidSprites / assets
- FidHaptics
- FidTime
- FidRandom
- FidSave
- FidStats

The exact API is not frozen yet. It should be defined primarily by the needs of the first real game rather than by guessing future requirements.

## Example Shape

```cpp
class FidGame {
public:
    virtual void init(FidContext& ctx) = 0;
    virtual void update(float dt, const FidInput& input) = 0;
    virtual void draw(FidRenderer& renderer) = 0;
    virtual void save(FidSaveWriter& out) = 0;
    virtual void load(FidSaveReader& in) = 0;
};
```

## Input Model

The engine exposes normalized logical inputs.

```cpp
struct FidInput {
    int slider;              // -100 ... +100
    bool trigger_pressed;
    bool trigger_down;
    bool shake;
    float tilt_x;
    float tilt_y;
};
```

Desktop and ESP32 backends produce the same logical input structure.

## Rendering

Games render through FidRenderer rather than platform-specific drawing APIs.

```cpp
renderer.clear();
renderer.sprite("player", x, y);
renderer.text(5, 5, score);
```

The desktop backend renders through Godot. The ESP32 backend renders through the physical display driver.

## Haptics

Games emit logical haptic events rather than calling hardware directly.

Examples include score, combo, collision, warning, and high-score events.

FidGames Lab can visualize these events while the ESP32 backend drives the physical haptic actuator.

## Save State

Save/resume is a core FidGames feature and belongs at the FidEngine level.

A game must serialize enough state to resume from the same gameplay situation after locking. State may include score, positions, timers, current mode, RNG state, and temporary gameplay state.

## Assets

Games refer to logical asset identifiers instead of platform-specific files.

```cpp
renderer.sprite("goal", x, y);
```

The Lab may use desktop-friendly source assets while the ESP32 build pipeline converts the same assets into a compact target format.

## Desktop Backend

The desktop FidEngine backend runs inside FidGames Lab and is responsible for translating Lab input into FidInput, rendering FidRenderer commands through Godot, simulating haptics, save/load storage, timing, RNG, and debug information.

## ESP32 Backend

The ESP32 backend provides the same API using real hardware: magnetic slider input, buttons, motion input, display, haptics, persistent storage, timing, and power/lock behavior.

## First Validation Target

Reactor should be the first FidEngine game.

Success criteria:

1. Reactor runs as C++ through FidEngine inside FidGames Lab.
2. The same Reactor game source is compiled for ESP32.
3. No gameplay source changes are required between desktop and ESP32.
4. Save/resume behavior is equivalent.
5. Input and haptic behavior use only FidEngine APIs.

## Non-Goal

FidEngine is not an ESP32 emulator. The goal is shared portable game code with platform-specific backends.
