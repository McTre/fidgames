# FidGames Lab

FidGames Lab is the development environment for designing, prototyping, testing, and preparing FidGames games for the physical ESP32-S3 device.

The Lab supports two game-development paths:

1. Fast GDScript prototypes for experimentation.
2. Portable C++ games built on FidEngine for desktop and ESP32.

The long-term goal is that gameplay can be designed without thinking about low-level hardware details.

## Core Components

- **FidGames Lab**: Godot-based desktop development environment.
- **FidEngine**: Portable C++ game API/runtime shared by desktop and ESP32.
- **FidGames Firmware**: ESP32-S3 hardware host and platform backend.
- **Agent-Workflow.md**: Optional workflow for any AI coding agent to convert, validate, test, and build games.

## Development Philosophy

GDScript is the preferred rapid-prototyping language.

C++/FidEngine is the preferred production format when the same game code needs to run on both desktop and ESP32.

Both formats are valid and supported. A game does not need to be converted to C++ until there is a reason to run it on hardware.

## Current Direction

The current Godot prototype remains useful as a starting point, but future game architecture should keep gameplay logic, assets, and platform integration clearly separated.

See:

- [FidEnginePlan.md](FidEnginePlan.md)
- [Agent-Workflow.md](Agent-Workflow.md)
- [Project-Structure.md](Project-Structure.md)
- [Notes.md](Notes.md)
