# FidGames Agent Workflow

## Purpose

This document defines an optional workflow for AI coding agents working on FidGames games. It is intentionally separate from global agent instruction files.

The user may use any repository-aware coding agent. The agent should follow this workflow when explicitly asked to do so.

## Required Reading

Before modifying or converting a game, read:

1. `FidEnginePlan.md`
2. `Project-Structure.md`
3. the target game's files
4. the target game's tests
5. the current FidEngine headers and documentation

Do not assume the FidEngine API from memory. Read the current repository version.

## Workflow: GDScript Prototype to FidEngine

1. Inspect the full prototype before editing.
2. Identify game states, input behavior, timing, rendering, scoring, random behavior, haptic events, save-state requirements, and assets.
3. Preserve gameplay behavior rather than performing a literal syntax translation.
4. Implement the game using only FidEngine APIs.
5. Do not introduce Godot-specific dependencies into portable game code.
6. Do not introduce ESP32-specific dependencies into portable game code.
7. Reuse existing shared assets.
8. Add or update tests for important behavior.
9. Build the desktop FidEngine version.
10. Compare the result against the prototype.
11. Fix unintended behavioral differences.
12. Build the ESP32 target when requested.

## Workflow: New FidEngine Game

1. Use the standard game directory structure.
2. Reuse FidEngine services instead of creating platform-specific helpers.
3. Keep game state explicit and serializable.
4. Keep rendering and game logic reasonably separated.
5. Add basic automated tests.
6. Verify the game runs in FidGames Lab before preparing an ESP32 build.

## Workflow: Modify Existing FidEngine Game

1. Read the existing game and tests.
2. Preserve the FidEngine portability boundary.
3. Avoid expanding FidEngine unless the feature genuinely needs a reusable engine capability.
4. If FidEngine changes, update its documentation and tests.
5. Validate desktop behavior after changes.

## API Compliance Check

Portable game code must not directly depend on Godot runtime types, Arduino APIs, ESP-IDF APIs, GPIO functions, display drivers, sensor drivers, or haptic drivers. Platform-specific code belongs in platform adapters.

## Build and Test

When asked to validate a game:

1. Run relevant tests.
2. Build the desktop target.
3. Run the game in FidGames Lab when practical.
4. Build the ESP32 target when requested.
5. Report build results, test results, warnings, memory/flash usage when available, and platform-specific differences.

## Build and Upload to ESP32

When hardware tooling is available:

1. Build ESP32 firmware with the selected FidEngine game.
2. Verify the configured board and upload target.
3. Upload using the repository's configured tooling.
4. Open the serial monitor when useful.
5. Report the result.

Do not silently change board configuration or device-specific settings.

## General Rules

- Prefer simple game code.
- Keep gameplay portable.
- Keep game state serializable.
- Use existing engine services before adding abstractions.
- Keep assets in their defined locations.
- Keep tests in the designated test location.
- Do not duplicate platform code inside games.
- Do not mechanically translate GDScript line-by-line when a clearer FidEngine implementation preserves the same behavior.
