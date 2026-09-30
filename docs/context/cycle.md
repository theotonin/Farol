# Ciclo atual

- **Ciclo:** C1 — Núcleo Jogável
- **Pergunta orientadora:** O jogador consegue realizar a ação principal?
- **Status:** IMPLEMENTADO — AGUARDANDO PLAYTEST HUMANO
- **Specs selecionadas:** [Protótipo escolar](../specs/prototipo.md).

## Evidências de playtest

- Incremento jogável inclui coleta, abrigo, noite, combate, morte, reparos, save/load e resgate.
- Em 21/09/2026, as seis suítes passaram na Godot 4.7.1: 128 checks de regras; arquitetura, física e integração sem falhas; expedição completa e feedback de salvamento com 0 falhas.
- O playtest físico automatizado moveu jogador e inimigo contra os quatro lados da costa e seis construções; confirmou fogueira e decoração atravessáveis, ponto de interação livre para os 69 recursos e ataque/dano nos quatro sentidos.
- A cena principal executou 120 iterações headless sem erro de cena, script ou runtime. A importação terminou com `exit 0`; o sandbox impediu apenas os sockets internos do editor (`ERR_CANT_CREATE`).
- Capturas reais em 1280×720: menu, introdução, dia, abrigo, noite, combate, resgate e vitória. Pixels, atlas, alinhamento, ordem Y, UI e iluminação foram inspecionados; nenhum defeito material foi observado.
- As capturas são estados preparados por script e o teste de expedição transporta o jogador entre recursos: essas evidências não substituem uma partida humana do início ao resgate.
- Ainda não houve playtest humano de ritmo, dificuldade e legibilidade em movimento.

## Motivo do avanço para o próximo ciclo

- Próximo passo: jogar do início ao resgate e avaliar se afastar-se da base provoca decisões interessantes. Só avançar depois dessa evidência humana.
