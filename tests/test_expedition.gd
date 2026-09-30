extends SceneTree
## Executa o caminho até o resgate usando recursos reais do mapa e ações do jogo.

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save_path = "user://expedition_test.json"
	game.start_new_game()
	game.begin_play()
	# O combate noturno é coberto por test_game.gd. Aqui isolamos a economia
	# para que inimigos não interfiram no transporte instantâneo entre pickups.
	game._clear_enemies()
	# Coleta recursos reais sem adulterar inventários. Transporte instantâneo isola
	# a economia; movimento físico é exercitado separadamente em test_game.gd.
	for resource: Node in game.island.get_resource_nodes():
		if game.state.bag_count() == 20:
			deposit(game)
		game.player.global_position = resource.global_position
		await physics_frame
		await physics_frame
		game.update_view()
		var before: int = game.state.bag_count()
		game.interact()
		check(game.state.bag_count() == before + 1, "Recurso deve ser acessível: " + resource.resource_id)
	deposit(game)
	check(game.state.storage.part == 3, "Mapa deve fornecer as três peças únicas.")
	for i in range(4):
		game.handle_action("fuel", "")
	check(game.state.fuel == 120.0, "Madeira do mapa deve sustentar uma noite inteira.")
	# Ciclo completo sem dano no abrigo e sem renovar peças únicas.
	game.state.time_of_day = 239.5
	game._physics_process(0.5)
	check(game.state.is_night(), "O relógio deve entrar na noite.")
	check(game.enemies_node.get_child_count() == 4, "A primeira noite deve gerar quatro animais.")
	for enemy: Node2D in game.enemies_node.get_children():
		check(enemy.global_position.length() > 180.0, "Animais não devem nascer dentro do abrigo.")
	game._physics_process(119.0)
	check(game.state.health == 100.0, "Fogueira deve proteger contra dano noturno.")
	game._physics_process(1.0)
	check(game.state.day == 2 and not game.state.is_night(), "Noite deve terminar na manhã seguinte.")
	check(game.state.collected.size() == 3, "Manhã deve renovar comuns, preservando as peças guardadas.")
	game.continue_game()
	check(game.mode == "playing" and game.state.day == 2, "Autosave da manhã deve restaurar a expedição.")
	for stage in range(3):
		game.handle_action("repair", "")
		check(game.state.repair_stage == stage + 1, "Recursos do mapa devem financiar etapa %d." % (stage + 1))
		game.continue_game()
		check(game.state.repair_stage == stage + 1, "Cada reparo deve persistir em checkpoint válido.")
	check(not game.state.won, "Reparo sozinho não deve encerrar a partida.")
	game.handle_action("ignite", "")
	check(game.state.won and game.mode == "rescue", "Ação final deve iniciar resgate.")
	game.continue_game()
	check(game.mode == "victory", "Carregar partida concluída deve mostrar o resgate.")
	game.queue_free()
	await create_timer(0.2).timeout
	if FileAccess.file_exists("user://expedition_test.json"):
		DirAccess.remove_absolute("user://expedition_test.json")
	print("Expedição completa: ", failures, " falhas")
	quit(1 if failures else 0)

func deposit(game) -> void:
	game.player.global_position = IslandWorld.SPAWN
	game.handle_action("deposit", "")
