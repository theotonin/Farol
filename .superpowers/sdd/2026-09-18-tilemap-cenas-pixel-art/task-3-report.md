# Task 3 — Mundo TileMap, costa e construções

## Status

Implementação concluída pelo subagente antes de seu turno encerrar por limite de uso. O controlador recuperou o checkpoint pelos arquivos e reexecutou os testes.

## TDD

- RED reportado pelo implementador: `tests/test_world_physics.gd` falhou pela ausência de `res://scenes/world/island.tscn`.
- GREEN reexecutado pelo controlador:

```text
XDG_DATA_HOME=/tmp/o-farol-task3 XDG_CONFIG_HOME=/tmp/o-farol-task3-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_world_physics.gd
```

Resultado: exit 0, sem erros.

- `tests/test_scene_architecture.gd`: exit 1 exclusivamente pelas quatro cenas futuras `player`, `enemy`, `resource_pickup` e `game_ui`.
- `tests/test_game.gd`: exit 0, `Integração: 0 falhas`, confirmando que manter `scripts/island.gd` preservou a linha de base.

## Implementado

- `scenes/world/island.tscn`: `Ground` TileMapLayer, `CoastCollision` StaticBody2D, `Decorations`, `Resources` vazio e `Structures` com farol, depósito, fogueira e quatro ruínas.
- `scripts/island_world.gd`: preenche o mapa determinístico, aplica transições manuais, desenha cinco caminhos por tiles, cria 19 polígonos de colisão costeira e 126 sprites decorativos sem colisão.
- `scenes/objects/lighthouse.tscn` + `scripts/lighthouse.gd`: quatro estágios raster, colisão, interação e luz final.
- `scenes/objects/campfire.tscn` + `scripts/campfire.gd`: corpo de construção, interação, animação e luz conforme combustível/noite.
- `scenes/objects/storage.tscn`: depósito bloqueante e área de interação.
- `scenes/objects/ruin.tscn`: ruína reutilizável bloqueante e área de interação.
- `tests/test_world_physics.gd`: verifica tipos, alcance do mapa, spawn, mar, estruturas, camadas/máscaras, ausência de colisão em decoração e estado visual tolerante a Resources vazio.

## Diagnóstico do implementador

- 6.956 células no TileMap.
- 211 tiles de caminho em cinco rotas.
- 420 transições manuais.
- 126 decorações sem colisão.
- 19 segmentos de costa.
- `Resources` vazio, conforme ruling para a Task 4.
- Colisão externa verificada e spawn livre.

## Decisões e preocupações

- `scripts/island.gd` foi preservado até a integração da Task 5; removê-lo agora quebraria o controlador antigo.
- `constrain_position()` permanece temporariamente por compatibilidade/validação, mas o controlador novo deve depender da física nativa.
- As transições usam seleção manual do atlas, pois o TileSet não contém peering automático completo.
- Nenhum commit foi criado porque Git está indisponível.
