class_name ResourcePickup
extends Area2D

signal collection_requested(pickup: ResourcePickup)

const OBJECTS_TEXTURE := preload("res://assets/pixel/objects.png")
const REGIONS := {
	"wood": Rect2(0, 8, 32, 32),
	"stone": Rect2(32, 8, 32, 32),
	"food": Rect2(64, 8, 32, 32),
	"scrap": Rect2(96, 8, 32, 32),
	"part": Rect2(128, 8, 32, 32),
}

@export var resource_id := ""
@export_enum("wood", "stone", "food", "scrap", "part") var kind := "wood"

var collected := false

@onready var sprite: Sprite2D = $Sprite
@onready var outline: Sprite2D = $Outline


func _ready() -> void:
	_update_sprite()
	set_collected(collected)


func request_collection() -> void:
	if not collected:
		collection_requested.emit(self)


func set_collected(value: bool) -> void:
	collected = value
	visible = not collected
	monitoring = not collected
	monitorable = not collected


func _update_sprite() -> void:
	var texture := AtlasTexture.new()
	texture.atlas = OBJECTS_TEXTURE
	texture.region = REGIONS.get(kind, REGIONS.wood)
	sprite.texture = texture
	outline.texture = texture
	var outline_material := outline.material as ShaderMaterial
	outline_material.set_shader_parameter(
		"outline_color",
		Color("ffc45c") if kind == "part" else Color("c9f1df")
	)
