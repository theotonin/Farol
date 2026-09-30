# Onda final de correções — mira, modos, direção, pixel scale e TileMap

Data: 2026-09-22

## Status

Concluída e verificada. Os cinco findings `Important` foram reproduzidos por testes antes das mudanças de produção e corrigidos em ciclos RED → GREEN. A política de Y-sort também foi explicitada e coberta para evitar que o jogador ficasse permanentemente acima das estruturas.

Não houve alteração de schema de save, custos, tempos, HP, dano, cooldown, velocidade, quantidades ou textos de fluxo existentes. Não houve commit nem despacho de subagentes. O diretório fornecido continua sem repositório Git utilizável (`git rev-parse` retorna `fatal: not a git repository`).

## 1. Mira real pelo mouse

### RED

O contrato acrescentado a `tests/test_scene_architecture.gd` exige uma fronteira pública alimentada pelo cursor, testa `facing`, posição e rotação de `AttackArea` nos quatro sentidos e confirma o fallback de movimento somente quando cursor e jogador coincidem. O clique e o movimento WASD preexistentes continuam no mesmo teste.

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-mouse-red \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-mouse-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1, com a falha esperada:

```text
Player deve expor a fronteira alimentada pelo mouse real
```

### GREEN

`Player._physics_process()` agora chama `aim_at_cursor(get_global_mouse_position(), direction)` somente enquanto o jogador está habilitado. `aim_at_cursor()` usa o vetor global do cursor quando ele existe, normaliza `facing` e atualiza `AttackArea`; o vetor de WASD só é usado quando o cursor não define direção. `Player._unhandled_input()` e a action `attack` de clique esquerdo foram preservadas.

O teste de combate em quatro sentidos foi migrado para usar essa fronteira real, em vez de escrever `facing` diretamente.

GREEN final do contrato: exit 0 com `/tmp/o-farol-finalfix-mouse-green2`.

## 2. Processamento e dano restritos a `playing`

### RED

`tests/test_game.gd` passou a observar o contêiner real `World/Enemies` em menu, introdução, jogo, pausa, resgate e vitória. Na pausa e no resgate, o teste coloca um `Enemy` real sobre o jogador, espera frames físicos e verifica posição e vida. Também chama `hurt_player()` diretamente fora de `playing`.

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-modes-red \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-modes-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_game.gd
```

Resultado: exit 1, 11 falhas específicas. Entre elas:

```text
Inimigos devem ficar desativados no menu
Pausa deve desativar o processamento dos inimigos
Inimigo não deve mover durante a pausa
Inimigo não deve causar dano durante a pausa
hurt_player deve ignorar chamadas fora de playing
Resgate deve desativar o processamento dos inimigos
Inimigo não deve mover durante o resgate
Inimigo não deve causar dano durante o resgate
Vitória deve manter os inimigos desativados
```

### GREEN

`game.gd` mantém a API privada existente `_sync_player_enabled()`, mas agora sincroniza também `enemies_node.process_mode`: `PROCESS_MODE_INHERIT` somente em `playing`, `PROCESS_MODE_DISABLED` nos demais modos. Todos os fluxos já chamavam essa função ao trocar de modo, incluindo menu, introdução, pausa, retomada, resgate, carregamento e vitória. `hurt_player()` agora retorna imediatamente quando `mode != "playing"`.

GREEN: exit 0, `Integração: 0 falhas`, com `/tmp/o-farol-finalfix-modes-green`.

## 3. Direção declarativa do farol

### RED

O contrato de UI passou a exigir `Root/HUD/DirectionArrow`, a API `set_lighthouse_direction()` e orientação nos quatro sentidos. O teste integrado posiciona o jogador a leste do farol, chama `game.update_view()` e confirma que o controlador fornece `-player_position`, sem substituir o texto `Farol · N m`.

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-arrow-red \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-arrow-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1:

```text
HUD deve declarar uma seta real para a direção do farol
UI deve aceitar o vetor global em direção ao farol
```

### GREEN

- `game_ui.tscn` declara um `Label` dourado `DirectionArrow`, com glifo `▲`, pivot central e posição junto do texto de distância.
- `game_ui.gd` referencia esse nó via `@onready` e aplica `direction.angle() + PI / 2`, pois o glifo aponta para cima em rotação zero.
- Vetor zero usa norte como orientação estável; a seta permanece visível sempre que o HUD está visível.
- `game.gd.update_view()` preserva a chamada e assinatura de `update_hud()` e, em seguida, chama `ui.set_lighthouse_direction(-player_position)`.

GREEN: `test_scene_architecture.gd` e `test_game.gd` retornaram exit 0 em `/tmp/o-farol-finalfix-arrow-green*`.

## 4. Pixel scale inteiro

### RED

`tests/test_world_physics.gd` passou a inspecionar todo `Sprite2D` descendente de `Decorations`, exigindo escala inteira e positiva em ambos os eixos.

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-scale-red \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-scale-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_world_physics.gd
```

Resultado: exit 1. As 62 árvores `Decoration000` a `Decoration061` falharam por usar 0,78× ou 0,72×.

### GREEN

As duas famílias de árvores em `island_world.gd` agora são instanciadas em `Vector2.ONE`. Rochas e demais decorações já estavam em 1×. Nenhum `scale` fracionário permanece nos sprites ou cenas; o único `texture_scale = 2.2` encontrado pertence à textura radial de `PointLight2D` da fogueira, não a rasterização de um sprite pixel art.

GREEN: exit 0, com o playtest físico completo e 69 recursos verificados, em `/tmp/o-farol-finalfix-scale-green`.

## 5. TileMap editável e serializado

### RED

O teste de mundo agora instancia `island.tscn` sem adicioná-la à árvore e exige:

- aproximadamente 6.956 células já presentes em `Ground` antes de `_ready()`;
- células de caminho já serializadas;
- uma célula-sentinela apagada antes de entrar na árvore deve continuar apagada depois de `_ready()`, provando que não houve `clear()`/rebuild;
- extensão, costa, física, estruturas, decorações e recursos continuam válidos após restaurar a sentinela.

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-tilemap-red \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-tilemap-red-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --script tests/test_world_physics.gd
```

Resultado: exit 1:

```text
Ground deve trazer aproximadamente 6956 células serializadas antes de _ready
Ground serializado deve incluir os caminhos de terra
```

### Geração controlada

Um script temporário em `/tmp` instanciou a cena sem entrar na árvore, executou o gerador antigo uma única vez e empacotou os dados. A propriedade `tile_map_data` foi então inserida na cena original, preservando sua estrutura concisa e suas instâncias externas.

```text
Ground gerado: 6956 células; 211 células de caminho
Ground serializado em res://scenes/world/island.tscn
Cena original preservada; tile_map_data serializado inserido (111335 bytes)
```

### GREEN

Depois da serialização, foram removidos de `island_world.gd`:

- a chamada de rebuild em `_ready()`;
- `_build_ground()` e `_draw_paths()`;
- funções de escolha/transição de tiles usadas apenas pelo rebuild;
- constantes de limites, tamanho e rotas que ficaram sem consumidor.

GREEN: exit 0 em `/tmp/o-farol-finalfix-tilemap-green`. O teste confirmou 6.956 células, 211 células de caminho, sentinela não reconstruída, extensão aproximada original e física íntegra.

O README foi ajustado para descrever o chão como editável e serializado, e não como preenchido pelo script em runtime.

## 6. Política de Y-sort

Um contrato adicional exige `y_sort_enabled` em `World`, `Island`, `Enemies`, `Decorations`, `Resources` e `Structures`, além de `Player.z_index == 0`.

RED em `/tmp/o-farol-finalfix-ysort-red`: exit 1 nas três divergências reais (`World`, `Island` e `Player.z_index`).

GREEN em `/tmp/o-farol-finalfix-ysort-green`: exit 0. `Effects` e `RescueVisuals` mantêm seus z-index de overlay intencionais; atores, estruturas, recursos e decorações compartilham a ordenação Y do mundo.

## Arquivos modificados

Produção e documentação:

- `scripts/player.gd`
- `scripts/game.gd`
- `scripts/game_ui.gd`
- `scripts/island_world.gd`
- `scenes/ui/game_ui.tscn`
- `scenes/world/island.tscn`
- `scenes/main.tscn`
- `README.md`

Testes e verificação visual:

- `tests/test_scene_architecture.gd`
- `tests/test_world_physics.gd`
- `tests/test_game.gd`
- `tests/capture_game.gd`

Temporários de geração ficaram somente em `/tmp`; não foram adicionados ao projeto.

## APIs e compatibilidade preservadas

Continuam intactas as APIs externas do controlador:

- `start_new_game()`
- `begin_play()`
- `continue_game()`
- `handle_action(action_name, payload)`
- `hurt_player(amount)`
- `player_is_safe()`
- `save_checkpoint()`
- `save_path`, `mode`, `state`, `player_position`
- referências `island`, `player`, `enemies_node`, `ui`, `sound`, `camera` e `lighting`

Também foram preservados `GameUI.update_hud(state, distance, interaction, safe)`, textos em português, save JSON, posição persistida, economia, três reparos, morte, noite, resgate e feedback de erro de save. As novas APIs são aditivas: `Player.aim_at_cursor()` e `GameUI.set_lighthouse_direction()`.

## Verificação final

### Seis suítes

Cada suíte foi executada em XDG isolado sob `/tmp/o-farol-finalfix-suite-*` com Godot 4.7.1:

| Suíte | Resultado observado |
|---|---|
| `tests/test_survival.gd` | exit 0; `PASS: 128 survival rule checks` |
| `tests/test_scene_architecture.gd` | exit 0; combate dirigido em quatro direções |
| `tests/test_world_physics.gd` | exit 0; quatro costas, seis construções, fogueira, decoração e 69 recursos |
| `tests/test_game.gd` | exit 0; `Integração: 0 falhas` |
| `tests/test_expedition.gd` | exit 0; `Expedição completa: 0 falhas` |
| `tests/test_save_feedback.gd` | exit 0; `Avisos de salvamento: 0 falhas` |

### Importação

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-import \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-import-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --editor --import --quit
```

Resultado: exit 0; scan de arquivos, classes globais e editor concluídos. O sandbox voltou a emitir somente `ERR_CANT_CREATE` ao tentar abrir sockets internos, limitação ambiental já documentada, sem erro de script, cena, tileset ou recurso.

### Smoke de 120 iterações

```bash
XDG_DATA_HOME=/tmp/o-farol-finalfix-smoke120 \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-smoke120-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --headless --path . --quit-after 120
```

Resultado: exit 0, saída limpa.

### Capturas reais

`tests/capture_game.gd` foi atualizado para capturar dia em `playing`, depois chamar `pause_game()` e capturar a pausa real. O combate visual usa a nova fronteira de mira.

```bash
DISPLAY=:0 \
XDG_DATA_HOME=/tmp/o-farol-finalfix-capture \
XDG_CONFIG_HOME=/tmp/o-farol-finalfix-capture-config \
/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 \
  --display-driver x11 --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1280x720 --path . --script tests/capture_game.gd
```

Resultado: exit 0; nove PNGs salvos (`menu`, `intro`, `day`, `paused`, `shelter`, `night`, `combat`, `rescue`, `victory`).

Capturas inspecionadas em resolução original:

| Estado | Arquivo | SHA-256 | Inspeção |
|---|---|---|---|
| Dia | `/tmp/o-farol-day.png` | `149f394c26a1f5fef3ab9e788d0b428d74c360c2f25b07848d5d734aa48f2603` | 1280×720; seta dourada visível junto de `Farol · 11 m`, apontando para norte a partir do spawn |
| Pausa | `/tmp/o-farol-paused.png` | `fabc5f29591cfd59e76a8bb43c37ac5ef2392ac0364aea6689a41416f61917cd` | 1280×720; modal `Maré suspensa`; HUD e seta permanecem visíveis sob o overlay |

### Auditoria estrutural

- Nenhuma ocorrência de `func _draw`, `queue_redraw`, `draw_player`, `draw_animal`, `CPUParticles2D.new`, `Sprite2D.new` ou `Polygon2D.new` em `game.gd`/`main.tscn`.
- Nenhuma ocorrência de `_build_ground`, `_draw_paths`, `ground.clear` ou `ground.set_cell` em `island_world.gd`.
- `game.gd` cria apenas estado, RNG, eventos de entrada e cenas `enemy.tscn`; os visuais permanecem declarativos ou delegados.
- Nenhuma propriedade `scale` de `Sprite2D`/`CanvasItem` é fracionária; `texture_scale = 2.2` pertence apenas à textura radial da luz da fogueira.

## Auto-revisão e preocupações

- A mira real é processada somente quando `Player.enabled` é verdadeiro, que o controlador restringe a `playing`; menus, pausa, resgate e vitória não atualizam nem movem o jogador.
- Desabilitar `Enemies` no pai interrompe tanto perseguição quanto emissão de dano dos filhos herdados; o guard adicional em `hurt_player()` protege também chamadas tardias ou externas.
- A rotação da seta foi verificada por API nos quatro sentidos, pela integração com `-player_position` e por duas capturas reais.
- O TileMap abre já preenchido no editor. A sentinela prova que entrar na árvore não sobrescreve uma edição feita antes de `_ready()`.
- A remoção do z-index do jogador é intencional; overlays de efeitos/resgate continuam acima do mundo.
- A única advertência observada fora dos testes é a falha ambiental de socket do editor headless; importação, seis suítes, smoke e captura gráfica terminaram com exit 0.
- Não foi realizado playtest humano de dificuldade; esta onda altera integração e apresentação, não balanceamento.
