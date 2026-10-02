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
	var style := panel.get_theme_stylebox("panel")
	check(style is StyleBoxTexture or style is StyleBoxFlat, "%s deve usar moldura pixelada dedicada" % path)


func run() -> void:
	var ui := (load("res://scenes/ui/game_ui.tscn") as PackedScene).instantiate()
	root.add_child(ui)
	await process_frame
	for path: String in ["Root/HUD/StatusBackdrop", "Root/HUD/ClockBackdrop", "Root/HUD/ObjectiveBackdrop", "Root/HUD/PromptBackdrop"]:
		bordered_panel(ui, path)
	var unified_bar := ui.get_node_or_null("Root/HUD/UnifiedBar") as Panel
	if unified_bar != null:
		check(unified_bar.size.x <= 460.0 and unified_bar.size.y <= 90.0, "Mochila deve ocupar uma faixa compacta, liberando a paisagem")
	check(ui.life.get_global_rect().position.y < 100.0, "Vida deve estar no topo para leitura rápida")
	check(ui.clock_label.get_global_rect().position.y < 100.0, "Relógio deve estar no topo")
	check(not ui.get_node("Root/HUD/Controls").visible, "Atalhos completos não devem ocupar permanentemente o HUD")
	check(ui.hud.get_theme_font("font") is FontFile, "HUD deve usar fonte pixelada própria")
	check(ui.hud.get_theme_font("font").get_font_name() == "Faroleiro", "HUD deve carregar a fonte bitmap original")
	for glyph in "ãáêçó":
		check(ui.hud.get_theme_font("font").has_char(glyph.unicode_at(0)), "Fonte deve oferecer os acentos usados no HUD: " + glyph)
	check(ui.hud.get_node_or_null("Identity") != null, "HUD deve apresentar o símbolo do farol e as três etapas")
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
	ui.toast("Aviso importante de sobrevivência")
	ui.toggle_shelter()
	ui.update_hud(state, 100.0, "E  ·  Coletar madeira", false)
	check(not ui.toast_backdrop.get_global_rect().intersects(ui.shelter.get_global_rect()), "Avisos não devem ficar escondidos atrás do abrigo")
	check(not ui.hud.get_node("ResourceStrip").get_global_rect().intersects(ui.shelter.get_global_rect()), "Mochila deve permanecer totalmente visível com o abrigo aberto")
	check(not prompt_backdrop.visible, "Abrigo aberto deve recolher o comando contextual")
	state.repair_stage = 2
	ui.update_hud(state, 100.0, "", false)
	check(ui.hud.get_node("Identity").repair_stage == 2, "Marcadores do farol devem acompanhar reparos reais")
	ui.shelter.hide()
	ui.update_hud(state, 100.0, "E  ·  Coletar madeira", false)
	check(prompt_backdrop.size.x < 320.0, "Comando de coleta deve ajustar a largura ao texto")
	check(ui.has_method("show_pickup"), "Coleta deve usar um aviso compacto próprio")
	if ui.has_method("show_pickup"):
		var previous_warning: String = ui.toast_label.text
		ui.show_pickup("wood")
		var notice = ui.hud.get_node("PickupNotice")
		check(notice.visible and notice.size.x <= 96.0 and notice.size.y <= 40.0, "Aviso de coleta deve ser pequeno")
		check(ui.toast_label.text == previous_warning, "Coleta não deve substituir avisos importantes")
		check(not notice.get_global_rect().intersects(ui.hud.get_node("UnifiedBar").get_global_rect()), "Aviso de coleta deve ficar ao lado da mochila")
		ui._process(2.0)
		check(not notice.visible, "Aviso de coleta deve desaparecer sozinho")
	print("Interface Faroleiro: ", failures, " falhas")
	ui.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
