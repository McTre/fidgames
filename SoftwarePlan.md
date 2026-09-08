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

## Game Development Principles

These are shared defaults for building consistent, reusable game objects. Exceptions are allowed when they improve gameplay or readability.

### Clear and Discoverable Gameplay

- Each game has one clear core idea and an unambiguous goal.
- Players should discover how to play by looking at the screen and trying the controls, without needing a tutorial or written instructions.
- Make the connection between an input and its effect immediate and consistent.
- Use object appearance, movement, and visual or haptic feedback to communicate what can be controlled, what to aim for, and why an attempt succeeded or failed.
- Avoid unnecessary instruction text, hidden rules, complicated exceptions, and details that players must memorize before they can enjoy the game.
- Keep on-screen text to essential information, such as the game name, score, and short state labels like START or MISSED.
- Build challenge through timing, precision, and mastery of simple rules rather than adding confusing mechanics.
- Test with someone who has not seen the game before. If they need an explanation to understand the basic interaction, simplify the design or improve its feedback first.

### Display and Play Area

- Target portrait resolution: 170 x 320 pixels for the planned T-Display-S3.
- Default play area width: 160 pixels, with 5-pixel margins on each side.
- Optionally reserve 32 pixels at the top for scores and status.
- With that status area, the play area is 160 x 288 pixels: 10 x 18 cells of 16 x 16 pixels.
- Grid-based games can use this layout directly; free-moving games do not need to snap movement to a grid.

Display reference: [LILYGO T-Display-S3 documentation](https://wiki.lilygo.cc/products/t-display-series/t-display-s3/).

### Sprite Sizes and Reusable Objects

- Base asset grid: 8 x 8 pixels.
- Default sprite display size: 32 x 32 pixels, drawn on an 8 x 8 cell canvas.
- Each drawing cell expands to a solid 4 x 4 block of display pixels using nearest-neighbor scaling.
- Distinguish drawing resolution from display size: the default sprite contains 64 editable cells, while occupying 32 x 32 pixels on the device.
- PNG exports and comparison objects use the expanded display size. The desktop's 1x/2x preview zoom is independent of this artwork scale.
- Prefer widths and heights that are multiples of 8 pixels.
- Rectangular sprites are supported; objects do not need to be square.

| Sprite size | Typical use |
| --- | --- |
| 8 x 8 px | Small collectibles, projectiles, terrain pieces |
| 16 x 16 px | Standard characters, obstacles, Snake segments |
| 24 x 24 px | More detailed player characters and important targets |
| 32 x 32 px | Default characters and objects, drawn with an 8 x 8 cell grid |
| 64 x 64 px | Large characters and objects, drawn with a 16 x 16 cell grid |
| 16 x 8 or 32 x 8 px | Platforms, bars, stackable blocks |

Build larger objects from reusable pieces where useful. For example, a platform can combine left and right end pieces with a repeating middle section.

### Animation Timing

Use these ranges as starting points and tune them to the game's feel. Frame counts refer to sprite images, not rendered game frames.

| Animation | Frame count | Total duration |
| --- | --- | --- |
| Idle loop | 2-4 | 400-800 ms per cycle |
| Movement loop | 4-6 | 300-600 ms per cycle |
| Button response or hit reaction | 2-3 | 100-200 ms |
| Collection or small destruction effect | 4-6 | 200-400 ms |

- Define animation timing in elapsed game time, independently of rendering frame rate.
- Gameplay can update at 60 FPS while sprite animation changes images at a lower rate.
- Respond to controls immediately; do not delay an action until its feedback animation finishes.
- Keep the same canvas size and anchor point across an animation's frames to avoid unintended visual jumps.

### Readability and Collision

- Render pixel art without smoothing filters; use integer scaling for enlarged previews.
- Use clear silhouettes and contrast for important gameplay objects.
- Avoid relying on tiny details in 8 x 8 sprites.
- Define collision shapes separately from sprite artwork.
- Check readability on the physical display as well as in the enlarged Godot preview.

### Save State Philosophy

Every game supports:

- Instant pause
- Instant resume
- State restoration after lock

The player should never lose progress because the device was locked.

### Input Model

Primary controls:

- Slider position (-100 to +100)
- Slider direction
- Rear button
- Lock button

Secondary:

- Shake detection
- Tilt detection

### Haptics

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
