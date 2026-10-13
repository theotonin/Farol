extends SceneTree
## Exporta os mesmos efeitos sintetizados em tempo de execução pelo jogo.

func _initialize() -> void:
	var output := ProjectSettings.globalize_path("res://Game/Audio/Efeitos")
	DirAccess.make_dir_recursive_absolute(output)
	var sound = load("res://scripts/soundscape.gd").new()
	var names := {
		"step": "passos", "swing": "golpe-no-ar", "collect": "coleta",
		"hit": "impacto", "hurt": "dano", "eat": "comer",
		"repair": "reparo", "death": "morte", "dawn": "amanhecer",
		"ignite": "acender-farol", "click": "clique-menu", "fire": "abastecer-fogueira"
	}
	var failures := 0
	seed(20261002)
	for kind in names:
		var stream: AudioStreamWAV = sound._synthesize(kind)
		var result := stream.save_to_wav(output.path_join(names[kind] + ".wav"))
		if result != OK:
			failures += 1
		print(names[kind], ": ", error_string(result))
	sound.free()
	quit(0 if failures == 0 else 1)
