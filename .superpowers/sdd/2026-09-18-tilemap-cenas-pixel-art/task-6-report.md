# Task 6 — regressão, inspeção visual e documentação

Data: 2026-09-21

## Status

Concluída e verificada. As seis suítes terminaram com `exit 0`, a cena principal executou 120 iterações sem erro, a importação terminou com `exit 0`, o playtest físico dirigido passou e oito estados visuais foram realmente renderizados e inspecionados em 1280×720.

Não foi necessário alterar mecânica, balanceamento, schema de save ou arquivos de produção: nenhuma falha de comportamento foi reproduzida. A cobertura física e de combate foi ampliada nas suítes existentes, o script de captura ganhou o estado explícito de combate e a documentação foi atualizada para a arquitetura entregue.

Não houve commit, conforme a instrução da tarefa. Além disso, `git rev-parse --is-inside-work-tree` retorna `fatal: not a git repository (or any of the parent directories): .git`.

## Fontes de verdade

- Brief: `.superpowers/sdd/2026-09-18-tilemap-cenas-pixel-art/task-6-brief.md`.
- Spec aprovado: `docs/superpowers/specs/2026-09-18-tilemap-cenas-pixel-art-design.md`.
- Ledger: `.superpowers/sdd/2026-09-18-tilemap-cenas-pixel-art/progress.md`.

O diretório SDD não contém um arquivo `spec.md`; o spec acima é o caminho registrado como aprovado no próprio ledger.

## Ambiente

- Godot: `/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64`.
- Versão observada: `4.7.1.stable.official.a13da4feb`.
- Dados: `XDG_DATA_HOME=/tmp/o-farol-task6`.
- Configuração: `XDG_CONFIG_HOME=/tmp/o-farol-task6-config`.
- Projeto: `/home/theotonin/Documentos/godot/o-farol`.
- Render gráfico: X11, OpenGL 4.6, renderer Compatibility, AMD Radeon 660M/Mesa 25.0.5-2.

## 1. Suíte completa

Comandos, executados inicialmente e repetidos depois das alterações de QA/documentação:

```bash
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_survival.gd
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_scene_architecture.gd
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_world_physics.gd
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_game.gd
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_expedition.gd
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_save_feedback.gd
```

Resultado final observado:

| Suíte | Exit | Saída de aceite |
|---|---:|---|
| `test_survival.gd` | 0 | `PASS: 128 survival rule checks` |
| `test_scene_architecture.gd` | 0 | `Combate dirigido: ataque de 35 e dano inimigo de 14 verificados em quatro direções` |
| `test_world_physics.gd` | 0 | `Playtest físico: 4 costas, 6 construções, fogueira, decoração e 69 recursos verificados com Player/Enemy` |
| `test_game.gd` | 0 | `Integração: 0 falhas` |
| `test_expedition.gd` | 0 | `Expedição completa: 0 falhas` |
| `test_save_feedback.gd` | 0 | `Avisos de salvamento: 0 falhas` |

Não houve erro de parser, recurso ausente, callback inválido nem aviso de nó/objeto órfão nas seis execuções finais.

## 2. Importação e smoke runtime

Importação:

```bash
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --editor --path . --import
```

Resultado: `exit 0`. O scan do projeto, o registro de classes e o carregamento do editor chegaram a `[ DONE ]`. A saída também contém, no início e no fim:

```text
ERROR: Condition "_sock == -1" is true. Returning: FAILED
ERROR: Condition "err != OK" is true. Returning: ERR_CANT_CREATE
```

Esses erros ocorreram ao editor tentar abrir seu servidor TCP dentro do sandbox (`_inet_open`/`tcp_server.cpp`); não houve erro de import de PNG, TileSet, cena ou script. A mesma limitação ambiental já constava no relatório da Task 5 e foi preservada aqui como limitação real, sem ocultá-la.

Smoke de 120 iterações:

```bash
XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --quit-after 120
```

Resultado: `exit 0`; somente o cabeçalho da Godot foi impresso, sem erro ou warning material.

## 3. Captura e inspeção visual

### Investigação do backend

`xvfb-run`, `Xvfb`, `weston`, `cage`, `grim` e ImageMagick `import` não estão instalados. A sessão, porém, expõe `DISPLAY=:0` e `WAYLAND_DISPLAY=wayland-0`.

A primeira tentativa, confinada ao sandbox, usou:

```bash
DISPLAY=:0 XDG_DATA_HOME=/tmp/o-farol-task6 XDG_CONFIG_HOME=/tmp/o-farol-task6-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --display-driver x11 --rendering-driver opengl3 --audio-driver Dummy --resolution 1280x720 --path . --script tests/capture_game.gd
```

Resultado: `exit 1`, com os erros exatos `X11 Display is not available`, `Can't connect to a Wayland display` e `Unable to create DisplayServer`. A tentativa não gerou capturas e não foi tratada como screenshot.

O mesmo comando, autorizado a acessar apenas o display local, terminou com `exit 0` e informou:

```text
OpenGL API 4.6 (Core Profile) Mesa 25.0.5-2 - Compatibility - Using Device: AMD - AMD Radeon 660M (radeonsi, rembrandt, LLVM 19.1.7, DRM 3.64, 6.17.6-lux-amd64)
Captura menu: 0
Captura intro: 0
Captura day: 0
Captura shelter: 0
Captura night: 0
Captura combat: 0
Captura rescue: 0
Captura victory: 0
```

### Arquivos gerados

Todos são PNG RGBA não entrelaçados de 1280×720:

| Estado | Caminho | SHA-256 |
|---|---|---|
| Menu | `/tmp/o-farol-menu.png` | `3c3b2260fd3046a03a0047a58ab0e6a755cfc0512f7c07bcb31e4980e4d68abd` |
| Introdução | `/tmp/o-farol-intro.png` | `471012d0bb33f5ab6443e632460f0bb9c49ff7bd0a3d1cbf650ba201e06910c6` |
| Dia | `/tmp/o-farol-day.png` | `28474d72287ef3db97c4617f9f1f1202bbd68bf5fce06453e068bd2bce1c5835` |
| Abrigo | `/tmp/o-farol-shelter.png` | `5e3e9b3bb9f90cfc34d50c77cda5498ae5917cbcce1876109d8e5d683841cac7` |
| Noite | `/tmp/o-farol-night.png` | `39aeca2b9344bbea709bf4f8b772ac4de1a908a4a93f9c00bb3e5f3cbf956773` |
| Combate | `/tmp/o-farol-combat.png` | `9fa97b65c1505b4f1c1f73a10845f22004606d9e20f8526505d599dcb4da44a5` |
| Resgate | `/tmp/o-farol-rescue.png` | `88d310cfa5cd6ee16335c7b63fd9f2bdb042653c1fa3e112f653fc455ffffbbe` |
| Vitória | `/tmp/o-farol-victory.png` | `0e5bb5eb73686e8f98d40979d3df2f621aad12c25dfd31360b2e0fa18d65b781` |

### Inspeção observada

- Pixels permanecem nítidos no terreno, atores e objetos; nenhuma interpolação borrada foi observada.
- Não há linha de bleeding aparente entre células do atlas nas vistas aproximada e panorâmica.
- Jogador, animal, fogueira, farol, depósito, ruínas, pickups e decorações aparecem alinhados ao chão, sem tremor entre os estados capturados.
- A ordem Y é coerente nos agrupamentos visíveis; árvores, atores, objetos e construções não exibem inversão material.
- Costa e volumes das construções são visualmente plausíveis em relação aos sprites; a confirmação de bloqueio foi feita por física, não inferida apenas da imagem.
- Menu, introdução, HUD, painel do abrigo e vitória cabem em 1280×720 sem corte ou overflow. O abrigo apresenta scrollbar real.
- A noite mantém terreno, recursos, jogador e inimigos legíveis; a fogueira cria foco quente perceptível e o HUD conserva contraste.
- A captura de combate mostra jogador orientado à direita, animação de ataque e inimigo dentro da área frontal. A aplicação do dano foi confirmada separadamente pelo teste físico de quatro direções.
- O resgate mostra a ilha completa, costa, caminhos e feixe; a vitória mantém o fundo escurecido e o texto legível.

Os arquivos em `/tmp` são artefatos temporários desta sessão. O comando e o script permanecem reproduzíveis; eles não foram copiados para o projeto como assets de produção.

## 4. Playtest físico dirigido

`tests/test_world_physics.gd` agora realiza consultas e movimentos físicos reais, além dos contratos estruturais anteriores:

- move `Player` e `Enemy` contra norte, leste, sul e oeste da costa e exige colisão com `CoastCollision`;
- move ambos contra farol, depósito e as quatro ruínas e exige colisão com cada `StaticBody2D`;
- move ambos através da fogueira e exige ausência de colisão world;
- atravessa uma decoração real e exige ausência de colisão;
- para cada um dos 69 pickups, busca até 60 pixels ao redor (dentro do raio de interação de 68) uma posição caminhável e livre para o corpo do jogador.

Saída observada:

```text
Playtest físico: 4 costas, 6 construções, fogueira, decoração e 69 recursos verificados com Player/Enemy
```

`tests/test_scene_architecture.gd` instancia o jogo e, para cima, direita, baixo e esquerda:

- orienta a `AttackArea`, confirma a sobreposição real e verifica redução de 65 para 30 HP (35 de dano);
- posiciona o inimigo ao redor do jogador, confirma a `DamageArea` e verifica redução de 100 para 86 de vida (14 de dano).

Saída observada:

```text
Combate dirigido: ataque de 35 e dano inimigo de 14 verificados em quatro direções
```

O spawn `(0, 110)` permaneceu caminhável. A expedição completa também coletou os recursos reais e chegou aos três reparos e ao resgate com `0 falhas`.

## 5. Checklist do spec

| Requisito | Evidência | Status |
|---|---|---|
| `TileMapLayer` para terreno | cena e teste de arquitetura/física; captura de dia/resgate | OK |
| Cenas independentes | jogador, inimigo, pickup, farol, fogueira, depósito, ruína e UI carregados/testados | OK |
| PNG pixel art; sem `_draw()` de mapa/atores/objetos | três PNGs importados; busca sem `func _draw`, `draw_player`, `draw_animal` ou `queue_redraw` em `scripts/` | OK |
| Grade 32×32, nearest, escala de referência | `island_tileset.tres`, `project.godot`, imports sem mipmap e capturas 1280×720 | OK |
| Somente costa/construções bloqueiam | playtest Player/Enemy; fogueira/decoração/pickup atravessáveis | OK |
| Spawn e recursos acessíveis | spawn caminhável; 69/69 pickups com ponto físico livre | OK |
| Combate/coleta/ciclo/morte/reparos/save/resgate preservados | seis suítes, quatro direções e expedição completa | OK |
| Import obrigatório falha se asset estiver ausente | carregamento/importação e contratos `ResourceLoader.exists` | OK |
| IDs únicos | física/arquitetura verificam 69 IDs e exatamente 3 peças | OK |
| Posição inválida de save volta ao spawn | `test_game.gd` | OK |
| UI em português e sem overflow | árvore declarativa, integração e capturas | OK |
| Dia/noite e fogueira legíveis | captura noturna real e `PointLight2D` exercitado | OK |
| Menu, dia, abrigo, noite, combate e vitória inspecionados | oito capturas reais; também introdução e resgate | OK |

## 6. Documentação

Atualizados:

- `README.md`: arquitetura de TileMap/cenas, assets, camadas de colisão, seis comandos de teste e captura gráfica.
- `DESIGN.md`: substitui a declaração procedural provisória por pixel art/TileMap/cenas/colisões e registra a inspeção real.
- `docs/context/cycle.md`: resultados dos testes, playtest físico, import/smoke, capturas e limites da automação.
- `docs/specs/prototipo.md`: substitui `scripts/island.gd` por `scripts/island_world.gd` e descreve a arquitetura atual.

Uma busca final nesses quatro documentos não encontrou `scripts/island.gd`, “gráficos procedurais”, “desenhos geométricos” nem “aparência provisória”.

## 7. Arquivos alterados nesta task

- `tests/capture_game.gd` — captura explícita do estado de combate.
- `tests/test_scene_architecture.gd` — ataque e dano nos quatro sentidos.
- `tests/test_world_physics.gd` — playtest dirigido de costa, construções, fogueira, decoração e alcance dos recursos.
- `README.md`.
- `DESIGN.md`.
- `docs/context/cycle.md`.
- `docs/specs/prototipo.md`.
- `.superpowers/sdd/2026-09-18-tilemap-cenas-pixel-art/task-6-report.md`.
- `.superpowers/sdd/2026-09-18-tilemap-cenas-pixel-art/progress.md` — checkpoint final.

Nenhum arquivo de mecânica/produção foi modificado.

## Limitações restantes

- Não houve partida humana contínua do início ao resgate. Ritmo, dificuldade e leitura durante movimento continuam pendentes de playtest humano.
- A expedição automatizada transporta o jogador entre recursos para validar economia/progressão; ela não mede navegação ou sensação de controle.
- As capturas são estados preparados por script, não uma gravação de uma partida contínua.
- Os PNGs estão em `/tmp` e podem desaparecer quando o ambiente temporário for limpo; o script e o comando de reprodução permanecem no projeto/relatório.
- O sandbox impede os sockets internos do editor durante `--import`; o comando ainda termina com `exit 0` e não há erro de recurso, cena ou script.
- Não há repositório Git utilizável, e a tarefa proibiu commit; nenhum checkpoint Git foi criado.

## Conclusão

O contrato da migração está coberto por regressão, física, runtime e inspeção visual real. Não foi encontrada regressão material que justificasse alterar a mecânica. O único próximo passo fora da automação é o playtest humano contínuo já registrado no ciclo.
