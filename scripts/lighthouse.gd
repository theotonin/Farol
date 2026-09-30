class_name Lighthouse
extends StaticBody2D

const OBJECTS_TEXTURE := preload("res://assets/pixel/objects.png")

var stage := 0
var won := false

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	set_stage(stage, won)


func set_stage(next_stage: int, next_won: bool) -> void:
	stage = clampi(next_stage, 0, 3)
	won = next_won
	var visual_stage := 3 if won else stage
	var texture := AtlasTexture.new()
	texture.atlas = OBJECTS_TEXTURE
	texture.region = Rect2(visual_stage * 64, 160, 64, 96)
	sprite.texture = texture
