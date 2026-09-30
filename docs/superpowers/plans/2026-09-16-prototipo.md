# O Farol Implementation Plan

> **For agentic workers:** Use subagent-driven-development for the independent rules task; integrate and verify in this session.

**Goal:** Entregar o protótipo jogável completo do escopo aprovado.

**Architecture:** Regras em RefCounted sem dependência visual, ilha determinística e controlador Node2D. Interface Control/CanvasLayer e áudio sintetizado separados. Recursos gráficos originais desenhados pela engine.

**Tech Stack:** Godot 4.7.1, GDScript, renderizador Compatibility.

**Spec:** docs/specs/prototipo.md

## Global Constraints

- Sem gastos; execução dentro da Godot no computador.
- 2D visto de cima; interface em português.
- Dia 240s, noite 120s; recursos e progresso conforme spec.
- Não alterar `.git`, `.agents` ou `.codex`; metadados Git indisponíveis neste workspace.

## Task 1 — Regras, inventários e persistência

- [x] Criar testes executáveis de capacidade, transferência, alimento, combustível, ciclos, morte, reparos, peças e save/load.
- [x] Verificar falha antes da implementação.
- [x] Implementar `scripts/survival_state.gd` e testar com engine headless.
- [x] Revisar entradas inválidas e saves incompletos/corrompidos.

Interface: `new_game()`, `collect(kind, id) -> bool`, `deposit_all()`, `withdraw(kind) -> bool`, `eat() -> bool`, `fuel_fire() -> bool`, `repair() -> bool`, `ignite() -> bool`, `die()`, `tick(delta) -> bool` (true se amanheceu), `save_game(path) -> Error`, `load_game(path) -> bool`, `is_night()`, `bag_count()`, `next_cost() -> Dictionary`. Campos: `day`, `time_of_day`, `health`, `stamina`, `fuel`, `repair_stage`, `won`, `bag`, `storage`, `collected`, `player_position` (Vector2). `collected` mapeia id de recurso coletado para tipo. Peças depositadas permanecem coletadas; peças carregadas e perdidas reaparecem na morte. API e valores documentados no script.

## Task 2 — Ilha e integração jogável

- [x] Criar teste de entrada real, movimento, coleta e retorno ao abrigo antes da implementação.
- [x] Configurar main scene, janela e Compatibility.
- [x] Criar ilha fixa com costa irregular, vegetação, caminhos e recursos próximos/distantes.
- [x] Implementar movimento com limites da ilha, energia, ataques direcionais, inimigos e proteção do abrigo.
- [x] Integrar ciclo, manhã, morte, checkpoints e resgate.

## Task 3 — Interface, áudio e apresentação

- [x] Implementar menu inicial, introdução, pausa e confirmação de novo jogo.
- [x] Exibir vida/energia, mochila, tempo, direção do farol, objetivo e interação contextual.
- [x] Implementar painel do abrigo com depósito/retirada, combustível e custos exatos de reparo; tempo continua.
- [x] Criar sons originais leves e opção de silenciar.
- [x] Garantir mensagens de falha de save, recurso indisponível, falta de materiais e mochila cheia.

## Task 4 — Verificação e documentação

- [x] Rodar testes de regras e integração completa, importação e execução headless.
- [x] Revisar cenários de morte, noite sem combustível, vitória, save/load e pausa.
- [x] Capturar uma partida via renderização disponível e inspecionar legibilidade.
- [x] Corrigir achados materiais, executar verificação final e documentar como jogar/testar.

## Registro

Design aprovado pelo usuário na conversa. Nenhuma aprovação adicional necessária para implementação local. Workspace sem repositório Git acessível; trabalho será feito no diretório autorizado sem commits ou worktree. Tarefas 1 e 2 compartilham somente o contrato acima; tarefa 3 consome controlador e estado; tarefa 4 verifica o conjunto.


## Evidência final — 16/09/2026

- Godot 4.7.1: importação com renderizador Compatibility sem erros após execução autorizada fora do sandbox.
- `test_survival.gd`: 128 verificações, exit 0.
- `test_game.gd`: integração com 0 falhas, exit 0.
- `test_expedition.gd`: coleta real, noite, três reparos e checkpoints até vitória, 0 falhas, exit 0.
- `test_save_feedback.gd`: erros de save preservados em início, morte e resgate, 0 falhas, exit 0.
- Cena principal executou 120 frames headless, exit 0, sem erros ou warnings.
- Capturas gráficas a 1280×720: menu, introdução, dia, abrigo, noite, resgate e vitória. Overflow do painel de abrigo corrigido e confirmado visualmente.
- Revisão independente corrigiu rastreabilidade de peças, validação de saves e avisos de falha. Re-revisão delimitada aprovou os ajustes.
- Limite: gráficos geométricos provisórios; ritmo/dificuldade ainda aguardam playtest humano. Nenhum commit ou publicação feito.
