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

