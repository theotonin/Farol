"""Generate the current GDD and two moodboard plates from project screenshots."""
from pathlib import Path
from xml.sax.saxutils import escape
import json
import math
import sys

from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, A3, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, KeepTogether
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'Game'
PHOTOS = OUT / 'Moodboard'
FONT_DIR = Path('/usr/share/fonts/truetype/dejavu')
pdfmetrics.registerFont(TTFont('Text', str(FONT_DIR / 'DejaVuSans.ttf')))
pdfmetrics.registerFont(TTFont('Bold', str(FONT_DIR / 'DejaVuSans-Bold.ttf')))
pdfmetrics.registerFontFamily('Text', normal='Text', bold='Bold', italic='Text', boldItalic='Bold')
SEA, PAPER, AMBER = '#142c32', '#edf0dc', '#efbd70'

# Content is explicit rather than inferred from historical plans. Each page groups
# related rules; numeric values were checked against the current Godot scripts.
PAGES = [
('O Farol Game Design Document', [
 ('sub','Estado atual do protótipo em 2 de outubro de 2026'),
 ('p','Este GDD reúne o jogo que está implementado: exploração de uma ilha, sobrevivência, coleta, abrigo, combate, três reparos do farol e resgate. Ele serve como referência para a equipe, para a apresentação escolar e para os próximos testes. A narrativa de mistério permanece provisória; as regras numéricas descrevem o código atual.'),
 ('img','08-hud-faroleiro.png','HUD Faroleiro no protótipo atual. Estado preparado para demonstrar os indicadores.'),
 ('table', ['Aspecto','Definição atual'], [
 ['Gênero','Sobrevivência 2D com exploração e objetivo de reconstrução'],
 ['Perspectiva e modo','Vista de cima; um jogador local'],
 ['Plataforma','Computador; projeto executado na Godot 4.7.1'],
 ['Entrega prevista','Protótipo escolar até 13/10/2026, conforme escopo aprovado'],
 ['Condição de vitória','Concluir os três reparos e acender o farol por interação'],
 ['Documentos visuais','Moodboard.pdf e capturas na subpasta Moodboard'],
 ]),
 ('p','O núcleo jogável está implementado e tem verificações automáticas. Ritmo, dificuldade e legibilidade em movimento ainda precisam de uma partida humana completa. Este documento não apresenta ideias futuras como recursos já existentes.'),
]),
('Conceito e narrativa', [
 ('h','Premissa'),
 ('p','O protagonista é descendente de uma família de exploradores desaparecida décadas antes. Documentos o levam a investigar uma ilha ausente dos mapas modernos. Depois de um acidente marítimo, ele chega sozinho à costa e encontra um farol inacabado. Reconstruir esse farol é sua chance de sinalizar a posição e conseguir um resgate.'),
 ('p','O roteiro-base é chamado O Último Faroleiro. O mistério da família e do sinal orienta a atmosfera, mas essa direção narrativa é provisória. No protótipo, ela aparece em textos de introdução e encerramento; não há diálogos, investigação interativa ou revelação posterior ao resgate.'),
 ('h','Experiência pretendida'),
 ('p','A distância da base deve criar uma decisão concreta: continuar procurando recursos ou voltar a tempo de preparar a noite. A luz do abrigo funciona como referência de segurança. A reconstrução torna o progresso visível e dá propósito às saídas pela ilha.'),
 ('table',['Pilar','Como aparece no jogo'],[
 ['Explorar com risco','Sair do abrigo, localizar materiais e enfrentar animais'],
 ['Preparar o retorno','Guardar a mochila, reservar comida e abastecer a fogueira'],
 ['Reconstruir para escapar','Aplicar recursos em três reparos e escolher quando partir'],
 ]),
 ('h','Limites narrativos e de escopo'),
 ('p','A partida não tem limite de dias nem termina automaticamente no último reparo. A morte devolve o jogador ao abrigo e preserva parte do progresso. O jogador decide acender o farol quando estiver pronto. O foco atual é esse ciclo, sem missões secundárias ou sistemas paralelos.'),
 ('h','Referências históricas'),
 ('p','Os registros de design citam O Peregrino e KeepUp Survival para movimento, Winter Survival e Survive the Nights para sobrevivência, 99 Noites na Floresta para a base como centro e Hollow Knight para estética. São referências em investigação; o projeto não reproduz seus sistemas completos nem utiliza seus assets.'),
]),
('Ciclo de jogo e controles', [
 ('h','Fluxo principal'),
 ('p','Menu inicial → nova expedição ou continuar → introdução → exploração e coleta → retorno ao abrigo → depósito e fogueira → reparo → nova saída. Depois do terceiro reparo, a interação de acender o farol leva ao resgate e à tela de vitória.'),
 ('h','Começo da expedição'),
 ('p','A nova partida começa na noite do dia 1, no tempo interno 270 segundos, com 100 de vida, 100 de energia, mochila e depósito vazios, farol sem reparos e fogueira sem combustível. Restam 90 segundos até o primeiro amanhecer. A introdução informa esse início noturno.'),
 ('table',['Ação','Controle e comportamento'],[
 ['Mover','WASD; movimento em oito direções'],
 ['Correr','Segurar Shift enquanto se move; usa energia'],
 ['Mirar','Posição do mouse define a direção do golpe'],
 ['Atacar','Clique esquerdo; golpe de curto alcance'],
 ['Interagir','E; coleta recurso ou abre abrigo próximo'],
 ['Comer','Q; consome comida da mochila quando a vida não está cheia'],
 ['Pausar','Esc; com o abrigo aberto, fecha primeiro esse painel'],
 ['Organizar materiais','Botões no painel do abrigo; o tempo continua passando'],
 ]),
 ('h','Dia e noite'),
 ('p','Um ciclo completo dura seis minutos: quatro de dia e dois de noite. O HUD mostra o tempo restante para a próxima fase. Um aviso aparece 30 segundos antes da noite. O amanhecer aumenta o número do dia, renova os recursos comuns, ajusta os inimigos e salva um checkpoint.'),
 ('p','Pausar, ler a introdução e permanecer no menu suspendem a simulação. Abrir o depósito durante a partida não pausa; organizar materiais à noite continua exigindo atenção ao combustível e à segurança.'),
]),
('Ilha e distribuição de recursos', [
 ('img','07-ilha.png','Visão geral da ilha fixa com farol central, caminhos, vegetação, ruínas e faixa costeira.'),
 ('h','Geografia e navegação'),
 ('p','A ilha tem contorno fixo, desenhado com TileMapLayer e atlas de terreno de 32×32. O farol, o depósito e a fogueira formam a base. Ruínas e áreas de vegetação compõem as saídas de exploração. A costa impede sair da área navegável; farol, depósito e ruínas bloqueiam movimento. Recursos, árvores, pedras pequenas, decoração e fogueira são atravessáveis.'),
 ('h','Distribuição atual'),
 ('p','Existem 69 pickups por expedição: 24 madeiras, 18 pedras, 16 sucatas, 8 comidas e 3 peças. Ao iniciar, uma semente redistribui os recursos no terreno. O contorno e as construções permanecem fixos; carregar o save recupera a mesma distribuição.'),
 ('p','O posicionamento evita a costa, as construções, as decorações e a área inicial, mantendo espaçamento entre pickups. As três peças são posicionadas primeiro e precisam estar a pelo menos 650 unidades do centro. Os demais tipos não têm uma regra que os limite a regiões específicas.'),
 ('p','Os planos iniciais descreviam madeira e pedra perto, sucata nas ruínas e peças nos extremos da ilha. O código atual usa distribuição aleatória com essas restrições, portanto essas localizações históricas não são garantias para o jogador.'),
]),
('Jogador e combate', [
 ('h','Movimento e energia'),
 ('table',['Parâmetro','Valor atual'],[
 ['Vida e energia máximas','100 cada'],
 ['Velocidade de caminhada','165 unidades por segundo'],
 ['Velocidade de corrida','265 unidades por segundo'],
 ['Consumo durante corrida','28 de energia por segundo'],
 ['Recuperação sem correr','19 de energia por segundo'],
 ['Exaustão','Ao chegar a 0; a corrida libera novamente a partir de 25'],
 ]),
 ('p','O jogador usa CharacterBody2D, colisão com mundo e animações para caminhada, repouso e golpe. A direção de movimento ou a mira atual orienta o sprite e a área de ataque. Os valores de velocidade são unidades internas; não representam metros reais.'),
 ('h','Animais e dano'),
 ('table',['Regra','Valor ou efeito'],[
 ['Espécies atuais','Uma espécie de animal hostil'],
 ['Vida do animal','65; um golpe do jogador causa 35'],
 ['Intervalo entre golpes','0,45 segundo; dois acertos derrotam um animal'],
 ['Dano do animal','14 por contato de ataque; intervalo de 1,1 segundo'],
 ['Proteção após dano','0,35 segundo para evitar dano repetido imediato'],
 ['Movimento do animal','92 unidades/s de dia; 110 à noite'],
 ['Detecção','370 unidades de dia; 860 à noite'],
 ]),
 ('p','Animais perseguem o jogador dentro da distância de detecção, recebem empurrão ao serem atingidos e evitam a área de abrigo quando protegida. Fora de perseguição, movimentam-se lentamente. Não atacam o farol nem o depósito e não fornecem loot.'),
 ('p','Durante o dia são três animais. À noite, a quantidade é o menor valor entre 12 e 3 + número do dia: quatro na primeira noite, aumentando até o teto de doze. Eles são reposicionados nas trocas de fase; não há combate ativo no menu ou na pausa.'),
]),
('Inventário abrigo e sobrevivência', [
 ('table',['Recurso','Uso atual'],[
 ['Madeira','Reparos da estrutura e do mecanismo; combustível da fogueira'],
 ['Pedra','Reparos da estrutura e da lanterna'],
 ['Sucata','Reparos do mecanismo e da lanterna'],
 ['Peças','Três itens únicos necessários aos dois últimos reparos'],
 ['Comida','Consumir com Q para recuperar até 25 de vida'],
 ]),
 ('h','Mochila e depósito'),
 ('p','A capacidade total da mochila é 20 unidades, somando todos os tipos. Uma coleta acrescenta uma unidade. A quantidade aparece junto do ícone e a capacidade total fica em destaque quando cheia. O depósito não tem limite definido. Guardar transfere toda a mochila; retirar transfere uma unidade do tipo escolhido, se houver espaço.'),
 ('h','Fogueira e área segura'),
 ('p','Uma madeira acrescenta até 30 segundos de combustível, com reserva máxima de 240 segundos. O abastecimento usa primeiro madeira carregada e depois madeira guardada. O combustível só diminui à noite: quatro madeiras cobrem uma noite completa de 120 segundos. Combustível positivo protege a área de raio 180 unidades em torno da base; sem reserva, animais podem alcançar o jogador.'),
 ('p','A aparência da fogueira e sua luz respondem à reserva e à noite. Abrir o abrigo exige estar a até 185 unidades do centro. A proteção não permite exploração remota: sair do círculo devolve o risco de perseguição e dano.'),
 ('h','Morte e recuperação'),
 ('p','Ao morrer, o jogador reaparece no abrigo na manhã do dia seguinte, com vida e energia cheias. A mochila é perdida; depósito, combustível restante e reparos são preservados. Recursos comuns voltam a ficar disponíveis. Peças únicas que estavam na mochila retornam ao seu ponto da expedição; peças guardadas ou já utilizadas não reaparecem. A recuperação gera um checkpoint.'),
 ('p','A sobrevivência usa vida, energia, comida e fogo. Não existem barras de fome ou sede, cura automática contínua, fabricação livre ou construção de novas bases.'),
]),
('Reconstrução e economia', [
 ('h','Três reparos sequenciais'),
 ('p','O painel do abrigo informa materiais guardados e custos do próximo reparo. Cada etapa exige seus materiais completos no depósito; itens que continuam na mochila não pagam o reparo. Um reparo consome os custos, altera o farol visualmente, acende um marco no HUD e salva o progresso.'),
 ('table',['Etapa','Materiais do depósito'],[
 ['1  Reforçar a estrutura','10 madeiras e 8 pedras'],
 ['2  Restaurar o mecanismo','8 madeiras, 6 sucatas e 1 peça'],
 ['3  Montar a lanterna','8 pedras, 8 sucatas e 2 peças'],
 ]),
 ('table',['Total para os três reparos','Quantidade'],[
 ['Madeira','18'],['Pedra','16'],['Sucata','14'],['Peças únicas','3'],['Total de unidades','51; sem contar comida ou combustível'],
 ]),
 ('h','Decisões de abastecimento'),
 ('p','Madeira serve tanto à obra quanto à proteção noturna. Comida ocupa espaço que poderia carregar materiais, mas permite corrigir dano da exploração. Guardar reduz o risco de perda na morte. As três peças únicas exigem sair da área central e retornar; podem ser reunidas antes de serem usadas.'),
 ('p','A capacidade de 20 unidades implica pelo menos três cargas para transportar as 51 unidades dos reparos, considerando a soma dos materiais e sem incluir reservas adicionais. Esse é um limite de capacidade, não uma estimativa de duração: a rota, os perigos e o preparo determinam quantas saídas serão necessárias.'),
 ('h','Finalização'),
 ('p','Completar a lanterna libera a ação Acender o farol e chamar resgate. A obra concluída não encerra a partida automaticamente. O jogador pode continuar explorando e decide quando acender. A interação válida inicia a cena de resgate; não existe um quarto reparo.'),
]),
('Interface Faroleiro', [
 ('img','08-hud-faroleiro.png','Fonte bitmap, barras segmentadas, marcos de reparo e feedback mínimo de coleta.'),
 ('h','Identidade visual do HUD'),
 ('p','O HUD usa mar escuro, texto claro, luz âmbar e molduras com cantos em degraus. A fonte Faroleiro é original, bitmap de 5×7 com maiúsculas, minúsculas e acentos em português; o tamanho-base 8 é exibido em 16. O símbolo do farol e a bússola são desenhos próprios. Vida e energia têm dez divisões visuais, preservando valores contínuos.'),
 ('table',['Elemento','Localização e função'],[
 ['Vida e energia','Canto superior esquerdo, com retrato do personagem'],
 ['Dia e direção','Canto superior direito; contagem regressiva e retorno ao farol'],
 ['Objetivo','Topo central; próximo reparo e três marcadores de progresso'],
 ['Mochila','Faixa de 404×84 na base; cinco ícones e quantidades'],
 ['Comando contextual','Acima da mochila; largura acompanha o texto'],
 ['Coleta','Ícone e +1 em 84×40 ao lado da mochila, por 1,2 segundo'],
 ]),
 ('p','Avisos importantes têm tamanho conforme o texto. A coleta usa um aviso separado, sem apagar alertas de salvamento. Com o abrigo aberto, mochila e avisos se deslocam para a área livre. Os atalhos completos ficam na pausa. Menus e abrigo mantêm a fonte padrão da Godot e o foco visível para navegação por teclado.'),
]),
('Arte atmosfera e áudio', [
 ('h','Direção de arte'),
 ('p','O jogo é pixel art visto de cima, com atlas de terreno de 32×32, sprites animados e objetos rasterizados originais. O filtro nearest e a ausência de mipmaps preservam pixels nítidos. A base visual usa mar #0a242b, floresta #173a35, terreno #324f42 e areia #9a9470. O âmbar #efbd70 identifica a luz, a proteção e o objetivo.'),
 ('p','A noite aplica tons frios ao mundo; a fogueira cria um ponto quente reconhecível. O farol muda de aparência por reparo e lança um feixe durante o resgate. O moodboard reúne essas relações com fotos do próprio projeto, incluindo paisagem, ruínas, abrigo, combate e HUD.'),
 ('h','Trilha e ambientação'),
 ('table',['Arquivo','Papel e duração'],[
 ['day.wav','Menu e exploração diurna; acordes suaves e sinos; 32 s'],
 ['night.wav','Introdução e noite; graves, dissonância e pulsação; 32 s'],
 ['rescue.wav','Resgate e vitória; melodia ascendente; 32 s'],
 ['ocean.wav','Ondas e vento sintetizados; loop de 11,5 s'],
 ['campfire.wav','Brasa e estalos; loop de 11,5 s com volume por proximidade'],
 ]),
 ('p','Os temas são instrumentais e originais, gerados sem gravações ou amostras de terceiros. As músicas trocam com transição de 2,5 segundos e continuam em repetição. O botão Som pausa trilha e ambientação e silencia efeitos; ao religar, os loops retomam. O oceano acompanha a ilha e a fogueira fica mais audível ao se aproximar.'),
 ('h','Efeitos e mixagem atual'),
 ('p','Há efeitos para passos, golpe no ar, impacto, dano, coleta, comida, abastecimento, reparo, amanhecer, morte, acendimento e botões. Passos acompanham deslocamento real e corrida, com pequena variação de afinação. A trilha usa alvo de -12 dB; passos, -21 dB; golpe no ar, -10 dB; demais cues, -6 dB. São parâmetros relativos de mixagem, não níveis acústicos medidos no ambiente.'),
]),
('Menus salvamento e resgate', [
 ('h','Estados e menus'),
 ('p','O controlador alterna menu, introdução, partida, pausa, resgate e vitória. O menu oferece continuar quando existe save, nova expedição e controle de som. Uma nova expedição pede confirmação antes de substituir progresso. A pausa permite retomar, alterar som e voltar ao menu. O encerramento informa quantos dias transcorreram até o resgate.'),
 ('h','Checkpoint automático'),
 ('table',['Momento','O que acontece'],[
 ['Começar a jogar','Grava o estado inicial da expedição'],
 ['Amanhecer','Salva o novo dia e a renovação de recursos'],
 ['Concluir reparo','Salva obra e materiais restantes'],
 ['Morrer','Salva recuperação, perdas e avanço de dia'],
 ['Acender o farol','Salva a condição de resgate'],
 ['Voltar ao menu','Salva a posição e o progresso atual'],
 ]),
 ('p','Há um save local em user://save.json, no diretório de dados da Godot para O Farol. O arquivo inclui inventários, vida, energia, tempo, combustível, etapa de obra, vitória, itens coletados, posição, semente e identidade das peças. O salvamento escreve um temporário e depois substitui o arquivo principal.'),
 ('p','Continuar valida o arquivo completo antes de aplicar os dados. Uma posição não navegável retorna ao ponto inicial. Save inválido não carrega estado parcial; falhas de escrita aparecem no HUD. Fechar a janela ou parar pelo editor entre checkpoints pode perder alterações recentes.'),
 ('h','Cena de resgate'),
 ('p','Acender o farol inicia um feixe e um barco no horizonte. A câmera se afasta gradualmente por quatro segundos; aos seis segundos o jogo mostra a vitória. Carregar um save com vitória já registrada leva ao encerramento. Não há combate ou nova exploração depois dessa tela.'),
]),
('Estrutura técnica atual', [
 ('p','Projeto Godot 4.7.1 com renderizador Compatibility. A cena inicial é scenes/main.tscn. A referência gráfica é 1280×720; a janela mínima é 960×540. O jogo não requer plugins, contas, downloads pagos ou serviços externos para executar.'),
 ('table',['Componente','Responsabilidade'],[
 ['scripts/survival_state.gd','Regras de inventário, vida, tempo, combustível, morte, reparos e save/load'],
 ['scripts/game.gd','Fluxo, combate, câmera, checkpoints, inimigos e integração da UI'],
 ['scripts/island_world.gd','Área navegável, recursos, semente, costa e decorações'],
 ['scripts/player.gd e enemy.gd','Corpos físicos, movimento, animação, áreas de interação e dano'],
 ['scenes/world e scenes/objects','TileMapLayer, farol, ruínas, depósito, fogueira e pickups'],
 ['scenes/ui/game_ui.tscn','Controles declarativos para HUD, menus e abrigo'],
 ['scripts/game_ui.gd','Mensagens, estados dos painéis, materiais e ações da interface'],
 ['scripts/soundscape.gd','Playback, transições musicais, ambiente e efeitos sintetizados'],
 ['scripts/hud_*.gd','Marca do farol, segmentos das barras e agulha da bússola'],
 ['assets/pixel e resources','Atlas, sprites e TileSet da ilha'],
 ['assets/ui e assets/audio','Fonte, moldura, músicas e loops originais'],
 ]),
 ('h','Ferramentas de produção'),
 ('p','tools/generate_audio.py reconstrói músicas e ambiente usando a biblioteca padrão do Python. tools/generate_hud_font.py gera a fonte bitmap e seu atlas. tools/build_game_docs.py gera este GDD e as pranchas do moodboard com as capturas organizadas na pasta Game.'),
 ('h','Colisão e apresentação'),
 ('p','O mundo usa camadas separadas de cenário, atores, interação e combate. Jogador e animal são CharacterBody2D; pickups são Area2D. Construções bloqueantes usam StaticBody2D. A fogueira usa Area2D e PointLight2D. A ordem de desenho por Y mantém personagem e objetos coerentes na vista de cima.'),
]),
('Estado do projeto e próximos testes', [
 ('h','O que está implementado'),
 ('p','O protótipo contém expedição, coleta, distribuição por semente, depósito, fogueira, animais, combate, morte com recuperação, três reparos, resgate, save/load, HUD Faroleiro e áudio. Capturas de cenas são preparadas por scripts; elas demonstram apresentação e estados, não comprovam equilíbrio de uma partida humana.'),
 ('table',['Verificação disponível','O que cobre'],[
 ['test_survival.gd','Economia, ciclo, morte e persistência'],
 ['test_scene_architecture.gd','Nós, cenas, contratos e combate dirigido'],
 ['test_world_physics.gd','Costa, construções e áreas atravessáveis'],
 ['test_game.gd e test_expedition.gd','Integração e caminho automatizado até o resgate'],
 ['test_resource_distribution.gd','Sementes, espaçamento e acesso aos recursos'],
 ['test_save_feedback.gd','Visibilidade de erros de salvamento'],
 ['test_ui_visuals.gd','HUD, contagens, acentos, avisos e coleta compacta'],
 ['test_soundscape.gd','Temas, loops completos, mute e transições'],
 ]),
 ('h','Playtest humano pendente'),
 ('p','Jogar do início ao resgate sem transporte automático; observar a pressão dos primeiros 90 segundos, a leitura dos itens, a decisão de voltar, o custo da fogueira, a dificuldade das noites e o uso do abrigo sem pausa. Registrar duração, mortes, saídas necessárias, materiais faltantes e momentos de dúvida. Ajustes de equilíbrio devem partir desses dados.'),
 ('h','Fora do escopo atual'),
 ('p','Não estão implementados multiplayer, mundo procedural em sua geometria, fabricação livre, construção livre, fome, sede, diálogos ou missões secundárias. A investigação familiar além dos textos é direção narrativa provisória. Não há compromisso documentado de publicação em lojas ou de novas plataformas.'),
 ('h','Fontes internas desta versão'),
 ('p','Regras conferidas em scripts/survival_state.gd, player.gd, enemy.gd, island_world.gd, game.gd, game_ui.gd e soundscape.gd. Contexto e intenção: docs/specs/prototipo.md, docs/context/game-overview.md, docs/context/cycle.md, DESIGN.md e README.md. Quando um plano histórico diverge do código, este GDD explicita o comportamento atual.'),
]),
]

styles = {
 'title': ParagraphStyle('title',fontName='Bold',fontSize=25,leading=31,textColor=colors.black,spaceAfter=12),
 'h': ParagraphStyle('h',fontName='Bold',fontSize=12,leading=17,textColor=colors.black,spaceBefore=11,spaceAfter=6,keepWithNext=True),
 'p': ParagraphStyle('p',fontName='Text',fontSize=10.3,leading=14.6,textColor=colors.HexColor('#202728'),spaceAfter=9),
 'sub': ParagraphStyle('sub',fontName='Text',fontSize=11,leading=16,textColor=colors.black,spaceAfter=15),
 'caption': ParagraphStyle('caption',fontName='Text',fontSize=8.2,leading=11,textColor=colors.HexColor('#43534e'),spaceAfter=10),
 'cell': ParagraphStyle('cell',fontName='Text',fontSize=9,leading=12.5,spaceAfter=0),
 'th': ParagraphStyle('th',fontName='Bold',fontSize=9,leading=12.5,textColor=colors.white,spaceAfter=0),
}

def para(text, style='p'):
 return Paragraph(escape(text),styles[style])

def footer(c, doc):
 c.saveState()
 c.setStrokeColor(colors.HexColor('#d3ddd6'))
 c.line(46,37,A4[0]-46,37)
 c.setFont('Text',8)
 c.setFillColor(colors.black)
 c.drawString(46,23,'O Farol  |  GDD do protótipo  |  02/10/2026')
 c.drawRightString(A4[0]-46,23,str(doc.page))
 c.restoreState()

def gdd():
 md=['# O Farol Game Design Document','', 'Versão do protótipo em 02/10/2026. A versão em PDF possui paginação e diagramação para apresentação.','']
 story=[]
 for number,(title,blocks) in enumerate(PAGES):
  if number: story.append(PageBreak())
  story.append(para(title,'title'))
  md.extend([f'## {title}' if number else '', ''])
  for block in blocks:
   kind=block[0]
   if kind in ['p','sub','h']:
    story.append(para(block[1],kind))
    md.extend([('### ' if kind=='h' else '')+block[1],''])
   elif kind=='img':
    source=PHOTOS/block[1]
    im=Image(str(source),width=499,height=499*9/16)
    im.hAlign='CENTER'
    story.extend([im,Spacer(1,5),para(block[2],'caption')])
    md.extend([f'![{block[2]}](Moodboard/{block[1]})','',block[2],''])
   elif kind=='table':
    headers,rows=block[1:]
    widths=[172,327]
    if title=='Reconstrução e economia': widths=[235,264]
    data=[[para(x,'th') for x in headers]]+[[para(x,'cell') for x in row] for row in rows]
    table=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
    table.setStyle(TableStyle([
      ('BACKGROUND',(0,0),(-1,0),colors.HexColor(SEA)),
      ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#f0f4ef'),colors.white]),
      ('LINEBELOW',(0,0),(-1,0),.6,colors.HexColor('#738477')),
      ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),
      ('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),
    ]))
    story.extend([table,Spacer(1,11)])
    md.extend(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |'])
    md.extend('| '+' | '.join(r)+' |' for r in rows)
    md.append('')
 doc=SimpleDocTemplate(str(OUT/'GDD.pdf'),pagesize=A4,rightMargin=48,leftMargin=48,topMargin=42,bottomMargin=51,title='O Farol Game Design Document',author='Projeto O Farol')
 outline_index = [0]
 def bookmark(flowable):
  if isinstance(flowable, Paragraph) and flowable.style.name == 'title':
   key = f'section-{outline_index[0]}'
   doc.canv.bookmarkPage(key)
   doc.canv.addOutlineEntry(flowable.getPlainText(), key, level=0, closed=False)
   outline_index[0] += 1
 doc.afterFlowable = bookmark
 doc.build(story,onFirstPage=footer,onLaterPages=footer)
 (OUT/'GDD.md').write_text('\n'.join(md),encoding='utf-8')

# Two deliberate landscape boards: world/lighting, then interface/graphic identity.
# Coordinates below use a 1600 x 1131 design canvas scaled to landscape A3.
def moodboard():
 c=canvas.Canvas(str(OUT/'Moodboard.pdf'),pagesize=landscape(A3))
 c.setTitle('O Farol Moodboard visual')
 c.setAuthor('Projeto O Farol')
 W,H=landscape(A3)
 def rect(x,y,w,h,color):
  c.setFillColor(colors.HexColor(color));c.rect(x,y,w,h,stroke=0,fill=1)
 def text(x,y,string,size=20,color=PAPER,bold=False):
  c.setFillColor(colors.HexColor(color));c.setFont('Bold' if bold else 'Text',size);c.drawString(x,y,string)
 def lines(x,y,string,width,size=20,color=PAPER,leading=29):
  words=string.split();line='';i=0
  for word in words:
   trial=(line+' '+word).strip()
   if pdfmetrics.stringWidth(trial,'Text',size)>width and line:
    text(x,y-i*leading,line,size,color);i+=1;line=word
   else:line=trial
  if line:text(x,y-i*leading,line,size,color)
 def image(name,x,y,w,h):
  c.saveState()
  p=c.beginPath();p.rect(x,y,w,h);c.clipPath(p,stroke=0)
  draw_w = max(w, h * 16 / 9)
  draw_h = draw_w * 9 / 16
  c.drawImage(str(PHOTOS/name), x + (w-draw_w)/2, y + (h-draw_h)/2, width=draw_w, height=draw_h, mask='auto')
  c.restoreState()
 def heading(title,subtitle,index):
  c.saveState();c.scale(W/1600,H/1131)
  rect(0,0,1600,1131,'#0c2026')
  rect(48,1033,12,56,AMBER)
  text(82,1055,title,40,PAPER,True)
  text(82,1022,subtitle,19,'#b3c7c3')
  text(1480,1054,index,18,'#b3c7c3')
 def caption(x,y,title,body,w):
  text(x,y,title,19,PAPER,True)
  lines(x,y-27,body,w,16,'#b3c7c3',23)
 def close():
  c.setStrokeColor(colors.HexColor('#48615c'));c.line(48,50,1552,50)
  text(48,27,'Capturas do próprio jogo  /  protótipo em 02.10.2026',14,'#b3c7c3')
  text(1150,27,'Pixel art original  /  O Farol',14,'#b3c7c3')
  c.restoreState();c.showPage()
 heading('O Farol','Atmosfera da ilha e relações de luz','1 / 2')
 image('04-luz-na-noite.png',48,437,936,526.5)
 caption(48,414,'A luz marca o retorno','Mar e floresta frios; fogo âmbar como ponto de proteção.',936)
 image('02-ruinas-na-floresta.png',1012,713,540,250)
 caption(1012,690,'Vestígios','Ruínas quebradas entre caminhos e vegetação.',540)
 image('03-praia-e-oceano.png',1012,383,540,250)
 caption(1012,360,'Isolamento','Areia aberta, borda de água e horizonte de fuga.',540)
 image('05-sobrevivencia.png',48,139,292,164)
 caption(48,119,'Tensão','Animais, pouca luz, retorno urgente.',292)
 image('06-resgate.png',366,139,292,164)
 caption(366,119,'Esperança','O feixe muda a leitura da ilha.',292)
 image('01-farol-e-abrigo.png',684,139,292,164)
 caption(684,119,'Reconstrução','O abrigo organiza a exploração.',292)
 text(1012,285,'Paleta do mundo',22,PAPER,True)
 palette=[('Mar','#0a242b'),('Floresta','#173a35'),('Terreno','#324f42'),('Areia','#9a9470'),('Luz','#efbd70')]
 for i,(name,color) in enumerate(palette):
  x=1012+i*108
  rect(x,197,96,60,color)
  text(x,172,name,14)
  text(x,151,color,12,'#b3c7c3')
 lines(1012,118,'Mistério, abrigo e perigo se distinguem por contraste e cor, sem apagar os recursos da noite.',540,16,'#b3c7c3',22)
 close()
 heading('Identidade Faroleiro','HUD compacto e linguagem gráfica ligada ao farol','2 / 2')
 image('08-hud-faroleiro.png',48,420,1000,562.5)
 caption(48,391,'A paisagem fica no centro','Indicadores nos cantos, mochila curta e aviso de coleta com ícone e +1.',1000)
 rect(1080,668,472,314,SEA)
 text(1104,943,'Forma e leitura',24,PAPER,True)
 lines(1104,900,'Fonte bitmap original com acentos em português. Cantos em degraus, barras segmentadas e desenhos próprios de bússola e farol.',424,20,PAPER,30)
 text(1104,741,'Vida',20,'#db8c78',True)
 text(1274,741,'Energia',20,'#88c4b0',True)
 for i in range(10):
  rect(1104+i*17,710,15,8,'#db8c78')
  rect(1290+i*17,710,15,8,'#88c4b0')
 text(1080,626,'Materiais e progresso',24,PAPER,True)
 lines(1080,587,'Os ícones reutilizam os sprites do mundo. Três marcos acendem conforme o farol é reparado. A luz âmbar aponta para o objetivo.',472,19,'#b3c7c3',29)
 image('09-abrigo-e-interface.png',48,108,456,242)
 caption(48,87,'Painel do abrigo','Feedback ocupa apenas a área livre.',456)
 text(544,327,'Cor com função',24,PAPER,True)
 palette=[('Superfície',SEA),('Borda','#738477'),('Texto',PAPER),('Objetivo',AMBER)]
 for i,(name,color) in enumerate(palette):
  x=544+i*126
  rect(x,235,112,58,color);text(x,209,name,15);text(x,186,color,13,'#b3c7c3')
 lines(544,147,'Coleta breve e discreta; mensagens maiores ficam reservadas a eventos que precisam ser lidos.',496,18,'#b3c7c3',27)
 text(1080,361,'Atmosfera sonora',24,PAPER,True)
 for y,title,body in [(315,'Exploração','Sinos espaçados e acordes suaves.'),(245,'Noite','Graves e pulsação contida.'),(175,'Resgate','Melodia ascendente e abertura.')]:
  text(1080,y,title,19,AMBER,True)
  lines(1080,y-28,body,472,17,'#b3c7c3',25)
 close()
 c.save()

if __name__=='__main__':
 OUT.mkdir(exist_ok=True)
 gdd();moodboard()
 print('Created Game/GDD.pdf, Game/GDD.md and Game/Moodboard.pdf')
