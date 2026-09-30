class_name Enemy
extends CharacterBody2D

signal damage_requested(amount: float)
signal defeated(enemy: Enemy)

const DAY_SPEED := 92.0
const NIGHT_SPEED := 110.0
const DAY_DETECTION := 370.0
const NIGHT_DETECTION := 860.0
const ATTACK_DAMAGE := 14.0
const ATTACK_COOLDOWN := 1.1
const KNOCKBACK_SPEED_SCALE := 10.0
const KNOCKBACK_DECELERATION := 1800.0
const CHARACTERS_TEXTURE := preload("res://assets/pixel/characters.png")

var health := 65.0
var facing := Vector2.DOWN

var _target: Node2D
var _phase := 0.0
var _elapsed := 0.0
var _attack_cooldown := 0.0
var _night := false
var _safe_center := Vector2.ZERO
var _safe_radius := 0.0
var _safe_active := false
var _is_defeated := false
var _knockback_velocity := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	_build_animations()
	_update_animation(false)


func configure(target: Node2D, phase: float) -> void:
	_target = target
	_phase = phase


func set_world_state(night: bool, safe_center: Vector2, safe_radius: float, safe_active: bool) -> void:
	_night = night
	_safe_center = safe_center
	_safe_radius = maxf(safe_radius, 0.0)
	_safe_active = safe_active


func receive_attack(damage: float, knockback: Vector2) -> void:
	if _is_defeated:
		return
	health = maxf(0.0, health - maxf(damage, 0.0))
	_knockback_velocity += knockback * KNOCKBACK_SPEED_SCALE
	if health <= 0.0:
		_is_defeated = true
		velocity = Vector2.ZERO
		_knockback_velocity = Vector2.ZERO
		defeated.emit(self)
		queue_free()


func _physics_process(delta: float) -> void:
	if _is_defeated:
		velocity = Vector2.ZERO
		return
	_elapsed += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if not _knockback_velocity.is_zero_approx():
		velocity = _knockback_velocity
		move_and_slide()
		if not velocity.is_zero_approx():
			facing = velocity.normalized()
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECELERATION * delta)
		_update_animation(true)
		return
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		_update_animation(false)
		return
	var offset := _target.global_position - global_position
	var target_safe := _safe_active and _target.global_position.distance_to(_safe_center) <= _safe_radius
	var detection := NIGHT_DETECTION if _night else DAY_DETECTION
	var direction := Vector2.ZERO
	if offset.length() < detection and not target_safe:
		direction = offset.normalized()
	else:
		direction = Vector2.from_angle(_elapsed * 0.35 + _phase) * 0.23

	var next_position := global_position + direction * (NIGHT_SPEED if _night else DAY_SPEED) * delta
	if _safe_active and next_position.distance_to(_safe_center) < _safe_radius + 22.0:
		var outward := (next_position - _safe_center).normalized()
		if outward.is_zero_approx():
			outward = Vector2.RIGHT
		direction = outward
	velocity = direction * (NIGHT_SPEED if _night else DAY_SPEED)
	move_and_slide()
	if not direction.is_zero_approx():
		facing = direction.normalized()
	_update_animation(not direction.is_zero_approx())

	if not target_safe and damage_area.overlaps_body(_target) and _attack_cooldown <= 0.0:
		_attack_cooldown = ATTACK_COOLDOWN
		damage_requested.emit(ATTACK_DAMAGE)


func _update_animation(moving: bool) -> void:
	if sprite.sprite_frames == null:
		return
	var animation_name := ("walk_" if moving else "idle_") + _direction_name(facing)
	sprite.play(animation_name)


func _direction_name(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var directions := ["down", "left", "right", "up"]
	for row in 4:
		var direction: String = directions[row]
		_add_animation(frames, "idle_" + direction, row + 4, [0], 1.0)
		_add_animation(frames, "walk_" + direction, row + 4, [1, 2], 7.0)
		_add_animation(frames, "attack_" + direction, row + 4, [3], 1.0)
	sprite.sprite_frames = frames


func _add_animation(frames: SpriteFrames, animation_name: String, row: int, columns: Array, fps: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, true)
	for column: int in columns:
		var texture := AtlasTexture.new()
		texture.atlas = CHARACTERS_TEXTURE
		texture.region = Rect2(column * 32, row * 32, 32, 32)
		frames.add_frame(animation_name, texture)
