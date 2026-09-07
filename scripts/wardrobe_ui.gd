class_name WardrobeUI
extends Control

signal item_selected(category: StringName, item_id: StringName, layer_textures: Dictionary)

const WARDROBE_ITEM_SCENE := preload("res://scenes/ui/WardrobeItem.tscn")

const CATEGORY_HAIR: StringName = &"Hair"
const CATEGORY_DRESS: StringName = &"Dress"
const CATEGORY_SHOES: StringName = &"Shoes"
const CATEGORY_BAG: StringName = &"Bag"
const CATEGORIES := [CATEGORY_HAIR, CATEGORY_DRESS, CATEGORY_SHOES, CATEGORY_BAG]

const ITEM_SLOTS_PER_PAGE := 4
const FALLBACK_PANEL_ASPECT_RATIO := 3.0
const WARDROBE_VIEWPORT_HEIGHT_RATIO := 0.30
const MAX_PANEL_WIDTH_RATIO := 0.68
const PANEL_BOTTOM_MARGIN := 8.0

const CATEGORY_DISCOVERY := {
	CATEGORY_HAIR: {
		"directory": "res://assets/character",
		"prefix": "hair_front_",
		"suffix": ".png",
		"layer": &"hair_front",
	},
	CATEGORY_DRESS: {
		"directory": "res://assets/wardrobe/dresses",
		"prefix": "dress_",
		"suffix": ".png",
		"layer": &"dress",
	},
	CATEGORY_SHOES: {
		"directory": "res://assets/wardrobe/shoes",
		"prefix": "shoes_",
		"suffix": ".png",
		"layer": &"shoes",
	},
	CATEGORY_BAG: {
		"directory": "res://assets/wardrobe/bags",
		"prefix": "bag_",
		"suffix": "_front.png",
		"layer": &"bag_front",
	},
}

const CATEGORY_TAB_RECTS := [
	Rect2(0.070, 0.335, 0.210, 0.205),
	Rect2(0.286, 0.335, 0.210, 0.205),
	Rect2(0.502, 0.335, 0.210, 0.205),
	Rect2(0.718, 0.335, 0.210, 0.205),
]
const CATEGORY_SELECTED_INSET_RATIO := Vector4(0.035, 0.17, 0.035, 0.17)
const ITEM_RAIL_VEIL_RECT := Rect2(0.040, 0.535, 0.920, 0.320)
const CAROUSEL_VIEW_RECT := Rect2(0.045, 0.540, 0.910, 0.300)
const PAGE_DOTS_RECT := Rect2(0.430, 0.850, 0.140, 0.045)
const CATEGORY_TAP_DRAG_THRESHOLD := 10.0
const CAROUSEL_TAP_DRAG_THRESHOLD := 10.0

const COLOR_SELECTED := Color(0.9, 0.13, 0.48, 0.26)
const COLOR_SELECTED_BORDER := Color(0.9, 0.13, 0.48, 0.65)
const COLOR_UNSELECTED := Color(1.0, 0.94, 0.98, 0.04)
const COLOR_BORDER := Color(0.95, 0.45, 0.68, 0.18)
const COLOR_TEXT_DARK := Color(0.25, 0.2, 0.35, 1.0)
const COLOR_VEIL := Color(1.0, 0.88, 0.97, 0.20)
const COLOR_VEIL_BORDER := Color(1.0, 0.72, 0.90, 0.18)
const COLOR_DOT := Color(0.9, 0.13, 0.48, 0.24)
const COLOR_DOT_SELECTED := Color(0.9, 0.13, 0.48, 0.68)
const COLOR_TRANSPARENT := Color(1.0, 1.0, 1.0, 0.0)

var _selected_category: StringName = CATEGORY_HAIR
var _category_buttons: Dictionary = {}
var _items_by_category: Dictionary = {}
var _selected_item_ids: Dictionary = {}
var _wardrobe_item_controls: Array[WardrobeItem] = []
var _current_page := 0
var _page_count := 1
var _snap_tween: Tween
var _carousel_dragging := false
var _carousel_pressing := false
var _carousel_press_position := Vector2.ZERO
var _carousel_press_scroll := 0
var _carousel_pressed_item: WardrobeItem
var _carousel_scroll_refresh_queued := false
var _category_pressing := false
var _category_press_position := Vector2.ZERO

@onready var panel_frame: Control = $PanelFrame
@onready var panel_background: TextureRect = $PanelFrame/PanelBackground
@onready var content: Control = $PanelFrame/Content
@onready var item_rail_veil: Panel = $PanelFrame/Content/ItemRailVeil
@onready var item_carousel_viewport: ScrollContainer = $PanelFrame/Content/ItemCarouselViewport
@onready var item_carousel_track: HBoxContainer = $PanelFrame/Content/ItemCarouselViewport/ItemCarouselTrack
@onready var page_dots: HBoxContainer = $PanelFrame/Content/PageDots
@onready var category_tabs: Control = $PanelFrame/Content/CategoryTabs
@onready var empty_state: Label = $PanelFrame/Content/EmptyState


func _ready() -> void:
	resized.connect(_layout_wardrobe_panel)
	category_tabs.gui_input.connect(_on_category_tabs_gui_input)
	item_carousel_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_carousel_viewport.scroll_started.connect(_on_carousel_scroll_started)
	item_carousel_viewport.scroll_ended.connect(_on_carousel_scroll_ended)
	item_carousel_viewport.gui_input.connect(_on_carousel_gui_input)

	_apply_panel_style()
	_discover_items()
	_seed_initial_selected_items()
	_build_category_buttons()
	_select_category(CATEGORY_HAIR, false)
	call_deferred("_layout_wardrobe_panel")


func _apply_panel_style() -> void:
	item_rail_veil.add_theme_stylebox_override("panel", _make_stylebox(COLOR_VEIL, COLOR_VEIL_BORDER, 1))
	empty_state.add_theme_color_override("font_color", COLOR_TEXT_DARK)
	empty_state.add_theme_font_size_override("font_size", 22)


func _discover_items() -> void:
	_items_by_category.clear()

	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		_items_by_category[category] = _discover_category_items(category)


func _discover_category_items(category: StringName) -> Array:
	var items: Array = []
	var config: Dictionary = CATEGORY_DISCOVERY.get(category, {})
	var directory_path := String(config.get("directory", ""))
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("Wardrobe asset directory is missing: %s" % directory_path)
		return items

	var files := directory.get_files()
	files.sort()

	for file_name in files:
		if not _is_matching_asset_file(file_name, config):
			continue

		var resource_path := directory_path.path_join(file_name)
		var texture := load(resource_path) as Texture2D
		if texture == null:
			push_warning("Could not load wardrobe texture: %s" % resource_path)
			continue

		var layer_textures := {}
		layer_textures[config["layer"]] = texture
		items.append({
			"id": StringName(file_name.get_basename()),
			"texture": texture,
			"layer_textures": layer_textures,
			"resource_path": resource_path,
		})

	return items


func _is_matching_asset_file(file_name: String, config: Dictionary) -> bool:
	if file_name.ends_with(".import"):
		return false

	return (
		file_name.ends_with(".png")
		and file_name.begins_with(String(config.get("prefix", "")))
		and file_name.ends_with(String(config.get("suffix", "")))
	)


func _seed_initial_selected_items() -> void:
	var hair_items: Array = _items_by_category.get(CATEGORY_HAIR, [])
	if not hair_items.is_empty():
		_selected_item_ids[CATEGORY_HAIR] = hair_items[0]["id"]


func _build_category_buttons() -> void:
	_clear_children(category_tabs)
	_category_buttons.clear()

	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button := Button.new()
		button.text = ""
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_apply_transparent_button_style(button)
		var selected_visual := Panel.new()
		selected_visual.name = "SelectedVisual"
		selected_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_visual.visible = false
		button.add_child(selected_visual)
		var label := Label.new()
		label.name = "Label"
		label.text = String(category)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		button.add_child(label)
		category_tabs.add_child(button)
		_category_buttons[category] = button


func _select_category(category: StringName, animate_scroll := true) -> void:
	if not CATEGORIES.has(category):
		return

	_selected_category = category
	_refresh_category_buttons()
	_rebuild_carousel()
	_snap_to_page(_get_page_for_selected_item(), animate_scroll)


func _refresh_category_buttons() -> void:
	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button: Button = _category_buttons.get(category) as Button
		if button == null:
			continue

		var is_selected := category == _selected_category
		_apply_category_button_style(button, is_selected)


func _rebuild_carousel() -> void:
	_clear_children(item_carousel_track)
	_wardrobe_item_controls.clear()

	var items: Array = _items_by_category.get(_selected_category, [])
	var has_items := not items.is_empty()
	item_carousel_viewport.visible = has_items
	empty_state.visible = not has_items
	_page_count = maxi(1, ceili(float(items.size()) / float(ITEM_SLOTS_PER_PAGE)))

	if not has_items:
		empty_state.text = "No items yet"
		_refresh_page_dots()
		_layout_wardrobe_panel()
		return

	for raw_item in items:
		var item: Dictionary = raw_item
		var item_control := WARDROBE_ITEM_SCENE.instantiate() as WardrobeItem
		var is_selected: bool = _selected_item_ids.get(_selected_category) == item["id"]
		item_control.configure(
			_selected_category,
			item["id"],
			item["texture"],
			item["layer_textures"],
			is_selected
		)
		item_control.wardrobe_item_selected.connect(_on_wardrobe_item_selected)
		item_carousel_track.add_child(item_control)
		_wardrobe_item_controls.append(item_control)

	var total_slots := _page_count * ITEM_SLOTS_PER_PAGE
	for _empty_slot_index in range(total_slots - items.size()):
		var spacer := Control.new()
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item_carousel_track.add_child(spacer)

	_refresh_page_dots()
	_layout_wardrobe_panel()


func _on_wardrobe_item_selected(category: StringName, item_id: StringName, layer_textures: Dictionary) -> void:
	_selected_item_ids[category] = item_id
	_refresh_wardrobe_item_selection()
	item_selected.emit(category, item_id, layer_textures)


func _select_wardrobe_item(item_control: WardrobeItem) -> void:
	if item_control == null:
		return

	_on_wardrobe_item_selected(
		item_control.category,
		item_control.item_id,
		item_control.layer_textures
	)


func _refresh_wardrobe_item_selection() -> void:
	var selected_item_id: StringName = _selected_item_ids.get(_selected_category, &"")
	for item_control in _wardrobe_item_controls:
		item_control.set_selected_state(item_control.item_id == selected_item_id)


func _layout_wardrobe_panel() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var panel_aspect_ratio := _get_panel_aspect_ratio()
	var viewport_size := get_viewport_rect().size
	var max_panel_height := minf(size.y, viewport_size.y * WARDROBE_VIEWPORT_HEIGHT_RATIO)
	var max_panel_width := size.x * MAX_PANEL_WIDTH_RATIO
	var panel_height := minf(max_panel_height, max_panel_width / panel_aspect_ratio)
	var panel_size := Vector2(panel_height * panel_aspect_ratio, panel_height)
	var local_bottom_limit := minf(
		size.y,
		viewport_size.y - get_global_rect().position.y - PANEL_BOTTOM_MARGIN
	)
	local_bottom_limit = maxf(panel_size.y, local_bottom_limit)

	panel_frame.position = Vector2((size.x - panel_size.x) * 0.5, local_bottom_limit - panel_size.y)
	panel_frame.size = panel_size
	_layout_overlay_regions(panel_size)


func _layout_overlay_regions(panel_size: Vector2) -> void:
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return

	var category_bounds := _get_scaled_bounds(CATEGORY_TAB_RECTS, panel_size)
	category_tabs.position = category_bounds.position
	category_tabs.size = category_bounds.size

	for category_index in range(CATEGORIES.size()):
		var category: StringName = CATEGORIES[category_index]
		var button: Button = _category_buttons.get(category) as Button
		if button == null:
			continue

		var category_rect := _scale_rect(CATEGORY_TAB_RECTS[category_index], panel_size)
		button.position = category_rect.position - category_bounds.position
		button.size = category_rect.size
		_layout_category_button_content(button)

	var veil_rect := _scale_rect(ITEM_RAIL_VEIL_RECT, panel_size)
	item_rail_veil.position = veil_rect.position
	item_rail_veil.size = veil_rect.size

	var carousel_rect := _scale_rect(CAROUSEL_VIEW_RECT, panel_size)
	item_carousel_viewport.position = carousel_rect.position
	item_carousel_viewport.size = carousel_rect.size
	empty_state.position = carousel_rect.position
	empty_state.size = carousel_rect.size
	_layout_carousel_track(carousel_rect.size)

	var dots_rect := _scale_rect(PAGE_DOTS_RECT, panel_size)
	page_dots.position = dots_rect.position
	page_dots.size = dots_rect.size
	_update_scroll_position_for_current_page()


func _layout_carousel_track(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var slot_size := Vector2(viewport_size.x / ITEM_SLOTS_PER_PAGE, viewport_size.y)
	var child_count := maxi(ITEM_SLOTS_PER_PAGE, item_carousel_track.get_child_count())
	item_carousel_track.custom_minimum_size = Vector2(slot_size.x * child_count, slot_size.y)
	item_carousel_track.size = item_carousel_track.custom_minimum_size

	for child in item_carousel_track.get_children():
		if child is Control:
			var control := child as Control
			control.custom_minimum_size = slot_size
			control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			control.size_flags_vertical = Control.SIZE_FILL
			control.update_minimum_size()

	item_carousel_track.update_minimum_size()
	item_carousel_viewport.queue_sort()
	_request_carousel_scroll_refresh()


func _request_carousel_scroll_refresh() -> void:
	if _carousel_scroll_refresh_queued or not is_inside_tree():
		return

	_carousel_scroll_refresh_queued = true
	call_deferred("_refresh_carousel_scroll_range")


func _refresh_carousel_scroll_range() -> void:
	_carousel_scroll_refresh_queued = false
	if not is_node_ready():
		return

	item_carousel_track.update_minimum_size()
	item_carousel_viewport.queue_sort()
	call_deferred("_update_scroll_position_for_current_page")


func _get_page_for_selected_item() -> int:
	var items: Array = _items_by_category.get(_selected_category, [])
	var selected_item_id: StringName = _selected_item_ids.get(_selected_category, &"")
	if selected_item_id == &"":
		return 0

	for item_index in range(items.size()):
		if items[item_index]["id"] == selected_item_id:
			return floori(float(item_index) / float(ITEM_SLOTS_PER_PAGE))

	return 0


func _on_carousel_scroll_started() -> void:
	if _snap_tween != null:
		_snap_tween.kill()
		_snap_tween = null


func _on_category_tabs_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_category_pointer_button(event.pressed, event.position)
		category_tabs.accept_event()
	elif event is InputEventMouseMotion and _category_pressing:
		category_tabs.accept_event()
	elif event is InputEventScreenTouch:
		_handle_category_pointer_button(event.pressed, event.position)
		category_tabs.accept_event()
	elif event is InputEventScreenDrag and _category_pressing:
		category_tabs.accept_event()


func _handle_category_pointer_button(is_pressed: bool, pointer_position: Vector2) -> void:
	if is_pressed:
		_category_pressing = true
		_category_press_position = pointer_position
		return

	if not _category_pressing:
		return

	_category_pressing = false
	if pointer_position.distance_to(_category_press_position) > CATEGORY_TAP_DRAG_THRESHOLD:
		return

	var category := _get_category_at_position(pointer_position)
	if category != &"":
		_select_category(category)


func _get_category_at_position(pointer_position: Vector2) -> StringName:
	for raw_category in CATEGORIES:
		var category: StringName = raw_category
		var button: Button = _category_buttons.get(category) as Button
		if button != null and button.get_rect().has_point(pointer_position):
			return category

	return &""


func _on_carousel_scroll_ended() -> void:
	_snap_to_nearest_page()


func _on_carousel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_carousel_pointer_button(event.pressed, event.position)
		item_carousel_viewport.accept_event()
	elif event is InputEventMouseMotion and (_carousel_pressing or _carousel_dragging):
		_handle_carousel_pointer_motion(event.position)
		item_carousel_viewport.accept_event()
	elif event is InputEventScreenTouch:
		_handle_carousel_pointer_button(event.pressed, event.position)
		item_carousel_viewport.accept_event()
	elif event is InputEventScreenDrag and (_carousel_pressing or _carousel_dragging):
		_handle_carousel_pointer_motion(event.position)
		item_carousel_viewport.accept_event()


func _handle_carousel_pointer_button(is_pressed: bool, pointer_position: Vector2) -> void:
	if is_pressed:
		_carousel_pressing = true
		_carousel_dragging = false
		_carousel_press_position = pointer_position
		_carousel_press_scroll = item_carousel_viewport.scroll_horizontal
		_carousel_pressed_item = _get_wardrobe_item_at_global_position(
			item_carousel_viewport.get_global_rect().position + pointer_position
		)
		if _carousel_pressed_item != null:
			_carousel_pressed_item.set_pressed_state(true)
		_on_carousel_scroll_started()
		return

	if not _carousel_pressing and not _carousel_dragging:
		return

	var was_dragging := _carousel_dragging
	var pressed_item := _carousel_pressed_item
	if _carousel_pressed_item != null:
		_carousel_pressed_item.set_pressed_state(false)
	_carousel_pressing = false
	_carousel_dragging = false
	_carousel_pressed_item = null

	if was_dragging:
		_snap_to_nearest_page()
		return

	if pressed_item != null:
		_select_wardrobe_item(pressed_item)


func _handle_carousel_pointer_motion(pointer_position: Vector2) -> void:
	if not _carousel_pressing:
		return

	var delta := pointer_position - _carousel_press_position
	if (
		not _carousel_dragging
		and absf(delta.x) >= CAROUSEL_TAP_DRAG_THRESHOLD
		and absf(delta.x) >= absf(delta.y)
	):
		_carousel_dragging = true
		if _carousel_pressed_item != null:
			_carousel_pressed_item.set_pressed_state(false)

	if _carousel_dragging:
		item_carousel_viewport.scroll_horizontal = _carousel_press_scroll - roundi(delta.x)


func _snap_to_nearest_page() -> void:
	if _page_count <= 1 or item_carousel_viewport.size.x <= 0.0:
		_current_page = 0
		_update_scroll_position_for_current_page()
		return

	var page := roundi(float(item_carousel_viewport.scroll_horizontal) / item_carousel_viewport.size.x)
	_snap_to_page(page, true)


func _snap_to_page(page: int, animate_scroll := true) -> void:
	_current_page = clampi(page, 0, _page_count - 1)
	var target_scroll := _get_target_scroll_for_page(_current_page)

	if _snap_tween != null:
		_snap_tween.kill()
		_snap_tween = null

	if animate_scroll and abs(item_carousel_viewport.scroll_horizontal - target_scroll) > 1:
		_snap_tween = create_tween()
		_snap_tween.set_trans(Tween.TRANS_QUAD)
		_snap_tween.set_ease(Tween.EASE_OUT)
		_snap_tween.tween_method(
			_set_carousel_scroll,
			float(item_carousel_viewport.scroll_horizontal),
			float(target_scroll),
			0.18
		)
	else:
		item_carousel_viewport.scroll_horizontal = target_scroll

	_refresh_page_dots()


func _set_carousel_scroll(scroll_value: float) -> void:
	item_carousel_viewport.scroll_horizontal = roundi(scroll_value)


func _update_scroll_position_for_current_page() -> void:
	item_carousel_viewport.scroll_horizontal = _get_target_scroll_for_page(_current_page)


func _get_target_scroll_for_page(page: int) -> int:
	return roundi(maxf(0.0, item_carousel_viewport.size.x) * clampi(page, 0, _page_count - 1))


func _refresh_page_dots() -> void:
	_clear_children(page_dots)
	page_dots.visible = _page_count > 1
	if _page_count <= 1:
		return

	for page_index in range(_page_count):
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page_dots.add_child(dot)

	_refresh_page_dots_style()


func _refresh_page_dots_style() -> void:
	for page_index in range(page_dots.get_child_count()):
		var dot := page_dots.get_child(page_index) as Panel
		if dot == null:
			continue

		var color := COLOR_DOT_SELECTED if page_index == _current_page else COLOR_DOT
		dot.add_theme_stylebox_override("panel", _make_stylebox(color, color, 0))


func _apply_transparent_button_style(button: Button) -> void:
	var transparent_style := _make_stylebox(COLOR_TRANSPARENT, COLOR_TRANSPARENT, 0)
	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", transparent_style)
	button.add_theme_stylebox_override("pressed", transparent_style)
	button.add_theme_stylebox_override("focus", transparent_style)
	button.add_theme_stylebox_override("disabled", transparent_style)


func _apply_category_button_style(button: Button, is_selected: bool) -> void:
	var selected_visual := button.get_node_or_null("SelectedVisual") as Panel
	if selected_visual != null:
		selected_visual.visible = is_selected
		selected_visual.add_theme_stylebox_override(
			"panel",
			_make_stylebox(COLOR_SELECTED, COLOR_SELECTED_BORDER, 2)
		)

	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.add_theme_color_override("font_color", Color.WHITE if is_selected else COLOR_TEXT_DARK)

	if is_selected:
		button.add_theme_stylebox_override("hover", _make_stylebox(Color(0.9, 0.13, 0.48, 0.04), COLOR_TRANSPARENT, 0))
		button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.9, 0.13, 0.48, 0.08), COLOR_TRANSPARENT, 0))
	else:
		button.add_theme_stylebox_override("hover", _make_stylebox(Color(1.0, 0.94, 0.97, 0.05), COLOR_TRANSPARENT, 0))
		button.add_theme_stylebox_override("pressed", _make_stylebox(Color(0.9, 0.13, 0.48, 0.06), COLOR_TRANSPARENT, 0))


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


func _layout_category_button_content(button: Button) -> void:
	var highlight_rect := _get_inset_rect(Rect2(Vector2.ZERO, button.size), CATEGORY_SELECTED_INSET_RATIO)
	var selected_visual := button.get_node_or_null("SelectedVisual") as Panel
	if selected_visual != null:
		selected_visual.position = highlight_rect.position
		selected_visual.size = highlight_rect.size

	var label := button.get_node_or_null("Label") as Label
	if label != null:
		label.position = highlight_rect.position
		label.size = highlight_rect.size


func _get_inset_rect(source_rect: Rect2, inset_ratio: Vector4) -> Rect2:
	var left := source_rect.size.x * inset_ratio.x
	var top := source_rect.size.y * inset_ratio.y
	var right := source_rect.size.x * inset_ratio.z
	var bottom := source_rect.size.y * inset_ratio.w
	return Rect2(
		source_rect.position + Vector2(left, top),
		source_rect.size - Vector2(left + right, top + bottom)
	)


func _get_wardrobe_item_at_global_position(global_position: Vector2) -> WardrobeItem:
	for item_control in _wardrobe_item_controls:
		if item_control.get_global_rect().has_point(global_position):
			return item_control

	return null


func _clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _make_stylebox(fill_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style
