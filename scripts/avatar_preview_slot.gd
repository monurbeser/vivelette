class_name AvatarPreviewSlot
extends Control

@onready var avatar_preview: AvatarPreview = $AvatarPreview


func _ready() -> void:
	resized.connect(_layout_avatar_preview)
	call_deferred("_layout_avatar_preview")


func _layout_avatar_preview() -> void:
	if avatar_preview == null:
		return

	if size.x <= 0.0 or size.y <= 0.0:
		return

	var canvas_size: Vector2 = Vector2(AvatarPreview.MASTER_CANVAS_SIZE)
	var scale_value: float = minf(size.x, size.y) / canvas_size.x
	var preview_size: Vector2 = canvas_size * scale_value

	avatar_preview.scale = Vector2.ONE * scale_value
	avatar_preview.position = (size - preview_size) * 0.5
