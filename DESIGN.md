---
name: O Farol — HUD Faroleiro
description: Sobrevivência pixel art com luz âmbar e instrumentos náuticos compactos.
colors:
  hud-sea: "#142c32"
  hud-edge: "#738477"
  paper: "#edf0dc"
  secondary: "#b3c7c3"
  amber: "#efbd70"
  life: "#db8c78"
  energy: "#88c4b0"
typography:
  hud:
    fontFamily: Faroleiro
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.5
rounded:
  hud: 0px
  menu: 4px
spacing:
  pixel: 2px
  edge: 16px
components:
  hud-panel:
    backgroundColor: "{colors.hud-sea}"
    textColor: "{colors.paper}"
    typography: "{typography.hud}"
  repair-marker:
    backgroundColor: "{colors.amber}"
---

## Overview

**Creative North Star: "Faroleiro"**

A ilha e as decisões de sobrevivência vêm primeiro. O HUD usa a linguagem do
farol: pedra clara, mar escuro, luz âmbar e instrumentos discretos. Esta direção
foi aprovada para o HUD; os menus e o painel do abrigo preservam seus controles e
sua tipografia estabelecida.

**Key Characteristics:**
- Fonte bitmap original com acentos em português.
- Molduras em degraus e desenho em grade de dois pixels.
- Silhueta do farol e três marcos ligados aos reparos reais.
- Centro livre para a ilha e mochila compacta.

## Colors

Mar do HUD e bordas dessaturadas separam os indicadores do cenário. Texto claro
mantém a leitura. Âmbar identifica objetivo, reparos concluídos e mochila cheia;
vida usa coral e energia usa verde-mar.

O mundo mantém mar `#0a242b`, floresta `#173a35`, terreno `#324f42` e areia
`#9a9470`. A noite usa tons frios sem esconder recursos; abrigo e jogador têm
acentos quentes.

## Typography

HUD: fonte **Faroleiro**, bitmap de base 8 exibido em 16, sem suavização e com
letras maiúsculas, minúsculas e acentos próprios. Fonte e atlas são regeneráveis
por `tools/generate_hud_font.py`.

Menus e abrigo: fonte padrão da Godot, tamanhos e hierarquia definidos na cena.
Foco de teclado visível, texto português e ações nomeadas explicitamente.

## Layout

Referência 1280×720; janela mínima 960×540, com escala proporcional do canvas.
Vida e energia ficam no topo esquerdo. Dia/noite, contagem regressiva e direção
ficam no topo direito. O objetivo e a marca do farol ficam no topo central.

A mochila ocupa uma faixa de 404×84 no centro inferior, com cinco ícones e suas
quantidades. O comando contextual aparece acima dela somente quando há ação.
Sua largura acompanha o texto; a coleta usa um aviso de 84×40 ao lado da mochila,
com ícone e +1, duração de 1,2 segundo e desaparecimento suave nos últimos 0,25.
Atalhos completos estão na pausa. Avisos são temporários, abaixo dos indicadores.
Com o abrigo aberto à direita, avisos e mochila se alinham ao espaço livre à
esquerda para continuar visíveis.

O abrigo permite rolagem e não pausa o mundo; pausa e introdução suspendem a
simulação. A ilha continua usando TileMapLayer, sprites PNG e cenas próprias.

## Elevation & Depth

O HUD usa superfícies opacas e molduras de alto contraste, sem sombras difusas
ou desfoque. A ilha continua responsável pela profundidade visual e pela luz.

## Shapes

Moldura `assets/ui/frame.svg`: 24×24, cantos em degraus, margens de nove regiões
com seis pixels. Barras segmentadas em dez divisões; os valores reais continuam
contínuos. Slots da mochila e barras têm cantos retos.

Bússola e símbolo do farol são desenhos próprios de CanvasItem, sem glifos de
emoji. A agulha acompanha o vetor real de retorno ao farol.

## Components

- Retrato e recursos reutilizam os atlas originais, com filtro nearest.
- Símbolo do farol: três marcadores; cada reparo concluído acende um marcador.
- Objetivo: nome do próximo reparo, ação de acender ou estado de resgate.
- Mochila: ícones com quantidades, capacidade total e destaque quando cheia.
- Avisos: largura e altura conforme o texto, com quebra de linha e área que evita o painel do abrigo. A coleta tem aviso próprio e não substitui alertas importantes.
- Menus: botões existentes com borda, foco, hover e estados desativados.

## Do's and Don'ts

- Do manter português e acentos legíveis.
- Do usar nearest, sem mipmaps, nos elementos bitmap.
- Do manter os ícones e as contagens dos recursos juntos.
- Don't substituir os desenhos náuticos por emoji ou ícones de fonte.
- Don't colocar avisos ou materiais atrás do painel do abrigo.
- Don't alterar economia, combate ou salvamento ao modificar a apresentação.

Validação do HUD em 02/10/2026: capturas reais de dia, noite, mochila cheia e
abrigo aberto nas duas dimensões suportadas. O cenário mantém costa física,
ordem Y, objetos atravessáveis e luz da fogueira. Sprites, áudio e elementos do
HUD são originais e não exigem bibliotecas externas. Ritmo e dificuldade
continuam dependendo de playtest humano.
