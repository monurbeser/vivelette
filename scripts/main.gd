extends Control

@onready var avatar_preview: AvatarPreview = $SafeArea/Layout/AvatarPreviewArea/AvatarPreview
@onready var wardrobe_ui: Node = $SafeArea/Layout/WardrobeUI


func _ready() -> void:
	wardrobe_ui.item_selected.connect(_on_wardrobe_item_selected)


func _on_wardrobe_item_selected(
	category: StringName,
	_item_id: StringName,
	layer_textures: Dictionary
) -> void:
	match category:
		&"Hair":
			var hair_front_texture: Texture2D = layer_textures.get(&"hair_front") as Texture2D
			if hair_front_texture != null:
				avatar_preview.set_hair_front_texture(hair_front_texture)
		&"Dress":
			var dress_texture: Texture2D = layer_textures.get(&"dress") as Texture2D
			if dress_texture != null:
				avatar_preview.set_dress_texture(dress_texture)
		&"Shoes":
			var shoes_texture: Texture2D = layer_textures.get(&"shoes") as Texture2D
			if shoes_texture != null:
				avatar_preview.set_shoes_texture(shoes_texture)
		&"Bag":
			var bag_front_texture: Texture2D = layer_textures.get(&"bag_front") as Texture2D
			if bag_front_texture != null:
				avatar_preview.set_bag_front_texture(bag_front_texture)
