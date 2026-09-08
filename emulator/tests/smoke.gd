extends SceneTree

const Shell = preload("res://scripts/device_shell.gd")
const Reactor = preload("res://scripts/reactor.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var shell := Shell.new()
	root.add_child(shell)
	shell.set_process(false)
	check(shell.screen.size == Vector2i(170, 320), "Native resolution must be 170 x 320")
	check(shell.preview.size == Vector2(340, 640), "Default preview must be 2x")
	shell._set_scale(1)
	check(shell.screen.size == Vector2i(170, 320), "1x must preserve native resolution")
	check(shell.preview.size == Vector2(170, 320), "1x preview size")
	shell._set_scale(2)
	# The headless display server has no real window mode to inspect.
	if DisplayServer.get_name() != "headless":
		check(root.mode == Window.MODE_WINDOWED, "Window must not be fullscreen")
	shell.game.advance(0.0, {"trigger_pressed": true})
	shell.game.advance(0.1, {"slider": shell.game.target, "trigger_pressed": true})
	check(shell.game.score == 1, "Accurate trigger must score")
	var before: Dictionary = shell.game.save_state()
	var restored := Reactor.new()
	check(restored.restore_state(before), "Snapshot should restore")
	check(restored.save_state() == before, "Snapshot should round-trip exactly")
	var hit := {"slider": shell.game.target, "trigger_pressed": true}
	shell.game.advance(0.1, hit)
	restored.advance(0.1, hit)
	check(restored.save_state() == shell.game.save_state(), "Restored RNG must produce same next target")
	restored.free()
	shell.toggle_lock()
	var locked_state: Dictionary = shell.game.save_state()
	shell._process(20.0)
	check(shell.game.save_state() == locked_state, "Lock must freeze timers and game state")
	shell.toggle_lock()
	check(shell.game.save_state() == locked_state, "Unlock must restore game state")
	check(shell.suppress_trigger, "Unlock must suppress held trigger")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	var score_before: int = shell.game.score
	shell._process(0.0)
	check(shell.game.score == score_before and shell.game.phase == "playing", "Held trigger after unlock must not fire")
	key = InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = false
	Input.parse_input_event(key)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tmp"))
	shell.save_path = "res://.tmp/smoke-state.save"
	var saved: Dictionary = shell.game.save_state()
	shell.save_game()
	shell.restart_game()
	shell.restore_game()
	check(shell.game.save_state() == saved, "Disk snapshot should recreate the game exactly")
	shell.slider_value = 70.0
	shell._process(0.1)
	check(shell.slider_value < 70.0 and shell.slider_value > 0, "Slider must return progressively to center")
	var invalid := locked_state.duplicate(true)
	invalid.version = 99
	check(not shell._new_game(invalid), "Unknown save version must be rejected")
	shell.game.advance(10.0, {})
	check(shell.game.phase == "over", "Timer expiration should end the run")
	if "--capture" in OS.get_cmdline_user_args():
		shell.restart_game()
		shell._process(0.0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.tmp"))
		check(root.get_texture().get_image().save_png("res://.tmp/emulator-preview.png") == OK, "Preview capture should save")
	root.remove_child(shell)
	shell.free()
	print("FidGames smoke checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
