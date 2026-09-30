### Task 2: Assets de pixel art e TileSet

**Files:**
- Create: `assets/pixel/terrain_atlas.png`
- Create: `assets/pixel/characters.png`
- Create: `assets/pixel/objects.png`
- Create: `resources/island_tileset.tres`

**Interfaces:**
- Produces: tiles 32×32 com IDs documentados no TileSet; regiões de sprites consistentes para cenas.
- Consumes: paleta de `DESIGN.md` e restrições globais.

- [ ] **Step 1: Gerar três folhas raster em pixel art**

Usar a skill `imagegen` três vezes, salvando os resultados nos caminhos declarados. Prompts:

```text
terrain_atlas.png — Sprite sheet raster em pixel art 2D top-down para jogo de sobrevivência numa ilha sombria. Grade rígida de tiles 32x32, vista totalmente ortográfica, sem perspectiva. Incluir tiles perfeitamente repetíveis de mar azul-petróleo escuro #0a242b, grama #324f42, areia #9a9470, espuma costeira clara #9ab5ab e caminho terroso #716d51, mais transições de costa retas, cantos internos/externos e variações sutis. Arestas pixel-perfect, paleta limitada, sem blur, sem antialiasing, sem texto, sem símbolos, iluminação neutra e consistente.

characters.png — Sprite sheet raster em pixel art 2D top-down, fundo transparente, grade rígida de células 32x32. Um sobrevivente de casaco âmbar e um animal selvagem cinza-azulado. Para cada personagem: quatro direções, dois quadros de caminhada, um quadro parado e um quadro de ataque; pés e pivôs sempre na mesma coordenada de cada célula. Silhuetas legíveis, paleta limitada, pixels duros, sem blur, sem antialiasing, sem texto, sem perspectiva inclinada.

objects.png — Sprite sheet raster em pixel art 2D top-down, fundo transparente e grade rígida de células 32x32 ou múltiplos inteiros. Incluir madeira, pedra, frutas/comida, sucata, peça rara âmbar, árvores, pedras pequenas, marca de solo, ruína, baú-depósito, fogueira apagada e dois quadros acesa, além de farol em quatro estágios de reparo. Paleta sombria coerente com mar #0a242b, floresta #173a35 e destaque #efbd70. Objetos isolados com margem transparente, pixels duros, sem blur, sem antialiasing, sem texto.
```

- [ ] **Step 2: Normalizar dimensões sem redesenhar conteúdo**

Inspecionar os arquivos com `file assets/pixel/*.png` e `identify assets/pixel/*.png` quando ImageMagick estiver disponível. Recortar apenas margens externas e redimensionar exclusivamente por vizinho mais próximo para dimensões múltiplas de 32; nunca interpolar, vetorizar ou criar SVG intermediário. Validar `width % 32 == 0`, `height % 32 == 0` e canal alpha nas folhas de personagens/objetos.

- [ ] **Step 3: Criar `island_tileset.tres`**

Configurar `tile_size = Vector2i(32, 32)`, `Texture2DArray`/`TileSetAtlasSource` sobre `terrain_atlas.png`, terrains para mar, areia, grama, espuma e caminho, e alternativas visuais sem colisão embutida. A colisão da costa será responsabilidade de `island.tscn`.

- [ ] **Step 4: Importar na Godot e verificar nitidez**

Run: `godot --headless --editor --path . --quit-after 3`

Expected: exit 0, `.import` gerados e nenhum erro de atlas/região.

- [ ] **Step 5: Registrar o checkpoint**

Inspecionar visualmente os três PNGs em zoom inteiro; commit `art: add pixel art world and actor sheets` apenas se Git estiver disponível.

---

