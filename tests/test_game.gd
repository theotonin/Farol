extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")


func resource_positions(game) -> Dictionary:
	var positions := {}
	for pickup: Node2D in game.island.get_resource_nodes():
		positions[pickup.resource_id] = pickup.position
	return positions

func run() -> void:
	if not ResourceLoader.exists("res://scenes/main.tscn"):
		check(false, "A cena principal jogável ainda não existe.")
		quit(1)
		return
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var integrated_player: Variant = game.get("player")
	var integrated_island: Variant = game.get("island")
	var integrated_enemies: Variant = game.get("enemies_node")
	check(integrated_player is CharacterBody2D, "Jogador integrado deve ser corpo físico")
	check(integrated_island != null and integrated_island.get_node_or_null("Ground") is TileMapLayer, "Mundo integrado deve usar TileMapLayer")
	check(integrated_enemies is Node2D, "Controlador deve expor o contêiner real de inimigos")
	check(not game.enemies_node.can_process(), "Inimigos devem ficar desativados no menu")
	if not integrated_player is CharacterBody2D or integrated_island == null or not integrated_enemies is Node2D:
		game.queue_free()
		await process_frame
		print("Integração: ", failures, " falhas")
		quit(1)
		return
	game.save_path = "user://integration_test.json"
	game.start_new_game()
	var first_distribution := resource_positions(game)
	var first_seed: int = game.state.world_seed
	game.start_new_game()
	var second_distribution := resource_positions(game)
	check(game.state.world_seed != first_seed, "Cada nova partida deve sortear uma nova semente de recursos")
	check(second_distribution != first_distribution, "Cada nova partida deve espalhar os drops em posições diferentes")
	check(game.mode == "intro", "Nova partida deve apresentar a introdução.")
	check(game.state.is_night(), "Nova partida deve preparar o mundo durante a noite")
	check(game.camera.zoom.is_equal_approx(Vector2(1.5, 1.5)), "Nova partida deve aproximar a câmera em 1,5x para destacar o personagem")
	check(not game.enemies_node.can_process(), "Inimigos devem ficar desativados na introdução")
	game.begin_play()
	check(game.mode == "playing", "Introdução deve permitir jogar.")
	check(game.enemies_node.get_child_count() == 4, "A primeira noite deve começar com quatro inimigos noturnos")
	game.island.distribute_resources(999999)
	game.continue_game()
	check(resource_positions(game) == second_distribution, "Carregar deve restaurar a distribuição salva da partida")
	check(game.enemies_node.can_process(), "Inimigos devem processar somente durante a partida")
	var integrated_arrow := game.ui.get_node_or_null("Root/HUD/DirectionArrow") as Label
	check(integrated_arrow != null, "Jogo deve integrar a seta declarativa do farol")
	if integrated_arrow != null:
		game.player.global_position = Vector2(100, 0)
		game.update_view()
		var left_rotation_error: float = absf(wrapf(integrated_arrow.rotation + PI / 2.0, -PI, PI))
		check(left_rotation_error < 0.001, "Controlador deve alimentar a seta com -player_position")
		check(game.ui.direction_label.text.begins_with("Farol · "), "Distância textual do farol deve ser preservada")
		game.player.global_position = IslandWorld.SPAWN
		game.update_view()
	check(game.enemies_node.get_child_count() > 0, "Inimigos devem ser cenas instanciadas")
	check(game.enemies_node.get_child(0) is CharacterBody2D, "Inimigo integrado deve ser corpo físico")
	var original_position: Vector2 = game.player.global_position
	Input.action_press("move_right")
	for i in range(12):
		await physics_frame
	Input.action_release("move_right")
	check(game.player.global_position.x > original_position.x, "WASD deve mover o jogador.")
	game.player.global_position = Vector2(5000, 5000)
	game.save_checkpoint()
	game.continue_game()
	check(game.player.global_position.distance_to(IslandWorld.SPAWN) < 1.0, "Posição inválida carregada deve retornar ao spawn.")
	check(game.camera.zoom.is_equal_approx(Vector2(1.5, 1.5)), "Continuar partida deve preservar a câmera aproximada em 1,5x")
	var resource: Node = game.island.get_resource_nodes()[0]
	game.player.global_position = resource.global_position
	await physics_frame
	await physics_frame
	game.interact()
	check(game.state.bag_count() > 0, "Interação deve coletar recurso próximo.")
	check(game.ui.pickup_notice.visible, "Coleta real deve mostrar o aviso compacto junto da mochila")
	game.player.global_position = IslandWorld.SPAWN
	game.handle_action("deposit", "")
	check(game.state.bag_count() == 0, "Depósito deve retirar os itens da mochila.")
	game.state.fuel = 60.0
	game.state.time_of_day = 250.0
	check(game.player_is_safe(), "Fogueira acesa deve proteger dentro do abrigo.")
	game.state.fuel = 0.0
	check(not game.player_is_safe(), "Abrigo sem fogo deve perder proteção.")
	game.state.health = 1.0
	game.state.bag.food = 2
	game.hurt_player(10.0)
	check(game.state.health == 100.0 and game.state.bag_count() == 0, "Morte deve recuperar vida e perder mochila.")
	check(game.player.global_position.distance_to(IslandWorld.SPAWN) < 1.0, "Morte deve devolver jogador ao abrigo.")
	var time_before: float = game.state.time_of_day
	var pause_enemy: Enemy = game.enemies_node.get_child(0) as Enemy
	pause_enemy.global_position = game.player.global_position + Vector2(8, 0)
	pause_enemy._attack_cooldown = 0.0
	game.state.health = 100.0
	game.hurt_flash = 0.0
	game.pause_game()
	check(not game.enemies_node.can_process(), "Pausa deve desativar o processamento dos inimigos")
	var paused_enemy_position: Vector2 = pause_enemy.global_position
	for i in range(5):
		await physics_frame
	check(game.state.time_of_day == time_before, "Pausa deve parar o relógio.")
	check(pause_enemy.global_position.is_equal_approx(paused_enemy_position), "Inimigo não deve mover durante a pausa")
	check(game.state.health == 100.0, "Inimigo não deve causar dano durante a pausa")
	game.hurt_player(14.0)
	check(game.state.health == 100.0, "hurt_player deve ignorar chamadas fora de playing")
	game.handle_action("resume", "")
	check(game.enemies_node.can_process(), "Retomar deve reativar os inimigos")
	game.player.global_position = Vector2(900, 0)
	game.state.storage.wood = 50
	game.handle_action("fuel", "")
	check(game.state.fuel == 0.0, "Não deve abastecer fogueira remotamente.")
	game.player.global_position = IslandWorld.SPAWN
	game.state.storage.wood = 100
	game.state.storage.stone = 100
	game.state.storage.scrap = 100
	for node: Node in game.island.get_resource_nodes():
		if node.kind == "part":
			game.state.collect(node.kind, node.resource_id)
	game.state.deposit_all()
	for i in range(3):
		game.handle_action("repair", "")
	check(game.state.repair_stage == 3 and not game.state.won, "Reparos completos devem aguardar acendimento explícito.")
	game.continue_game()
	check(game.state.repair_stage == 3 and game.mode == "playing", "Checkpoint final deve carregar com peças consumidas válidas.")
	var rescue_enemy: Enemy = game.enemies_node.get_child(0) as Enemy
	rescue_enemy.global_position = game.player.global_position + Vector2(8, 0)
	rescue_enemy._attack_cooldown = 0.0
	game.state.health = 100.0
	game.hurt_flash = 0.0
	game.handle_action("ignite", "")
	check(game.state.won and game.mode == "rescue", "Acender farol deve iniciar resgate.")
	check(not game.enemies_node.can_process(), "Resgate deve desativar o processamento dos inimigos")
	var rescue_enemy_position: Vector2 = rescue_enemy.global_position
	for i in range(5):
		await physics_frame
	check(rescue_enemy.global_position.is_equal_approx(rescue_enemy_position), "Inimigo não deve mover durante o resgate")
	check(game.state.health == 100.0, "Inimigo não deve causar dano durante o resgate")
	game.hurt_player(14.0)
	check(game.state.health == 100.0, "hurt_player deve ignorar dano durante o resgate")
	for i in range(8):
		game._physics_process(1.0)
	check(game.mode == "victory", "Resgate deve terminar na tela de vitória.")
	check(not game.enemies_node.can_process(), "Vitória deve manter os inimigos desativados")
	game.sound.set_muted(true)
	game.queue_free()
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://integration_test.json"):
		DirAccess.remove_absolute("user://integration_test.json")
	print("Integração: ", failures, " falhas")
	quit(1 if failures else 0)
