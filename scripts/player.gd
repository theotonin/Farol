class_name Player
extends CharacterBody2D

signal attack_requested(facing: Vector2)
signal interact_requested

const WALK_SPEED := 165.0
const RUN_SPEED := 265.0
const ATTACK_COOLDOWN := 0.45
const ATTACK_VISUAL_TIME := 0.18
const CHARACTERS_TEXTURE := preload("res://assets/pixel/characters.png")
const DIAGONAL_TEXTURE := preload("res://assets/pixel/player_diagonals.png")

var stamina := 100.0
var facing := Vector2.DOWN
var walking := false
var exhausted := false
var enabled := true

var _attack_cooldown := 0.0
var _attack_visual_time := 0.0
var _nearby_areas: Array[Area2D] = []

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	_build_animations()
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	_update_attack_area()
	_update_animation()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_attack_visual_time = maxf(0.0, _attack_visual_time - delta)
	if not enabled:
		velocity = Vector2.ZERO
		walking = false
		_update_animation()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	walking = not direction.is_zero_approx()
	if walking:
		face_movement(direction)
	var sprinting := Input.is_action_pressed("sprint") and walking and stamina > 0.0 and not exhausted
	stamina = clampf(stamina + (-28.0 if sprinting else 19.0) * delta, 0.0, 100.0)
	if stamina <= 0.0:
		exhausted = true
	elif stamina >= 25.0:
		exhausted = false
	velocity = direction * (RUN_SPEED if sprinting else WALK_SPEED)
	move_and_slide()
	_update_animation()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("attack") and not event.is_echo():
		request_attack_at(get_global_mouse_position())
	elif event.is_action_pressed("interact") and not event.is_echo():
		interact_requested.emit()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		velocity = Vector2.ZERO
		walking = false


func face_movement(direction: Vector2) -> void:
	if direction.is_zero_approx():
		return
	facing = direction.normalized()
	_update_attack_area()
	_update_animation()


func request_attack_at(cursor_global_position: Vector2) -> void:
	if _attack_cooldown > 0.0:
		return
	var aim_direction := cursor_global_position - global_position
	if not aim_direction.is_zero_approx():
		facing = aim_direction.normalized()
	_update_attack_area()
	_attack_cooldown = ATTACK_COOLDOWN
	_attack_visual_time = ATTACK_VISUAL_TIME
	_update_animation()
	attack_requested.emit(facing)


func get_interaction_target() -> Node:
	var candidates: Array[Node] = []
	for area: Area2D in _nearby_areas:
		if not is_instance_valid(area):
			continue
		var owner := _interaction_owner(area)
		if owner != null and owner not in candidates:
			candidates.append(owner)
	candidates.sort_custom(func(a: Node, b: Node) -> bool:
		var a_priority := _interaction_priority(a)
		var b_priority := _interaction_priority(b)
		if a_priority != b_priority:
			return a_priority < b_priority
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	return candidates[0] if not candidates.is_empty() else null


func _request_attack() -> void:
	request_attack_at(get_global_mouse_position())


func _update_attack_area() -> void:
	attack_area.position = facing.normalized() * 42.0
	attack_area.rotation = facing.angle()


func _on_interaction_area_entered(area: Area2D) -> void:
	if area != attack_area and area not in _nearby_areas:
		_nearby_areas.append(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	_nearby_areas.erase(area)


func _interaction_owner(area: Area2D) -> Node:
	var candidate: Node = area
	while candidate != null:
		if candidate.is_in_group("structures") or candidate.is_in_group("resources"):
			return candidate
		candidate = candidate.get_parent()
	return null


func _interaction_priority(candidate: Node) -> int:
	if candidate.is_in_group("shelter"):
		return 0
	if candidate.is_in_group("resources"):
		return 1
	return 2


func _update_animation() -> void:
	if sprite.sprite_frames == null:
		return
	var direction_name := _direction_name(facing)
	if _attack_visual_time > 0.0:
		sprite.play("attack_" + direction_name)
	elif walking:
		sprite.play("walk_" + direction_name)
	else:
		sprite.play("idle_" + direction_name)


func _direction_name(direction: Vector2) -> String:
	var angle := wrapf(direction.angle(), -PI, PI)
	if angle >= -PI / 8.0 and angle < PI / 8.0:
		return "right"
	if angle >= PI / 8.0 and angle < 3.0 * PI / 8.0:
		return "down_right"
	if angle >= 3.0 * PI / 8.0 and angle < 5.0 * PI / 8.0:
		return "down"
	if angle >= 5.0 * PI / 8.0 and angle < 7.0 * PI / 8.0:
		return "down_left"
	if angle >= -3.0 * PI / 8.0 and angle < -PI / 8.0:
		return "up_right"
	if angle >= -5.0 * PI / 8.0 and angle < -3.0 * PI / 8.0:
		return "up"
	if angle >= -7.0 * PI / 8.0 and angle < -5.0 * PI / 8.0:
		return "up_left"
	return "left"


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions := ["down", "left", "right", "up"]
	for row in 4:
		var direction: String = directions[row]
		_add_animation(frames, "idle_" + direction, CHARACTERS_TEXTURE, row, [0], 1.0)
		_add_animation(frames, "walk_" + direction, CHARACTERS_TEXTURE, row, [1, 2], 7.0)
		_add_animation(frames, "attack_" + direction, CHARACTERS_TEXTURE, row, [3], 1.0)
	var diagonal_directions := ["down_right", "down_left", "up_right", "up_left"]
	for row in 4:
		var direction: String = diagonal_directions[row]
		_add_animation(frames, "idle_" + direction, DIAGONAL_TEXTURE, row, [0], 1.0)
		_add_animation(frames, "walk_" + direction, DIAGONAL_TEXTURE, row, [1, 2], 7.0)
		_add_animation(frames, "attack_" + direction, DIAGONAL_TEXTURE, row, [3], 1.0)
	sprite.sprite_frames = frames


func _add_animation(frames: SpriteFrames, animation_name: String, source_texture: Texture2D, row: int, columns: Array, fps: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, true)
	for column: int in columns:
		var texture := AtlasTexture.new()
		texture.atlas = source_texture
		texture.region = Rect2(column * 32, row * 32, 32, 32)
		frames.add_frame(animation_name, texture)
