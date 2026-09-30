# Migração para TileMap, cenas e pixel art

## Objetivo

Substituir a apresentação procedural de *O Farol* por um mapa editável em TileMapLayer, sprites rasterizados em pixel art, cenas independentes e colisões nativas da Godot, preservando as regras, o mapa, a progressão, a interface em português e os salvamentos do protótipo atual.

## Restrições aprovadas

- Usar TileMapLayer para mar, areia, grama, caminhos e transições da costa.
- Usar cenas independentes para jogador, inimigo, recursos e construções.
- Usar sprites pixel art rasterizados em PNG; não desenhar mapa, atores ou objetos com `_draw()`.
- Usar grade-base de 32×32 pixels, filtro `nearest` e escalas inteiras.
- Apenas a costa e as construções bloqueiam movimento.
- Árvores, pedras pequenas e outras decorações permanecem atravessáveis.
- Preservar ciclo, combate, coleta, mochila, depósito, fogueira, reparos, morte, salvamento e resgate existentes.
- Manter Godot 4.7, renderizador Compatibility e resolução de referência 1280×720.

## Arquitetura de cenas

`main.tscn` permanece como ponto de entrada e passa a instanciar componentes editáveis:

```text
OFarol (Node2D)
├── World (Node2D)
│   ├── Island (instância de island.tscn)
│   │   ├── Ground (TileMapLayer)
│   │   ├── CoastCollision (StaticBody2D)
│   │   ├── Decorations (Node2D)
│   │   └── Structures (Node2D)
│   ├── Resources (Node2D)
│   ├── Enemies (Node2D)
│   └── Player (instância de player.tscn)
├── Lighting (CanvasModulate)
├── Camera2D
└── UI (instância de game_ui.tscn)
```

### Cenas independentes

- `player.tscn`: `CharacterBody2D`, `AnimatedSprite2D`, `CollisionShape2D` e `Area2D` de ataque. `player.gd` lê entrada, usa `move_and_slide()`, atualiza direção/animação e emite pedidos de ataque e interação.
- `enemy.tscn`: `CharacterBody2D`, `AnimatedSprite2D`, colisão corporal e área de dano. `enemy.gd` recebe um alvo, persegue ou vagueia, respeita colisões e a zona segura e emite dano.
- `resource.tscn`: `Area2D`, `Sprite2D`, `CollisionShape2D` e propriedades exportadas `resource_id` e `kind`. A cena detecta proximidade, mas não bloqueia movimento.
- `lighthouse.tscn`: `StaticBody2D` com colisão, sprites para os estágios de reparo, lanterna e área de interação.
- `campfire.tscn`: `Area2D`, `AnimatedSprite2D`, `PointLight2D` e indicador visual da zona segura; a fogueira não cria uma parede física adicional.
- `storage.tscn`: `StaticBody2D`, sprite, colisão e área de interação.
- `ruin.tscn`: construção reutilizável com sprite e colisão física.
- `game_ui.tscn`: árvore real de `Control`, `CanvasLayer`, painéis, rótulos, barras e botões; `game_ui.gd` apenas atualiza e alterna esses nós.

## TileMap e mundo

O mapa conserva a silhueta e a distribuição atual da ilha. Um atlas PNG conterá tiles de mar, espuma, areia, grama e caminho, com variações suficientes para evitar repetição visual evidente. O `TileSet` será um recurso editável da Godot.

A costa usará colisão nativa alinhada ao contorno jogável. O interior da ilha será a região navegável; o mar ficará fora dela. As construções usarão formas de colisão simples e estáveis, menores que o volume visual quando isso melhorar a navegação. Decorações não terão colisão.

As posições e identidades atuais dos recursos serão mantidas para preservar custos, testes e compatibilidade do save. Os recursos comuns reaparecem ao amanhecer; as três peças continuam únicas.

## Pixel art

Os recursos visuais serão PNGs com transparência e paleta derivada da direção atual: mar e floresta frios, areia dessaturada e âmbar para jogador, fogo e objetivo. O conjunto incluirá:

- atlas de terreno 32×32;
- jogador em quatro direções, com animações parado, andando e ataque;
- animal em quatro direções, com animações parado, andando e ataque;
- madeira, pedra, comida, sucata e peça;
- farol em quatro estágios, depósito, fogueira acesa/apagada e ruínas;
- árvores, rochas e detalhes de solo atravessáveis.

Todos os imports desativarão filtragem. O enquadramento, pivô e escala ficarão consistentes para impedir tremor entre quadros.

## Fluxo e responsabilidades

`game.gd` continuará sendo o coordenador de alto nível: cria nova partida, carrega estado, avança o ciclo, gera inimigos, conecta sinais, salva checkpoints e decide vitória. Ele não criará nós visuais nem desenhará formas.

`survival_state.gd` permanece como fonte das regras persistentes. A posição do jogador continuará serializada como `Vector2`, mantendo o esquema existente. Ao carregar, a posição será validada contra a região navegável; uma posição inválida retorna ao ponto de surgimento.

Interações serão baseadas em `Area2D`: o jogador mantém a lista de alvos próximos e escolhe o de maior prioridade e menor distância. Abrigo/construção tem prioridade sobre recurso quando ambos estiverem ao alcance. Ataques usam a área orientada do jogador; dano inimigo usa a área do animal com intervalo de ataque.

O `CanvasModulate` mantém a transição dia/noite. A fogueira usa `PointLight2D` e um indicador visual, mas `SurvivalState.fuel` continua decidindo se o jogador está protegido.

## Compatibilidade e falhas

- Saves válidos existentes continuarão carregando sem migração de esquema.
- Ausência de um sprite ou cena obrigatória deve aparecer como erro de carregamento durante os testes, não como substituição procedural silenciosa.
- IDs duplicados de recursos serão detectados na inicialização do mapa.
- Nenhuma colisão pode prender o jogador no ponto de surgimento ou impedir acesso ao farol, depósito e recursos.
- O comportamento de erro de salvamento e suas mensagens atuais serão preservados.

## Verificação

Os testes de regras de `SurvivalState` continuarão inalterados sempre que possível. Os testes de integração serão atualizados para operar sobre `CharacterBody2D`, cenas instanciadas e sinais, sem escrever diretamente em estruturas internas de desenho.

Novas verificações confirmarão:

- existência e tipo das cenas independentes;
- uso de `TileMapLayer`, `CharacterBody2D`, `Area2D`, `StaticBody2D` e formas de colisão;
- inexistência de desenho procedural de mapa, atores e objetos;
- bloqueio na costa e nas construções;
- passagem através de decorações;
- coleta, combate, proteção, morte, renovação de recursos e salvamento;
- expedição completa até os três reparos e o resgate;
- importação dos PNGs sem filtro e renderização nítida a 1280×720;
- inspeção visual de menu, dia, noite, abrigo, combate e vitória.

## Fora de escopo

- Alterar balanceamento, custos, duração do ciclo ou quantidade de recursos.
- Adicionar construção livre, inventário novo, novos inimigos ou conteúdo narrativo.
- Tornar árvores e pedras obstáculos.
- Migrar para 3D, vetores ou assets externos pagos.
