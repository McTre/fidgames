extends "res://scripts/game_module.gd"
## All coordinates are native display pixels. No desktop input or wall clock here.

const INK := Color("cde5e5")
const MINT := Color("77f2bd")
const RED := Color("ff806d")
const CURSOR_SPRITE = preload("res://Sprites/cursor.png")
const GOAL_SPRITE = preload("res://Sprites/goal.png")
const LINE_SPRITE = preload("res://Sprites/Line.png")
# Leave half the 32 px goal at each end so every sprite stays in the playfield.
const TRACK_LEFT := 21.0
const TRACK_SPAN := 128.0
const HIT_TOLERANCE := 25.0 # 16 display pixels on either side: the full 32 px goal.
var rng := RandomNumberGenerator.new()
var score := 0
var target := 0.0
var tolerance := HIT_TOLERANCE
var remaining := 3.0
var round_duration := 3.0
var phase := "ready"
var slider := 0.0
var feedback := "ALIGN. THEN FIRE."
var flash := 0.0
var game_time := 0.0

func _init() -> void:
	rng.randomize()
	_next_target()

func _next_target() -> void:
	tolerance = HIT_TOLERANCE
	target = rng.randf_range(-100.0 + tolerance, 100.0 - tolerance)
	round_duration = maxf(1.0, 3.0 - score * 0.06)
	remaining = round_duration

func advance(delta: float, input: Dictionary) -> void:
	slider = float(input.get("slider", 0.0))
	game_time += delta
	flash = maxf(0.0, flash - delta)
	var pressed: bool = input.get("trigger_pressed", false)
	if phase == "ready":
		if pressed:
			phase = "playing"
			feedback = "FIND THE GREEN ZONE"
	elif phase == "over":
		if pressed:
			score = 0
			_next_target()
			phase = "playing"
			feedback = "FIND THE GREEN ZONE"
	else:
		remaining = maxf(0.0, remaining - delta)
		if remaining <= 0.0:
			_fail("TIME UP")
		elif pressed:
			if absf(slider - target) <= tolerance:
				score += 1
				feedback = "GOOD HIT +1"
				flash = 0.25
				haptic.emit("combo" if score % 5 == 0 else "score")
				_next_target()
			else:
				_fail("MISSED")
	queue_redraw()

func _fail(message: String) -> void:
	phase = "over"
	feedback = message
	flash = 0.3
	haptic.emit("collision")

func save_state() -> Dictionary:
	return {"version": 1, "game": "reactor", "score": score, "target": target,
		"tolerance": tolerance, "remaining": remaining, "round_duration": round_duration,
		"phase": phase, "slider": slider, "feedback": feedback, "flash": flash,
		"game_time": game_time, "rng_state": str(rng.state)}

func restore_state(state: Dictionary) -> bool:
	var required := ["version", "game", "score", "target", "tolerance", "remaining",
		"round_duration", "phase", "slider", "feedback", "flash", "game_time", "rng_state"]
	for key in required:
		if not state.has(key):
			return false
	if state.version != 1 or state.game != "reactor":
		return false
	if state.phase not in ["ready", "playing", "over"]:
		return false
	if not str(state.rng_state).is_valid_int():
		return false
	for key in ["score", "target", "tolerance", "remaining", "round_duration", "slider", "flash", "game_time"]:
		if not (state[key] is float or state[key] is int) or not is_finite(float(state[key])):
			return false
	if state.score < 0 or state.round_duration <= 0 or state.remaining < 0:
		return false
	if absf(state.target) > 100 or absf(state.slider) > 100 or state.tolerance <= 0:
		return false
	score = int(state.score)
	target = float(state.target)
	tolerance = HIT_TOLERANCE
	remaining = float(state.remaining)
	round_duration = float(state.round_duration)
	phase = str(state.phase)
	slider = float(state.slider)
	feedback = str(state.feedback)
	flash = float(state.flash)
	game_time = float(state.game_time)
	rng.state = int(state.rng_state)
	queue_redraw()
	return true

func diagnostics() -> String:
	return "State   %s\nScore   %d\nTime    %.2f s\nTarget  %+.0f" % [phase, score, remaining, target]

func _text(at: Vector2, value: String, font_size: int = 10, color: Color = INK) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 170, 320), Color("101e24"))
	draw_rect(Rect2(5, 5, 160, 23), Color("20363e"))
	_text(Vector2(11, 21), "RACTOR", 12, MINT)
	_text(Vector2(118, 21), "%03d" % score, 12)
	if device_locked:
		return
	if show_grid:
		for x in range(5, 166, 8):
			draw_line(Vector2(x, 32), Vector2(x, 320), Color(0.3, 0.6, 0.6, 0.15))
		for y in range(32, 321, 8):
			draw_line(Vector2(5, y), Vector2(165, y), Color(0.3, 0.6, 0.6, 0.15))
	var target_x := TRACK_LEFT + (target + 100.0) * TRACK_SPAN / 200.0
	var marker_x := TRACK_LEFT + (slider + 100.0) * TRACK_SPAN / 200.0
	for i in 5:
		draw_texture(LINE_SPRITE, Vector2(5 + i * 32, 145))
	draw_texture(GOAL_SPRITE, Vector2(roundf(target_x) - 16, 145))
	draw_texture(CURSOR_SPRITE, Vector2(roundf(marker_x) - 8, 153))
	draw_rect(Rect2(5, 216, 160, 4), Color("29434b"))
	draw_rect(Rect2(5, 216, 160 * remaining / round_duration, 4), RED if remaining < 0.75 else MINT)
	if phase != "playing":
		var caption := "MISSED" if phase == "over" else "START"
		var width := ThemeDB.fallback_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_text(Vector2(roundf((170 - width) / 2), 300), caption, 14, RED if phase == "over" else MINT)
	if flash > 0:
		draw_rect(Rect2(5, 32, 160, 284), RED if phase == "over" else MINT, false, 1)
