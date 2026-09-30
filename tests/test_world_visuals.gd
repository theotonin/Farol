extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func count_flame_pixels_near_texture_top(sprite: Sprite2D) -> int:
	var image := sprite.texture.get_image()
	var flame_pixels := 0
	for y in mini(28, image.get_height()):
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.a > 0.5 and color.r > 0.85 and color.g > 0.2 and color.g < 0.75 and color.b < 0.18 and color.r > color.g + 0.2:
				flame_pixels += 1
	return flame_pixels


func run() -> void:
	check(ResourceLoader.exists("res://assets/pixel/ground_details.png"), "Detalhes raster do chão devem existir como asset pixel art")

	var pickup := (load("res://scenes/objects/resource_pickup.tscn") as PackedScene).instantiate()
	pickup.kind = "part"
	root.add_child(pickup)
	await process_frame
	var outline := pickup.get_node_or_null("Outline") as Sprite2D
	check(outline != null, "Item coletável deve ter contorno pixelado dedicado")
	if outline != null:
		check(outline.material is ShaderMaterial, "Contorno do item deve ser rasterizado por shader de pixels")
		var color: Color = outline.material.get_shader_parameter("outline_color")
		check(color.r > 0.8 and color.g > 0.55 and color.b < 0.4, "Peça rara deve usar contorno dourado")
	pickup.set_collected(true)
	check(not pickup.visible, "Contorno deve desaparecer junto com o item coletado")
	pickup.queue_free()
	await process_frame

	var island := (load("res://scenes/world/island.tscn") as PackedScene).instantiate()
	root.add_child(island)
	await process_frame
	var decorations := island.get_node("Decorations")
	var detail_kinds := {}
	var decorative_fires := 0
	var collision_decorations := 0
	var flame_contaminated_trees := 0
	for decoration: Node in decorations.get_children():
		var kind := String(decoration.get_meta("detail_kind", ""))
		if not kind.is_empty():
			detail_kinds[kind] = true
		if kind == "campfire":
			decorative_fires += 1
		if kind in ["broadleaf_tree", "pine_tree"] and decoration is Sprite2D:
			if count_flame_pixels_near_texture_top(decoration) > 0:
				flame_contaminated_trees += 1
		if decoration is CollisionObject2D:
			collision_decorations += 1
	check(decorative_fires == 0, "Somente a fogueira do abrigo pode permanecer na ilha")
	check(flame_contaminated_trees == 0, "Árvores decorativas não podem reutilizar pixels das fogueiras do atlas")
	check(detail_kinds.size() >= 4, "Chão deve combinar ao menos quatro tipos de detalhe ambiental")
	check(decorations.get_child_count() >= 180, "Chão deve receber detalhes suficientes para não parecer vazio")
	check(collision_decorations == 0, "Detalhes ambientais devem ser totalmente atravessáveis")
	var campfires := island.find_children("*", "Campfire", true, false)
	check(campfires.size() == 1, "A ilha deve conter exatamente a fogueira interativa do abrigo")

	print("Visuais do mundo: %d detalhes, %d tipos, %d fogueira interativa" % [decorations.get_child_count(), detail_kinds.size(), campfires.size()])
	island.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)
