# TileMap, cenas e pixel art — Plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrar o protótipo de desenho procedural para TileMapLayer, cenas independentes, sprites PNG em pixel art e colisões nativas sem alterar as regras do jogo.

**Architecture:** `main.tscn` instancia um mundo editável, jogador, grupos de inimigos/recursos, iluminação e UI. Corpos e áreas nativos substituem posições em dicionários e limites matemáticos; `SurvivalState` continua sendo a fonte das regras persistentes e `game.gd` fica restrito à coordenação.

**Tech Stack:** Godot 4.7, GDScript, TileMapLayer/TileSetAtlasSource, CharacterBody2D, StaticBody2D, Area2D, AnimatedSprite2D, PNG pixel art, renderizador Compatibility.

**Spec:** `docs/superpowers/specs/2026-09-18-tilemap-cenas-pixel-art-design.md`

## Global Constraints

- TileMapLayer para mar, areia, grama, caminhos e costa.
- Sprites PNG rasterizados em pixel art, grade-base 32×32, filtro `nearest` e escala inteira.
- Nenhum `_draw()` para mapa, atores, recursos ou construções.
- Apenas costa e construções bloqueiam jogador e inimigos; decorações são atravessáveis.
- Preservar posições/IDs de recursos, balanceamento, ciclo, salvamento, interface e fluxo de vitória.
- Godot 4.7, Compatibility, viewport 1280×720.
- Os metadados Git do workspace não estão acessíveis; registrar checkpoints no plano, mas não tentar commits enquanto `git status` não funcionar.

## Estrutura de arquivos

### Criar

- `assets/pixel/terrain_atlas.png`: atlas raster de mar, areia, grama, espuma e caminho.
- `assets/pixel/characters.png`: quadros alinhados de jogador e animal.
- `assets/pixel/objects.png`: recursos, decorações e construções.
- `assets/pixel/*.png.import`: imports gerados pela Godot com filtro desativado pelo projeto.
- `resources/island_tileset.tres`: TileSet 32×32 e atlas de terreno.
- `scenes/world/island.tscn`: TileMapLayer, costa, decorações, recursos e estruturas.
- `scenes/actors/player.tscn`, `scenes/actors/enemy.tscn`: corpos físicos e animações.
- `scenes/objects/resource_pickup.tscn`: coletável reutilizável.
- `scenes/objects/lighthouse.tscn`, `campfire.tscn`, `storage.tscn`, `ruin.tscn`: construções/áreas independentes.
- `scenes/ui/game_ui.tscn`: árvore da interface editável.
- `scripts/player.gd`, `enemy.gd`, `resource_pickup.gd`, `lighthouse.gd`, `campfire.gd`, `island_world.gd`: comportamento focado por cena.
- `tests/test_scene_architecture.gd`: contratos de cenas e ausência de desenho procedural.
- `tests/test_world_physics.gd`: colisões, passagem por decoração e áreas de interação.

### Modificar

- `scenes/main.tscn`: composição explícita do jogo.
- `scripts/game.gd`: coordenação por nós/sinais em vez de desenho e dicionários.
- `scripts/game_ui.gd`: referências a nós da cena, sem construção programática.
- `tests/test_game.gd`, `tests/test_expedition.gd`, `tests/test_save_feedback.gd`: integração com corpos reais.
- `project.godot`: filtro de textura nearest e camadas/máscaras físicas nomeadas.
- `README.md`, `DESIGN.md`, `docs/context/cycle.md`: arquitetura e comandos de verificação.

### Preservar

- `scripts/survival_state.gd`: regras e esquema de save, exceto se um teste revelar adaptação estritamente necessária.
- `scripts/soundscape.gd`: áudio atual.
- `tests/test_survival.gd`: regressão das regras persistentes.

---

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

### Task 2: Assets de pixel art e TileSet

**Files:**
- Create: `assets/pixel/terrain_atlas.png`
- Create: `assets/pixel/characters.png`
- Create: `assets/pixel/objects.png`
- Create: `resources/island_tileset.tres`

**Interfaces:**
- Produces: tiles 32×32 com IDs documentados no TileSet; regiões de sprites consistentes para cenas.
- Consumes: paleta de `DESIGN.md` e restrições globais.

- [ ] **Step 1: Gerar três folhas raster em pixel art**

Usar a skill `imagegen` três vezes, salvando os resultados nos caminhos declarados. Prompts:

```text
terrain_atlas.png — Sprite sheet raster em pixel art 2D top-down para jogo de sobrevivência numa ilha sombria. Grade rígida de tiles 32x32, vista totalmente ortográfica, sem perspectiva. Incluir tiles perfeitamente repetíveis de mar azul-petróleo escuro #0a242b, grama #324f42, areia #9a9470, espuma costeira clara #9ab5ab e caminho terroso #716d51, mais transições de costa retas, cantos internos/externos e variações sutis. Arestas pixel-perfect, paleta limitada, sem blur, sem antialiasing, sem texto, sem símbolos, iluminação neutra e consistente.

characters.png — Sprite sheet raster em pixel art 2D top-down, fundo transparente, grade rígida de células 32x32. Um sobrevivente de casaco âmbar e um animal selvagem cinza-azulado. Para cada personagem: quatro direções, dois quadros de caminhada, um quadro parado e um quadro de ataque; pés e pivôs sempre na mesma coordenada de cada célula. Silhuetas legíveis, paleta limitada, pixels duros, sem blur, sem antialiasing, sem texto, sem perspectiva inclinada.

objects.png — Sprite sheet raster em pixel art 2D top-down, fundo transparente e grade rígida de células 32x32 ou múltiplos inteiros. Incluir madeira, pedra, frutas/comida, sucata, peça rara âmbar, árvores, pedras pequenas, marca de solo, ruína, baú-depósito, fogueira apagada e dois quadros acesa, além de farol em quatro estágios de reparo. Paleta sombria coerente com mar #0a242b, floresta #173a35 e destaque #efbd70. Objetos isolados com margem transparente, pixels duros, sem blur, sem antialiasing, sem texto.
```

- [ ] **Step 2: Normalizar dimensões sem redesenhar conteúdo**

Inspecionar os arquivos com `file assets/pixel/*.png` e `identify assets/pixel/*.png` quando ImageMagick estiver disponível. Recortar apenas margens externas e redimensionar exclusivamente por vizinho mais próximo para dimensões múltiplas de 32; nunca interpolar, vetorizar ou criar SVG intermediário. Validar `width % 32 == 0`, `height % 32 == 0` e canal alpha nas folhas de personagens/objetos.

- [ ] **Step 3: Criar `island_tileset.tres`**

Configurar `tile_size = Vector2i(32, 32)`, `Texture2DArray`/`TileSetAtlasSource` sobre `terrain_atlas.png`, terrains para mar, areia, grama, espuma e caminho, e alternativas visuais sem colisão embutida. A colisão da costa será responsabilidade de `island.tscn`.

- [ ] **Step 4: Importar na Godot e verificar nitidez**

Run: `godot --headless --editor --path . --quit-after 3`

Expected: exit 0, `.import` gerados e nenhum erro de atlas/região.

- [ ] **Step 5: Registrar o checkpoint**

Inspecionar visualmente os três PNGs em zoom inteiro; commit `art: add pixel art world and actor sheets` apenas se Git estiver disponível.

---

### Task 3: Mundo TileMap, costa e construções

**Files:**
- Create: `scenes/world/island.tscn`
- Create: `scenes/objects/lighthouse.tscn`
- Create: `scenes/objects/campfire.tscn`
- Create: `scenes/objects/storage.tscn`
- Create: `scenes/objects/ruin.tscn`
- Create: `scripts/island_world.gd`
- Create: `scripts/lighthouse.gd`
- Create: `scripts/campfire.gd`
- Create: `tests/test_world_physics.gd`
- Delete after migration: `scripts/island.gd`

**Interfaces:**
- Produces: `IslandWorld.spawn_position: Vector2`, `is_walkable(point: Vector2) -> bool`, `get_resource_nodes() -> Array[Node]`, `set_visual_state(collected, stage, fuel, night_amount, won)`.
- Produces: `Lighthouse.set_stage(stage: int, won: bool)` e `Campfire.set_fuel(fuel: float, night_amount: float)`.

- [ ] **Step 1: Escrever testes físicos falhos**

```gdscript
extends SceneTree

var failures := 0

func check(value: bool, message: String) -> void:
    if not value:
        failures += 1
        push_error(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var island = load("res://scenes/world/island.tscn").instantiate()
    root.add_child(island)
    await physics_frame
    check(island.get_node("Ground") is TileMapLayer, "O chão deve ser TileMapLayer")
    check(island.get_node("CoastCollision") is StaticBody2D, "A costa deve ser física")
    check(island.get_node("Decorations").get_child_count() > 0, "A ilha deve ter decorações")
    for decoration in island.get_node("Decorations").get_children():
        check(not decoration is CollisionObject2D, "Decoração deve ser atravessável")
    check(island.get_node("Structures/Lighthouse") is StaticBody2D, "Farol deve bloquear")
    check(island.get_node("Structures/Storage") is StaticBody2D, "Depósito deve bloquear")
    island.queue_free()
    await process_frame
    quit(1 if failures else 0)
```

- [ ] **Step 2: Executar o teste e confirmar falha de carregamento**

Run: `godot --headless --path . --script tests/test_world_physics.gd`

Expected: exit diferente de zero porque `island.tscn` ainda não existe.

- [ ] **Step 3: Construir o TileMap da ilha**

Preencher `Ground: TileMapLayer` com mar ao redor, contorno de espuma/areia, interior gramado e os cinco caminhos atuais. Manter a extensão aproximada `(-1430,-1100)` a `(1430,1100)` e centro do farol em `Vector2.ZERO`.

- [ ] **Step 4: Criar a costa física**

Adicionar `StaticBody2D` com segmentos `CollisionPolygon2D`/`CollisionShape2D` cobrindo o mar do lado de fora do contorno. Validar que `Vector2(0,110)` está livre e que pontos além do litoral colidem.

- [ ] **Step 5: Criar construções independentes**

Cada construção terá `Sprite2D` ou `AnimatedSprite2D`, forma física no layer `world`, máscara `actors`, área de interação no layer `interaction` e grupo `structures`. Instanciar farol, depósito, fogueira e quatro ruínas nas posições atuais.

- [ ] **Step 6: Adicionar decorações sem colisão**

Instanciar `Sprite2D` para árvores, pedras e marcas de solo sob `Decorations`, mantendo semente visual determinística e evitando o centro/recursos. Nenhum descendente de `Decorations` pode herdar `CollisionObject2D`.

- [ ] **Step 7: Implementar estado visual**

```gdscript
func set_visual_state(collected: Dictionary, stage: int, fuel: float, night_amount: float, won: bool) -> void:
    $Structures/Lighthouse.set_stage(stage, won)
    $Structures/Campfire.set_fuel(fuel, night_amount)
    for pickup in get_resource_nodes():
        pickup.set_collected(collected.has(pickup.resource_id))
```

- [ ] **Step 8: Executar teste físico**

Run: `godot --headless --path . --script tests/test_world_physics.gd`

Expected: exit 0.

- [ ] **Step 9: Registrar o checkpoint**

Commit `feat: build tilemap island with native collisions` somente se Git estiver disponível.

---

### Task 4: Jogador, inimigo e recursos como cenas físicas

**Files:**
- Create: `scenes/actors/player.tscn`
- Create: `scenes/actors/enemy.tscn`
- Create: `scenes/objects/resource_pickup.tscn`
- Create: `scripts/player.gd`
- Create: `scripts/enemy.gd`
- Create: `scripts/resource_pickup.gd`
- Modify: `tests/test_scene_architecture.gd`

**Interfaces:**
- Produces `Player`: sinais `attack_requested(facing)`, `interact_requested`, propriedades `stamina`, `facing`, `walking`, método `set_enabled(bool)`.
- Produces `Enemy`: sinais `damage_requested(amount)`, `defeated(enemy)`, métodos `configure(target, phase)`, `set_world_state(night, safe_center, safe_radius, safe_active)`, `receive_attack(damage, knockback)`.
- Produces `ResourcePickup`: `resource_id`, `kind`, `set_collected(bool)`, sinal `collection_requested(pickup)`.

- [ ] **Step 1: Estender o teste de arquitetura com filhos obrigatórios**

```gdscript
var player := load("res://scenes/actors/player.tscn").instantiate()
expect(player.get_node("Sprite") is AnimatedSprite2D, "Jogador deve ter AnimatedSprite2D")
expect(player.get_node("BodyCollision") is CollisionShape2D, "Jogador deve ter colisão")
expect(player.get_node("AttackArea") is Area2D, "Jogador deve ter área de ataque")
player.free()
```

- [ ] **Step 2: Executar e confirmar falha pelos nós ausentes**

Run: `godot --headless --path . --script tests/test_scene_architecture.gd`

Expected: exit 1.

- [ ] **Step 3: Implementar `Player` com movimento físico**

```gdscript
func _physics_process(delta: float) -> void:
    if not enabled:
        velocity = Vector2.ZERO
        return
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    walking = not direction.is_zero_approx()
    var sprinting := Input.is_action_pressed("sprint") and walking and stamina > 0.0 and not exhausted
    stamina = clampf(stamina + (-28.0 if sprinting else 19.0) * delta, 0.0, 100.0)
    if stamina <= 0.0: exhausted = true
    elif stamina >= 25.0: exhausted = false
    velocity = direction * (RUN_SPEED if sprinting else WALK_SPEED)
    move_and_slide()
```

- [ ] **Step 4: Implementar ataque e interação por áreas**

Orientar `AttackArea` com `facing`, emitir ataque somente fora do cooldown e manter uma lista de `Area2D` próximos. Ordenar candidatos por prioridade (`structure` antes de `resource`) e distância.

- [ ] **Step 5: Implementar `Enemy`**

Usar `move_and_slide()`, corpo no layer `actors` e máscara `world`; perseguir o alvo dentro do alcance, vaguear fora dele e recuar do raio seguro quando ativo. Dano e HP ficam no próprio inimigo.

- [ ] **Step 6: Implementar `ResourcePickup` e instâncias do mapa**

Criar um pickup para cada entrada existente com o mesmo ID, tipo e posição. `set_collected(true)` desativa visibilidade e monitoramento; `false` restaura ambos.

- [ ] **Step 7: Executar arquitetura e física**

Run: `godot --headless --path . --script tests/test_scene_architecture.gd`

Expected: exit 0.

- [ ] **Step 8: Registrar o checkpoint**

Commit `feat: move actors and pickups into physical scenes` somente se Git estiver disponível.

---

### Task 5: UI real e integração do controlador

**Files:**
- Create: `scenes/ui/game_ui.tscn`
- Modify: `scripts/game_ui.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/game.gd`
- Modify: `tests/test_game.gd`
- Modify: `tests/test_expedition.gd`
- Modify: `tests/test_save_feedback.gd`

**Interfaces:**
- Consumes: interfaces de `IslandWorld`, `Player`, `Enemy`, `ResourcePickup`, `Lighthouse`, `Campfire`.
- Preserves: API externa usada pelos testes (`start_new_game`, `begin_play`, `continue_game`, `handle_action`, `hurt_player`, `player_is_safe`, `save_path`, `mode`, `state`).

- [ ] **Step 1: Atualizar testes de integração antes do controlador**

Trocar atribuições `game.player_position = value` por `game.player.global_position = value`, leituras por `game.player.global_position` e recursos-dicionário por nós retornados por `game.island.get_resource_nodes()`. Acrescentar:

```gdscript
check(game.player is CharacterBody2D, "Jogador integrado deve ser corpo físico")
check(game.island.get_node("Ground") is TileMapLayer, "Mundo integrado deve usar TileMapLayer")
check(game.enemies_node.get_child_count() > 0, "Inimigos devem ser cenas instanciadas")
```

- [ ] **Step 2: Executar integração e confirmar falha de contrato**

Run: `godot --headless --path . --script tests/test_game.gd`

Expected: exit diferente de zero até a nova composição ser conectada.

- [ ] **Step 3: Converter a UI em cena**

Reproduzir a árvore atual em `game_ui.tscn`, com nomes estáveis (`HUD`, `Shelter`, `Modal`, `Life`, `Energy`, `Toast`, `Prompt` etc.). Substituir `new()` e `add_child()` de `game_ui.gd` por `@onready` e manter os mesmos sinais/textos/estados públicos.

- [ ] **Step 4: Compor `main.tscn`**

Instanciar `Island`, `Player` e `UI`; adicionar `Enemies`, `CanvasModulate` e `Camera2D` explicitamente. O controlador recebe referências com `%UniqueName` ou caminhos estáveis e conecta sinais em `_ready()`.

- [ ] **Step 5: Migrar posição, coleta e inimigos**

Substituir `player_position` interno por acesso ao corpo, mantendo uma propriedade de compatibilidade se necessária:

```gdscript
var player_position: Vector2:
    get: return player.global_position if is_instance_valid(player) else IslandWorld.SPAWN
    set(value):
        if is_instance_valid(player): player.global_position = value
```

`spawn_enemies()` passa a instanciar `enemy.tscn`; `attack()` consulta sobreposições da `AttackArea`; `interact()` usa o alvo selecionado pelo jogador; partículas usam `GPUParticles2D`/`CPUParticles2D` ou animações de cena, nunca `_draw()`.

- [ ] **Step 6: Preservar save e ciclo**

Antes de salvar, copiar `player.global_position` para `state.player_position`. Ao carregar, validar por `island.is_walkable()` e usar `IslandWorld.SPAWN` se inválida. Atualizar farol, fogueira, recursos, iluminação, HUD e animações em `update_view()`.

- [ ] **Step 7: Executar os testes de integração**

Run:

```bash
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_expedition.gd
godot --headless --path . --script tests/test_save_feedback.gd
```

Expected: todos exit 0 e `0 falhas`.

- [ ] **Step 8: Registrar o checkpoint**

Commit `refactor: integrate scene-based world and interface` somente se Git estiver disponível.

---

### Task 6: Regressão, inspeção visual e documentação

**Files:**
- Modify: `README.md`
- Modify: `DESIGN.md`
- Modify: `docs/context/cycle.md`
- Modify as findings require: arquivos das Tasks 2–5

**Interfaces:**
- Verifica todo o contrato do spec; não cria novas mecânicas.

- [ ] **Step 1: Rodar toda a suíte**

```bash
godot --headless --path . --script tests/test_survival.gd
godot --headless --path . --script tests/test_scene_architecture.gd
godot --headless --path . --script tests/test_world_physics.gd
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_expedition.gd
godot --headless --path . --script tests/test_save_feedback.gd
```

Expected: todos exit 0, sem erros de parser, recursos ausentes ou nós órfãos.

- [ ] **Step 2: Executar a cena principal headless**

Run: `godot --headless --path . --quit-after 120`

Expected: exit 0, sem erros ou warnings materiais.

- [ ] **Step 3: Capturar e inspecionar estados visuais**

Capturar menu, dia, abrigo, noite, combate e vitória em 1280×720. Conferir: pixels nítidos, sem bleeding no atlas, sprites alinhados, ordem Y coerente, colisões visualmente plausíveis, UI sem overflow e iluminação legível.

- [ ] **Step 4: Playtest físico dirigido**

Confirmar manualmente: costa bloqueia; farol/depósito/ruínas bloqueiam; árvore/pedra deixam passar; jogador não nasce preso; todos os recursos são alcançáveis; inimigos não atravessam costa/construções; ataque e coleta funcionam nos quatro sentidos.

- [ ] **Step 5: Atualizar documentação**

Remover de `DESIGN.md` a declaração de gráficos procedurais provisórios, descrever atlas/cenas/colisões em `README.md` e registrar as evidências e limitações reais em `docs/context/cycle.md`.

- [ ] **Step 6: Verificação final após correções**

Repetir a suíte completa e a execução de 120 frames. Guardar no relatório final os comandos e resultados observados, sem afirmar sucesso para uma etapa não executada.

- [ ] **Step 7: Registrar o checkpoint final**

Commit `feat: complete pixel art scene migration` somente se Git estiver disponível.
