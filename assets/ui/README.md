# HUD Faroleiro

Fonte bitmap original de 5×7 pixels, com letras maiúsculas, minúsculas e acentos
em português. `faroleiro.fnt` usa `faroleiro-font.png`; regenere ambos com
`python3 tools/generate_hud_font.py`. A descrição de origem está embutida no PNG.

`frame.svg` é uma moldura original de 24×24 pixels, com cantos em degraus e
divisão em nove regiões (`StyleBoxTexture`). O HUD usa filtro `nearest`, fonte
de tamanho 16 (2× o tamanho-base 8) e os ícones do atlas já existente.

O símbolo do farol e as três etapas de reparo são desenhados em
`scripts/hud_identity.gd`; a bússola usa `scripts/hud_compass.gd`.
As divisões das barras vêm de `scripts/hud_bar_segments.gd`, sem alterar os
valores reais de vida e energia.

Todos estes desenhos e glifos foram criados para O Farol, sem fontes ou
ilustrações de terceiros.
