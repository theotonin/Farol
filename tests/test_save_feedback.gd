extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check_error(game, context: String) -> void:
	if game.last_save_ok or not game.ui.toast_label.text.contains("Não foi possível salvar"):
		push_error("Erro de salvamento deve permanecer visível: " + context)
		failures += 1

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	if not game.get("player") is CharacterBody2D or not game.get("ui") is CanvasLayer:
		push_error("Feedback de save deve usar jogador e UI de cena reais")
		failures += 1
		game.queue_free()
		await process_frame
		print("Avisos de salvamento: ", failures, " falhas")
		quit(1)
		return
	game.save_path = "user://directory_that_does_not_exist/save.json"
	game.start_new_game()
	game.begin_play()
	check_error(game, "início")
	game.state.health = 1.0
	game.hurt_player(10.0)
	check_error(game, "morte")
	game.state.repair_stage = 3
	game.handle_action("ignite", "")
	check_error(game, "resgate")
	game.queue_free()
	await create_timer(0.2).timeout
	print("Avisos de salvamento: ", failures, " falhas")
	quit(1 if failures else 0)
