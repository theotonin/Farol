# O Farol

Protótipo escolar de sobrevivência 2D, criado na Godot 4.7.1. Explore uma ilha, prepare seu abrigo e reconstrua o farol para chamar o resgate. Sem limite de dias; a partida termina quando você decide acender o farol concluído.

## Executar

1. Abra `project.godot` na Godot 4.7.1.
2. Pressione **F5** (Executar Projeto).
3. Escolha **Nova expedição**, leia a introdução e clique em **Chegar à ilha**.

A cena inicial é `scenes/main.tscn`. Não há plugins, downloads, contas ou recursos pagos necessários. O renderizador Compatibility reduz a exigência de hardware.

## Controles

| Ação | Controle |
|---|---|
| Mover | WASD |
| Correr | Segurar Shift; consome energia |
| Mirar / atacar | Mouse / clique esquerdo |
| Coletar ou abrir abrigo | E |
| Comer e recuperar vida | Q |
| Fechar painel / pausar | Esc |

No abrigo, **Guardar toda a mochila** transfere materiais para o depósito. Você pode retirar uma unidade de cada tipo. Os reparos usam automaticamente o depósito; abastecer a fogueira usa primeiro madeira carregada, depois madeira guardada. Organizar materiais não pausa a partida.

## Primeira expedição

- Procure os troncos e pedras perto do farol. Aproximar-se mostra o comando de coleta.
- A mochila comporta 20 unidades. Volte para guardar materiais e abastecer a fogueira.
- Uma madeira sustenta 30 segundos de fogo; quatro sustentam a noite inteira. O combustível só é consumido à noite, com reserva máxima de 240 segundos.
- O dia dura quatro minutos; a noite, dois. Há um aviso 30 segundos antes de escurecer. A seta dourada junto da distância no HUD aponta para o farol.
- A fogueira acesa protege a área circular do abrigo. Sem fogo, animais podem entrar. Comida na mochila recupera 25 de vida.
- Sucata fica nas ruínas mais distantes. As três peças únicas estão nos extremos oeste, leste e sul da ilha.
- Complete os três reparos e use **Acender o farol e chamar resgate** quando quiser encerrar a partida.

| Reparo | Materiais do depósito |
|---|---|
| Estrutura | 10 madeiras, 8 pedras |
| Mecanismo | 8 madeiras, 6 sucatas, 1 peça |
| Lanterna | 8 pedras, 8 sucatas, 2 peças |

Ao morrer, você acorda na manhã seguinte com vida cheia e mochila vazia. O depósito e os reparos permanecem. Materiais comuns renovam a cada manhã; peças perdidas retornam ao local original. As noites aumentam de quatro até doze animais.

## Salvamento

Um checkpoint é salvo automaticamente ao amanhecer, após cada reparo, na morte, ao acender o farol e ao voltar ao menu. Uma nova expedição é salva ao começar a jogar. **Continuar expedição** retoma o último checkpoint; encerrar pela janela ou parar pelo editor entre checkpoints perde as alterações desde o último save.

Arquivo: `user://save.json`, na pasta de dados da Godot para **O Farol**. O menu pede confirmação antes de começar outra expedição sobre o progresso existente. Salvamentos inválidos mostram uma mensagem e não carregam estado parcial.

## Estrutura

- `scripts/survival_state.gd`: inventários, tempo, combustível, morte, reparos e save/load.
- `scripts/game.gd`: coordenação do ciclo, combate, inimigos, câmera, checkpoints e vitória.
- `scripts/island_world.gd`: contorno navegável, costa física, recursos e decorações.
- `scenes/world/island.tscn`: chão editável e serializado, costa física e instâncias das construções.
- `scenes/actors/`: jogador e inimigo como `CharacterBody2D`, com sprites animados e áreas de ataque/dano.
- `scenes/objects/`: recursos como `Area2D`; farol, depósito e ruínas como `StaticBody2D`; fogueira atravessável como `Area2D` com luz.
- `scenes/ui/game_ui.tscn`: árvore declarativa de menus, HUD e painel do abrigo em português.
- `scripts/soundscape.gd`: efeitos sintetizados originais.
- `assets/pixel/`: atlas de terreno 32×32, personagens e objetos rasterizados.
- `docs/specs/prototipo.md`: escopo aprovado.

O mapa usa `TileMapLayer` com `resources/island_tileset.tres`. O projeto define filtro `nearest`, não gera mipmaps nos PNGs e mantém a referência de 1280×720 para preservar pixels nítidos. A costa e as construções bloqueiam jogador e animais; fogueira, recursos, árvores, pedras pequenas e demais decorações são atravessáveis. Os gráficos pixel art e os efeitos sonoros são originais deste protótipo e não exigem bibliotecas, contas ou licenças externas.

O fluxo, a física e a apresentação têm cobertura automática, mas ritmo, dificuldade e leitura durante movimento ainda devem ser avaliados em uma partida humana antes da apresentação escolar.

## Testes

Substitua `godot` pelo caminho do executável, se necessário. Em Linux, `XDG_DATA_HOME=/tmp/o-farol-tests` isola os dados de teste da sua partida.

```bash
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_survival.gd
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_scene_architecture.gd
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_world_physics.gd
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_game.gd
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_expedition.gd
XDG_DATA_HOME=/tmp/o-farol-tests XDG_CONFIG_HOME=/tmp/o-farol-tests-config godot --headless --path . --script tests/test_save_feedback.gd
```

As suítes cobrem regras, cenas, camadas e colisões físicas, combate nos quatro sentidos, integração de controles, coleta até o resgate, checkpoints e erros de salvamento. A expedição automatizada transporta o jogador entre recursos para verificar a economia; não substitui o playtest de dificuldade. O script opcional `tests/capture_game.gd` requer display gráfico e grava em `/tmp` capturas de menu, introdução, dia, abrigo, noite, combate, resgate e vitória.
