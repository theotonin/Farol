# O Farol

Documentação do estado atual do protótipo em **02/10/2026**.

- **GDD.pdf** — documento de design completo, com 12 páginas e navegação por seções no leitor de PDF.
- **GDD.md** — versão editável do conteúdo, com imagens relativas à subpasta Moodboard.
- **Moodboard.pdf** — duas pranchas A3 horizontais: atmosfera da ilha e identidade Faroleiro.
- **Moodboard.png** — prancha da atmosfera, pronta para visualizar ou inserir em uma apresentação.
- **Moodboard-HUD.png** — prancha da identidade visual e sonora.
- **Moodboard/** — nove capturas usadas como referências, incluindo o HUD atual.
- **Audio/** — três trilhas, dois ambientes e doze efeitos em WAV; inclui catálogo e players em `Ouvir.html`.
- **Prototipos/** — imagens do HUD e menu inicial, com navegação demonstrativa em `Prototipo.html`.

As pranchas usam capturas do próprio jogo, com paletas, legendas e relações de
atmosfera. O GDD diferencia comportamento implementado, intenção histórica e
narrativa provisória. A duração e a dificuldade da partida ainda dependem de
playtest humano.

Para regenerar os PDFs e a versão Markdown, execute
`python3 tools/build_game_docs.py` na raiz do projeto; o gerador usa ReportLab.
As versões PNG foram exportadas do PDF com Poppler.

Para explorar a interface, abra `Prototipos/Prototipo.html` no navegador.
Para ouvir os sons separadamente, abra `Audio/Ouvir.html`.
As duas páginas funcionam localmente e não dependem de internet.

Para atualizar o pacote de áudio e as imagens, exporte os efeitos usando
Godot com `--headless --path . --script tools/export_game_audio.gd`,
gere as capturas com `tests/capture_game.gd` e `tests/capture_hud.gd`
(com display gráfico) e execute `python3 tools/package_game_assets.py`.

O arquivo `.gdignore` mantém esta documentação fora da importação de assets do jogo.
