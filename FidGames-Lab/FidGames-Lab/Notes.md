# FidGames Lab Notes

## Design Decisions

### Keep both GDScript and C++

GDScript remains valuable for very fast gameplay prototyping.

C++/FidEngine is used when a game needs to run on both desktop and ESP32.

A game may exist in both forms.

### AI conversion instead of a hard transpiler

Do not build a custom GDScript-to-C++ transpiler unless a future need clearly justifies it.

Modern coding agents can perform semantic conversion from a GDScript prototype into a FidEngine implementation. Conversion should preserve behavior, not syntax.

### No built-in AI dependency in FidGames Lab

Do not tightly integrate a specific AI provider into the Lab.

Instead:

- keep repository structure predictable
- keep FidEngine well documented
- document the optional agent workflow in `Agent-Workflow.md`

This lets the user choose any coding agent.

### FidGames Lab should become a practical SDK

Long-term desktop workflow may include:

- open a GDScript game
- open a FidEngine C++ game
- run a game in Lab
- inspect input
- inspect save state
- inspect haptic events
- edit assets
- run tests
- build desktop target
- build ESP32 target
- upload to device
- open serial monitor

These functions should use normal local build tools where practical.

### Hardware abstraction is a core requirement

Game code should think in terms of slider position, trigger state, logical motion input, sprites, text, haptic events, game time, random numbers, and save state.

Game code should not need to think about GPIO numbers, Hall-sensor calibration, display commands, motion-sensor registers, haptic-driver commands, or flash-storage details.

### Reactor is the architecture test

Reactor is the first candidate for proving the GDScript prototype workflow, FidEngine C++ implementation, desktop backend, ESP32 backend, shared assets, save/resume, and automated tests.

The architecture should be proven before FidEngine is expanded significantly.

## Open Questions

- Exact FidEngine API v0.1
- CMake/build-system layout
- Godot integration method for C++ games
- GDExtension versus a thinner native bridge
- asset source format
- generated asset format for ESP32
- game manifest format
- desktop/ESP32 RNG equivalence requirements
- save-state binary format
- how Lab selects a FidEngine game for ESP32 build
- how much ESP32 build tooling belongs inside the Godot UI
