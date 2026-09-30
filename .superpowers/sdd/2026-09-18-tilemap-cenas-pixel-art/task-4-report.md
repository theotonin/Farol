# Task 4 — Jogador, inimigo e recursos como cenas físicas

Status: implementada e verificada. O teste de arquitetura permanece vermelho exclusivamente porque `scenes/ui/game_ui.tscn` pertence à tarefa futura. Os contratos de jogador, inimigo, pickup e população do mapa passam.

## Entrega

- `Player` é `CharacterBody2D` no grupo `player`, camada `actors` e máscara somente `world`. Usa `move_and_slide()`, stamina/sprint com os números legados, facing, animações direcionais 32×32, cooldown de ataque, interação por `Area2D`, prioridade de estrutura sobre recurso e `set_enabled(bool)`.
- `Enemy` é `CharacterBody2D` no grupo `enemies`, camada `actors` e máscara somente `world`. Mantém HP e cooldown próprios, persegue/vagueia com velocidades e alcances legados, recua da área segura, solicita 14 de dano e emite `defeated` ao esgotar HP.
- `ResourcePickup` é `Area2D` no grupo `resources`, camada `interaction` e máscara `actors`. É atravessável, usa regiões explícitas do atlas de objetos, emite solicitação de coleta e alterna visual/monitoramento em `set_collected(bool)`.
- `IslandWorld/Resources` instancia 69 pickups: 24 madeira, 18 pedra, 8 comida, 16 sucata e 3 peças. IDs, tipos e posições são idênticos aos de `scripts/island.gd`.
- Costa e construções continuam na camada `world`; jogador/inimigo só colidem com essa camada. Decorações e pickups não bloqueiam movimento.
- `game.gd` e `scenes/main.tscn` não foram modificados; a integração legada continua funcionando.

## Ciclo TDD

### RED inicial

Primeiro, `tests/test_scene_architecture.gd` ganhou contratos de estrutura e comportamento para:

- movimento real, facing, desabilitação, camadas, ataque/cooldown e interação do jogador;
- prioridade de interação `structure` antes de `resource`;
- perseguição, dano, HP, knockback e derrota do inimigo;
- sinal de coleta e ida/volta de `set_collected`;
- todos os 69 IDs/tipos/posições do mapa e aplicação de estado visual.

Comando:

```bash
XDG_DATA_HOME=/tmp/o-farol-task4 XDG_CONFIG_HOME=/tmp/o-farol-task4-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_scene_architecture.gd
```

Resultado inicial: exit 1 pelas três cenas ausentes de Task 4 (`player.tscn`, `enemy.tscn`, `resource_pickup.tscn`) e por `game_ui.tscn`. Não houve erro de parse. Uma primeira execução após implementação revelou apenas um defeito do observador de teste — inteiro capturado por closure não mutava o escopo externo — corrigido usando contêiner mutável, sem mudar o contrato de produção.

### GREEN dos contratos da Task 4

Após a implementação, o mesmo comando retorna exit 1 com uma única mensagem:

```text
Cena ausente: res://scenes/ui/game_ui.tscn
```

Assim, todos os testes de Task 4 executados dentro da arquitetura passam; o vermelho residual está isolado à UI futura, conforme o requisito de integração.

### Evolução deliberada do teste físico

`tests/test_world_physics.gd` ainda continha duas expectativas transitórias da Task 3, exigindo `Resources` vazio. O RED observado foi exatamente:

```text
Resources deve ficar vazio até a Task 4
get_resource_nodes deve tolerar Resources vazio
```

Por ruling do agente de integração, o teste foi atualizado para o contrato da Task 4: população não vazia, IDs únicos, exatamente três pickups `part`, cada pickup como `Area2D` no grupo `resources`, layer 4/mask 2, enquanto decorações permanecem sem colisão. A nova execução retorna exit 0.

## Arquivos

Criados:

- `scenes/actors/player.tscn`
- `scenes/actors/enemy.tscn`
- `scenes/objects/resource_pickup.tscn`
- `scripts/player.gd` e UID gerado pela Godot
- `scripts/enemy.gd` e UID gerado pela Godot
- `scripts/resource_pickup.gd` e UID gerado pela Godot

Modificados:

- `scripts/island_world.gd`: instanciação declarativa dos pickups legados em `Resources`.
- `tests/test_scene_architecture.gd`: contratos arquiteturais e comportamentais de Task 4.
- `tests/test_world_physics.gd`: substituição do contrato transitório da Task 3 pelo contrato físico de Task 4, conforme ruling.

`scenes/world/island.tscn` não precisou mudar: seu nó `Resources` já existia e é populado por `IslandWorld` antes do restante da construção do mapa.

## Assets e regiões

- `characters.png`: células 32×32; colunas idle/walkA/walkB/attack; linhas 0–3 para jogador down/left/right/up e 4–7 para animal nas mesmas direções.
- `objects.png`: regiões explícitas `wood (0,8,32,32)`, `stone (32,8,32,32)`, `food (64,8,32,32)`, `scrap (96,8,32,32)` e `part (128,8,32,32)`.
- Nenhum asset foi alterado.

## Verificações

Editor/importação:

```bash
XDG_DATA_HOME=/tmp/o-farol-task4 XDG_CONFIG_HOME=/tmp/o-farol-task4-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --editor --path . --import
```

Retorno exit 0; scripts `Player`, `Enemy`, `ResourcePickup` e `IslandWorld` registrados. O editor em sandbox emitiu `ERR_CANT_CREATE` ao tentar abrir sockets, sem erro de cena, asset ou script.

Resultados da suíte antes da atualização deliberada de `test_world_physics.gd`:

| Teste | Resultado |
|---|---|
| `test_scene_architecture.gd` | exit 1; somente `game_ui.tscn` futura |
| `test_world_physics.gd` | exit 1; duas expectativas transitórias de Resources vazio |
| `test_survival.gd` | exit 0; 128 checks |
| `test_game.gd` | exit 0; 0 falhas |
| `test_expedition.gd` | exit 0; 0 falhas |
| `test_save_feedback.gd` | exit 0; 0 falhas |

Rodada final fresca após o ruling e todas as edições:

| Teste | Resultado final |
|---|---|
| `test_scene_architecture.gd` | exit 1; única falha: `scenes/ui/game_ui.tscn` ausente |
| `test_world_physics.gd` | exit 0 |
| `test_survival.gd` | exit 0; 128 checks |
| `test_game.gd` | exit 0; 0 falhas |
| `test_expedition.gd` | exit 0; 0 falhas |
| `test_save_feedback.gd` | exit 0; 0 falhas |

Não houve saída sobre Player, Enemy, ResourcePickup, população, parse ou runtime na arquitetura final.

## Auto-revisão

- Mutação de layer/mask do jogador, inimigo ou pickup falha nos testes; pickups são `Area2D`, não corpos bloqueadores.
- Remover movimento físico, sinais, cooldown, dano/HP, knockback, coleta ou restauração de monitoramento falha nos testes comportamentais.
- O teste do mapa compara todos os 69 registros contra fixtures literais independentes e também detecta IDs duplicados.
- A prioridade de interação é exercitada com uma estrutura e um recurso reais sobrepostos; a estrutura vence mesmo estando mais distante.
- Valores de balanceamento migrados: jogador 165/265, stamina −28/+19 e recuperação de exaustão em 25; inimigo 92/110, detecção 370/860, HP 65, dano 14, cooldown 1,1; ataque do jogador emite a cada 0,45 s.
- Nenhum subagente foi despachado e nenhum commit foi criado.

## Preocupações e limites deliberados

- As novas cenas ainda não substituem os atores desenhados e os dicionários de inimigos em `game.gd`; essa integração foi explicitamente adiada e o fluxo antigo foi preservado.
- `test_scene_architecture.gd` continuará exit 1 até a criação de `scenes/ui/game_ui.tscn` pela tarefa correspondente. Não é falha de Player/Enemy/ResourcePickup.
- O erro de socket do editor headless é uma limitação do sandbox; o processo de importação terminou com exit 0.

## Fix round 1 — knockback respeita colisões do mundo

Finding importante: `receive_attack()` aplicava `global_position += knockback`, deslocando o inimigo instantaneamente e permitindo atravessar costa ou construções.

### RED

Foi adicionado a `tests/test_scene_architecture.gd` um teste comportamental com `StaticBody2D` real na camada `world`, forma retangular e Enemy real com máscara `world`. O teste aplica `receive_attack(1.0, Vector2(300, 0))`, aguarda 12 frames físicos e exige que o inimigo se mova, permaneça antes da barreira e conserve a aplicação de dano.

Comando:

```bash
XDG_DATA_HOME=/tmp/o-farol-task4-fix1-red XDG_CONFIG_HOME=/tmp/o-farol-task4-fix1-red-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1 com as duas falhas esperadas e nenhuma outra:

```text
Cena ausente: res://scenes/ui/game_ui.tscn
Knockback não deve atravessar barreira na camada world
```

### Implementação

- A API pública `receive_attack(damage, knockback)` foi preservada.
- O vetor recebido alimenta `_knockback_velocity`, escalado deterministicamente para um impulso físico.
- `_physics_process()` processa o impulso com `move_and_slide()`, portanto usa a máscara `world` do Enemy.
- O impulso desacelera por `move_toward(Vector2.ZERO, 1800.0 * delta)` e tem prioridade temporária sobre perseguição/vagueio.
- Inimigos sem alvo ainda processam knockback; dano letal limpa o impulso, emite `defeated` e mantém o fluxo anterior.
- O teste anterior de dano/knockback passou a observar o deslocamento após um frame físico, coerente com o novo contrato sem teleporte.

### GREEN e regressões

Comando focado igual ao RED, usando diretórios `o-farol-task4-fix1-green`: exit 1 somente por `game_ui.tscn`. A falha da barreira desapareceu; dano, HP, knockback e `defeated` continuaram passando.

Rodada adicional:

| Teste | Resultado |
|---|---|
| `test_world_physics.gd` | exit 0 |
| `test_survival.gd` | exit 0; 128 checks |
| `test_game.gd` | exit 0; 0 falhas |
| `test_expedition.gd` | exit 0; 0 falhas |
| `test_save_feedback.gd` | exit 0; 0 falhas |

Comandos usaram Godot 4.7.1 headless, `XDG_DATA_HOME=/tmp/o-farol-task4-fix1-suite-*` e `XDG_CONFIG_HOME=/tmp/o-farol-task4-fix1-suite-config-*`. Nenhum commit ou subagente foi criado.
