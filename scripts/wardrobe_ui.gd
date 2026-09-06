class_name WardrobeUI
extends PanelContainer

signal item_selected(category: StringName, item_id: StringName, layer_textures: Dictionary)

const CATEGORY_HAIR: StringName = &"Hair"
const CATEGORY_DRESS: StringName = &"Dress"
const CATEGORY_SHOES: StringName = &"Shoes"
const CATEGORY_BAG: StringName = &"Bag"
const CATEGORIES := [CATEGORY_HAIR, CATEGORY_DRESS, CATEGORY_SHOES, CATEGORY_BAG]

const HAIR_FRONT_001 := preload("res://assets/character/hair_front_001.png")
const DRESS_001 := preload("res://assets/wardrobe/dresses/dress_001.png")

const COLOR_PANEL := Color(1.0, 0.88, 0.94, 0.96)
const COLOR_SELECTED := Color(0.9, 0.13, 0.48, 1.0)
const COLOR_UNSELECTED := Color(1.0, 1.0, 1.0, 0.96)
const COLOR_BORDER := Color(0.95, 0.45, 0.68, 1.0)
const COLOR_TEXT_DARK := Color(0.25, 0.2, 0.35, 1.0)

var _selected_category: StringName = CATEGORY_HAIR
var _category_buttons: Dictionary = {}
var _items_by_category: Dictionary = {}

@onready var content: VBoxContainer = $Content
@onready var category_bar: HBoxContainer = $Content/CategoryBar
@onready var item_scroll: ScrollContainer = $Content/ItemScroll
@onready var item_strip: HBoxContainer = $Content/ItemScroll/ItemStrip
@onready var empty_state: Label = $Content/EmptyState


func _ready() -> void:
	_build_items()
	_apply_panel_style()
	_build_category_buttons()
	_select_category(CATEGORY_HAIR)


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
		CATEGORY_SHOES: [],
		CATEGORY_BAG: [],
	}


func _apply_panel_style() -> void:
	add_theme_stylebox_override("panel", _make_stylebox(COLOR_PANEL, COLOR_BORDER, 1))
	empty_state.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	empty_state.add_theme_font_size_override("font_size", 22)


func _build_category_buttons() -> void:
	for child: Node in category_bar.get_children():
		child.queue_free()

	_category_buttons.clear()

	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button := Button.new()
		button.text = String(category)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(150, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(_select_category.bind(category))
		category_bar.add_child(button)
		_category_buttons[category] = button


func _select_category(category: StringName) -> void:
	_selected_category = category
	_refresh_category_buttons()
	_refresh_item_strip()


func _refresh_category_buttons() -> void:
	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button: Button = _category_buttons.get(category) as Button
		if button == null:
			continue

		var is_selected := category == _selected_category
		button.button_pressed = is_selected
		_apply_category_button_style(button, is_selected)


func _refresh_item_strip() -> void:
	for child: Node in item_strip.get_children():
		child.queue_free()

	var items: Array = _items_by_category.get(_selected_category, [])
	var has_items := not items.is_empty()
	item_scroll.visible = has_items
	empty_state.visible = not has_items

	if not has_items:
		empty_state.text = "No items yet"
		return

	for raw_item in items:
		var item: Dictionary = raw_item
		var item_button := Button.new()
		item_button.text = String(item.get("label", "Item"))
		item_button.custom_minimum_size = Vector2(180, 64)
		item_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		item_button.add_theme_font_size_override("font_size", 22)
		_apply_item_button_style(item_button)
		item_button.pressed.connect(_emit_item_selected.bind(item))
		item_strip.add_child(item_button)


func _emit_item_selected(item: Dictionary) -> void:
	var item_id: StringName = item["id"]
	var layer_textures: Dictionary = item["layer_textures"]
	item_selected.emit(_selected_category, item_id, layer_textures)


func _apply_category_button_style(button: Button, is_selected: bool) -> void:
	if is_selected:
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _make_stylebox(COLOR_SELECTED, COLOR_SELECTED, 2))
		button.add_theme_stylebox_override("hover", _make_stylebox(COLOR_SELECTED, COLOR_SELECTED, 2))
		button.add_theme_stylebox_override("pressed", _make_stylebox(COLOR_SELECTED, COLOR_SELECTED, 2))
	else:
		button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
		button.add_theme_stylebox_override("normal", _make_stylebox(COLOR_UNSELECTED, COLOR_BORDER, 1))
		button.add_theme_stylebox_override("hover", _make_stylebox(Color(1.0, 0.94, 0.97, 1.0), COLOR_BORDER, 1))
		button.add_theme_stylebox_override("pressed", _make_stylebox(COLOR_SELECTED, COLOR_SELECTED, 2))


func _apply_item_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	button.add_theme_stylebox_override("normal", _make_stylebox(Color.WHITE, COLOR_BORDER, 1))
	button.add_theme_stylebox_override("hover", _make_stylebox(Color(1.0, 0.94, 0.97, 1.0), COLOR_BORDER, 1))
	button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.98, 0.78, 0.88, 1.0), COLOR_SELECTED, 2))


func _make_stylebox(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style
