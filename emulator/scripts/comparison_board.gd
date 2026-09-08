extends Control
signal activated
signal selection_changed(description: String)
const Document = preload("res://scripts/sprite_document.gd")
var objects: Array[Dictionary] = []
var selected := -1
var comparing := false
var snap := true
var moving := false
var offset := Vector2.ZERO
var elapsed := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("fid_sprite")

func _drop_data(at: Vector2, data: Variant) -> void:
	add_object(data.fid_sprite, at / (size.x / 170.0))

func add_object(data: Dictionary, at: Vector2) -> bool:
	var doc := Document.new()
	if not doc.deserialize(data):
		return false
	var textures: Array[ImageTexture] = []
	for i in doc.frames.size():
		textures.append(ImageTexture.create_from_image(doc.make_image(i)))
	objects.append({"textures": textures, "dimensions": doc.dimensions, "duration": doc.duration_ms / 1000.0, "position": Vector2.ZERO})
	selected = objects.size() - 1
	_place(at - Vector2(doc.dimensions) / 2)
	comparing = true
	activated.emit()
	queue_redraw()
	return true

func _place(at: Vector2) -> void:
	if selected < 0:
		return
	var dims: Vector2i = objects[selected].dimensions
	if snap:
		at = Vector2(5, 32) + ((at - Vector2(5, 32)) / 8).round() * 8
	at = at.round().clamp(Vector2.ZERO, Vector2(170, 320) - Vector2(dims))
	objects[selected].position = at
	selection_changed.emit("Object %d / %d x %d px / (%d, %d)" % [selected + 1, dims.x, dims.y, at.x, at.y])
	queue_redraw()

func remove_selected() -> void:
	if selected >= 0:
		objects.remove_at(selected)
		selected = -1
		selection_changed.emit("Object removed.")
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not comparing:
		return
	var zoom := size.x / 170.0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		moving = false
		if event.pressed:
			selected = -1
			for i in range(objects.size() - 1, -1, -1):
				if Rect2(objects[i].position, Vector2(objects[i].dimensions)).has_point(event.position / zoom):
					selected = i
					offset = event.position / zoom - objects[i].position
					moving = true
					_place(objects[i].position)
					break
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and moving:
		if event.button_mask == 0:
			moving = false
		else:
			_place(event.position / zoom - offset)
		accept_event()

func _process(delta: float) -> void:
	elapsed += delta
	if comparing:
		queue_redraw()

func _draw() -> void:
	if not comparing:
		return
	var zoom := size.x / 170.0
	draw_rect(Rect2(Vector2.ZERO, size), Color("101e24"))
	draw_rect(Rect2(5 * zoom, 5 * zoom, 160 * zoom, 23 * zoom), Color("20363e"))
	draw_string(ThemeDB.fallback_font, Vector2(11, 21) * zoom, "SPRITE COMPARISON", HORIZONTAL_ALIGNMENT_LEFT, -1, int(10 * zoom), Color("77f2bd"))
	for x in range(5, 166, 8):
		draw_line(Vector2(x, 32) * zoom, Vector2(x, 320) * zoom, Color("233940"))
	for y in range(32, 321, 8):
		draw_line(Vector2(5, y) * zoom, Vector2(165, y) * zoom, Color("233940"))
	for i in objects.size():
		var obj := objects[i]
		var index: int = int(elapsed / float(obj.duration) * obj.textures.size()) % obj.textures.size()
		var rect := Rect2(obj.position * zoom, Vector2(obj.dimensions) * zoom)
		draw_texture_rect(obj.textures[index], rect, false)
		if i == selected:
			draw_rect(rect.grow(1), Color("f4bb59"), false, 1)
