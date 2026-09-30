extends SceneTree

var failures := 0


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("run")


func bordered_panel(ui: Node, path: String) -> void:
	var panel := ui.get_node_or_null(path) as Panel
	check(panel != null, "%s deve fornecer background próprio" % path)
	if panel == null:
		return
	var style := panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(style != null, "%s deve usar moldura pixelada dedicada" % path)
	if style != null:
		check(style.bg_color.a >= 0.85, "%s deve manter o HUD legível sobre a ilha" % path)
		check(style.border_width_left >= 1 and style.border_width_top >= 1, "%s deve possuir borda visível" % path)
		check(style.corner_radius_top_left <= 6, "%s deve manter cantos compactos de jogo pixel art" % path)


func run() -> void:
	var ui := (load("res://scenes/ui/game_ui.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	for path: String in ["Root/HUD/UnifiedBar", "Root/HUD/ObjectiveBackdrop", "Root/HUD/PromptBackdrop"]:
		bordered_panel(ui, path)
	for obsolete_path: String in ["Root/HUD/StatusBackdrop", "Root/HUD/ClockBackdrop", "Root/HUD/InventoryBackdrop", "Root/HUD/ControlsBackdrop"]:
		check(ui.get_node_or_null(obsolete_path) == null, "%s não deve fragmentar a nova barra unificada" % obsolete_path)
	var unified_bar := ui.get_node_or_null("Root/HUD/UnifiedBar") as Panel
	if unified_bar != null:
		check(unified_bar.size.x >= 1000.0, "Barra de sobrevivência deve unificar a maior parte da base da tela")
	var portrait := ui.get_node_or_null("Root/HUD/Portrait") as TextureRect
	check(portrait != null and portrait.texture != null, "HUD deve exibir retrato pixel art do personagem")
	var resource_strip := ui.get_node_or_null("Root/HUD/ResourceStrip") as Control
	check(resource_strip != null, "HUD deve reunir os recursos em uma faixa visual")
	for resource_name: String in ["Wood", "Stone", "Scrap", "Part", "Food"]:
		var icon := ui.get_node_or_null("Root/HUD/ResourceStrip/%s/Icon" % resource_name) as TextureRect
		var count := ui.get_node_or_null("Root/HUD/ResourceStrip/%s/Count" % resource_name) as Label
		check(icon != null and icon.texture is AtlasTexture, "%s deve usar ícone pixel art do atlas" % resource_name)
		check(count != null, "%s deve exibir sua quantidade junto do desenho" % resource_name)
	bordered_panel(ui, "Root/Modal/MenuFrame")
	var normal_button := ui.get_node("Root/Modal/Content/Buttons/New") as Button
	var normal_style := normal_button.get_theme_stylebox("normal") as StyleBoxFlat
	check(normal_style != null and normal_style.border_width_left >= 1, "Botões do menu devem compartilhar moldura visível")
	ui.show_intro()
	check("noite já" in ui.modal_body.text.to_lower(), "Introdução deve informar que a expedição começa durante a noite")
	ui.show_play()
	var prompt_backdrop := ui.get_node_or_null("Root/HUD/PromptBackdrop") as Panel
	var state = load("res://scripts/survival_state.gd").new()
	state.bag = {"wood": 2, "stone": 4, "scrap": 6, "part": 1, "food": 3}
	ui.update_hud(state, 100.0, "", false)
	var expected_counts := {"Wood": "2", "Stone": "4", "Scrap": "6", "Part": "1", "Food": "3"}
	for resource_name: String in expected_counts:
		var count := ui.get_node_or_null("Root/HUD/ResourceStrip/%s/Count" % resource_name) as Label
		if count != null:
			check(count.text == expected_counts[resource_name], "%s deve atualizar sua contagem visual" % resource_name)
	if prompt_backdrop != null:
		check(not prompt_backdrop.visible, "Background de interação deve desaparecer sem ação disponível")
	ui.update_hud(state, 100.0, "E  ·  Coletar madeira", false)
	if prompt_backdrop != null:
		check(prompt_backdrop.visible, "Background de interação deve aparecer junto da ação contextual")
	print("Interface sandbox: HUD e menu possuem backgrounds com molduras pixeladas")
	ui.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
