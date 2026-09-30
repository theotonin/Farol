# Task 2 — Assets de pixel art e TileSet

Status: implementado e importável, com ressalvas visuais explicitadas abaixo. Não declarar conformidade perfeita com a grade global dos objetos, pivôs ou seamlessness.

## Escopo entregue

- `assets/pixel/terrain_atlas.png`: PNG raster RGBA8, 256×256, atlas 8×8 de tiles32×32.
- `assets/pixel/characters.png`: PNG raster RGBA8,128×256;4×8 células32×32;32poses.
- `assets/pixel/objects.png`: PNG raster RGBA8,256×256;recursos,árvores,ruína,baú,fogueiras e4estágios do farol.
- `resources/island_tileset.tres`: source0;64células válidas;28alternativas flip_h em tiles de preenchimento;5terrains;zero camadas de colisão.
- Os três `.png.import` foram produzidos pela Godot. Todas as referências de produção usam `res://assets/pixel/`. Nenhuma referência do recurso aponta para CODEX_HOME.

## Método e instruções

Lidos integralmente o brief, `/home/theotonin/.codex/skills/.system/imagegen/SKILL.md`, `references/prompting.md` e `references/sample-prompts.md`; direção visual conferida em DESIGN.md.

Modo **built-in image_gen**; nenhuma chave/API/CLI fallback. Três chamadas generate distintas e uma edição dirigida de objects, motivada por inspeção de alinhamento. Não foram usados SVG, vetorização ou desenho procedural. Os PNGs finais foram normalizados diretamente das saídas raster com `Image.resize(..., Image.INTERPOLATE_NEAREST)` da Godot. Nenhum recorte interno, repacking, alteração de cores ou substituição de alfa. Originais mantidos intactos. Inspeção visual dos três finais em zoom inteiro4× por nearest.

Arquivos originais do modo integrado, em `/home/theotonin/.codex/generated_images/01a0b43f-dd29-7cd0-8e26-6ac0925f4177/`:

- terrain: `exec-335776df-2f11-4b80-82f5-5f2289f70a20.png`,1254×1254.
- characters: `exec-98167e88-f26e-4b7e-999b-bfa151143f76.png`,887×1774.
- objects primeira versão descartada: `exec-7d5f4a5c-1a7f-4aa1-a339-bb90bf03ee4c.png`.
- objects final: `exec-6e2ace56-4c6d-433e-97bb-94ecde6ee294.png`,1254×1254.

## Contrato de integração

TileSet source0, tile_size32×32; terrain IDs mar0,areia1,grama2,espuma3,caminho4. TileSet contém metadata/atlas_rows com o mapa completo. Linhas0..2 e últimos4tiles da linha7 são preenchimentos; transições nas demais posições estão disponíveis para seleção manual por atlas, sem peering automático atribuído. IDs alternativos0=original;1=flip_h somente nos28preenchimentos. Nenhuma colisão é embutida.

Characters: colunas idle,walkA,walkB,attack; linhas sobrevivente down,left,right,up,animal down,left,right,up. Usar regiões32×32. O pivô lógico é o centro da célula, com baseline visual aproximada; há pequenas diferenças de posição dos pés, portanto não prometer alinhamento exato.

Objects: **usar regiões explícitas**, pois as origens dos sprites pequenos ficaram deslocadas da grade global solicitada. Todas estas regiões foram documentadas também em metadata do TileSet:

| Conteúdo | Rect2(x,y,w,h) |
|---|---|
| madeira,pedra,comida,sucata,peça rara | (0/32/64/96/128,8,32,32) |
| pedra pequena | (160,8,32,32) |
| marca de solo | (192,8,32,32) |
| baú | (224,8,32,32) |
| fogueira apagada | (4,48,32,32) |
| fogueira acesaA | (40,48,32,32) |
| fogueira acesaB | (72,48,32,32) |
| árvoreA | (0,64,64,96) |
| árvoreB | (64,64,64,96) |
| ruína | (132,64,64,96) |
| faróis0..3 | (0/64/128/192,160,64,96) |

O grande pedregulho à direita é extra: região visível aproximada(209,127,38,33); não foi incluído no contrato de células, pois a pedra pequena já atende ao brief.

## Verificação executada

ImageMagick/identify não disponível. `file assets/pixel/*.png` confirmou os três PNGs RGBA8 não entrelaçados nas dimensões acima.

Scripts auxiliares criados via apply_patch somente em /tmp:
- `/tmp/o_farol_normalize.gd`: normalização nearest e previews4×.
- `/tmp/o_farol_tileset.gd`: criação de TileSet com ResourceSaver; metadados de regiões refinados posteriormente via apply_patch.
- `/tmp/o_farol_verify.gd`: dimensões,múltiplos32,formatoRGBA8,estatísticas alfa,atlas carregado,64regiões internas,alternativas,terrains,ausência de física e limites visíveis dos objetos.

Comandos relevantes (cwd=/home/theotonin/Documentos/godot/o-farol):

```bash
XDG_DATA_HOME=/tmp/o-farol-task2 /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script /tmp/o_farol_normalize.gd
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --editor --path . --import
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script /tmp/o_farol_tileset.gd
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --editor --path . --quit-after 3
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script /tmp/o_farol_verify.gd
file assets/pixel/*.png
sha256sum assets/pixel/*.png
```

Todos retornaram exit0. `--import` concluiu importação de characters,objects,terrain_atlas; .import presentes. `--quit-after3` isolado encerra scan cedo e emite Scan thread aborted; por isso houve também o comando --import completo. Editor em sandbox emitiu erros de socket/listen ERR_CANT_CREATE, sem erro de atlas/região ou script. A primeira execução sem XDG_CONFIG_HOME tentou salvar editor_settings fora do workspace e falhou; execuções seguintes usaram diretório /tmp. O verificador em /tmp usa Image.load_from_file e emite aviso sobre esse método não funcionar em export; esse método **não foi introduzido no código do jogo**. O recurso do jogo carrega Texture2D importada normalmente.

Resultado final de verificação:
```text
terrain_atlas (256,256) RGBA8; alpha [zero,opaque,partial]=[0,0,65536]; range .870588.. .972549
characters (128,256) RGBA8; alpha [zero,opaque,partial]=[21392,11,11365]; range0..1
objects (256,256) RGBA8; alpha [zero,opaque,partial]=[46214,17,19305]; range0..1
PASS TileSet 64 valid atlas regions;28 alternatives;5 terrains;no collisions
```

SHA256:
```text
ef766e900ca102208faa34d512694ce42f1a4afba30652aa0ee7623772d3f2cb characters.png
579edb28ec2debd61216c23c29e0e5bf9e24139d29dec82a75d08a9dbf63c875 objects.png
5ec66199263c86c6720a4a6c304975883d0494c02a06c2e556db93ffdd9dea0a terrain_atlas.png
```

## Auto-revisão e preocupações

- Raster e alfa foram preservados; a geração trouxe muitos pixels parcialmente transparentes e pequenos artefatos coloridos nas bordas. O terreno também veio levemente translúcido, apesar de o prompt pedir opaque. Não alterei o alfa por processamento, respeitando o brief. Isso pode reduzir contraste no jogo.
- O downsample nearest mantém pixels duros, mas não garante a paleta exata hexadecimal nem elimina o sombreamento interno original.
- A grade8×8 do terreno é utilizável, mas a imagem original inclui linhas finas entre tiles e diferenças de tonalidade; há risco de costuras repetitivas. A inspeção do atlas não prova seamlessness no mapa final.
- Objects melhorou após a edição, porém não atende a uma grade única de origens múltiplas de32. As regiões explícitas evitam cortar itens; dimensões regionais são32 ou múltiplos.
- Characters tem todas as poses e direções, mas os quadros de caminhada do animal diferem pouco e os pés não estão numericamente travados ao mesmo pivô.
- Transições estão disponíveis manualmente; não foi construído um autotile completo para todas as combinações, nem colisões.
- Não houve alteração em scenes/scripts/project.godot nem tentativa de commit. Nenhum subagente foi despachado.
- Recomendo revisão visual em cena pelo agente de integração; esta tarefa entrega arte utilizável com limitações visíveis, não aprovação estética irrestrita.

## Prompts finais exatos

### Terrain — generate
```text
Use case: stylized-concept
Asset type: terrain_atlas.png, raster tile atlas for Godot, production sprite sheet.
Primary request: Sprite sheet raster em pixel art 2D top-down para jogo de sobrevivência numa ilha sombria. Grade rígida de tiles 32x32, vista totalmente ortográfica, sem perspectiva. Incluir tiles perfeitamente repetíveis de mar azul-petróleo escuro #0a242b, grama #324f42, areia #9a9470, espuma costeira clara #9ab5ab e caminho terroso #716d51, mais transições de costa retas, cantos internos/externos e variações sutis. Arestas pixel-perfect, paleta limitada, sem blur, sem antialiasing, sem texto, sem símbolos, iluminação neutra e consistente.
Composition/framing: EXACT 8 columns x 8 rows equal square tile cells, edge-to-edge no gutters, no border, no grid lines. Logical image 256x256 pixels, each logical tile32x32; if rendering larger, enlarge each logical pixel as a solid nearest-neighbor square. Fully opaque texture atlas. All tiles fill their own cell, never cross cell boundaries.
Row0 from left: 4 dark sea seamless variants then 4 grass seamless variants.
Row1 from left: 4 sand seamless variants then 4 dirt path seamless variants.
Row2: 4 pale foam seamless water variants then 4 forest grass variants.
Row3: 4 sand/water straight shoreline transitions facing north east south west, then 4 sand/water outer corners NW NE SE SW.
Row4: 4 sand/water inner corners NW NE SE SW, then 4 grass/sand straight transitions facing north east south west.
Row5: 4 grass/sand outer corners NW NE SE SW, then 4 grass/sand inner corners NW NE SE SW.
Row6: 4 grass/dirt straight transitions north east south west, then 4 grass/dirt outer corners NW NE SE SW.
Row7: 4 grass/dirt inner corners NW NE SE SW, then 4 subtle grass variants.
Constraints: usable game raster, no typography or letters, no props or actors, no display frame, no blur or gradient lighting; hard pixel edges.
```

### Characters — generate
```text
Use case: stylized-concept
Asset type: characters.png, production raster sprite sheet for Godot.
Primary request: Sprite sheet raster em pixel art 2D top-down, fundo transparente, grade rígida de células 32x32. Um sobrevivente de casaco âmbar e um animal selvagem cinza-azulado. Para cada personagem: quatro direções, dois quadros de caminhada, um quadro parado e um quadro de ataque; pés e pivôs sempre na mesma coordenada de cada célula. Silhuetas legíveis, paleta limitada, pixels duros, sem blur, sem antialiasing, sem texto, sem perspectiva inclinada.
Composition/framing: EXACT 4 columns x 8 rows, image aspect ratio 1:2. Logical canvas 128x256. Every cell exactly 32x32 logical pixels. If rendering larger, enlarge logical pixels as solid square blocks. NO drawn grid lines and NO background color, genuinely transparent PNG alpha around every isolated sprite. Four columns ordered: idle, walking A, walking B, attack.
Rows0-3: same amber-coated survivor facing down, left, right, up respectively. Rows4-7: same blue-gray wild wolf facing down, left, right, up respectively. 32 sprites total, no missing poses.
Same grounded pivot at logical local coordinate (16,28) in every cell. Keep each actor inside its own cell with 3 pixels clear margin; all poses stay centered. Survivor coat amber #efbd70 with dark forest shadows #173a35. Wolf gray-blue. Very simple readable actual 32-pixel game sprites, no tiny painted detail.
Constraints: no text, no labels, no logos, no visible checkerboard, no floor, no props outside sprite cell, no blur, no antialiasing.
```

### Objects — generate
```text
Use case: stylized-concept
Asset type: objects.png, production raster object atlas for Godot.
Primary request: Sprite sheet raster em pixel art 2D top-down, fundo transparente e grade rígida de células 32x32 ou múltiplos inteiros. Incluir madeira, pedra, frutas/comida, sucata, peça rara âmbar, árvores, pedras pequenas, marca de solo, ruína, baú-depósito, fogueira apagada e dois quadros acesa, além de farol em quatro estágios de reparo. Paleta sombria coerente com mar #0a242b, floresta #173a35 e destaque #efbd70. Objetos isolados com margem transparente, pixels duros, sem blur, sem antialiasing, sem texto.
Composition/framing: square image, logical 256x256 canvas and rigid 8x8 grid of 32px cells; if larger, render logical pixels as hard square blocks for nearest-neighbor downsampling. Genuinely transparent alpha background, no visible checkerboard, no grid lines, no labels.
Exact atlas layout (coordinates in logical pixels):
Top row y0..31: wood at x0..31; stone resource x32..63; fruit/food x64..95; scrap x96..127; rare amber part x128..159; small rock x160..191; soil mark x192..223; storage chest x224..255.
Second row y32..63: unlit campfire x0..31; same campfire flame A x32..63; flame B x64..95. Leave other cells transparent.
Middle zone y64..159: tree A in x0..63,y64..159; tree B x64..127,y64..159; stone ruin x128..191,y64..127; small boulder x192..223,y64..95. Leave other cells transparent.
Bottom zone y160..255: FOUR lighthouse stages, each inside its own 64x96 region: x0 ruined foundation, x64 partly rebuilt masonry tower, x128 complete dark tower with unlit lantern, x192 completed working lighthouse with amber lantern. Same footprint center and baseline y250 for every stage. Keep each whole silhouette inside the specified region with transparent margin, no overlap between regions.
Style: simple crisp low-resolution game pixel art with strong silhouettes and limited dark maritime palette. No ground scene behind sprites, no text, no logos, no blur, no painted background.
```

### Objects — edição dirigida final
```text
Use case: precise-object-edit
Input image: existing objects sprite sheet, edit target.
Change ONLY object placement and scale to fit a strict usable game atlas, preserve every object's design, colors, hard pixel-art style and transparent alpha background. No new objects, no text.
The current objects touch their cell edges and lighthouse tops begin too high. Fix by SHRINKING all objects inside their allotted cells, leaving substantial clear transparent margins. Treat canvas as 8 columns x8 rows of square32px logical cells, 256x256 logical canvas. Keep entire canvas and alpha.
Top row y0..32 contains exactly eight small icons centered at x16,48,80,112,144,176,208,240: wood,stone,fruit,scrap,amber,small rock,soil,chest. Each icon fits an INNER 22x22 box, never larger, with at least5px margin all around.
Second row y32..64: unlit fire,fireA,fireB centered x16,48,80, each inside22x22 with5px margin. The remainder is transparent.
Trees occupy x0..64 and64..128, y64..160; shrink each to inner48x72 with margins. Ruin occupies x128..192,y64..160, same48x72 inner box. Boulder occupies x192..256,y96..160, inner48x48.
BOTTOM y160..256 contains four lighthouse stages each inside a64x96 cell at x0,64,128,192. Each lighthouse must have at least8 transparent pixels left,right,top,bottom of its region. Thus NO lighthouse pixel above logical y168. All four baselines y248. Lighthouse art must be max48x80 within each region. Keep first ruined foundation, second partly restored, third complete but unlit, fourth complete glowing amber.
Absolute priority: objects do not cross or touch cell boundaries. The result must remain genuine transparent PNG alpha, with NO grid lines, background or checkerboard.
```

## Fix round 1 — divisórias do terrain atlas

**Status:** finding de divisórias incorporadas corrigido. Somente `assets/pixel/terrain_atlas.png` foi substituído entre os assets; sua importação foi atualizada automaticamente. `resources/island_tileset.tres` não precisou mudar. A ordem de 64 tiles e a dimensão 256×256 permanecem.

### Verificação da revisão e ruling

A inspeção da versão anterior confirmou faixas escuras nas bordas de areia/caminho. Duas edições dirigidas pelo **built-in image_gen** removeram as divisórias verticais, porém mantiveram limites de linhas deslocados por poucos pixels no raster 1254×1254. Na normalização global, esses deslocamentos produziam uma linha da faixa vizinha no recorte.

Ruling recebido do agente de integração, nesta rodada:

> Faça normalização determinística por célula somente em terrain_atlas.png. O spec exige TileMap 32×32 sem costuras; esse requisito prevalece sobre a restrição operacional do brief a margens externas. Recorte cada célula da saída raster em seus limites lógicos, remova exclusivamente a faixa contaminada pela célula vizinha, redimensione cada tile por nearest para 32×32 e repacke na mesma ordem 8×8. Não pinte, suavize, vetorize nem invente pixels.

Foi selecionada a primeira edição desta rodada, `exec-98383b7b-e242-4bcb-bded-7649d63086c8.png`, por conter fundo opaco e melhor continuidade visual. A segunda edição, `exec-63f631c8-b1a5-4b1b-9a2b-ccf01e557130.png`, foi inspecionada e descartada; não entrou no projeto.

A normalização por célula usou estes limites observados no raster 1254×1254:

```text
x = [0,156,314,470,627,783,939,1095,1254]
y = [0,156,311,470,625,777,931,1086,1254]
```

Cada região foi recortada com margem interna de 3 pixels do raster original em cada lado (menos de um pixel lógico de 32×32), redimensionada por nearest e copiada para sua posição original no atlas. Esse procedimento remove pixels existentes de borda, não pinta nem interpola novas cores. Script reproduzível: `/tmp/o_farol_terrain_repack_fix1.gd`.

### Previews e inspeção de junções

- `/tmp/o-farol-terrain-before-repetition-4x.png`: antes; mar, areia, grama e caminho repetidos 3×3. As faixas horizontais são visíveis.
- `/tmp/o-farol-terrain-fix1-basic.png`: final; mar(0,0), areia(0,1), grama(4,0), caminho(4,1), cada tile repetido 3×3 e ampliado 4× nearest.
- `/tmp/o-farol-terrain-fix1-all-fills.png`: todos os 28 preenchimentos em ordem row-major do atlas, cada um repetido 3×3; 7 blocos por linha; zoom 2×.
- `/tmp/o-farol-terrain-fix1-transitions.png`: todas as 36 transições em ordem row-major, cada uma repetida 2×2; 6 blocos por linha; zoom 2×. Repetir transições iguais revela cortes, mas não substitui a montagem lógica de costas.
- `/tmp/o-farol-terrain-fix1-atlas4x.png`: atlas final completo em zoom 4×.

As três previews finais foram abertas e inspecionadas visualmente. As faixas artificiais retas de areia/caminho desapareceram; não há gutters nem linhas de grade desenhadas nos preenchimentos. Há repetição reconhecível de motivos, sobretudo ondas/espuma e tufos de grama. Isso é uma preocupação residual de variedade visual, não a divisória contínua do finding. Não se afirma igualdade numérica de todas as bordas de cores entre todas as variantes. Algumas transições têm desenhos de costa que precisam ser combinados segundo suas orientações.

### Comandos e resultados

```bash
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script /tmp/o_farol_terrain_repack_fix1.gd
cp /tmp/o-farol-terrain-fix1-repacked.png assets/pixel/terrain_atlas.png
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --editor --path . --import
XDG_DATA_HOME=/tmp/o-farol-task2 XDG_CONFIG_HOME=/tmp/o-farol-task2-config /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script /tmp/o_farol_verify.gd
file assets/pixel/*.png
sha256sum assets/pixel/*.png
```

Todos os comandos finais retornaram exit 0. Saída relevante:

```text
PASS repacked64cells, same8x8 order, 256x256; per-edge trim3 source pixels; nearest only
PREVIEW 4basic tiles x3x3 repeats; all28fill tiles x3x3; all36transition tiles x2x2
terrain_atlas.png: PNG image data, 256 x 256, 8-bit/color RGB, non-interlaced
terrain_atlas (256,256) format=4; alpha [zero,opaque,partial]=[0,65536,0]
alpha range=1.0..1.0
PASS TileSet 64 valid atlas regions; 28 alternatives; 5 terrains; no collisions
```

A nova geração é **RGB opaca**: isso também elimina a translucidez acidental do terreno anterior. Personagens/objetos continuam RGBA intactos. O editor continua emitindo ERR_CANT_CREATE para sockets bloqueados no sandbox, sem erros de atlas/região; o comando --import concluiu a reimportação do único PNG alterado. O aviso Image.load_from_file sobre export é restrito ao verificador temporário, como na validação anterior.

Houve uma falha inicial do script de preview por tentar blit RGB em RGBA; corrigida criando a preview com o mesmo formato da imagem-fonte. Todas as previews finais foram regeneradas após a correção, sem esse erro.

SHA256 final:

```text
19b7f613122730b8486ac34711816f040be1392e16de847e2ecca9247c4910e4 terrain_atlas.png
ef766e900ca102208faa34d512694ce42f1a4afba30652aa0ee7623772d3f2cb characters.png — inalterado
579edb28ec2debd61216c23c29e0e5bf9e24139d29dec82a75d08a9dbf63c875 objects.png — inalterado
```

### Prompt da edição selecionada

```text
Use case: precise-object-edit
Asset type: production terrain_atlas.png for Godot.
Edit ONLY the terrain atlas supplied. Preserve EXACTLY its 8 columns × 8 rows layout and ordering, the same subjects in every tile, dark maritime pixel-art palette and top-down orthographic view. Final logical canvas256×256, logical tile32×32; if output is larger render logical pixels as solid nearest-neighbor squares.
CRITICAL CORRECTION: Remove ALL drawn tile-divider lines, seams, gutters, outlines, shaded edge strips, frames and grid marks. Especially the entire second row (four sand, then four dirt path tiles) currently has thin dark vertical separators. These separators must disappear completely. A tile border must be indistinguishable from its interior; no darkened first/last column or row.
Make EVERY full-fill sea, sand, grass and dirt tile individually perfectly seamless in BOTH axes. Textural marks must wrap across opposite edges; use an identical flat base tone along a 2-logical-pixel perimeter for each fill tile, with sparse subtle texture inside. The4 sand variants share exactly the same sand base color #9a9470; dirt base #716d51; sea #0a242b; grass #324f42. Avoid broad lighting gradients or shadows within any tile. Fills should be quiet sparse game textures, never bounded squares.
Unchanged layout:
row0: sea x0..3, grass x4..7.
row1: sand x0..3, dirt path x4..7.
row2: foam water x0..3, forest grass x4..7.
row3:4 sand/water straight shoreline transitions, then4 outer corners.
row4:4 sand/water inner corners, then4 grass/sand straight transitions.
row5:4 grass/sand outer corners, then4 inner corners.
row6:4 grass/dirt straight transitions, then4 outer corners.
row7:4 grass/dirt inner corners, then4 grass full-fill variants.
Preserve all shore transition orientations from the reference. Do not replace transitions with a scene. Output fully opaque raster PNG; no text, no labels, no props, no antialiasing, no blur, NO VISIBLE GRID LINES. This will be sliced directly into32×32 tiles and repeated across a map, so opposite fill-tile edges must match.
```

### Prompt da segunda tentativa descartada

```text
Use case: precise-object-edit
Edit target:256x256 terrain atlas.
Keep the exact eight-by-eight tile ordering and designs. Fix ONLY the strict grid registration and seamless tile edges. Critical technical defect: sand/dirt row starts slightly above y32 and ends slightly above y64, causing foreign-color horizontal strips when sliced into32px cells. Every material row boundary MUST be exactly y32,64,96,128,160,192,224 on a256px canvas (or corresponding exact fractions if upscaled).
Absolute image geometry:8 equal rows,8 equal columns, no dividers. Row0 y0..31:sea first4,grass last4. Row1 y32..63:SAND first4,DIRT last4. Row2 y64..95:foam first4,forest last4. Other5rows retain reference transitions in their original cells.
Make the top TWO logical rows and bottom TWO logical rows of every FULL-FILL32x32 tile equal to that tile's interior base tone. Same for the left/right TWO logical columns. In sand cells every pixel on these perimeters is solid sand #9a9470; dirt #716d51; sea #0a242b; grass #324f42. This perimeter is NOT a border drawn in a different color: it is the same background base tone as the center. Subtle sparse texture ONLY in the interior28x28.
Especially NO sea/grass/foam-colored stray pixels in y32..63: the ENTIRE second row is solely sand left and dirt right. Fill tiles must tile in bothaxes without visible straight lines. No shading gradients. Strict simple32pixel pixel art, opaquePNG, no labels, no grid marks, no antialiasing.
```

