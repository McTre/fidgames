extends Control
signal stroke_started
signal edited
var document: RefCounted
var ink := 2
var drawing := false
var last_pixel := Vector2i.ZERO
var stroke_ink := 2

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_CROSS

func cell_size() -> int:
	return maxi(1, int(minf(size.x / document.grid_size().x, size.y / document.grid_size().y)))

func origin() -> Vector2:
	return ((size - Vector2(document.grid_size() * cell_size())) / 2).floor()

func pixel_at(at: Vector2) -> Vector2i:
	return Vector2i(((at - origin()) / cell_size()).floor())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		if event.pressed:
			if not Rect2i(Vector2i.ZERO, document.grid_size()).has_point(pixel_at(event.position)):
				return
			drawing = true
			stroke_ink = -1 if event.button_index == MOUSE_BUTTON_RIGHT else ink
			last_pixel = pixel_at(event.position)
			stroke_started.emit()
			_line(last_pixel, last_pixel)
		else:
			drawing = false
		accept_event()
	elif event is InputEventMouseMotion and drawing:
		if event.button_mask == 0:
			drawing = false
			return
		var next := pixel_at(event.position)
		_line(last_pixel, next)
		last_pixel = next
		accept_event()

func _line(from: Vector2i, to: Vector2i) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for i in steps + 1:
		var p := Vector2(from).lerp(Vector2(to), float(i) / maxi(steps, 1)).round()
		document.paint(Vector2i(p), stroke_ink)
	queue_redraw()
	edited.emit()

func _draw() -> void:
	if document == null:
		return
	var cell := cell_size()
	var offset := origin()
	for y in document.grid_size().y:
		for x in document.grid_size().x:
			var rect := Rect2(offset + Vector2(x, y) * cell, Vector2.ONE * cell)
			var index: int = document.frames[document.current][y * document.grid_size().x + x]
			var color: Color = document.PALETTE[index] if index >= 0 else Color("29343f") if (x + y) % 2 == 0 else Color("354451")
			draw_rect(rect, color)
			draw_rect(rect, Color(0, 0, 0, 0.2), false)
	for x in range(0, document.grid_size().x + 1, 8):
		draw_line(offset + Vector2(x * cell, 0), offset + Vector2(x * cell, document.grid_size().y * cell), Color("779399"))
	for y in range(0, document.grid_size().y + 1, 8):
		draw_line(offset + Vector2(0, y * cell), offset + Vector2(document.grid_size().x * cell, y * cell), Color("779399"))
