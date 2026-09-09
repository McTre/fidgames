# FidGames Lab Project Structure

## Purpose

Keep the repository predictable so humans and coding agents can find every part of a game without guessing.

This is a target structure and can be refined during the first FidEngine implementation.

## Proposed Structure

```text
FidGames-Lab/
├─ README.md
├─ FidEnginePlan.md
├─ Agent-Workflow.md
├─ Project-Structure.md
├─ Notes.md
│
├─ engine/
│  ├─ include/
│  ├─ src/
│  └─ tests/
│
├─ lab/
│  └─ Godot desktop application
│
├─ firmware/
│  └─ ESP32-S3 platform backend
│
└─ games/
   ├─ reactor/
   │  ├─ prototype/
   │  │  └─ reactor.gd
   │  ├─ fidengine/
   │  │  ├─ reactor.cpp
   │  │  └─ reactor.h
   │  ├─ assets/
   │  ├─ tests/
   │  └─ game.json
   └─ another-game/
      └─ ...
```

## Game Directory Rules

Each game gets one directory under `games/`. A game may contain both a GDScript prototype and a FidEngine implementation.

### prototype/

Contains the rapid-prototyping version. GDScript is initially preferred. Prototype code may use Godot directly and is not expected to run on ESP32.

### fidengine/

Contains portable production game code.

Rules:

- C++
- depends only on FidEngine
- no direct Godot dependencies
- no direct ESP32 dependencies

### assets/

Contains game-owned source assets. Avoid storing separate desktop and ESP32 copies unless technically necessary.

### tests/

Contains game-specific automated tests.

### game.json

Planned game manifest. Possible future fields include game ID, display name, prototype entry point, FidEngine entry point, asset list, version, save-state version, and supported inputs.

The manifest format is not yet frozen.

## Migration Note

The repository currently contains an existing `emulator/` Godot prototype.

Do not delete or move it until the new FidGames Lab structure is proven. Reactor should be the first migration target. Existing Lab functionality can then be migrated incrementally.
