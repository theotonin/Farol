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

