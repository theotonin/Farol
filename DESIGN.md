# Direção visual do protótipo

Interface de experiência: a ilha e as decisões de sobrevivência vêm primeiro. O usuário aprovou 2D visto de cima, atmosfera sombria, recursos e caminhos legíveis e formas simples na primeira versão.

- Mar `#0a242b`, floresta `#173a35`, terreno `#324f42`, areia `#9a9470`.
- Interface `#172c34`, texto `#edf0dc`, texto secundário `#b3c7c3`, destaque âmbar `#efbd70`.
- Cor quente identifica jogador, abrigo e objetivo; noite usa tons frios sem esconder por completo os recursos.
- HUD: vida/energia no topo esquerdo, objetivo no centro, relógio e distância no topo direito, mochila embaixo à esquerda e ação contextual no centro inferior.
- Menus e botões usam a fonte padrão da Godot; foco de teclado visível, contraste claro, texto português e ações nomeadas explicitamente.
- Painel do abrigo à direita, com rolagem se necessário. Ele não pausa o mundo; menus de pausa e introdução suspendem a simulação.
- Terreno em `TileMapLayer` com atlas de 32×32; personagens, recursos e construções usam sprites PNG pixel art e cenas próprias. Filtro `nearest`, sem mipmaps e com escala inteira na referência 1280×720.
- Costa e construções têm colisões nativas; recursos e decorações continuam atravessáveis. A fogueira é uma área de interação com `PointLight2D`, não uma parede.
- Sprites, atlas e sons sintetizados são originais. Sem assets externos.

Validação em 21/09/2026: capturas reais na Godot 4.7.1 a 1280×720 para menu, introdução, dia, abrigo, noite, combate, resgate e vitória. A inspeção confirmou pixels nítidos, atlas sem bleeding aparente, sprites alinhados, ordem Y coerente, UI sem overflow e noite legível. Janela escala com proporção preservada, mínimo 960×540. Dificuldade, ritmo e leitura durante movimento ainda precisam de playtest humano.
