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

