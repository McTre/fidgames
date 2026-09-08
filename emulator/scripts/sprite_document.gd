extends RefCounted
## Palette indices, -1 for transparency. Every animation frame shares its canvas.
const PALETTE := [Color("101e24"), Color("f3f6df"), Color("77f2bd"), Color("3998c9"), Color("6855ad"), Color("ee7185"), Color("f4bb59"), Color("8c6b50")]
const SIZES := [Vector2i(8, 8), Vector2i(16, 16), Vector2i(24, 24), Vector2i(32, 32), Vector2i(64, 64), Vector2i(16, 8), Vector2i(32, 8)]
var dimensions := Vector2i(32, 32)
var pixel_scale := 4
var frames: Array[PackedInt32Array] = []
var current := 0
var duration_ms := 400

func _init() -> void:
	reset(dimensions)

func reset(value: Vector2i) -> void:
	dimensions = value
	pixel_scale = 4
	frames.clear()
	current = 0
	add_frame(false)

func grid_size() -> Vector2i:
	return dimensions / pixel_scale

func add_frame(copy: bool) -> bool:
	if frames.size() >= 6:
		return false
	var pixels := PackedInt32Array()
	pixels.resize(grid_size().x * grid_size().y)
	pixels.fill(-1)
	if copy:
		pixels = frames[current].duplicate()
	frames.insert(current + 1 if not frames.is_empty() else 0, pixels)
	current = frames.size() - 1 if frames.size() == 1 else current + 1
	return true

func remove_frame() -> void:
	if frames.size() > 1:
		frames.remove_at(current)
		current = mini(current, frames.size() - 1)

func paint(point: Vector2i, color: int) -> void:
	if Rect2i(Vector2i.ZERO, grid_size()).has_point(point) and color >= -1 and color < 8:
		frames[current][point.y * grid_size().x + point.x] = color

func make_image(index: int) -> Image:
	var grid := grid_size()
	var result := Image.create(grid.x, grid.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	for y in grid.y:
		for x in grid.x:
			var ink := frames[index][y * grid.x + x]
			if ink >= 0:
				result.set_pixel(x, y, PALETTE[ink])
	result.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_NEAREST)
	return result

func serialize() -> Dictionary:
	var data: Array = []
	for frame in frames:
		data.append(Array(frame))
	return {"version": 2, "width": dimensions.x, "height": dimensions.y, "pixel_scale": pixel_scale, "duration_ms": duration_ms, "frames": data}

func deserialize(data: Dictionary) -> bool:
	if data.get("version") != 1 and data.get("version") != 2:
		return false
	# Legacy files keep their original artwork at one display pixel per cell.
	var scale_value: Variant = 1 if data.version == 1 else data.get("pixel_scale", 0)
	if scale_value != 1 and scale_value != 4:
		return false
	var incoming_scale := int(scale_value)
	var dims := Vector2i(int(data.get("width", 0)), int(data.get("height", 0)))
	var incoming: Variant = data.get("frames")
	if dims not in SIZES or not incoming is Array or incoming.size() < 1 or incoming.size() > 6:
		return false
	var parsed: Array[PackedInt32Array] = []
	for frame in incoming:
		if not frame is Array or frame.size() != (dims.x / incoming_scale) * (dims.y / incoming_scale):
			return false
		var pixels := PackedInt32Array()
		for ink in frame:
			if not (ink is int or ink is float) or ink < -1 or ink > 7 or float(ink) != int(ink):
				return false
			pixels.append(int(ink))
		parsed.append(pixels)
	var timing := int(data.get("duration_ms", 0))
	if timing < 100 or timing > 2000:
		return false
	dimensions = dims
	pixel_scale = incoming_scale
	frames = parsed
	duration_ms = timing
	current = 0
	return true

func export_animation(parent_path: String) -> String:
	# Always create a new folder; never overwrite a previous animation export.
	var folder := parent_path.path_join("fid_sprite_%d" % Time.get_unix_time_from_system())
	var suffix := 1
	while DirAccess.dir_exists_absolute(folder):
		folder = parent_path.path_join("fid_sprite_%d_%d" % [Time.get_unix_time_from_system(), suffix])
		suffix += 1
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return ""
	for i in frames.size():
		if make_image(i).save_png(folder.path_join("frame_%02d.png" % (i + 1))) != OK:
			return ""
	var file := FileAccess.open(folder.path_join("animation.fidsprite"), FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(serialize()))
	file.close()
	return folder
