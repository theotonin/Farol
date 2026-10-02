# Audio original — O Farol

Três temas instrumentais em estéreo, com 32 segundos e caudas de notas que
atravessam o ponto de repetição:

- `day.wav`: exploração e menu; acordes suaves e melodia de sinos em ré menor.
- `night.wav`: noite e introdução; registro grave, dissonância e pulsação discreta.
- `rescue.wav`: resgate e vitória; melodia ascendente em fá maior.
- `ocean.wav`: ondas e vento sintetizados, repetição de 11,5 segundos.
- `campfire.wav`: brasa e estalos sintetizados, repetição de 11,5 segundos.

Todos os arquivos foram compostos e sintetizados para este projeto, sem amostras,
gravações ou músicas de terceiros. Regenere com `python3 tools/generate_audio.py`;
o gerador usa apenas a biblioteca padrão do Python.

O jogo repete os arquivos automaticamente e troca os temas com transição de 2,5
segundos. A fogueira fica mais audível ao se aproximar. O botão **Som** pausa a
trilha e a ambientação e silencia os efeitos; ao religar, os loops continuam.
Passos, golpes, coleta, reparos e demais efeitos são sintetizados em
`scripts/soundscape.gd`.
