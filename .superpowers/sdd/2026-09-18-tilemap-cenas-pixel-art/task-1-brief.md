### Task 1: Contratos de arquitetura e configuração raster

**Files:**
- Create: `tests/test_scene_architecture.gd`
- Modify: `project.godot`

**Interfaces:**
- Produces: grupos `player`, `enemies`, `resources`, `structures`; camadas físicas 1 `world`, 2 `actors`, 3 `interaction`, 4 `combat`.
- Produces: contrato de caminhos/tipos que todas as tarefas seguintes devem satisfazer.

- [ ] **Step 1: Escrever o teste de arquitetura inicialmente falho**

```gdscript
extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run")

func expect(value: bool, message: String) -> void:
    if not value:
        failures += 1
        push_error(message)

func run() -> void:
    var required := {
        "res://scenes/world/island.tscn": "Node2D",
        "res://scenes/actors/player.tscn": "CharacterBody2D",
        "res://scenes/actors/enemy.tscn": "CharacterBody2D",
        "res://scenes/objects/resource_pickup.tscn": "Area2D",
        "res://scenes/objects/lighthouse.tscn": "StaticBody2D",
        "res://scenes/objects/storage.tscn": "StaticBody2D",
        "res://scenes/ui/game_ui.tscn": "CanvasLayer",
    }
    for path: String in required:
        expect(ResourceLoader.exists(path), "Cena ausente: " + path)
        if ResourceLoader.exists(path):
            var node := load(path).instantiate()
            expect(node.get_class() == required[path], "%s deve usar %s" % [path, required[path]])
            node.free()
    var island_source := FileAccess.get_file_as_string("res://scripts/island_world.gd")
    var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
    expect(not island_source.contains("func _draw"), "Ilha não pode usar desenho procedural")
    expect(not game_source.contains("func draw_player"), "Controlador não pode desenhar jogador")
    expect(not game_source.contains("func draw_animal"), "Controlador não pode desenhar inimigo")
    quit(1 if failures else 0)
```

- [ ] **Step 2: Executar e confirmar falha pelas cenas ausentes**

Run: `godot --headless --path . --script tests/test_scene_architecture.gd`

Expected: exit 1 e mensagens `Cena ausente`.

- [ ] **Step 3: Configurar pixels e camadas físicas no projeto**

Adicionar em `project.godot`:

```ini
[layer_names]
2d_physics/layer_1="world"
2d_physics/layer_2="actors"
2d_physics/layer_3="interaction"
2d_physics/layer_4="combat"

[rendering]
textures/default_filters/use_nearest_mipmap_filter=false
textures/canvas_textures/default_texture_filter=0
```

- [ ] **Step 4: Registrar o checkpoint**

Confirmar que somente teste/configuração desta tarefa mudaram; commit `test: define scene architecture contracts` apenas se Git voltar a estar disponível.

---

