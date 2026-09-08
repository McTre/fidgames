# FidGames Software Plan

## Platform

- ESP32-S3
- Arduino framework or ESP-IDF
- 60 FPS target where practical

## Main Architecture

### System Layer

Responsible for:
- Power management
- Sleep and wake
- Save states
- Input handling
- Haptic control

### Launcher

Features:
- Game selection
- Statistics
- High scores
- Achievements

### Game Engine

Common services:
- Input abstraction
- Rendering
- Save state API
- Haptics API
- Timer API

## Save State Philosophy

Every game supports:

- Instant pause
- Instant resume
- State restoration after lock

The player should never lose progress because the device was locked.

## Input Model

Primary controls:

- Slider position (-100 to +100)
- Slider direction
- Rear button
- Lock button

Secondary:

- Shake detection
- Tilt detection

## Haptics

Event-driven feedback:

- Score
- Combo
- Collision
- Warning
- High score

No mandatory audio.

## Initial Games

### Endless Snake

- Left
- Right
- Rear button for special action

### SkyStack

- Move block
- Drop block
- Endless tower building

### Reactor

- Fast reactions
- Slider accuracy

### Tunnel Run

- Dodge obstacles
- Increasing speed

## Statistics

Track:

- Total play time
- High scores
- Number of launches
- Fidget usage metrics
