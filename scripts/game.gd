extends Node2D
## Coordena cenas e regras persistentes; apresentação e física vivem nos nós filhos.

const SurvivalState = preload("res://scripts/survival_state.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const ENEMY_SCENE := preload("res://scenes/actors/enemy.tscn")
const SAVE_PATH := "user://save.json"
const SHELTER_REACH := 185.0
const GAMEPLAY_CAMERA_ZOOM := Vector2(1.5, 1.5)

var state = SurvivalState.new()
var mode := "menu"
var save_path := SAVE_PATH
var random := RandomNumberGenerator.new()
var world_random := RandomNumberGenerator.new()
var attack_cooldown := 0.0
var hurt_flash := 0.0
var animation_time := 0.0
var night_warning_day := 0
var rescue_time := 0.0
var last_save_ok := true

# Campos de observação mantidos para consumidores do controlador legado.
var facing := Vector2.DOWN
var walking := false
var exhausted := false

@onready var island: IslandWorld = $World/Island
@onready var player: Player = $World/Player
@onready var enemies_node: Node2D = $World/Enemies
@onready var effects_node = $World/Effects
@onready var rescue_visuals: Node2D = $World/RescueVisuals
@onready var rescue_beam: Polygon2D = $World/RescueVisuals/Beam
@onready var rescue_boat: Node2D = $World/RescueVisuals/Boat
@onready var lighting: CanvasModulate = $Lighting
@onready var camera: Camera2D = $Camera2D
@onready var ui = $UI
@onready var sound = $Soundscape

var player_position: Vector2:
	get:
		return player.global_position if is_instance_valid(player) else IslandWorld.SPAWN
	set(value):
		if is_instance_valid(player):
			player.global_position = value


func _ready() -> void:
	configure_input()
	random.seed = 103
	world_random.randomize()
	player.attack_requested.connect(_on_player_attack_requested)
	player.interact_requested.connect(interact)
	ui.action_requested.connect(handle_action)
	_connect_resource_signals()
	state.new_game()
	player_position = IslandWorld.SPAWN
	player.stamina = state.stamina
	show_main_menu()
	update_view()


func configure_input() -> void:
	var bindings := {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"sprint": KEY_SHIFT,
		"interact": KEY_E,
		"eat": KEY_Q,
		"pause": KEY_ESCAPE,
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = bindings[action]
			InputMap.action_add_event(action, event)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", click)


func _connect_resource_signals() -> void:
	var callback := Callable(self, "_on_resource_collection_requested")
	for pickup: Node in island.get_resource_nodes():
		if pickup.has_signal("collection_requested") and not pickup.is_connected("collection_requested", callback):
			pickup.connect("collection_requested", callback)


func _sync_player_enabled() -> void:
	var is_playing := mode == "playing"
	player.set_enabled(is_playing)
	enemies_node.process_mode = Node.PROCESS_MODE_INHERIT if is_playing else Node.PROCESS_MODE_DISABLED


func show_main_menu(error: String = "") -> void:
	mode = "menu"
	_sync_player_enabled()
	ui.show_menu(FileAccess.file_exists(save_path), error)


func start_new_game() -> void:
	state.new_game(world_random.randi_range(1, 2147483647))
	island.distribute_resources(state.world_seed)
	player_position = IslandWorld.SPAWN
	state.player_position = player_position
	player.stamina = state.stamina
	player.exhausted = false
	_clear_enemies()
	_clear_effects()
	night_warning_day = 0
	attack_cooldown = 0.0
	hurt_flash = 0.0
	rescue_time = 0.0
	mode = "intro"
	_sync_player_enabled()
	camera.zoom = GAMEPLAY_CAMERA_ZOOM
	camera.position = player_position
	camera.reset_smoothing()
	ui.show_intro()
	update_view()


func begin_play() -> void:
	mode = "playing"
	_sync_player_enabled()
	ui.show_play()
	spawn_enemies(state.is_night())
	save_checkpoint()
	if last_save_ok:
		ui.toast("Colete materiais com E. No farol, guarde e abasteça a fogueira.", 7.0)


func continue_game() -> void:
	if not state.load_game(save_path):
		show_main_menu("Não foi possível ler o salvamento. Você pode começar uma nova expedição.")
		return
	island.distribute_resources(state.world_seed)
	var loaded_position: Vector2 = state.player_position
	if not island.is_walkable(loaded_position):
		loaded_position = IslandWorld.SPAWN
	player_position = loaded_position
	state.player_position = loaded_position
	player.stamina = state.stamina
	player.exhausted = false
	camera.zoom = GAMEPLAY_CAMERA_ZOOM
	camera.position = player_position
	camera.reset_smoothing()
	_clear_effects()
	_clear_enemies()
	attack_cooldown = 0.0
	hurt_flash = 0.0
	night_warning_day = 0
	rescue_time = 0.0
	if state.won:
		mode = "victory"
		ui.show_victory(state.day)
	else:
		mode = "playing"
		ui.show_play()
		spawn_enemies(state.is_night())
		ui.toast("Expedição retomada. Seu abrigo espera por você.")
	_sync_player_enabled()
	update_view()


func save_checkpoint() -> void:
	state.player_position = player_position
	state.stamina = player.stamina
	var error: Error = state.save_game(save_path)
	last_save_ok = error == OK
	if error != OK:
		ui.toast("Não foi possível salvar. Verifique o espaço e a permissão da pasta de dados.", 8.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if mode == "playing":
			if ui.shelter.visible:
				ui.shelter.hide()
			else:
				pause_game()
		elif mode == "paused":
			handle_action("resume", "")
		get_viewport().set_input_as_handled()
		return
	if mode != "playing":
		return
	if event.is_action_pressed("eat") and not event.is_echo():
		if state.eat():
			sound.play_cue("eat")
			ui.toast("Comida consumida. Sua vida foi recuperada.", 2.0)
		else:
			ui.toast("Vida cheia." if state.health >= 100 else "Você não tem comida na mochila.", 2.0)
		update_view()


func _physics_process(delta: float) -> void:
	animation_time += delta
	if mode == "playing":
		var previous_night: bool = state.is_night()
		var previous_fuel: float = state.fuel
		var dawn: bool = state.tick(delta)
		if dawn:
			spawn_enemies(false)
			save_checkpoint()
			sound.play_cue("dawn")
			ui.toast("Dia %d. Recursos renovados. %s" % [state.day, "Progresso salvo." if last_save_ok else "Falha ao salvar."], 5.0)
		elif state.is_night() and not previous_night:
			spawn_enemies(true)
			ui.toast("A noite chegou. Procure a luz do abrigo.", 5.0)
		if previous_fuel > 0.0 and state.fuel <= 0.0 and state.is_night():
			ui.toast("A fogueira apagou. O abrigo está desprotegido!", 5.0)
		if state.time_of_day >= 210.0 and not state.is_night() and night_warning_day != state.day:
			night_warning_day = state.day
			ui.toast("Faltam 30 segundos para a noite. Hora de voltar.", 5.0)
		update_player(delta)
		attack_cooldown = maxf(0.0, attack_cooldown - delta)
		hurt_flash = maxf(0.0, hurt_flash - delta)
		_update_enemy_world_state()
		if ui.shelter.visible and player_position.length() > SHELTER_REACH:
			ui.shelter.hide()
	elif mode == "rescue":
		rescue_time += delta
		camera.zoom = GAMEPLAY_CAMERA_ZOOM.lerp(Vector2(0.36, 0.36), smoothstep(0.0, 4.0, rescue_time))
		if rescue_time >= 6.0:
			mode = "victory"
			_sync_player_enabled()
			ui.show_victory(state.day)
	camera.position = player_position if mode not in ["rescue", "victory"] else Vector2(180, 0)
	_update_rescue_visuals()
	update_view()


func update_player(_delta: float) -> void:
	state.stamina = player.stamina
	state.player_position = player_position
	facing = player.facing
	walking = player.walking
	exhausted = player.exhausted


func player_is_safe() -> bool:
	return state.fuel > 0.0 and player_position.length() <= IslandWorld.SAFE_RADIUS


func _clear_enemies() -> void:
	for enemy: Node in enemies_node.get_children():
		enemies_node.remove_child(enemy)
		enemy.queue_free()


func spawn_enemies(night: bool) -> void:
	_clear_enemies()
	var count: int = mini(12, 3 + state.day) if night else 3
	for index in range(count):
		for attempt in range(80):
			var angle := random.randf_range(-PI, PI)
			var radius := random.randf_range(410, 820) if night else random.randf_range(850, 1200)
			var spot := Vector2.from_angle(angle) * radius
			if not island.is_walkable(spot) or spot.distance_to(player_position) < 280.0:
				continue
			var enemy := ENEMY_SCENE.instantiate() as Enemy
			enemy.position = spot
			enemy.configure(player, random.randf_range(0.0, TAU))
			enemy.damage_requested.connect(_on_enemy_damage_requested)
			enemy.defeated.connect(_on_enemy_defeated)
			enemies_node.add_child(enemy)
			enemy.set_world_state(night, Vector2.ZERO, IslandWorld.SAFE_RADIUS, state.fuel > 0.0)
			break


func _update_enemy_world_state() -> void:
	for enemy: Node in enemies_node.get_children():
		if enemy.has_method("set_world_state"):
			enemy.call("set_world_state", state.is_night(), Vector2.ZERO, IslandWorld.SAFE_RADIUS, state.fuel > 0.0)


func _on_enemy_damage_requested(amount: float) -> void:
	hurt_player(amount)


func _on_enemy_defeated(enemy: Enemy) -> void:
	burst(enemy.global_position, Color("c4b29b"), 8)


func hurt_player(amount: float) -> void:
	if mode != "playing" or player_is_safe() or hurt_flash > 0.0:
		return
	state.health = maxf(0.0, state.health - amount)
	hurt_flash = 0.35
	sound.play_cue("hurt")
	burst(player_position, Color("d68675"), 7)
	if state.health <= 0.0:
		state.die()
		player_position = IslandWorld.SPAWN
		state.player_position = player_position
		player.stamina = state.stamina
		player.exhausted = false
		exhausted = false
		ui.shelter.hide()
		camera.position = player_position
		camera.reset_smoothing()
		spawn_enemies(false)
		save_checkpoint()
		sound.play_cue("death")
		if last_save_ok:
			ui.toast("Você acordou no abrigo. A mochila se perdeu; depósito e reparos ficaram.", 7.0)
	update_view()


func _on_player_attack_requested(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		player.facing = direction.normalized()
	attack()


func attack() -> void:
	if mode != "playing" or attack_cooldown > 0.0:
		return
	attack_cooldown = 0.45
	sound.play_cue("hit")
	var attack_shape := player.attack_area.get_node("Shape") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = attack_shape.shape
	query.transform = attack_shape.global_transform
	query.collision_mask = 2
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit_enemies := {}
	for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body := hit.collider as Node2D
		if not body is Enemy or hit_enemies.has(body):
			continue
		hit_enemies[body] = true
		var enemy := body as Enemy
		var hit_position := enemy.global_position
		enemy.receive_attack(35.0, player.facing * 36.0)
		if is_instance_valid(enemy) and enemy.health > 0.0:
			burst(hit_position, Color("c4b29b"), 8)


func interact() -> void:
	if mode != "playing":
		return
	var target: Node = player.get_interaction_target()
	if target == null:
		ui.toast("Aproxime-se de um recurso ou do abrigo para interagir.", 2.0)
		return
	if target.is_in_group("resources") and target.has_method("request_collection"):
		target.call("request_collection")
		return
	if target.is_in_group("structures"):
		if player_position.length() <= SHELTER_REACH:
			ui.toggle_shelter()
		else:
			ui.toast("As ruínas guardam apenas marcas antigas da ilha.", 2.0)


func _on_resource_collection_requested(pickup: Node) -> void:
	var kind := String(pickup.get("kind"))
	var resource_id := String(pickup.get("resource_id"))
	if state.collect(kind, resource_id):
		burst((pickup as Node2D).global_position, Color("efbd70"), 6)
		sound.play_cue("collect")
		ui.toast("+1 %s" % GameUI.NAMES[kind], 1.7)
		update_view()
	else:
		ui.toast("Mochila cheia. Guarde materiais no depósito do farol.", 3.0)


func pause_game() -> void:
	if mode == "playing":
		mode = "paused"
		_sync_player_enabled()
		ui.show_pause()


func handle_action(action_name: String, payload: String) -> void:
	if action_name in ["deposit", "withdraw", "fuel", "repair", "ignite"]:
		if mode != "playing" or player_position.length() > SHELTER_REACH:
			return
	match action_name:
		"new":
			if FileAccess.file_exists(save_path):
				ui.show_new_confirmation()
			else:
				start_new_game()
		"confirm_new":
			start_new_game()
		"cancel_new":
			show_main_menu()
		"begin":
			begin_play()
		"continue":
			continue_game()
		"resume":
			mode = "playing"
			_sync_player_enabled()
			ui.show_play()
		"menu":
			save_checkpoint()
			show_main_menu("Não foi possível salvar o progresso atual." if not last_save_ok else "")
		"mute":
			ui.set_muted(not ui.muted)
			sound.set_muted(ui.muted)
		"close_shelter":
			ui.shelter.hide()
		"deposit":
			state.deposit_all()
			ui.toast("Materiais guardados. O depósito permanece após a morte.", 2.5)
		"withdraw":
			if not state.withdraw(payload):
				ui.toast("Sem espaço na mochila ou material indisponível.", 2.0)
		"fuel":
			if state.fuel_fire():
				sound.play_cue("fire")
				ui.toast("Fogueira abastecida. O combustível só queima à noite.", 2.5)
			else:
				ui.toast("Falta madeira ou a fogueira já está cheia.", 2.0)
		"repair":
			if state.repair():
				save_checkpoint()
				sound.play_cue("repair")
				burst(Vector2(0, -40), Color("efbd70"), 25)
				ui.toast("Reparo %d/3 concluído. %s" % [state.repair_stage, "Progresso salvo." if last_save_ok else "Falha ao salvar."], 4.0)
			else:
				ui.toast("Guarde no depósito os materiais indicados para o reparo.", 3.0)
		"ignite":
			if state.ignite():
				mode = "rescue"
				rescue_time = 0.0
				_sync_player_enabled()
				ui.shelter.hide()
				save_checkpoint()
				sound.play_cue("ignite")
				if last_save_ok:
					ui.toast("A luz atravessa a névoa. Há um barco no horizonte…", 6.0)
	update_view()


func update_view() -> void:
	var night_amount: float = smoothstep(190.0, 245.0, state.time_of_day)
	if state.time_of_day > 335.0:
		night_amount *= 1.0 - smoothstep(335.0, 360.0, state.time_of_day)
	lighting.color = Color.WHITE.lerp(Color(0.52, 0.63, 0.79), night_amount)
	island.set_visual_state(state.collected, state.repair_stage, state.fuel, night_amount, state.won)
	player.modulate = Color("fff1d3") if hurt_flash > 0.0 else Color.WHITE
	var interaction := ""
	if mode == "playing":
		var target: Node = player.get_interaction_target()
		if target != null and target.is_in_group("resources"):
			var kind := String(target.get("kind"))
			interaction = "E  ·  Coletar %s" % GameUI.NAMES.get(kind, kind).to_lower()
		elif target != null and target.is_in_group("structures"):
			interaction = "E  ·  Abrir abrigo, depósito e reparos" if player_position.length() <= SHELTER_REACH else "E  ·  Examinar ruínas"
	ui.update_hud(state, player_position.length(), interaction, player_is_safe())
	ui.set_lighthouse_direction(-player_position)


func _update_rescue_visuals() -> void:
	rescue_visuals.visible = mode in ["rescue", "victory"]
	if not rescue_visuals.visible:
		return
	rescue_beam.rotation = animation_time * 0.65
	rescue_boat.position = Vector2(lerpf(1670.0, 1480.0, minf(rescue_time / 6.0, 1.0)), -260.0)


func burst(point: Vector2, color: Color, count: int) -> void:
	effects_node.burst(point, color, count)


func _clear_effects() -> void:
	effects_node.clear_effects()
