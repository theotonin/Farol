extends SceneTree

var failures := 0

const EXPECTED_RESOURCE_COUNT := 69

func _initialize() -> void:
	call_deferred("run")

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func ensure_input_actions() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down", "sprint", "attack", "interact"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)


func action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func expected_resources() -> Dictionary:
	var result := {}
	var common_offsets: Array[Vector2] = [
		Vector2(-42, -30), Vector2(0, -38), Vector2(42, -28),
		Vector2(-42, 25), Vector2(0, 36), Vector2(42, 24)
	]
	var clusters := {
		"wood": {
			"anchors": [Vector2(-305, 175), Vector2(365, 215), Vector2(-475, -70), Vector2(225, -400)],
			"offsets": common_offsets,
		},
		"stone": {
			"anchors": [Vector2(-340, -285), Vector2(505, -165), Vector2(-165, 510)],
			"offsets": common_offsets,
		},
		"food": {
			"anchors": [Vector2(285, 335), Vector2(-410, 360), Vector2(90, -525), Vector2(-250, -440)],
			"offsets": [Vector2(-25, 0), Vector2(25, 0)],
		},
		"scrap": {
			"anchors": [Vector2(-760, -180), Vector2(650, -520), Vector2(775, 410), Vector2(-620, 620)],
			"offsets": [Vector2(-32, -32), Vector2(32, -32), Vector2(-32, 32), Vector2(32, 32)],
		},
	}
	for kind: String in clusters:
		var number := 1
		for anchor: Vector2 in clusters[kind].anchors:
			for offset: Vector2 in clusters[kind].offsets:
				result["%s_%02d" % [kind, number]] = {"kind": kind, "position": anchor + offset}
				number += 1
	for index in 3:
		result["part_%02d" % (index + 1)] = {
			"kind": "part",
			"position": [Vector2(-1070, -405), Vector2(1060, -425), Vector2(180, 980)][index],
		}
	return result


func test_player_contract() -> void:
	var player_scene := load("res://scenes/actors/player.tscn") as PackedScene
	var player := player_scene.instantiate()
	expect(player.get_node("Sprite") is AnimatedSprite2D, "Jogador deve ter AnimatedSprite2D")
	expect(player.get_node("BodyCollision") is CollisionShape2D, "Jogador deve ter colisão")
	expect(player.get_node("AttackArea") is Area2D, "Jogador deve ter área de ataque")
	expect(player.get_node("InteractionArea") is Area2D, "Jogador deve detectar interações por área")
	expect(player.collision_layer == 2, "Jogador deve estar na camada actors")
	expect(player.collision_mask == 1, "Jogador deve colidir somente com world")

	root.add_child(player)
	await physics_frame
	var start: Vector2 = player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	Input.action_release("move_down")
	expect(player.position.x > start.x, "Jogador deve mover fisicamente com move_and_slide")
	expect(player.position.y > start.y, "Duas teclas devem mover o jogador fisicamente na diagonal")
	expect(player.walking, "Jogador deve expor walking durante movimento")
	expect(player.facing.is_equal_approx(Vector2(1, 1).normalized()), "Movimento diagonal deve orientar o personagem na diagonal")

	var eight_directions: Array[Vector2] = [
		Vector2.UP, Vector2(1, -1).normalized(), Vector2.RIGHT, Vector2(1, 1).normalized(),
		Vector2.DOWN, Vector2(-1, 1).normalized(), Vector2.LEFT, Vector2(-1, -1).normalized(),
	]
	expect(player.has_method("face_movement"), "Player deve expor orientação comandada pelo movimento")
	expect(player.has_method("request_attack_at"), "Player deve orientar ao mouse somente quando solicita ataque")
	if player.has_method("face_movement"):
		player.face_movement(Vector2.LEFT)
		expect(player.facing == Vector2.LEFT, "Movimento deve definir a direção enquanto não há ataque")
	if player.has_method("request_attack_at"):
		player.request_attack_at(player.global_position + Vector2(1, -1) * 120.0)
		expect(player.facing.is_equal_approx(Vector2(1, -1).normalized()), "Clique de ataque deve orientar o personagem na diagonal do mouse")
		expect(player.attack_area.position.is_equal_approx(Vector2(1, -1).normalized() * 42.0), "Área de ataque deve acompanhar a mira diagonal")
	var player_frames := (player.get_node("Sprite") as AnimatedSprite2D).sprite_frames
	for diagonal_name: String in ["down_right", "down_left", "up_right", "up_left"]:
		for action_name: String in ["idle_", "walk_", "attack_"]:
			expect(player_frames.has_animation(action_name + diagonal_name), "Sprite deve conter animação %s%s" % [action_name, diagonal_name])

	player.set_enabled(false)
	var disabled_position: Vector2 = player.position
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	expect(player.position.is_equal_approx(disabled_position), "Jogador desabilitado não deve mover")
	player.set_enabled(true)

	var attacks: Array[Vector2] = []
	var interactions := [0]
	player.attack_requested.connect(func(direction: Vector2) -> void: attacks.append(direction))
	player.interact_requested.connect(func() -> void: interactions[0] += 1)
	player._attack_cooldown = 0.0
	if player.has_method("request_attack_at"):
		player.request_attack_at(player.global_position + Vector2(1, 1) * 120.0)
		player.request_attack_at(player.global_position + Vector2.LEFT * 120.0)
	expect(attacks.size() == 1 and attacks[0].is_equal_approx(Vector2(1, 1).normalized()), "Ataque diagonal deve emitir a mira uma vez durante o cooldown")
	player._unhandled_input(action_event("interact"))
	expect(interactions[0] == 1, "Interação habilitada deve emitir interact_requested")
	player.queue_free()
	await process_frame


func test_interaction_priority() -> void:
	var player := (load("res://scenes/actors/player.tscn") as PackedScene).instantiate()
	var pickup := (load("res://scenes/objects/resource_pickup.tscn") as PackedScene).instantiate()
	var storage := (load("res://scenes/objects/storage.tscn") as PackedScene).instantiate()
	var ruin := (load("res://scenes/objects/ruin.tscn") as PackedScene).instantiate()
	pickup.position = Vector2(2, 0)
	storage.position = Vector2(24, 0)
	root.add_child(player)
	root.add_child(pickup)
	root.add_child(storage)
	await physics_frame
	await physics_frame
	expect(player.get_interaction_target() == storage, "Estrutura deve ter prioridade sobre recurso mais próximo")
	storage.queue_free()
	await physics_frame
	await physics_frame
	expect(player.get_interaction_target() == pickup, "Recurso deve ser alvo quando não há estrutura próxima")
	ruin.position = pickup.position
	root.add_child(ruin)
	await physics_frame
	await physics_frame
	expect(player.get_interaction_target() == pickup, "Ruína sem ação não deve tornar recurso sobreposto inalcançável")
	player.queue_free()
	pickup.queue_free()
	ruin.queue_free()
	await process_frame


func test_enemy_contract() -> void:
	var enemy := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate()
	expect(enemy.get_node("Sprite") is AnimatedSprite2D, "Inimigo deve ter AnimatedSprite2D")
	expect(enemy.get_node("BodyCollision") is CollisionShape2D, "Inimigo deve ter colisão")
	expect(enemy.collision_layer == 2, "Inimigo deve estar na camada actors")
	expect(enemy.collision_mask == 1, "Inimigo deve colidir somente com world")
	var damage_area := enemy.get_node_or_null("DamageArea") as Area2D
	expect(damage_area != null, "Inimigo deve ter DamageArea real")
	if damage_area != null:
		expect(damage_area.collision_layer == 8, "DamageArea deve estar na camada combat")
		expect(damage_area.collision_mask == 2, "DamageArea deve detectar actors")
		expect(damage_area.get_node_or_null("Shape") is CollisionShape2D, "DamageArea deve ter CollisionShape2D")
	var target := CharacterBody2D.new()
	target.collision_layer = 0
	target.collision_mask = 0
	var target_collision := CollisionShape2D.new()
	var target_shape := CircleShape2D.new()
	target_shape.radius = 6.0
	target_collision.shape = target_shape
	target.add_child(target_collision)
	target.position = Vector2(140, 0)
	root.add_child(target)
	root.add_child(enemy)
	enemy.configure(target, 0.0)
	enemy.set_world_state(false, Vector2.ZERO, 180.0, false)
	var start: Vector2 = enemy.position
	await physics_frame
	await physics_frame
	expect(enemy.position.x > start.x, "Inimigo deve perseguir alvo em alcance durante o dia")

	var damage_events: Array[float] = []
	enemy.damage_requested.connect(func(amount: float) -> void: damage_events.append(amount))
	target.position = enemy.position + Vector2(8, 0)
	await physics_frame
	await physics_frame
	expect(damage_events.is_empty(), "Alvo próximo fora da camada actors não deve receber dano")
	target.collision_layer = 2
	await physics_frame
	await physics_frame
	expect(damage_events == [14.0], "Sobreposição real da DamageArea deve solicitar 14 de dano")
	target.collision_layer = 0
	for frame in 75:
		await physics_frame
	expect(damage_events == [14.0], "Alvo fora da DamageArea não deve receber dano após o cooldown")

	var defeated: Array[Node] = []
	enemy.defeated.connect(func(value: Node) -> void: defeated.append(value))
	var before_knockback: Vector2 = enemy.position
	enemy.receive_attack(35.0, Vector2(36, 0))
	expect(enemy.health == 30.0, "Ataque deve reduzir HP mantido pelo inimigo")
	await physics_frame
	expect(enemy.position.x > before_knockback.x, "Ataque deve aplicar knockback")
	enemy.receive_attack(35.0, Vector2.ZERO)
	expect(defeated.size() == 1 and defeated[0] == enemy, "HP esgotado deve emitir defeated com o inimigo")
	target.queue_free()
	await process_frame


func test_enemy_knockback_respects_world_collision() -> void:
	var barrier := StaticBody2D.new()
	barrier.collision_layer = 1
	barrier.collision_mask = 2
	barrier.position = Vector2(30, 0)
	var barrier_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(10, 100)
	barrier_shape.shape = rectangle
	barrier.add_child(barrier_shape)

	var enemy := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate()
	enemy.position = Vector2.ZERO
	root.add_child(barrier)
	root.add_child(enemy)
	await physics_frame
	enemy.receive_attack(1.0, Vector2(300, 0))
	for frame in 12:
		await physics_frame
	expect(enemy.position.x > 0.0, "Knockback deve mover o inimigo como impulso físico")
	expect(enemy.position.x < 20.0, "Knockback não deve atravessar barreira na camada world")
	expect(enemy.health == 64.0, "Knockback físico deve preservar aplicação de dano")
	enemy.queue_free()
	barrier.queue_free()
	await process_frame


func test_resource_contract() -> void:
	var pickup := (load("res://scenes/objects/resource_pickup.tscn") as PackedScene).instantiate()
	pickup.resource_id = "wood_test"
	pickup.kind = "wood"
	expect(pickup.get_node("Sprite") is Sprite2D, "Recurso deve ter Sprite2D")
	expect(pickup.get_node("DetectionShape") is CollisionShape2D, "Recurso deve ter forma de detecção")
	expect(pickup.collision_layer == 4, "Recurso deve estar na camada interaction")
	expect(pickup.collision_mask == 2, "Recurso deve detectar actors")
	root.add_child(pickup)
	await process_frame
	var requests: Array[Node] = []
	pickup.collection_requested.connect(func(value: Node) -> void: requests.append(value))
	pickup.request_collection()
	expect(requests.size() == 1 and requests[0] == pickup, "Recurso disponível deve emitir collection_requested")
	pickup.set_collected(true)
	expect(not pickup.visible and not pickup.monitoring and not pickup.monitorable, "Recurso coletado deve sumir e parar de monitorar")
	pickup.request_collection()
	expect(requests.size() == 1, "Recurso coletado não deve solicitar nova coleta")
	pickup.set_collected(false)
	expect(pickup.visible and pickup.monitoring and pickup.monitorable, "Recurso renovado deve restaurar visual e detecção")
	pickup.queue_free()
	await process_frame


func test_world_resources() -> void:
	var island := (load("res://scenes/world/island.tscn") as PackedScene).instantiate()
	root.add_child(island)
	await process_frame
	var expected := expected_resources()
	var pickups: Array[Node] = island.get_resource_nodes()
	expect(pickups.size() == EXPECTED_RESOURCE_COUNT, "Ilha deve instanciar os 69 recursos da expedição")
	var actual := {}
	for pickup: Node in pickups:
		actual[pickup.resource_id] = pickup.kind
	expect(actual.size() == expected.size(), "IDs dos recursos devem ser únicos")
	for resource_id: String in expected:
		expect(actual.has(resource_id), "Recurso ausente: " + resource_id)
		if actual.has(resource_id):
			expect(actual[resource_id] == expected[resource_id].kind, "Tipo divergente: " + resource_id)
	island.set_visual_state({"wood_01": true}, 0, 0.0, 0.0, false)
	var wood_01: Node = pickups.filter(func(node: Node) -> bool: return node.resource_id == "wood_01")[0]
	expect(not wood_01.visible and not wood_01.monitoring, "Estado visual deve esconder recurso coletado")
	island.set_visual_state({}, 0, 0.0, 0.0, false)
	expect(wood_01.visible and wood_01.monitoring, "Estado visual deve renovar recurso comum")
	island.queue_free()
	await process_frame


func test_game_ui_contract() -> void:
	var ui := (load("res://scenes/ui/game_ui.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	expect(ui.root == ui.get_node("Root"), "UI deve referenciar o Root declarado na cena")
	expect(ui.hud == ui.get_node("Root/HUD"), "UI deve referenciar o HUD declarado na cena")
	expect(ui.shelter == ui.get_node("Root/Shelter"), "UI deve referenciar o Shelter declarado na cena")
	expect(ui.modal == ui.get_node("Root/Modal"), "UI deve referenciar o Modal declarado na cena")
	expect(ui.life is ProgressBar and ui.life.name == "Life", "HUD deve expor a barra Life real")
	expect(ui.energy is ProgressBar and ui.energy.name == "Energy", "HUD deve expor a barra Energy real")
	expect(ui.toast_label is Label and ui.toast_label.name == "Toast", "HUD deve expor o Toast real")
	expect(ui.prompt is Label and ui.prompt.name == "Prompt", "HUD deve expor o Prompt real")
	var direction_arrow := ui.get_node_or_null("Root/HUD/DirectionArrow") as Label
	expect(direction_arrow != null, "HUD deve declarar uma seta real para a direção do farol")
	expect(ui.has_method("set_lighthouse_direction"), "UI deve aceitar o vetor global em direção ao farol")
	var actions: Array[String] = []
	ui.action_requested.connect(func(action_name: String, _payload: String) -> void: actions.append(action_name))
	ui.show_menu(false)
	ui.get_node("Root/Modal/Content/Buttons/New").pressed.emit()
	expect(actions == ["new"], "Botão real da nova expedição deve emitir a API action_requested")
	ui.show_play()
	expect(ui.hud.visible and not ui.modal.visible, "show_play deve alternar os nós reais de HUD e Modal")
	if direction_arrow != null and ui.has_method("set_lighthouse_direction"):
		var arrow_cases := {
			Vector2.UP: 0.0,
			Vector2.RIGHT: PI / 2.0,
			Vector2.DOWN: PI,
			Vector2.LEFT: -PI / 2.0,
		}
		for direction: Vector2 in arrow_cases:
			ui.set_lighthouse_direction(direction)
			var rotation_error: float = absf(wrapf(direction_arrow.rotation - arrow_cases[direction], -PI, PI))
			expect(rotation_error < 0.001, "Seta deve apontar para o farol em %s" % direction)
		expect(direction_arrow.is_visible_in_tree(), "Seta deve permanecer visível durante o jogo")
	ui.toast("Teste de aviso", 2.0)
	expect(ui.toast_label.text == "Teste de aviso", "toast deve atualizar o Label real")
	ui.queue_free()
	await process_frame


func test_effects_component_contract() -> void:
	expect(ResourceLoader.exists("res://scenes/effects/burst_effects.tscn"), "Efeitos devem existir como cena independente")
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var effects: Node = game.get_node("World/Effects")
	expect(effects.has_method("burst"), "Componente de efeitos deve expor burst")
	expect(effects.has_method("clear_effects"), "Componente de efeitos deve expor clear_effects")
	var pool_size := effects.get_child_count()
	expect(pool_size > 0, "Pool de partículas deve ser predeclarado na cena")
	game.burst(Vector2(40, 25), Color("efbd70"), 6)
	await process_frame
	expect(effects.get_child_count() == pool_size, "Controlador deve reutilizar o pool sem criar nós visuais")
	var active_particles := effects.get_children().filter(func(node: Node) -> bool:
		return node is CPUParticles2D and node.emitting and node.position == Vector2(40, 25)
	)
	expect(not active_particles.is_empty(), "burst deve ativar uma partícula real do componente")
	if effects.has_method("clear_effects"):
		effects.call("clear_effects")
		expect(effects.get_children().all(func(node: Node) -> bool:
			return not node is CPUParticles2D or not node.emitting
		), "clear_effects deve interromper todo o pool")
	game.sound.set_muted(true)
	game.queue_free()
	await process_frame


func test_world_y_sort_policy() -> void:
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var world := game.get_node("World") as Node2D
	var island := game.get_node("World/Island") as Node2D
	var enemies := game.get_node("World/Enemies") as Node2D
	var player := game.get_node("World/Player") as Node2D
	expect(world.y_sort_enabled, "World deve compartilhar ordenação Y entre ilha e atores")
	expect(island.y_sort_enabled, "Island deve propagar Y-sort aos contêineres de mundo")
	expect(enemies.y_sort_enabled, "Enemies deve manter ordenação Y entre inimigos")
	expect(player.z_index == 0, "Player não deve usar z_index que contorne a política de Y-sort")
	for container_name: String in ["Decorations", "Resources", "Structures"]:
		expect(island.get_node(container_name).y_sort_enabled, "%s deve participar da ordenação Y" % container_name)
	game.free()


func test_eight_direction_combat() -> void:
	var game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.save_path = "user://task6_four_direction.json"
	root.add_child(game)
	await process_frame
	game.sound.set_muted(true)
	game.start_new_game()
	game.begin_play()
	game._clear_enemies()
	game.player.set_physics_process(false)
	if not game.player.has_method("request_attack_at"):
		expect(false, "Combate em oito direções requer request_attack_at")
		game.sound.set_muted(true)
		game.queue_free()
		await process_frame
		return
	var directions: Array[Vector2] = [
		Vector2.UP, Vector2(1, -1).normalized(), Vector2.RIGHT, Vector2(1, 1).normalized(),
		Vector2.DOWN, Vector2(-1, 1).normalized(), Vector2.LEFT, Vector2(-1, -1).normalized(),
	]
	for direction: Vector2 in directions:
		var enemy := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as Enemy
		enemy.global_position = game.player.global_position + direction * 42.0
		enemy.configure(game.player, 0.0)
		game.enemies_node.add_child(enemy)
		enemy.set_physics_process(false)
		game.player.face_movement(direction.rotated(PI / 2.0))
		await physics_frame
		await physics_frame
		game.player._attack_cooldown = 0.0
		game.attack_cooldown = 0.0
		game.player.request_attack_at(game.player.global_position + direction * 120.0)
		await physics_frame
		await physics_frame
		expect(game.player.attack_area.overlaps_body(enemy), "Área de ataque deve alcançar inimigo em %s" % direction)
		expect(enemy.health == 30.0, "Ataque deve causar 35 de dano em %s" % direction)
		enemy.queue_free()
		await physics_frame

	for direction: Vector2 in directions:
		var enemy := (load("res://scenes/actors/enemy.tscn") as PackedScene).instantiate() as Enemy
		enemy.global_position = game.player.global_position + direction * 12.0
		enemy.configure(game.player, 0.0)
		enemy.set_world_state(false, Vector2.ZERO, 0.0, false)
		enemy.damage_requested.connect(game._on_enemy_damage_requested)
		game.enemies_node.add_child(enemy)
		enemy.set_physics_process(false)
		await physics_frame
		await physics_frame
		expect(enemy.damage_area.overlaps_body(game.player), "Área de dano deve alcançar jogador em %s" % direction)
		game.state.health = 100.0
		game.hurt_flash = 0.0
		enemy._attack_cooldown = 0.0
		enemy._physics_process(0.0)
		expect(game.state.health == 86.0, "Inimigo deve causar 14 de dano em %s" % direction)
		enemy.queue_free()
		await physics_frame

	print("Combate dirigido: ataque de 35 e dano inimigo de 14 verificados em oito direções")
	game.queue_free()
	await process_frame
	if FileAccess.file_exists("user://task6_four_direction.json"):
		DirAccess.remove_absolute("user://task6_four_direction.json")

func run() -> void:
	ensure_input_actions()
	var required := {
		"res://scenes/world/island.tscn": "Node2D",
		"res://scenes/actors/player.tscn": "CharacterBody2D",
		"res://scenes/actors/enemy.tscn": "CharacterBody2D",
		"res://scenes/objects/resource_pickup.tscn": "Area2D",
		"res://scenes/objects/lighthouse.tscn": "StaticBody2D",
		"res://scenes/objects/storage.tscn": "StaticBody2D",
		"res://scenes/ui/game_ui.tscn": "CanvasLayer",
	}
	var required_groups := {
		"res://scenes/actors/player.tscn": "player",
		"res://scenes/actors/enemy.tscn": "enemies",
		"res://scenes/objects/resource_pickup.tscn": "resources",
		"res://scenes/objects/lighthouse.tscn": "structures",
		"res://scenes/objects/storage.tscn": "structures",
	}
	for path: String in required:
		expect(ResourceLoader.exists(path), "Cena ausente: " + path)
		if ResourceLoader.exists(path):
			var node: Node = load(path).instantiate()
			expect(node.get_class() == required[path], "%s deve usar %s" % [path, required[path]])
			if path in required_groups:
				expect(node.is_in_group(required_groups[path]), "%s deve estar no grupo %s" % [path, required_groups[path]])
			node.free()
	if ResourceLoader.exists("res://scenes/actors/player.tscn"):
		await test_player_contract()
	if ResourceLoader.exists("res://scenes/actors/player.tscn") \
			and ResourceLoader.exists("res://scenes/objects/resource_pickup.tscn"):
		await test_interaction_priority()
	if ResourceLoader.exists("res://scenes/actors/enemy.tscn"):
		await test_enemy_contract()
		await test_enemy_knockback_respects_world_collision()
	if ResourceLoader.exists("res://scenes/objects/resource_pickup.tscn"):
		await test_resource_contract()
	if ResourceLoader.exists("res://scenes/world/island.tscn") \
			and ResourceLoader.exists("res://scenes/objects/resource_pickup.tscn"):
		await test_world_resources()
	if ResourceLoader.exists("res://scenes/ui/game_ui.tscn"):
		await test_game_ui_contract()
	await test_effects_component_contract()
	test_world_y_sort_policy()
	await test_eight_direction_combat()
	quit(1 if failures else 0)
