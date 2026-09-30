# O Farol — escopo aprovado em 16/09/2026

Protótipo escolar para entrega até 13/10/2026, executado no editor Godot no computador. Sem gastos, sem dependências externas obrigatórias. Implementação pelo assistente; valores de equilíbrio podem ser ajustados durante testes.

## Experiência

Sobrevivência 2D vista de cima em ilha pequena e fixa. O jogador explora e decide quando voltar ao abrigo. História breve: naufrágio durante busca pela família desaparecida, farol inacabado como caminho para resgate. Paleta sombria com caminhos, recursos e perigos legíveis. A apresentação usa pixel art rasterizada original e gratuita, sem dependências externas.

## Regras verificáveis

- WASD move; Shift corre gastando energia; mouse mira; clique esquerdo ataca; E interage; Q consome comida; Esc pausa.
- Dia de 240 segundos, noite de 120 segundos. Sem limite de dias. HUD mostra tempo, direção do farol e aviso antes da noite.
- Madeira e pedra perto; sucata e peças longe; arbustos fornecem comida. Coleta simples, sem ferramentas.
- Mochila limitada pelo total de unidades. Depósito no farol permite guardar e retirar recursos sem pausar. Materiais guardados financiam três reparos fixos.
- Fogueira abastecida com madeira consome combustível somente à noite. Abrigo seguro enquanto acesa; animais não nascem dentro dele. Sem combustível, animais entram e ferem apenas o jogador.
- Uma espécie de animal, ataque próximo. Animais distantes durante o dia; mais próximos à noite. Quantidade cresce por noite até um limite.
- Vida recuperada com comida; sem fome/sede e sem cura automática. Corrida limitada por energia.
- Morte: manhã do dia seguinte, vida/energia cheias, mochila vazia, depósito e reparos preservados. Peças perdidas ficam novamente disponíveis na origem; recursos comuns renovam pela manhã.
- Três reparos consomem materiais e peças. Depois, interação explícita acende farol e inicia cena de resgate com total de dias.
- Salvamento único automático pela manhã e após reparo, com continuar e novo jogo. Novo jogo pede confirmação se substituir progresso. Salvar inclui inventários, fase do ciclo, recursos retirados, combustível e posição segura do jogador. Falha de leitura não deve carregar progresso parcial.
- Sem diálogos, missões secundárias, fabricação livre ou sistemas separados de fome/sede.

## Arquitetura

`scripts/survival_state.gd`: regras e persistência, independente da árvore visual.
`scripts/island_world.gd`: mapa fixo em `TileMapLayer`, geometria navegável, costa física, recursos e decorações.
`scripts/game.gd`: ciclo, inimigos, interação, câmera, tempo, checkpoints e integração das cenas.
`scenes/actors/`: jogador e animal em `CharacterBody2D`, com áreas físicas de ataque e dano.
`scenes/objects/`: pickups atravessáveis; farol, depósito e ruínas bloqueantes; fogueira atravessável com luz.
`scenes/ui/game_ui.tscn` e `scripts/game_ui.gd`: HUD, menus, depósito e mensagens em português.
`scripts/soundscape.gd`: efeitos sintetizados originais, sem downloads.
`scenes/main.tscn`: entrada do projeto.
`tests/`: regras, contratos de cena, física, integração, expedição e salvamento headless; captura gráfica opcional para inspeção visual.

## Aceite

Executar F6/F5 abre o menu; nova partida permite coletar, depositar, abastecer, lutar e reparar. Noite e morte preservam as regras acima. Uma partida completa chega ao resgate. Continuar restaura checkpoint. Testes isolam saves do jogador. Playtest humano de dificuldade continua necessário após verificação automática.
