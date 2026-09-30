### Task 6: Regressão, inspeção visual e documentação

**Files:**
- Modify: `README.md`
- Modify: `DESIGN.md`
- Modify: `docs/context/cycle.md`
- Modify as findings require: arquivos das Tasks 2–5

**Interfaces:**
- Verifica todo o contrato do spec; não cria novas mecânicas.

- [ ] **Step 1: Rodar toda a suíte**

```bash
godot --headless --path . --script tests/test_survival.gd
godot --headless --path . --script tests/test_scene_architecture.gd
godot --headless --path . --script tests/test_world_physics.gd
godot --headless --path . --script tests/test_game.gd
godot --headless --path . --script tests/test_expedition.gd
godot --headless --path . --script tests/test_save_feedback.gd
```

Expected: todos exit 0, sem erros de parser, recursos ausentes ou nós órfãos.

- [ ] **Step 2: Executar a cena principal headless**

Run: `godot --headless --path . --quit-after 120`

Expected: exit 0, sem erros ou warnings materiais.

- [ ] **Step 3: Capturar e inspecionar estados visuais**

Capturar menu, dia, abrigo, noite, combate e vitória em 1280×720. Conferir: pixels nítidos, sem bleeding no atlas, sprites alinhados, ordem Y coerente, colisões visualmente plausíveis, UI sem overflow e iluminação legível.

- [ ] **Step 4: Playtest físico dirigido**

Confirmar manualmente: costa bloqueia; farol/depósito/ruínas bloqueiam; árvore/pedra deixam passar; jogador não nasce preso; todos os recursos são alcançáveis; inimigos não atravessam costa/construções; ataque e coleta funcionam nos quatro sentidos.

- [ ] **Step 5: Atualizar documentação**

Remover de `DESIGN.md` a declaração de gráficos procedurais provisórios, descrever atlas/cenas/colisões em `README.md` e registrar as evidências e limitações reais em `docs/context/cycle.md`.

- [ ] **Step 6: Verificação final após correções**

Repetir a suíte completa e a execução de 120 frames. Guardar no relatório final os comandos e resultados observados, sem afirmar sucesso para uma etapa não executada.

- [ ] **Step 7: Registrar o checkpoint final**

Commit `feat: complete pixel art scene migration` somente se Git estiver disponível.
