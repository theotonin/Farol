"""Empacota áudio e protótipos fiéis às capturas do jogo em Game/."""
from pathlib import Path
import csv
import html
import shutil
import wave

ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "Game"
PROTO = GAME / "Prototipos"
PROTO.mkdir(parents=True, exist_ok=True)

tracks = [
    ("day", "Trilha/exploracao.wav", "Menu e exploração diurna", -12),
    ("night", "Trilha/noite.wav", "Introdução e exploração noturna", -12),
    ("rescue", "Trilha/resgate.wav", "Resgate e vitória", -12),
    ("ocean", "Ambiente/oceano.wav", "Ambiente do oceano", -24),
    ("campfire", "Ambiente/fogueira.wav", "Fogueira; volume varia com a distância", -18),
]
for source, target, _, _ in tracks:
    destination = GAME / "Audio" / target
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / "assets/audio" / f"{source}.wav", destination)

effects = [
    ("passos", "Passos; variação de tom no jogo", -21),
    ("golpe-no-ar", "Movimento de ataque", -10),
    ("coleta", "Coleta de recurso", -6),
    ("impacto", "Ataque acertando um inimigo", -6),
    ("dano", "Jogador recebendo dano", -6),
    ("comer", "Consumo de alimento", -6),
    ("reparo", "Etapa de reparo do farol", -6),
    ("morte", "Morte do jogador", -6),
    ("amanhecer", "Início de um novo dia", -6),
    ("acender-farol", "Acendimento do farol", -6),
    ("clique-menu", "Interação com menu", -6),
    ("abastecer-fogueira", "Abastecimento da fogueira", -6),
]
entries = [(target, label, gain) for _, target, label, gain in tracks]
entries += [(f"Efeitos/{name}.wav", label, gain) for name, label, gain in effects]
with (GAME / "Audio/catalogo.csv").open("w", newline="", encoding="utf-8-sig") as output:
    writer = csv.writer(output)
    writer.writerow(["arquivo", "uso", "duracao_segundos", "canais", "taxa_hz", "volume_no_jogo_db"])
    for target, label, gain in entries:
        with wave.open(str(GAME / "Audio" / target)) as audio:
            writer.writerow([target, label, round(audio.getnframes() / audio.getframerate(), 3),
                             audio.getnchannels(), audio.getframerate(), gain])

captures = {
    "menu": ("/tmp/o-farol-menu.png", "Menu-inicial.png"),
    "intro": ("/tmp/o-farol-intro.png", "Introducao.png"),
    "day": ("/tmp/o-farol-hud-day.png", "HUD.png"),
    "night": ("/tmp/o-farol-hud-night.png", "HUD-noite.png"),
    "pickup": ("/tmp/o-farol-hud-pickup.png", "HUD-coleta.png"),
    "shelter": ("/tmp/o-farol-hud-shelter.png", "HUD-abrigo.png"),
    "small": ("/tmp/o-farol-hud-small.png", "HUD-960x540.png"),
}
for source, target in captures.values():
    shutil.copy2(source, PROTO / target)

(PROTO / "Prototipo.html").write_text('''<!doctype html>
<html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>O Farol · Protótipo de interface</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#09181d;color:#ecefd8;font:16px system-ui,sans-serif}
main{max-width:1328px;margin:auto;padding:24px}h1{font-size:24px;margin:0 0 6px}p{color:#b6c9c5;line-height:1.5}
nav{display:flex;gap:8px;flex-wrap:wrap;margin:16px 0}nav button,a{color:inherit}
nav button{background:#203a40;border:1px solid #526d64;padding:10px 14px;cursor:pointer;font:inherit}
nav button[aria-pressed=true]{border-color:#e7b65c;color:#e7b65c}
.stage{position:relative;width:100%;aspect-ratio:16/9;background:#09181d}.stage img{width:100%;height:100%;object-fit:contain;display:block;image-rendering:pixelated}
.hotspot{position:absolute;left:30.859375%;width:38.28125%;height:6.388889%;background:transparent;color:transparent;border:0;cursor:pointer}
.hotspot:focus-visible{outline:3px solid #e7b65c;outline-offset:3px}.new{top:37.083333%}.begin{top:63.333333%}
.sound{top:44.583333%;background:#28434b;border:1px solid #526d64;border-radius:4px;color:#ecefd8;font:500 clamp(10px,1.5625vw,20px) system-ui}
[hidden]{display:none!important}footer{font-size:14px;color:#b6c9c5;margin-top:14px}
</style>
<main><h1>O Farol · HUD e menu inicial</h1>
<p>Protótipo navegável da interface atual. Clique em “Nova expedição” para percorrer a introdução e chegar ao HUD. As cenas abaixo demonstram os estados da interface.</p>
<nav aria-label="Estados do protótipo">
<button data-state="menu" aria-pressed="true">Menu inicial</button><button data-state="day" aria-pressed="false">HUD · dia</button>
<button data-state="night" aria-pressed="false">HUD · noite</button><button data-state="pickup" aria-pressed="false">Coleta</button>
<button data-state="shelter" aria-pressed="false">Abrigo</button><button data-state="small" aria-pressed="false">HUD · 960 × 540</button>
</nav><div class="stage">
<img id="scene" src="Menu-inicial.png" alt="Menu inicial de O Farol">
<button id="new" class="hotspot new" aria-label="Nova expedição">Nova expedição</button>
<button id="sound" class="hotspot sound" aria-pressed="true">Som: ligado</button>
<button id="begin" class="hotspot begin" aria-label="Chegar à ilha" hidden>Chegar à ilha</button>
</div><footer><span id="status" role="status">Menu inicial</span> · Esc retorna ao menu · <a href="../Audio/Ouvir.html">Ouvir trilha e efeitos</a></footer></main>
<script>
const screens={menu:['Menu-inicial.png','Menu inicial'],intro:['Introducao.png','Introdução · À deriva'],day:['HUD.png','HUD · dia'],night:['HUD-noite.png','HUD · noite'],pickup:['HUD-coleta.png','Coleta · aviso compacto'],shelter:['HUD-abrigo.png','HUD · abrigo aberto'],small:['HUD-960x540.png','HUD · resolução mínima']};
const scene=document.querySelector('#scene'),start=document.querySelector('#new'),begin=document.querySelector('#begin'),sound=document.querySelector('#sound');
const music=new Audio('../Audio/Trilha/exploracao.wav');music.loop=true;music.volume=Math.pow(10,-12/20);
const cue=new Audio('../Audio/Efeitos/clique-menu.wav');cue.volume=Math.pow(10,-6/20);
const collect=new Audio('../Audio/Efeitos/coleta.wav');collect.volume=Math.pow(10,-6/20);
let enabled=true,current='menu',theme='exploracao';
function play(audio){audio.play().catch(()=>{});}
function show(state){current=state;scene.src=screens[state][0];scene.alt=screens[state][1];document.querySelector('#status').textContent=screens[state][1];start.hidden=state!=='menu';sound.hidden=state!=='menu';begin.hidden=state!=='intro';document.querySelectorAll('[data-state]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.state===state)));let next=(state==='intro'||state==='night')?'noite':'exploracao';if(next!==theme){theme=next;music.src='../Audio/Trilha/'+theme+'.wav';}if(enabled){cue.currentTime=0;play(cue);play(music);if(state==='pickup'){collect.currentTime=0;play(collect);}}}
document.querySelectorAll('[data-state]').forEach(b=>b.addEventListener('click',()=>show(b.dataset.state)));
start.addEventListener('click',()=>show('intro'));begin.addEventListener('click',()=>show('night'));
sound.addEventListener('click',()=>{enabled=!enabled;sound.textContent='Som: '+(enabled?'ligado':'desligado');sound.setAttribute('aria-pressed',String(enabled));if(enabled)play(music);else{music.pause();cue.pause();collect.pause();}});
document.addEventListener('keydown',e=>{if(e.key==='Escape')show('menu');});
</script></html>''', encoding="utf-8")

rows = "\n".join(
    f'<article><h2>{html.escape(label)}</h2><p>{html.escape(target)} · mixagem no jogo: {gain} dB</p>'
    f'<audio controls preload="none" src="{target}"></audio></article>' for target, label, gain in entries)
(GAME / "Audio/Ouvir.html").write_text('''<!doctype html><html lang="pt-BR"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>O Farol · Áudio</title>
<style>body{max-width:1000px;margin:32px auto;padding:0 24px;background:#09181d;color:#ecefd8;font:16px system-ui}h2{font-size:18px}p,a{color:#b6c9c5}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}article{background:#182f34;padding:16px;border:1px solid #526d64}audio{width:100%}</style>
<h1>O Farol · Trilha, ambiente e efeitos</h1><p>Arquivos originais em WAV. Os players reproduzem o áudio bruto; os valores indicam o volume aplicado pelo jogo.</p>
<p><a href="../Prototipos/Prototipo.html">Abrir protótipo do HUD e menu</a></p><section>''' + rows + "</section></html>", encoding="utf-8")

(GAME / "Audio/README.md").write_text('''# Áudio de O Farol

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
''', encoding="utf-8")
(PROTO / "README.md").write_text('''# Protótipos de interface

Abra **Prototipo.html** no navegador. Não precisa instalar ferramentas ou usar internet.
O menu tem botões clicáveis para iniciar a introdução e chegar à ilha, além de
controle de som. As abas mostram dia, noite, coleta, abrigo e resolução mínima.
Esc retorna ao menu. A trilha começa após a primeira interação no navegador.

As imagens PNG são capturas da interface implementada no jogo, em 1280 × 720;
`HUD-960x540.png` demonstra a janela mínima. O HUD usa a identidade Faroleiro:
fonte bitmap, recortes pixelados, paleta costeira, farol com três etapas e aviso
de coleta compacto. O menu inicial reproduz a versão atual do jogo.

Este arquivo demonstra a navegação e os estados visuais da interface.
Para jogar com movimento, combate e persistência, abra o projeto Godot da raiz.
''', encoding="utf-8")
print(f"Empacotados {len(entries)} WAVs, {len(captures)} capturas e 2 páginas HTML.")
