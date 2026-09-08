extends SceneTree
const Shell = preload("res://scripts/device_shell.gd")
const Document = preload("res://scripts/sprite_document.gd")
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
	var studio: Control = shell.studio
	var doc: RefCounted = studio.document
	check(doc.dimensions == Vector2i(32, 32), "Default sprite should occupy 32 x 32 display pixels")
	check(doc.grid_size() == Vector2i(8, 8), "Default drawing grid should have only 8 x 8 cells")
	check(doc.PALETTE.size() == 8, "Palette should have eight colors")
	var down := InputEventMouseButton.new()
	down.position = Vector2(11, 11)
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	studio.canvas._gui_input(down)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(341, 11)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	studio.canvas._gui_input(motion)
	for x in 8:
		check(doc.frames[0][x] == 2, "Continuous pencil stroke must have no gaps")
	studio.undo()
	check(doc.frames[0][0] == -1, "Undo restores transparency")
	for y in range(1, 7):
		for x in range(1, 7):
			if Vector2(x - 3.5, y - 3.5).length() < 3:
				doc.paint(Vector2i(x, y), 2)
	for x in range(2, 6):
		doc.paint(Vector2i(x, 3), 0)
	doc.paint(Vector2i(2, 3), 1)
	var original: PackedInt32Array = doc.frames[0].duplicate()
	doc.add_frame(true)
	doc.paint(Vector2i(2, 3), 5)
	check(doc.frames[0] == original, "Duplicate frame must not share mutable pixels")
	for i in 4:
		check(doc.add_frame(true), "Frames up to six are allowed")
	check(not doc.add_frame(true) and doc.frames.size() == 6, "Seventh frame must be refused")
	studio.refresh()
	check(studio.add_button.disabled and studio.copy_button.disabled, "UI must enforce six-frame limit")
	var state: Dictionary = doc.serialize()
	var loaded := Document.new()
	check(loaded.deserialize(JSON.parse_string(JSON.stringify(state))), "Editable document should reopen")
	check(loaded.serialize() == state, "Editable document preserves pixels, dimensions and timing")
	var invalid := state.duplicate(true)
	invalid.frames.append(invalid.frames[0])
	check(not loaded.deserialize(invalid), "Invalid seven-frame file must be rejected")
	var temp_path := ProjectSettings.globalize_path("res://.tmp")
	DirAccess.make_dir_recursive_absolute(temp_path)
	var exported: String = doc.export_animation(temp_path)
	check(not exported.is_empty(), "Animation export should succeed")
	for i in 6:
		var image := Image.load_from_file(exported.path_join("frame_%02d.png" % (i + 1)))
		check(image != null and image.get_size() == Vector2i(32, 32), "Exported PNG must have full display size")
		for y in 32:
			for x in 32:
				check(image.get_pixel(x, y) == image.get_pixel((x / 4) * 4, (y / 4) * 4), "Every drawing cell must export as a uniform 4 x 4 block")
		check(image.get_pixel(0, 0).a == 0, "Exported PNG must preserve transparency")
		check(image.get_data() == doc.make_image(i).get_data(), "Exported frame must match drawn pixels")
	check(FileAccess.file_exists(exported.path_join("animation.fidsprite")), "Animation export must preserve editable timing data")
	studio.playing = true
	studio.clock = 0
	studio._process(0.1)
	check(studio.shown_frame == 1, "Playback must advance based on loop duration")
	studio.stop()
	shell.comparison._drop_data(Vector2(100, 200), {"fid_sprite": state})
	check(shell.comparison.comparing and shell.comparison.objects.size() == 1, "Dropping must enable comparison and add a sprite")
	var position: Vector2 = shell.comparison.objects[0].position
	check(fmod(position.x - 5, 8) == 0 and fmod(position.y - 32, 8) == 0, "Placement must snap to the playfield grid")
	var game_before: Dictionary = shell.game.save_state()
	shell._process(5)
	check(game_before == shell.game.save_state(), "Comparison mode pauses game simulation")
	shell.comparison._place(Vector2(999, 999))
	check(shell.comparison.objects[0].position == Vector2(138, 288), "Objects must remain inside the device display")
	shell.comparison._place(Vector2(53, 96))
	shell._set_scale(1)
	check(shell.comparison.objects[0].dimensions == Vector2i(32, 32), "Preview zoom must not change sprite dimensions")
	shell._set_scale(2)
	studio.timing.get_line_edit().grab_focus()
	check(not shell._keyboard_allowed(), "Typing in editor fields must not control the game")
	studio.timing.get_line_edit().release_focus()
	var block := Document.new()
	block.reset(Vector2i(32, 8))
	for y in block.grid_size().y:
		for x in block.grid_size().x:
			block.paint(Vector2i(x, y), 6 if y == 0 else 7)
	var legacy_pixels: Array = []
	legacy_pixels.resize(256)
	legacy_pixels.fill(-1)
	legacy_pixels[0] = 2
	var legacy := Document.new()
	check(legacy.deserialize({"version": 1, "width": 16, "height": 16, "duration_ms": 400, "frames": [legacy_pixels]}), "Old editable sprites must still load")
	check(legacy.pixel_scale == 1 and legacy.make_image(0).get_pixel(1, 0).a == 0, "Old artwork must retain its original pixel density")
	shell.comparison.add_object(block.serialize(), Vector2(85, 144))
	check(shell.comparison.objects.size() == 2, "Multiple sprite sizes should coexist")
	doc.paint(Vector2i(0, 0), 4)
	check(shell.comparison.objects[0].textures[0].get_image().get_pixel(0, 0).a == 0, "Placed objects must be independent snapshots")
	if "--capture" in OS.get_cmdline_user_args():
		studio.document.current = 0
		studio.refresh()
		await process_frame
		await process_frame
		# Exercise Godot's actual GUI drag routing, not just the drop handler.
		var source: Vector2 = studio.thumbnail.global_position + studio.thumbnail.size / 2
		var destination: Vector2 = shell.comparison.global_position + Vector2(190, 430)
		var drag_down := InputEventMouseButton.new()
		drag_down.button_index = MOUSE_BUTTON_LEFT
		drag_down.pressed = true
		drag_down.position = source
		drag_down.global_position = source
		Input.parse_input_event(drag_down)
		await process_frame
		var drag_move := InputEventMouseMotion.new()
		drag_move.position = source + Vector2(20, 0)
		drag_move.global_position = drag_move.position
		drag_move.relative = Vector2(20, 0)
		drag_move.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(drag_move)
		await process_frame
		drag_move = InputEventMouseMotion.new()
		drag_move.position = destination
		drag_move.global_position = destination
		drag_move.relative = destination - source - Vector2(20, 0)
		drag_move.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(drag_move)
		await process_frame
		var drag_up := InputEventMouseButton.new()
		drag_up.button_index = MOUSE_BUTTON_LEFT
		drag_up.pressed = false
		drag_up.position = destination
		drag_up.global_position = destination
		Input.parse_input_event(drag_up)
		await process_frame
		check(shell.comparison.objects.size() == 3, "Real GUI drag from sprite preview must reach device board")
		if shell.comparison.objects.size() == 3:
			shell.comparison.remove_selected()
			shell.comparison.selected = 1
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://.tmp/studio-preview.png") == OK, "Studio screenshot should save")
		check(shell.status.global_position.y + shell.status.size.y <= root.size.y, "Workbench content must fit within window")
	shell.comparison.remove_selected()
	check(shell.comparison.objects.size() == 1, "Remove selected must preserve other objects")
	root.remove_child(shell)
	shell.free()
	print("FidGames studio checks: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
