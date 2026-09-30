# SDD ledger — plan: docs/superpowers/plans/2026-09-18-tilemap-cenas-pixel-art.md

## Setup

- Spec: `docs/superpowers/specs/2026-09-18-tilemap-cenas-pixel-art-design.md` (reachable and approved).
- Git/worktree: unavailable; `.git` is empty and `git rev-parse` reports no repository.
- Ruling: execute in the authorized workspace without commits or Git-based review packages — user explicitly requested implementation, there is no repository state to isolate, and all changes remain local/reversible — cost if wrong: no automatic commit-level rollback; reviews must use file inventories and reports.
- Godot: `/home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64`, version 4.7.1.
- Test environment: set a task-specific `XDG_DATA_HOME` under `/tmp` because the sandbox cannot write Godot logs under the default user data directory.
- Baseline: `test_survival.gd` PASS (128); `test_game.gd` PASS (0 failures); `test_expedition.gd` PASS (0 failures); `test_save_feedback.gd` PASS (0 failures).

## Pre-flight review

| Tasks | Producer / consumer or internal check | Finding / ruling |
|---|---|---|
| 1 | Own test vs code | Conflict: source-text assertions for removed draw functions violate behavior-test guidance. Ruling: test real scene roots/children/groups; reviewers inspect removal of procedural drawing structurally. Cost if wrong: automated tests may not catch a later reintroduction of `_draw()`, but scene behavior remains covered. |
| 2 | Own asset task | Consistent: outputs three PNG sheets and a 32×32 TileSet; import validation covers resource integrity. |
| 3 | Own world task | Consistent after Task 2: consumes TileSet/assets, produces IslandWorld and structure interfaces used downstream. |
| 4 | Own actor task | Consistent: test-first scene contracts precede player/enemy/pickup implementation. |
| 5 | Own integration task | Consistent: updates existing integration tests before replacing controller/UI behavior. |
| 6 | Own verification task | Consistent: full regression, visual inspection and docs only after integrated behavior exists. |
| 1 ↔ 4 | `tests/test_scene_architecture.gd` | Task 1 creates base contract; Task 4 extends it. No conflict. |
| 1 ↔ 5 | Groups/layers and main composition | Task 1 defines names; Task 5 consumes them. No conflict. |
| 2 ↔ 3 | `terrain_atlas.png`, `objects.png`, `island_tileset.tres` | Task 2 produces assets; Task 3 consumes them. No conflict. |
| 2 ↔ 4 | `characters.png`, `objects.png` | Task 2 produces aligned regions; Task 4 consumes them. No conflict. |
| 2 ↔ 6 | PNG imports and visual QA | Task 6 verifies Task 2 outputs. No conflict. |
| 3 ↔ 4 | `IslandWorld.get_resource_nodes()` and pickups | Ordering ambiguity: Task 3 references pickup interface created by Task 4. Ruling: Task 3 may create empty `Resources` container and make state update tolerant; Task 4 populates it. Cost if wrong: temporary Task 3 coverage cannot verify resource visibility until Task 4. |
| 3 ↔ 5 | Island/structure interfaces | Task 3 produces exact methods and node names consumed by controller. No conflict. |
| 3 ↔ 6 | World files and QA | Task 6 may modify findings only; no interface conflict. |
| 4 ↔ 5 | Player/Enemy/Pickup interfaces | Task 4 produces signals/methods; Task 5 consumes them. No conflict. |
| 4 ↔ 6 | Actor files and QA | Task 6 may modify findings only; no interface conflict. |
| 5 ↔ 6 | Main/UI/tests/docs | Task 6 validates and documents integrated Task 5. No conflict. |

## Task status

- Task 1: fix round 1/5 (1 addressed, 0 open — groups now contractually verified; no commits because Git unavailable)
- Task 1: complete (review clean; architectural test intentionally RED until later scene tasks)
- Task 2: pending
- Task 2: Ruling: permitir normalização/repack raster por célula no terrain atlas — o spec exige tiles 32×32 sem costuras e prevalece sobre a limitação do brief a recorte externo; preservar ordem/conteúdo e usar somente nearest — custo se errado: até poucos pixels de borda podem ser perdidos.
- Task 2: minor (deferred): objects exige regiões explícitas em vez de hframes/vframes uniformes.
- Task 2: minor (deferred): transições do TileSet serão selecionadas manualmente; peering automático não foi configurado.
- Task 2: minor (deferred): offsets/pivôs e alfa parcial de personagens/objetos precisam de conferência em cena.
- Task 2: fix round 1/5 (1 addressed, 0 open — costuras do terrain atlas removidas; sem commits porque Git indisponível)
- Task 2: complete (review clean após fix; três PNGs e TileSet importáveis)
- Task 3: pending
- Task 3: minor (deferred): teste físico amostra colisão costeira externa apenas ao sul; implementação foi revisada geometricamente nos quatro lados.
- Task 3: complete (review clean; sem commits porque Git indisponível)
- Task 4: pending
- Task 4: Ruling: substituir asserções transitórias de Resources vazio em `test_world_physics.gd` por contrato de pickups populados — Task 4 deliberadamente completa a interface deixada vazia na Task 3 — custo se errado: o teste físico passa a depender da distribuição de recursos aprovada no spec.
- Task 4: minor (deferred): testes de movimento não cobrem jogador contra barreira world; knockback inimigo passou a cobrir colisão real.
- Task 4: minor (deferred): fixture de clusters replica parte do gerador em vez de enumerar 69 posições literais.
- Task 4: fix round 1/5 (1 addressed, 0 open — knockback agora usa física nativa; sem commits porque Git indisponível)
- Task 4: complete (review clean após fix)
- Task 5: pending
- Task 5: minor (deferred to Task 6): README/docs ainda mencionam `scripts/island.gd` removido e precisam descrever a arquitetura nova.
- Task 5: minor (deferred): round-trip de integração não usa fixture externo de save pré-migração; esquema de SurvivalState permaneceu inalterado e seus testes passam.
- Task 5: fix round 1/5 (3 addressed, 0 open — efeitos declarativos, fogueira não bloqueante com luz, dano inimigo por Area2D; sem commits porque Git indisponível)
- Task 5: complete (review clean após fix; suíte 6/6 reportada verde)
- Task 6: complete (seis suítes em exit 0; import exit 0 com limitação ambiental de socket documentada; smoke 120 exit 0; playtest físico dirigido e oito capturas 1280×720 inspecionadas; documentação atualizada; sem commit por instrução e ausência de Git)
- Final review: fixes required — mouse aim missing; enemies/hurt not fully paused outside playing; lighthouse direction arrow missing; fractional tree scales violate pixel constraint; Ground TileMap populated only at runtime instead of serialized/editable.
- Final fix wave: in progress (single dispatch per SDD final-review rule).
- Final fix wave: complete — mouse aim, full mode pause/damage guard, lighthouse direction arrow, integer decoration scales, serialized TileMap Ground and Y-sort policy implemented with TDD.
- Final scoped re-review: clean; all five findings addressed and no new Critical/Important breakage.
- Fresh controller verification: six suites exit 0 (`survival` 128 checks; architecture combat four directions; physical playtest four coasts/six structures/69 resources; integration/expedition/save feedback 0 failures), import exit 0 with sandbox-only TCP socket warnings, smoke 120 exit 0.
- Finalization Ruling: preserve this SDD workspace because Git history is unavailable and these reports are the only rollback/audit record — cost if wrong: `.superpowers/sdd` remains as local project metadata instead of being cleaned up.
