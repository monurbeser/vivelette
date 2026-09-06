class_name WardrobeUI
extends Control

signal item_selected(category: StringName, item_id: StringName, layer_textures: Dictionary)

const CATEGORY_HAIR: StringName = &"Hair"
const CATEGORY_DRESS: StringName = &"Dress"
const CATEGORY_SHOES: StringName = &"Shoes"
const CATEGORY_BAG: StringName = &"Bag"
const CATEGORIES := [CATEGORY_HAIR, CATEGORY_DRESS, CATEGORY_SHOES, CATEGORY_BAG]

const HAIR_FRONT_001 := preload("res://assets/character/hair_front_001.png")
const DRESS_001 := preload("res://assets/wardrobe/dresses/dress_001.png")
const SHOES_001 := preload("res://assets/wardrobe/shoes/shoes_001.png")
const BAG_001_FRONT := preload("res://assets/wardrobe/bags/bag_001_front.png")

const FALLBACK_PANEL_ASPECT_RATIO := 3.0
const WARDROBE_VIEWPORT_HEIGHT_RATIO := 0.30
const MAX_PANEL_WIDTH_RATIO := 0.64
const CATEGORY_SLOT_RECTS := [
	Rect2(0.075, 0.350, 0.200, 0.165),
	Rect2(0.290, 0.350, 0.200, 0.165),
	Rect2(0.510, 0.350, 0.200, 0.165),
	Rect2(0.725, 0.350, 0.200, 0.165),
]
const ITEM_SLOT_RECTS := [
	Rect2(0.065, 0.565, 0.215, 0.220),
	Rect2(0.285, 0.565, 0.215, 0.220),
	Rect2(0.505, 0.565, 0.215, 0.220),
	Rect2(0.725, 0.565, 0.215, 0.220),
]

const COLOR_SELECTED := Color(0.9, 0.13, 0.48, 0.26)
const COLOR_SELECTED_BORDER := Color(0.9, 0.13, 0.48, 0.65)
const COLOR_UNSELECTED := Color(1.0, 0.94, 0.98, 0.04)
const COLOR_BORDER := Color(0.95, 0.45, 0.68, 0.18)
const COLOR_TEXT_DARK := Color(0.25, 0.2, 0.35, 1.0)
const COLOR_ITEM := Color(1.0, 0.97, 0.99, 0.92)

var _selected_category: StringName = CATEGORY_HAIR
var _category_buttons: Dictionary = {}
var _item_buttons: Array[Button] = []
var _items_by_category: Dictionary = {}

@onready var panel_frame: Control = $PanelFrame
@onready var panel_background: TextureRect = $PanelFrame/PanelBackground
@onready var content: Control = $PanelFrame/Content
@onready var category_slots: Control = $PanelFrame/Content/CategorySlots
@onready var item_slots: Control = $PanelFrame/Content/ItemSlots
@onready var empty_state: Label = $PanelFrame/Content/EmptyState


func _ready() -> void:
	resized.connect(_layout_wardrobe_panel)
	_build_items()
	_apply_panel_style()
	_build_category_buttons()
	_select_category(CATEGORY_HAIR)
	call_deferred("_layout_wardrobe_panel")


func _build_items() -> void:
	_items_by_category = {
		CATEGORY_HAIR: [
			{
				"id": &"hair_front_001",
				"label": "Hair 1",
				"layer_textures": {
					&"hair_front": HAIR_FRONT_001,
				},
			},
		],
		CATEGORY_DRESS: [
			{
				"id": &"dress_001",
				"label": "Dress 1",
				"layer_textures": {
					&"dress": DRESS_001,
				},
			},
		],
		CATEGORY_SHOES: [
			{
				"id": &"shoes_001",
				"label": "Shoes 1",
				"layer_textures": {
					&"shoes": SHOES_001,
				},
			},
		],
		CATEGORY_BAG: [
			{
				"id": &"bag_001",
				"label": "Bag 1",
				"layer_textures": {
					&"bag_front": BAG_001_FRONT,
				},
			},
		],
	}


func _apply_panel_style() -> void:
	empty_state.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	empty_state.add_theme_font_size_override("font_size", 22)


func _build_category_buttons() -> void:
	for child: Node in category_slots.get_children():
		child.queue_free()

	_category_buttons.clear()

	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button := Button.new()
		button.text = String(category)
		button.toggle_mode = true
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_select_category.bind(category))
		category_slots.add_child(button)
		_category_buttons[category] = button


func _select_category(category: StringName) -> void:
	_selected_category = category
	_refresh_category_buttons()
	_refresh_item_slots()


func _refresh_category_buttons() -> void:
	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button: Button = _category_buttons.get(category) as Button
		if button == null:
			continue

		var is_selected := category == _selected_category
		button.button_pressed = is_selected
		_apply_category_button_style(button, is_selected)


func _refresh_item_slots() -> void:
	for child: Node in item_slots.get_children():
		child.queue_free()

	_item_buttons.clear()

	var items: Array = _items_by_category.get(_selected_category, [])
	var has_items := not items.is_empty()
	empty_state.visible = not has_items

	if not has_items:
		empty_state.text = "No items yet"
		_layout_overlay_regions(panel_frame.size)
		return

	var visible_item_count: int = mini(items.size(), ITEM_SLOT_RECTS.size())
	for item_index in range(visible_item_count):
		var item: Dictionary = items[item_index]
		var item_button := Button.new()
		item_button.text = String(item.get("label", "Item"))
		item_button.set_meta("slot_index", _get_item_slot_index(item_index, visible_item_count))
		item_button.add_theme_font_size_override("font_size", 22)
		_apply_item_button_style(item_button)
		item_button.pressed.connect(_emit_item_selected.bind(item))
		item_slots.add_child(item_button)
		_item_buttons.append(item_button)

	_layout_overlay_regions(panel_frame.size)


func _emit_item_selected(item: Dictionary) -> void:
	var item_id: StringName = item["id"]
	var layer_textures: Dictionary = item["layer_textures"]
	item_selected.emit(_selected_category, item_id, layer_textures)


func _apply_category_button_style(button: Button, is_selected: bool) -> void:
	if is_selected:
		button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		button.add_theme_stylebox_override("normal", _make_stylebox(COLOR_SELECTED, COLOR_SELECTED_BORDER, 2))
		button.add_theme_stylebox_override("hover", _make_stylebox(Color(0.9, 0.13, 0.48, 0.32), COLOR_SELECTED_BORDER, 2))
		button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.9, 0.13, 0.48, 0.36), COLOR_SELECTED_BORDER, 2))
	else:
		button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		button.add_theme_stylebox_override("normal", _make_stylebox(COLOR_UNSELECTED, COLOR_BORDER, 1))
		button.add_theme_stylebox_override("hover", _make_stylebox(Color(1.0, 0.94, 0.97, 0.12), COLOR_BORDER, 1))
		button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.9, 0.13, 0.48, 0.22), COLOR_SELECTED_BORDER, 2))


func _apply_item_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_stylebox_override("normal", _make_stylebox(COLOR_ITEM, COLOR_BORDER, 1))
	button.add_theme_stylebox_override("hover", _make_stylebox(Color(1.0, 0.94, 0.97, 1.0), COLOR_BORDER, 1))
	button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.98, 0.78, 0.88, 1.0), COLOR_SELECTED, 2))


func _layout_wardrobe_panel() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var panel_aspect_ratio := _get_panel_aspect_ratio()
	var viewport_size := get_viewport_rect().size
	var max_panel_height := minf(size.y, viewport_size.y * WARDROBE_VIEWPORT_HEIGHT_RATIO)
	var max_panel_width := size.x * MAX_PANEL_WIDTH_RATIO
	var panel_height := minf(max_panel_height, max_panel_width / panel_aspect_ratio)
	var panel_size := Vector2(panel_height * panel_aspect_ratio, panel_height)

	panel_frame.position = Vector2((size.x - panel_size.x) * 0.5, size.y - panel_size.y)
	panel_frame.size = panel_size
	_layout_overlay_regions(panel_size)


func _layout_overlay_regions(panel_size: Vector2) -> void:
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return

	var category_bounds := _get_scaled_bounds(CATEGORY_SLOT_RECTS, panel_size)
	var item_bounds := _get_scaled_bounds(ITEM_SLOT_RECTS, panel_size)
	category_slots.position = category_bounds.position
	category_slots.size = category_bounds.size
	item_slots.position = item_bounds.position
	item_slots.size = item_bounds.size

	for category_index in range(CATEGORIES.size()):
		var category: StringName = CATEGORIES[category_index]
		var button: Button = _category_buttons.get(category) as Button
		if button == null:
			continue

		var category_rect := _scale_rect(CATEGORY_SLOT_RECTS[category_index], panel_size)
		button.position = category_rect.position - category_bounds.position
		button.size = category_rect.size

	for item_index in range(_item_buttons.size()):
		var item_button := _item_buttons[item_index]
		if item_button == null:
			continue

		var slot_index: int = item_button.get_meta("slot_index", item_index)
		var slot_rect := _scale_rect(ITEM_SLOT_RECTS[slot_index], panel_size)
		var item_size := Vector2(
			minf(190.0, slot_rect.size.x * 0.78),
			minf(70.0, maxf(54.0, slot_rect.size.y * 0.60))
		)
		item_button.position = slot_rect.position - item_bounds.position + (slot_rect.size - item_size) * 0.5
		item_button.size = item_size

	var empty_rect := _scale_rect(ITEM_SLOT_RECTS[0], panel_size)
	empty_state.position = empty_rect.position
	empty_state.size = empty_rect.size


func _get_item_slot_index(item_index: int, visible_item_count: int) -> int:
	if visible_item_count == 1:
		return maxi(0, CATEGORIES.find(_selected_category))

	return item_index


func _get_panel_aspect_ratio() -> float:
	if panel_background.texture == null:
		return FALLBACK_PANEL_ASPECT_RATIO

	var texture_size := panel_background.texture.get_size()
	if texture_size.y <= 0.0:
		return FALLBACK_PANEL_ASPECT_RATIO

	return float(texture_size.x) / float(texture_size.y)


func _scale_rect(normalized_rect: Rect2, panel_size: Vector2) -> Rect2:
	return Rect2(
		Vector2(
			normalized_rect.position.x * panel_size.x,
			normalized_rect.position.y * panel_size.y
		),
		Vector2(
			normalized_rect.size.x * panel_size.x,
			normalized_rect.size.y * panel_size.y
		)
	)


func _get_scaled_bounds(normalized_rects: Array, panel_size: Vector2) -> Rect2:
	var bounds := _scale_rect(normalized_rects[0], panel_size)
	for rect_index in range(1, normalized_rects.size()):
		bounds = bounds.merge(_scale_rect(normalized_rects[rect_index], panel_size))
	return bounds


func _make_stylebox(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style
