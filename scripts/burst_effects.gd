class_name BurstEffects
extends Node2D
## Pool declarativo de partículas curtas usado pelo coordenador do jogo.

@onready var _pool: Array[CPUParticles2D] = [
	$Burst0,
	$Burst1,
	$Burst2,
	$Burst3,
	$Burst4,
	$Burst5,
	$Burst6,
	$Burst7,
]

var _next_index := 0


func _ready() -> void:
	clear_effects()


func burst(point: Vector2, color: Color, count: int) -> void:
	if count <= 0:
		return
	var particle := _available_particle()
	particle.emitting = false
	particle.position = point
	particle.amount = count
	particle.color = color
	particle.restart()
	particle.emitting = true


func clear_effects() -> void:
	for particle: CPUParticles2D in _pool:
		particle.emitting = false
	_next_index = 0


func _available_particle() -> CPUParticles2D:
	for particle: CPUParticles2D in _pool:
		if not particle.emitting:
			return particle
	var particle := _pool[_next_index]
	_next_index = (_next_index + 1) % _pool.size()
	return particle
