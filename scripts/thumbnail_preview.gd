class_name ThumbnailPreview
extends Control

const ALPHA_THRESHOLD := 0.05
const PREVIEW_INSET_RATIO := 0.03

static var _visible_bounds_cache: Dictionary = {}

var texture: Texture2D:
	set(value):
		texture = value
		_visible_bounds = _get_visible_bounds(texture)
		queue_redraw()

var _visible_bounds := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if texture == null or _visible_bounds.size.x <= 0.0 or _visible_bounds.size.y <= 0.0:
		return

	var inset := minf(size.x, size.y) * PREVIEW_INSET_RATIO
	var available_rect := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
	if available_rect.size.x <= 0.0 or available_rect.size.y <= 0.0:
		return

	var source_size := _visible_bounds.size
	var scale_value := minf(
		available_rect.size.x / source_size.x,
		available_rect.size.y / source_size.y
	)
	var draw_size := source_size * scale_value
	var draw_rect := Rect2(
		available_rect.position + (available_rect.size - draw_size) * 0.5,
		draw_size
	)

	draw_texture_rect_region(texture, draw_rect, _visible_bounds)


static func _get_visible_bounds(source_texture: Texture2D) -> Rect2:
	if source_texture == null:
		return Rect2()

	var cache_key := source_texture.resource_path
	if cache_key.is_empty():
		cache_key = str(source_texture.get_instance_id())

	if _visible_bounds_cache.has(cache_key):
		return _visible_bounds_cache[cache_key]

	var image := source_texture.get_image()
	if image == null or image.is_empty():
		var fallback_bounds := Rect2(Vector2.ZERO, source_texture.get_size())
		_visible_bounds_cache[cache_key] = fallback_bounds
		push_warning("Thumbnail image data is unavailable: %s" % cache_key)
		return fallback_bounds

	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)

	var bounds: Rect2
	if max_x < min_x or max_y < min_y:
		bounds = Rect2(Vector2.ZERO, source_texture.get_size())
		push_warning("Thumbnail texture has no visible alpha pixels: %s" % cache_key)
	else:
		bounds = Rect2(
			Vector2(min_x, min_y),
			Vector2(max_x - min_x + 1, max_y - min_y + 1)
		)

	_visible_bounds_cache[cache_key] = bounds
	return bounds
