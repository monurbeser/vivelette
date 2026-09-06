class_name AvatarPreview
extends Node2D

const MASTER_CANVAS_SIZE := Vector2i(1254, 1254)
const LAYER_ORDER := [
	"Background",
	"HairBack",
	"BagBack",
	"BodyBase",
	"Dress",
	"Shoes",
	"BagFront",
	"HairFront",
	"Effects",
]

@onready var avatar_canvas: Node2D = $AvatarCanvas


func _ready() -> void:
	_validate_avatar_layers()


func set_hair_front_texture(texture: Texture2D) -> void:
	_set_layer_texture(&"HairFront", texture)


func set_dress_texture(texture: Texture2D) -> void:
	_set_layer_texture(&"Dress", texture)


func set_shoes_texture(texture: Texture2D) -> void:
	_set_layer_texture(&"Shoes", texture)


func set_bag_textures(back_texture: Texture2D, front_texture: Texture2D) -> void:
	_set_layer_texture(&"BagBack", back_texture)
	_set_layer_texture(&"BagFront", front_texture)


func _validate_avatar_layers() -> void:
	for layer_name: String in LAYER_ORDER:
		var layer := avatar_canvas.get_node_or_null(NodePath(layer_name))
		if layer == null:
			push_warning("Missing avatar layer: %s" % layer_name)
			continue

		if not layer is Sprite2D:
			push_warning("Avatar layer is not a Sprite2D: %s" % layer_name)
			continue

		var sprite := layer as Sprite2D
		_validate_shared_layer_transform(layer_name, sprite)
		_validate_texture_size(layer_name, sprite)


func _set_layer_texture(layer_name: StringName, texture: Texture2D) -> void:
	var layer := avatar_canvas.get_node_or_null(NodePath(String(layer_name)))
	if not layer is Sprite2D:
		push_warning("Avatar layer is not available for texture assignment: %s" % layer_name)
		return

	var sprite := layer as Sprite2D
	sprite.texture = texture
	_validate_shared_layer_transform(String(layer_name), sprite)
	_validate_texture_size(String(layer_name), sprite)


func _validate_shared_layer_transform(layer_name: String, sprite: Sprite2D) -> void:
	if sprite.position != Vector2.ZERO:
		push_warning("Avatar layer has a non-zero position: %s" % layer_name)

	if sprite.scale != Vector2.ONE:
		push_warning("Avatar layer has a non-unit scale: %s" % layer_name)

	if not is_equal_approx(sprite.rotation, 0.0):
		push_warning("Avatar layer has a non-zero rotation: %s" % layer_name)

	if sprite.offset != Vector2.ZERO:
		push_warning("Avatar layer has a non-zero offset: %s" % layer_name)

	if sprite.centered:
		push_warning("Avatar layer should use top-left canvas coordinates: %s" % layer_name)


func _validate_texture_size(layer_name: String, sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return

	var texture_size := Vector2i(sprite.texture.get_size())
	if texture_size != MASTER_CANVAS_SIZE:
		push_warning(
			"Avatar layer texture size is %s, expected %s: %s"
			% [texture_size, MASTER_CANVAS_SIZE, layer_name]
		)
