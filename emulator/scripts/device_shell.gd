extends Control

const Reactor = preload("res://scripts/reactor.gd")
const SpriteEditor = preload("res://scripts/sprite_editor.gd")
const ComparisonBoard = preload("res://scripts/comparison_board.gd")
var studio: Control
var comparison: Control
var comparison_toggle: CheckButton
var save_path := "user://reactor_state.save"
const DISPLAY_SIZE := Vector2i(170, 320)
var game: Node2D
var screen: SubViewport
var preview: TextureRect
var slider_control: HSlider
var trigger_button: Button
var lock_button: Button
var telemetry: Label
var event_log: Label
var status: Label
var panel: VBoxContainer
var scale_selector: OptionButton
var display_scale := 2
var locked := false
var slider_value := 0.0
var dragging := false
var mouse_trigger := false
var previous_trigger := false
var suppress_trigger := false
var snapshot: Dictionary = {}
var events: Array[String] = []
var dead_zone := 5.0
var return_speed := 400.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_ui()
	_new_game()
	_set_scale(2)
	get_window().focus_exited.connect(_focus_lost)

func _label(value: String, font_size: int = 14, color: Color = Color("cde5e5")) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 34
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button

func _build_ui() -> void:
	var title := _label("FIDGAMES / LAB", 19, Color("77f2bd"))
	title.position = Vector2(24, 15)
	add_child(title)
	screen = SubViewport.new()
	screen.size = DISPLAY_SIZE
	screen.disable_3d = true
	screen.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(screen)
	preview = TextureRect.new()
	preview.texture = screen.get_texture()
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.position = Vector2(24, 60)
	add_child(preview)
	comparison = ComparisonBoard.new()
	comparison.position = preview.position
	comparison.activated.connect(func(): comparison_toggle.set_pressed_no_signal(true); _clear_input())
	add_child(comparison)
	studio = SpriteEditor.new()
	studio.position = Vector2(744, 60)
	studio.size = Vector2(612, 800)
	add_child(studio)
	slider_control = HSlider.new()
	slider_control.min_value = -100
	slider_control.max_value = 100
	slider_control.step = 0.1
	slider_control.focus_mode = Control.FOCUS_NONE
	slider_control.drag_started.connect(func(): dragging = true)
	slider_control.drag_ended.connect(func(_changed: bool): dragging = false)
	add_child(slider_control)
	trigger_button = _button("TRIGGER / Space", func(): pass)
	trigger_button.button_down.connect(func(): mouse_trigger = true)
	trigger_button.button_up.connect(func(): mouse_trigger = false)
	add_child(trigger_button)
	panel = VBoxContainer.new()
	panel.size.x = 300
	panel.add_theme_constant_override("separation", 7)
	add_child(panel)
	panel.add_child(_label("DEVICE WORKBENCH", 16, Color("77f2bd")))
	panel.add_child(_label("Reactor / prototype 01", 17))
	panel.add_child(_label("170 x 320 native pixels", 13))
	scale_selector = OptionButton.new()
	scale_selector.add_item("1x  /  170 x 320", 1)
	scale_selector.add_item("2x  /  340 x 640", 2)
	scale_selector.select(1)
	scale_selector.focus_mode = Control.FOCUS_NONE
	scale_selector.item_selected.connect(func(index: int): _set_scale(index + 1))
	panel.add_child(scale_selector)
	comparison_toggle = CheckButton.new()
	comparison_toggle.text = "Sprite comparison / pause game"
	comparison_toggle.focus_mode = Control.FOCUS_NONE
	comparison_toggle.toggled.connect(func(enabled: bool): comparison.comparing = enabled; comparison.queue_redraw(); _clear_input())
	panel.add_child(comparison_toggle)
	var snap_toggle := CheckButton.new()
	snap_toggle.text = "Snap objects to 8 px grid"
	snap_toggle.button_pressed = true
	snap_toggle.focus_mode = Control.FOCUS_NONE
	snap_toggle.toggled.connect(func(enabled: bool): comparison.snap = enabled)
	panel.add_child(snap_toggle)
	panel.add_child(_button("Remove selected object", comparison.remove_selected))
	var grid := CheckButton.new()
	grid.text = "Show 8 px grid"
	grid.focus_mode = Control.FOCUS_NONE
	grid.toggled.connect(func(enabled: bool): game.show_grid = enabled; game.queue_redraw())
	panel.add_child(grid)
	lock_button = _button("Lock / L", toggle_lock)
	panel.add_child(lock_button)
	panel.add_child(_button("Restart game / R", restart_game))
	var saves := HBoxContainer.new()
	var save_button := _button("Save", save_game)
	var restore_button := _button("Restore", restore_game)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	saves.add_child(save_button)
	saves.add_child(restore_button)
	panel.add_child(saves)
	telemetry = _label("", 14)
	panel.add_child(telemetry)
	panel.add_child(_label("HAPTIC EVENTS", 12, Color("77f2bd")))
	event_log = _label("No events yet", 13)
	event_log.custom_minimum_size.y = 62
	panel.add_child(event_log)
	panel.add_child(_label("A / D or arrows: slide\nMouse: drag slider, release to center\nSpace: trigger     L: lock     R: restart", 12, Color("8da5ac")))
	status = _label("Ready to experiment.", 12, Color("77f2bd"))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	comparison.selection_changed.connect(func(description: String): status.text = description)

func _set_scale(value: int) -> void:
	display_scale = value
	preview.size = Vector2(DISPLAY_SIZE * value)
	comparison.size = preview.size
	slider_control.position = Vector2(24, 70 + preview.size.y)
	slider_control.size = Vector2(preview.size.x, 24)
	trigger_button.position = Vector2(24, 108 + preview.size.y)
	trigger_button.size = Vector2(preview.size.x, 36)
	panel.position = Vector2(396, 60)
	get_window().mode = Window.MODE_WINDOWED
	# Keep room for the workbench even when the device preview is only 1x.
	get_window().size = Vector2i(1380, 900)
	queue_redraw()

func _draw() -> void:
	if preview:
		draw_style_box(_case_style(), Rect2(14, 50, preview.size.x + 20, preview.size.y + 104))

func _case_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("1c2c38")
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color("3c5564")
	return style

func _new_game(state: Dictionary = {}) -> bool:
	var candidate := Reactor.new()
	if not state.is_empty() and not candidate.restore_state(state):
		candidate.free()
		return false
	if is_instance_valid(game):
		candidate.show_grid = game.show_grid
		screen.remove_child(game)
		game.queue_free()
	game = candidate
	game.device_locked = locked
	game.haptic.connect(_on_haptic)
	screen.add_child(game)
	return true

func _on_haptic(event: String) -> void:
	events.push_front("%06.2f  %s" % [game.game_time, event])
	if events.size() > 3:
		events.resize(3)
	event_log.text = "\n".join(events)

func _process(delta: float) -> void:
	var keyboard := _keyboard_allowed()
	var trigger_held := mouse_trigger or (keyboard and Input.is_physical_key_pressed(KEY_SPACE))
	if not trigger_held:
		suppress_trigger = false
	var pressed := trigger_held and not previous_trigger and not suppress_trigger
	var released := not trigger_held and previous_trigger
	previous_trigger = trigger_held
	if not locked and not comparison.comparing:
		var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		if not keyboard:
			axis = 0
		if dragging:
			slider_value = slider_control.value
		elif axis != 0:
			slider_value = move_toward(slider_value, axis * 100.0, return_speed * delta)
		else:
			slider_value = move_toward(slider_value, 0.0, return_speed * delta)
		slider_control.set_value_no_signal(slider_value)
		var region := 0 if absf(slider_value) <= dead_zone else int(signf(slider_value))
		game.advance(delta, {"slider": slider_value, "direction": region,
			"trigger_pressed": pressed, "trigger_released": released,
			"trigger_held": trigger_held and not suppress_trigger})
	telemetry.text = "INPUT / %s\nSlider  %+.1f\nTrigger %s\n\n%s" % ["COMPARISON" if comparison.comparing else "LOCKED" if locked else "LIVE", slider_value, "held" if trigger_held else "released", game.diagnostics()]

func _unhandled_key_input(event: InputEvent) -> void:
	if not _keyboard_allowed():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_L:
				toggle_lock()
			KEY_R:
				restart_game()

func _keyboard_allowed() -> bool:
	var focus := get_viewport().gui_get_focus_owner()
	return not (focus is LineEdit or focus is TextEdit or studio.dialog.visible or studio.reset_dialog.visible)

func _clear_input() -> void:
	dragging = false
	mouse_trigger = false
	previous_trigger = false
	suppress_trigger = true
	slider_value = 0.0
	slider_control.set_value_no_signal(0.0)

func toggle_lock() -> void:
	if not locked:
		snapshot = game.save_state().duplicate(true)
		locked = true
	else:
		locked = false
		_new_game(snapshot)
	_clear_input()
	game.device_locked = locked
	game.queue_redraw()
	slider_control.editable = not locked
	trigger_button.disabled = locked
	lock_button.text = "Unlock / L" if locked else "Lock / L"
	status.text = "Locked. Game time is frozen." if locked else "Resumed from the lock snapshot."

func restart_game() -> void:
	_new_game()
	if locked:
		snapshot = game.save_state().duplicate(true)
	_clear_input()
	status.text = "Game restarted." + (" Unlock to play." if locked else "")

func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		status.text = "Could not write save file."
		return
	# Preserve floating-point state exactly, including randomly generated targets.
	file.store_var(game.save_state())
	file.close()
	status.text = "Snapshot saved to local app data."

func restore_game() -> void:
	var legacy := save_path == "user://reactor_state.save" and not FileAccess.file_exists(save_path) and FileAccess.file_exists("user://reactor_state.json")
	if not FileAccess.file_exists(save_path) and not legacy:
		status.text = "No snapshot yet. Press Save first."
		return
	var data: Variant
	if legacy:
		data = JSON.parse_string(FileAccess.get_file_as_string("user://reactor_state.json"))
	else:
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file == null:
			status.text = "Could not read save file."
			return
		data = file.get_var(false)
		file.close()
	if not data is Dictionary:
		status.text = "Save file is invalid."
		return
	if data.is_empty() or not _new_game(data):
		status.text = "Save file is incompatible or invalid."
		return
	if locked:
		snapshot = game.save_state().duplicate(true)
	_clear_input()
	status.text = "Game recreated from saved state."

func _focus_lost() -> void:
	if not locked:
		toggle_lock()
	_clear_input()
