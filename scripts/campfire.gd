class_name Campfire
extends Area2D

const OBJECTS_TEXTURE := preload("res://assets/pixel/objects.png")

var fuel := 0.0
var night_amount := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var light: PointLight2D = $Light


func _ready() -> void:
	set_fuel(fuel, night_amount)


func set_fuel(next_fuel: float, next_night_amount: float) -> void:
	fuel = maxf(next_fuel, 0.0)
	night_amount = clampf(next_night_amount, 0.0, 1.0)
	var region := Rect2(4, 48, 32, 32)
	if fuel > 0.0:
		region = Rect2(72, 48, 32, 32) if night_amount >= 0.5 else Rect2(40, 48, 32, 32)
	var texture := AtlasTexture.new()
	texture.atlas = OBJECTS_TEXTURE
	texture.region = region
	sprite.texture = texture
	sprite.self_modulate = Color.WHITE.lerp(Color(1.0, 0.83, 0.55), night_amount * 0.35) if fuel > 0.0 else Color.WHITE
	light.energy = night_amount * 1.25 if fuel > 0.0 else 0.0
	light.visible = light.energy > 0.01
