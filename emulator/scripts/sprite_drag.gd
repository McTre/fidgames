extends TextureRect
var document: RefCounted

func _get_drag_data(_at: Vector2) -> Variant:
	var ghost := TextureRect.new()
	ghost.texture = texture
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.custom_minimum_size = Vector2(document.dimensions * 2)
	set_drag_preview(ghost)
	return {"fid_sprite": document.serialize().duplicate(true), "frame": document.current}
