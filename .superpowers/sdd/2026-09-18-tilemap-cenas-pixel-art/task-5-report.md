# Task 5 — UI real e integração do controlador

Data: 2026-09-21

## Status

Implementação concluída e verificada. `main.tscn` agora compõe o mundo, jogador, inimigos, iluminação, câmera, efeitos e UI como nós reais. `game.gd` ficou restrito à coordenação do ciclo e das regras persistentes; o controlador não desenha nem constrói mundo, atores ou interface. O mundo procedural legado foi removido depois de confirmada a ausência de referências.

Não houve commit: o diretório fornecido não contém um repositório Git utilizável (`git rev-parse` retorna `not a git repository`) e a tarefa também instruiu explicitamente a não commitar.

## TDD — RED → GREEN

### RED principal: composição ainda legada

Os testes de integração já estavam migrados no checkpoint recebido: `test_game.gd`, `test_expedition.gd` e `test_save_feedback.gd` operavam sobre `CharacterBody2D`, pickups retornados por `island.get_resource_nodes()` e o contêiner real `enemies_node`. Eles foram preservados sem retornar a dicionários ou estruturas de desenho.

Antes de alterar produção, foi executado:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5 \
XDG_CONFIG_HOME=/tmp/o-farol-task5-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_game.gd
```

Resultado: exit 1, com exatamente os três contratos de composição esperados:

```text
Jogador integrado deve ser corpo físico
Mundo integrado deve usar TileMapLayer
Controlador deve expor o contêiner real de inimigos
Integração: 3 falhas
```

Isso confirmou que o teste falhava pela arquitetura ainda procedural, e não por erro de sintaxe do teste.

### GREEN da UI declarativa

Após criar `game_ui.tscn` e converter `game_ui.gd` para referências `@onready`, foi executado:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-ui \
XDG_CONFIG_HOME=/tmp/o-farol-task5-ui-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 0. O teste confirmou os nós reais `Root`, `HUD`, `Shelter`, `Modal`, `Life`, `Energy`, `Toast` e `Prompt`, além do sinal do botão real `Root/Modal/Content/Buttons/New`.

### Integração do controlador

A primeira tentativa após compor `main.tscn` revelou que `GameUI` ainda não constava no cache de classes globais do processo. A evidência foi `.godot/global_script_class_cache.cfg` conter `Player` e `IslandWorld`, mas não `GameUI`. O vínculo foi tornado determinístico com `preload("res://scripts/game_ui.gd")`, o mesmo padrão já usado pelo projeto, sem depender de uma importação prévia do editor.

Em seguida, `test_game.gd` passou nas asserções, mas expôs erro de runtime em uma propriedade de `CPUParticles2D`. A lista de propriedades da própria Godot 4.7 confirmou `explosiveness`, não `explosiveness_ratio`; a correção isolada eliminou o erro e os vazamentos derivados.

GREEN limpo:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-green1 \
XDG_CONFIG_HOME=/tmp/o-farol-task5-green1-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_game.gd
```

Resultado: exit 0, `Integração: 0 falhas`, sem erros ou avisos de vazamento.

### RED adicional: recursos sobrepostos às ruínas

O primeiro `test_expedition.gd` sobre a composição real retornou exit 1: 14 pickups de sucata próximos às ruínas eram ocultados pela prioridade genérica de `structures`, impedindo financiar os reparos. Uma inspeção dos alvos reais mostrou, por exemplo, `scrap_01 -> RuinNW`, `scrap_06 -> RuinNE`, `scrap_12 -> RuinSE` e `scrap_15 -> RuinSW`.

Foi acrescentado primeiro um contrato comportamental real em `test_scene_architecture.gd`: depósito funcional continua vencendo um pickup sobreposto, mas ruína sem ação não pode tornar esse pickup inalcançável.

RED observado:

```text
Ruína sem ação não deve tornar recurso sobreposto inalcançável
```

Resultado: exit 1.

A implementação mínima marcou farol, depósito e fogueira com o grupo funcional `shelter` e refinou a prioridade do jogador para `shelter` → `resources` → estruturas inertes. A área física e o grupo `structures` das ruínas foram preservados. O teste focado voltou a exit 0.

O mesmo RED da expedição também revelou callbacks de temporizador capturando partículas já liberadas no encerramento da cena. A Godot confirmou que `CPUParticles2D` fornece o sinal `finished`; o efeito passou a se autoliberar por esse sinal, sem temporizador externo.

GREEN da expedição:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-expedition-green \
XDG_CONFIG_HOME=/tmp/o-farol-task5-expedition-green-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_expedition.gd
```

Resultado: exit 0, `Expedição completa: 0 falhas`, sem callbacks inválidos.

## Implementação

### UI real

- `scenes/ui/game_ui.tscn` contém a árvore completa declarativa de `CanvasLayer`, `Control`, HUD, barras, labels, painel do abrigo, modal e botões.
- Os nomes públicos pedidos são estáveis: `Root/HUD`, `Root/Shelter`, `Root/Modal`, `Life`, `Energy`, `Toast` e `Prompt`.
- Tema, cores, painéis, barras e estados de botões estão em recursos da cena.
- `scripts/game_ui.gd` não chama `.new()` nem `add_child()`: usa exclusivamente nós `@onready`, conecta seus botões e alterna conteúdo/visibilidade.
- Sinal `action_requested(action_name, payload)`, textos em português, toasts, menu, introdução, pausa, confirmação, abrigo e vitória foram preservados.

### Composição de `main.tscn`

Árvore principal entregue:

```text
OFarol
├── World
│   ├── Island (island.tscn)
│   ├── Enemies
│   ├── Player (player.tscn)
│   ├── Effects
│   └── RescueVisuals
├── Lighting (CanvasModulate)
├── Camera2D
├── UI (game_ui.tscn)
└── Soundscape
```

O resgate usa `Polygon2D` declarativos para feixe/barco, e impactos/coleta usam `CPUParticles2D`. Não há `_draw()`, `draw_player`, `draw_animal` ou `queue_redraw` no controlador.

### Controlador e cenas

- `game.gd` referencia `IslandWorld`, `Player`, `Enemies`, `Lighting`, `Camera2D`, `GameUI` e `Soundscape` da cena.
- `player_position` foi preservada como propriedade de compatibilidade, lendo e escrevendo `player.global_position`.
- Movimento e stamina vêm de `Player`; o controlador apenas sincroniza `SurvivalState` e HUD.
- `Player.attack_requested` aciona combate contra corpos reais sobrepostos à `AttackArea`.
- `Enemy.damage_requested` encaminha dano para `hurt_player`; `Enemy.defeated` aciona efeito nativo.
- `Player.interact_requested` consulta `get_interaction_target()`; pickups emitem `collection_requested` e são coletados pelo controlador.
- `spawn_enemies()` instancia `enemy.tscn` no contêiner real, preservando quantidade, faixas de spawn, HP, velocidades, detecção e zona segura.
- Não existem arrays de dicionários para inimigos ou partículas visuais.

### Save, ciclo e visual

- Antes de salvar, `player.global_position` e stamina são copiados para `state`.
- Ao carregar, a posição passa por `island.is_walkable()`; posição inválida retorna a `IslandWorld.SPAWN` (`Vector2(0, 110)`).
- O schema e `SurvivalState` não foram alterados.
- Amanhecer, noite, combustível, renovação de recursos, morte, checkpoints, três reparos, acendimento e vitória permanecem no mesmo fluxo.
- `update_view()` atualiza `CanvasModulate`, farol, fogueira, pickups, HUD, feedback de dano e visuais do resgate.

## API externa preservada

Foram mantidos e exercitados:

- `start_new_game()`
- `begin_play()`
- `continue_game()`
- `handle_action(action_name, payload)`
- `hurt_player(amount)`
- `player_is_safe()`
- `save_checkpoint()`
- `save_path`
- `mode`
- `state`
- compatibilidade adicional: `player_position`, `island`, `player`, `ui`, `sound`, `camera`, `lighting` e `enemies_node`

## Arquivos

Criado:

- `scenes/ui/game_ui.tscn`

Modificados:

- `scripts/game_ui.gd`
- `scenes/main.tscn`
- `scripts/game.gd`
- `scripts/island_world.gd` — constantes públicas `SPAWN` e `SAFE_RADIUS`
- `scripts/player.gd` — prioridade entre abrigo, recursos e ruínas inertes
- `scenes/objects/lighthouse.tscn`
- `scenes/objects/storage.tscn`
- `scenes/objects/campfire.tscn`
- `tests/test_scene_architecture.gd` — regressão para recurso sobreposto a ruína

Removidos:

- `scripts/island.gd`
- `scripts/island.gd.uid`

`tests/test_game.gd`, `tests/test_expedition.gd` e `tests/test_save_feedback.gd` já estavam migrados para nós reais no checkpoint recebido e foram mantidos sem redução de cobertura.

## Verificação final

Todos os comandos abaixo usaram Godot 4.7.1 headless, `XDG_DATA_HOME=/tmp/o-farol-task5` e `XDG_CONFIG_HOME=/tmp/o-farol-task5-config`:

| Teste | Resultado |
|---|---|
| `tests/test_scene_architecture.gd` | exit 0 |
| `tests/test_world_physics.gd` | exit 0 |
| `tests/test_survival.gd` | exit 0; 128 checks |
| `tests/test_game.gd` | exit 0; 0 falhas |
| `tests/test_expedition.gd` | exit 0; 0 falhas |
| `tests/test_save_feedback.gd` | exit 0; 0 falhas |

Verificações adicionais:

- `--headless --path . --quit-after 5`: exit 0, sem erro de cena/script/runtime.
- `--headless --editor --path . --import`: exit 0; registrou `GameUI`, `IslandWorld`, `Player` e `Enemy`. O editor em sandbox registrou apenas `ERR_CANT_CREATE` ao tentar abrir sockets, a mesma limitação ambiental já documentada nas tasks anteriores.
- Busca estrutural: nenhuma ocorrência proibida em `game.gd`/`main.tscn`; `game_ui.gd` não contém `.new()` nem `add_child()`; nenhum `scripts/island.gd*` permanece.

## Auto-revisão

- Remover/substituir `Player`, `Island`, `Enemies` ou a UI real quebra os contratos de integração.
- Uma posição de save fora da ilha é coberta e retorna ao spawn.
- Inimigos são filhos `CharacterBody2D`; pickups são `Area2D` e a expedição coleta os 69 recursos reais.
- A regressão nova diferencia estrutura funcional de ruína inerte sem remover colisão, grupo ou área das ruínas.
- O fluxo de erro de salvamento é exercitado no início, morte e resgate e mantém a mensagem visível.
- O teste de arquitetura cobre sinal real do jogador, dano/derrota/knockback do inimigo, coleta/restauração do pickup e sinal do botão real da UI.
- Nenhum asset, TileMap ou balanceamento de Tasks 1–4 foi refeito.
- Nenhum subagente foi despachado.

## Limitações e preocupações

- A captura visual automatizada existente requer um display gráfico. No backend headless, ela ficou aguardando `frame_post_draw` e não gerou PNG; por isso a entrega tem verificação estrutural, de importação e smoke runtime, mas não inspeção visual por screenshot nesta sessão.
- O erro de socket durante `--editor --import` é imposto pelo sandbox; a importação terminou com exit 0 e sem erro de recurso, cena ou script.
- Não há Git no diretório fornecido, portanto não foi possível produzir diff/commit nem executar a etapa de integração de branch.

## Fix round 1 — efeitos declarativos, fogueira atravessável e DamageArea

Três findings Important da revisão foram validados contra o código entregue e corrigidos individualmente em ciclos RED → GREEN. Não houve alteração de schema, textos, custos, velocidades, HP, dano ou cooldown.

### Finding 1 — efeitos fora do controlador

Contrato acrescentado em `tests/test_scene_architecture.gd`:

- existe `res://scenes/effects/burst_effects.tscn` como componente independente;
- `World/Effects` expõe `burst(point, color, count)` e `clear_effects()`;
- o pool contém partículas predeclaradas;
- chamar `game.burst()` não muda a quantidade de filhos;
- `clear_effects()` interrompe o pool.

RED:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-fix1-effects-red \
XDG_CONFIG_HOME=/tmp/o-farol-task5-fix1-effects-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1 com as falhas esperadas `Efeitos devem existir como cena independente`, ausência das duas APIs, pool vazio e criação de filho pelo controlador.

Implementação:

- criada `scenes/effects/burst_effects.tscn` com oito `CPUParticles2D` predeclarados;
- criado `scripts/burst_effects.gd`, responsável por seleção/reuso do pool, configuração do burst e limpeza;
- `main.tscn` passou a instanciar a cena no nó `World/Effects`;
- `game.gd` apenas delega `burst(...)` e `_clear_effects()` ao componente;
- removidas do controlador a criação, adição, remoção e liberação de nós visuais.

GREEN: o mesmo teste com diretórios `o-farol-task5-fix1-effects-green` terminou com exit 0 e saída limpa.

### Finding 2 — fogueira não bloqueante e luz real

`tests/test_world_physics.gd` passou a separar as construções bloqueantes (`Lighthouse`, `Storage` e quatro ruínas) da fogueira. O contrato da fogueira exige:

- raiz `Area2D`, nunca `StaticBody2D`;
- ausência da camada `world` e uso de `interaction` layer 4 / mask 2;
- grupos `shelter` e `structures` preservados;
- `InteractionShape` real, sem colisão corporal;
- `PointLight2D` apagado sem combustível/de dia e ativo com combustível à noite.

RED:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-fix1-campfire-red \
XDG_CONFIG_HOME=/tmp/o-farol-task5-fix1-campfire-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_world_physics.gd
```

Resultado: exit 1 pelas quatro divergências esperadas: raiz não era `Area2D`, ainda criava parede, não possuía `InteractionShape` direto nem `PointLight2D`.

Implementação:

- `Campfire` convertido de `StaticBody2D` para `Area2D`;
- removidos `BodyCollision`, layer `world` e máscara física de parede;
- a raiz agora é a própria área de interação, mantendo os grupos funcionais;
- adicionado `PointLight2D` com textura radial declarativa;
- `set_fuel()` mantém a API e atualiza sprite, energia e visibilidade da luz conforme combustível e `night_amount`.

GREEN: o mesmo teste com diretórios `o-farol-task5-fix1-campfire-green` terminou com exit 0.

### Finding 3 — dano inimigo por sobreposição física

O teste de inimigo foi migrado para um alvo `CharacterBody2D` com `CollisionShape2D` real. Ele verifica:

- `DamageArea` em layer 8 (`combat`) e mask 2 (`actors`);
- forma física real;
- alvo próximo, mas fora da layer `actors`, não recebe dano;
- ao entrar na layer, a sobreposição emite exatamente 14 de dano;
- após sair da layer e transcorrer o cooldown, não ocorre novo dano.

RED:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-fix1-enemy-red \
XDG_CONFIG_HOME=/tmp/o-farol-task5-fix1-enemy-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1 com as falhas esperadas: `DamageArea` ausente, dano indevido no alvo fora da layer e novo dano após o cooldown sem sobreposição válida.

Implementação:

- `enemy.tscn` ganhou `DamageArea/Shape`, `Area2D` layer 8 / mask 2;
- o raio da área foi ajustado considerando a forma corporal do jogador para preservar alcance central aproximado de 30 px;
- `enemy.gd` preserva dano 14 e cooldown 1,1 s, mas condiciona o ataque a `damage_area.overlaps_body(_target)`;
- perseguição, zona segura, HP, derrota e knockback permaneceram inalterados.

GREEN: o mesmo teste com diretórios `o-farol-task5-fix1-enemy-green` terminou com exit 0.

### Arquivos do fix round

Criados:

- `scenes/effects/burst_effects.tscn`
- `scripts/burst_effects.gd`

Modificados:

- `scenes/main.tscn`
- `scripts/game.gd`
- `scenes/objects/campfire.tscn`
- `scripts/campfire.gd`
- `scenes/actors/enemy.tscn`
- `scripts/enemy.gd`
- `tests/test_scene_architecture.gd`
- `tests/test_world_physics.gd`

### Regressão integrada do fix round

Todos os testes abaixo usaram Godot 4.7.1 headless e diretórios XDG `o-farol-task5-fix1-suite*`:

| Teste | Resultado |
|---|---|
| `tests/test_scene_architecture.gd` | exit 0 |
| `tests/test_world_physics.gd` | exit 0 |
| `tests/test_survival.gd` | exit 0; 128 checks |
| `tests/test_game.gd` | exit 0; 0 falhas |
| `tests/test_expedition.gd` | exit 0; 0 falhas |
| `tests/test_save_feedback.gd` | exit 0; 0 falhas |

Smoke runtime:

```bash
XDG_DATA_HOME=/tmp/o-farol-task5-fix1-smoke \
XDG_CONFIG_HOME=/tmp/o-farol-task5-fix1-smoke-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --quit-after 5
```

Resultado: exit 0, sem erro de cena, script ou runtime.

Busca final em `scripts/game.gd`: nenhuma ocorrência de `CPUParticles2D.new`, `effects_node.add_child`, `effects_node.remove_child`, `_draw`, `draw_player` ou `draw_animal`.
