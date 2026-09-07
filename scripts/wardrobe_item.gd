class_name WardrobeItem
extends Control

signal wardrobe_item_selected(category: StringName, item_id: StringName, layer_textures: Dictionary)

const COLOR_NORMAL := Color(1.0, 0.96, 0.99, 0.12)
const COLOR_HOVER := Color(1.0, 0.96, 0.99, 0.22)
const COLOR_PRESSED := Color(0.98, 0.76, 0.88, 0.32)
const COLOR_SELECTED := Color(1.0, 0.90, 0.98, 0.40)
const COLOR_BORDER := Color(0.95, 0.45, 0.68, 0.20)
const COLOR_SELECTED_BORDER := Color(0.9, 0.13, 0.48, 0.82)
const PREVIEW_PADDING_RATIO := 0.08
const PREVIEW_MIN_PADDING := 6.0

var category: StringName
var item_id: StringName
var layer_textures: Dictionary = {}
var thumbnail_texture: Texture2D
var selected := false
var _pressed := false

@onready var preview_viewport: Control = $PreviewViewport
@onready var thumbnail_preview: ThumbnailPreview = $PreviewViewport/ThumbnailPreview


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	focus_mode = Control.FOCUS_NONE
	resized.connect(_layout_preview)
	_sync_thumbnail()
	_layout_preview()
	queue_redraw()


func configure(
	next_category: StringName,
	next_item_id: StringName,
	next_thumbnail_texture: Texture2D,
	next_layer_textures: Dictionary,
	is_selected: bool
) -> void:
	category = next_category
	item_id = next_item_id
	thumbnail_texture = next_thumbnail_texture
	layer_textures = next_layer_textures
	selected = is_selected

	if is_node_ready():
		_sync_thumbnail()
		_layout_preview()
		queue_redraw()


func set_selected_state(is_selected: bool) -> void:
	selected = is_selected
	queue_redraw()


func set_pressed_state(is_pressed: bool) -> void:
	_pressed = is_pressed
	queue_redraw()


func activate() -> void:
	wardrobe_item_selected.emit(category, item_id, layer_textures)


func _draw() -> void:
	var style := _make_current_stylebox()
	style.draw(get_canvas_item(), _get_preview_rect())


func _sync_thumbnail() -> void:
	if thumbnail_preview != null:
		thumbnail_preview.texture = thumbnail_texture


func _layout_preview() -> void:
	if preview_viewport == null:
		return

	var preview_rect := _get_preview_rect()
	preview_viewport.position = preview_rect.position
	preview_viewport.size = preview_rect.size


func _get_preview_rect() -> Rect2:
	var padding := maxf(PREVIEW_MIN_PADDING, minf(size.x, size.y) * PREVIEW_PADDING_RATIO)
	var preview_size := size - Vector2(padding, padding) * 2.0
	if preview_size.x <= 0.0 or preview_size.y <= 0.0:
		return Rect2(Vector2.ZERO, size)

	return Rect2(Vector2(padding, padding), preview_size)


func _make_current_stylebox() -> StyleBoxFlat:
	if selected:
		return _make_stylebox(COLOR_SELECTED, COLOR_SELECTED_BORDER, 2)

	if _pressed:
		return _make_stylebox(COLOR_PRESSED, COLOR_SELECTED_BORDER, 2)

	if get_global_rect().has_point(get_global_mouse_position()):
		return _make_stylebox(COLOR_HOVER, COLOR_BORDER, 1)

	return _make_stylebox(COLOR_NORMAL, COLOR_BORDER, 1)


func _make_stylebox(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style
