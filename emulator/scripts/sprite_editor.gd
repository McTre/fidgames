extends Control
const Document = preload("res://scripts/sprite_document.gd")
const Canvas = preload("res://scripts/pixel_canvas.gd")
const DragSprite = preload("res://scripts/sprite_drag.gd")
var document := Document.new()
var canvas: Control
var thumbnail: TextureRect
var timeline: HBoxContainer
var info: Label
var color_info: Label
var grid_info: Label
var message: Label
var play_button: Button
var add_button: Button
var copy_button: Button
var remove_button: Button
var size_picker: OptionButton
var timing: SpinBox
var playing := false
var clock := 0.0
var shown_frame := -1
var undo_stack: Array[Dictionary] = []
var dialog: FileDialog
var file_action := ""
var reset_dialog: ConfirmationDialog

func label_at(value: String, at: Vector2, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("cde5e5"))
	add_child(label)
	return label

func button_at(value: String, at: Vector2, extent: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = extent
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	add_child(button)
	return button

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label_at("PIXEL STUDIO", Vector2(0, 0), 20)
	label_at("8 colors / transparent canvas / up to 6 frames", Vector2(0, 30))
	size_picker = OptionButton.new()
	size_picker.position = Vector2(0, 62)
	size_picker.size = Vector2(180, 34)
	size_picker.focus_mode = Control.FOCUS_NONE
	for dims in Document.SIZES:
		size_picker.add_item("%d x %d px" % [dims.x, dims.y])
	size_picker.select(3)
	size_picker.item_selected.connect(_request_resize)
	add_child(size_picker)
	button_at("Undo", Vector2(190, 62), Vector2(74, 34), undo)
	button_at("Clear frame", Vector2(272, 62), Vector2(112, 34), func(): remember(); document.frames[document.current].fill(-1); refresh())
	canvas = Canvas.new()
	canvas.document = document
	canvas.position = Vector2(0, 112)
	canvas.size = Vector2(352, 352)
	canvas.stroke_started.connect(func(): stop(); remember())
	canvas.edited.connect(refresh)
	add_child(canvas)
	label_at("PALETTE", Vector2(378, 112), 13)
	for i in 8:
		var swatch := button_at("", Vector2(378 + (i % 4) * 48, 138 + (i / 4) * 44), Vector2(40, 36), func(): canvas.ink = i; color_info.text = "Color %d selected" % (i + 1))
		var style := StyleBoxFlat.new()
		style.bg_color = Document.PALETTE[i]
		style.set_border_width_all(2)
		style.border_color = Color("728991")
		swatch.add_theme_stylebox_override("normal", style)
		swatch.add_theme_stylebox_override("hover", style)
		swatch.add_theme_stylebox_override("pressed", style)
		swatch.tooltip_text = "Color %d / #%s" % [i + 1, Document.PALETTE[i].to_html(false)]
	button_at("Eraser", Vector2(378, 230), Vector2(184, 32), func(): canvas.ink = -1; color_info.text = "Transparent eraser selected")
	color_info = label_at("Color 3 selected", Vector2(378, 270), 13)
	label_at("DRAG TO DEVICE", Vector2(378, 306), 13)
	thumbnail = DragSprite.new()
	thumbnail.document = document
	thumbnail.position = Vector2(410, 332)
	thumbnail.size = Vector2(112, 112)
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.mouse_default_cursor_shape = Control.CURSOR_DRAG
	thumbnail.tooltip_text = "Drag this sprite onto the device screen. Each drop creates an independent copy."
	add_child(thumbnail)
	grid_info = label_at("", Vector2(0, 475), 13)
	info = label_at("", Vector2(0, 503), 14)
	timeline = HBoxContainer.new()
	timeline.position = Vector2(0, 530)
	timeline.add_theme_constant_override("separation", 8)
	add_child(timeline)
	add_button = button_at("+ Blank", Vector2(0, 598), Vector2(90, 34), func(): remember(); stop(); document.add_frame(false); refresh())
	copy_button = button_at("Duplicate", Vector2(98, 598), Vector2(100, 34), func(): remember(); stop(); document.add_frame(true); refresh())
	remove_button = button_at("Delete frame", Vector2(206, 598), Vector2(116, 34), func(): remember(); stop(); document.remove_frame(); refresh())
	play_button = button_at("Play", Vector2(330, 598), Vector2(86, 34), func(): playing = not playing; clock = 0; play_button.text = "Stop" if playing else "Play"; shown_frame = -1; refresh_preview())
	label_at("Loop duration (ms)", Vector2(0, 647), 13)
	timing = SpinBox.new()
	timing.position = Vector2(144, 640)
	timing.size = Vector2(120, 34)
	timing.min_value = 100
	timing.max_value = 2000
	timing.step = 10
	timing.value = 400
	timing.value_changed.connect(func(value: float): document.duration_ms = int(value); refresh())
	add_child(timing)
	label_at("Suggested loops: 300-800 ms", Vector2(280, 647), 13)
	button_at("Save sprite PNG", Vector2(0, 686), Vector2(142, 34), func(): choose_file("png"))
	button_at("Export frames", Vector2(150, 686), Vector2(130, 34), func(): choose_file("animation"))
	button_at("Save editable", Vector2(288, 686), Vector2(130, 34), func(): choose_file("save"))
	button_at("Open editable", Vector2(426, 686), Vector2(136, 34), func(): choose_file("open"))
	message = label_at("Draw a sprite, then drag its preview onto the device.", Vector2(0, 734), 13)
	message.size.x = 600
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog = FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_selected.connect(_file_selected)
	dialog.dir_selected.connect(_file_selected)
	add_child(dialog)
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.dialog_text = "Create a blank animation at this size? Current frames will be cleared. Undo can restore them."
	reset_dialog.confirmed.connect(func(): remember(); stop(); document.reset(Document.SIZES[size_picker.selected]); refresh())
	reset_dialog.canceled.connect(func(): size_picker.select(Document.SIZES.find(document.dimensions)))
	add_child(reset_dialog)
	refresh()

func _request_resize(_index: int) -> void:
	reset_dialog.popup_centered(Vector2i(430, 150))

func remember() -> void:
	undo_stack.append({"document": document.serialize(), "frame": document.current})
	if undo_stack.size() > 40:
		undo_stack.pop_front()

func undo() -> void:
	if not undo_stack.is_empty():
		stop()
		var state: Dictionary = undo_stack.pop_back()
		document.deserialize(state.document)
		document.current = state.frame
		size_picker.select(Document.SIZES.find(document.dimensions))
		timing.set_value_no_signal(document.duration_ms)
		refresh()

func stop() -> void:
	playing = false
	clock = 0
	if play_button:
		play_button.text = "Play"

func refresh() -> void:
	canvas.queue_redraw()
	var grid: Vector2i = document.grid_size()
	grid_info.text = "%d x %d drawing grid / cell = %d x %d display px / Right: erase" % [grid.x, grid.y, document.pixel_scale, document.pixel_scale]
	shown_frame = -1
	refresh_preview()
	for child in timeline.get_children():
		timeline.remove_child(child)
		child.queue_free()
	for i in document.frames.size():
		var button := Button.new()
		button.text = str(i + 1)
		button.icon = ImageTexture.create_from_image(document.make_image(i))
		button.expand_icon = true
		button.custom_minimum_size = Vector2(80, 54)
		button.toggle_mode = true
		button.button_pressed = i == document.current
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): stop(); document.current = i; refresh())
		timeline.add_child(button)
	add_button.disabled = document.frames.size() >= 6
	copy_button.disabled = add_button.disabled
	remove_button.disabled = document.frames.size() == 1
	info.text = "FRAME %d / %d     %d x %d px     %.0f ms / frame" % [document.current + 1, document.frames.size(), document.dimensions.x, document.dimensions.y, float(document.duration_ms) / document.frames.size()]

func refresh_preview() -> void:
	var zoom := maxi(1, int(112.0 / maxi(document.dimensions.x, document.dimensions.y)))
	thumbnail.size = Vector2(document.dimensions * zoom)
	thumbnail.position = Vector2(410, 332) + (Vector2(112, 112) - thumbnail.size) / 2
	var index: int = int(clock * 1000 / document.duration_ms * document.frames.size()) % document.frames.size() if playing else document.current
	if shown_frame != index:
		thumbnail.texture = ImageTexture.create_from_image(document.make_image(index))
		shown_frame = index

func _process(delta: float) -> void:
	if playing:
		clock += delta
		refresh_preview()

func choose_file(action: String) -> void:
	file_action = action
	dialog.clear_filters()
	dialog.current_file = ""
	if action == "animation":
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
		dialog.title = "Choose parent folder for animation PNGs"
	else:
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if action == "open" else FileDialog.FILE_MODE_SAVE_FILE
		dialog.add_filter("*.png", "Sprite PNG") if action == "png" else dialog.add_filter("*.fidsprite", "Editable FidGames sprite")
		dialog.title = "Open editable sprite" if action == "open" else "Save sprite"
		if action != "open":
			dialog.current_file = "sprite.png" if action == "png" else "animation.fidsprite"
	dialog.popup_centered(Vector2i(800, 560))

func _file_selected(path: String) -> void:
	if file_action == "png":
		message.text = "Sprite PNG saved." if document.make_image(document.current).save_png(path) == OK else "Could not save PNG."
	elif file_action == "animation":
		var folder: String = document.export_animation(path)
		message.text = "Exported PNG frames + editable timing data to: " + folder if not folder.is_empty() else "Export failed. Check the destination folder."
	elif file_action == "save":
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			message.text = "Could not save editable sprite."
			return
		file.store_string(JSON.stringify(document.serialize()))
		file.close()
		message.text = "Editable animation saved."
	else:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var incoming := Document.new()
		if not data is Dictionary or not incoming.deserialize(data):
			message.text = "Invalid sprite file. Current work was kept."
			return
		remember()
		stop()
		document.deserialize(data)
		size_picker.select(Document.SIZES.find(document.dimensions))
		timing.set_value_no_signal(document.duration_ms)
		refresh()
		message.text = "Editable animation opened."
