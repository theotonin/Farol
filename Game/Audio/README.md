# Áudio de O Farol

- `Trilha/`: exploração/menu, noite e resgate; três loops de 32 segundos.
- `Ambiente/`: oceano e fogueira; dois loops de 11,5 segundos.
- `Efeitos/`: doze efeitos do jogo exportados em WAV mono.
- `catalogo.csv`: uso, duração, canais, taxa e volume aplicado pelo jogo.
- `Ouvir.html`: catálogo com players; abra no navegador.

Todos os arquivos são WAV PCM de 16 bits a 22.050 Hz. Música e ambiente são
estéreo. São sons originais sintetizados para este projeto, sem samples externos.
Os WAVs mantêm as amostras originais. O jogo aplica -21 dB aos passos, -12 dB
à trilha, -10 dB ao golpe no ar e -6 dB aos demais efeitos. A fogueira varia
de -18 dB até silêncio conforme a distância; o oceano usa -24 dB.
Os passos também recebem variação de tom em tempo de execução.

Para atualizar os efeitos após mudar `scripts/soundscape.gd`, execute Godot com
`--headless --path . --script tools/export_game_audio.gd` e depois
`python3 tools/package_game_assets.py` na raiz do projeto.
