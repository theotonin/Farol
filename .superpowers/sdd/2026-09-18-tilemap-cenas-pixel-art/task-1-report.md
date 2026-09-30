# Task 1 — Relatório

## Status

Concluída a configuração de contratos e raster. O teste de arquitetura permanece vermelho de forma intencional porque as cenas contratadas serão criadas em tarefas futuras.

## Alterações

- Criado `tests/test_scene_architecture.gd`, validando a existência e o tipo-raiz das sete cenas contratadas.
- Atualizado `project.godot` com os grupos de nomes de camadas físicas 2D `world`, `actors`, `interaction` e `combat`.
- Atualizado `project.godot` para filtro de textura padrão sem filtragem e mipmap nearest desativado.
- O teste não inspeciona texto-fonte nem procura `_draw`, `draw_player` ou `draw_animal`; a verificação fica restrita a recursos/cenas e tipos reais.

## Registro de testes

### RED (esperado)

Comando:

```text
XDG_DATA_HOME=/tmp/o-farol-task1 /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_scene_architecture.gd
```

Resultado: exit 1, com sete mensagens `Cena ausente`, uma para cada caminho contratado. A primeira execução revelou apenas uma inferência de tipo do próprio teste; ela foi corrigida antes do RED válido, sem alterar produção.

### Validação da configuração

Comando:

```text
XDG_DATA_HOME=/tmp/o-farol-task1 /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --quit
```

Resultado: exit 0.

Também foi executada a inicialização headless do editor com exit 0; o ambiente reportou avisos de socket/editor settings, sem erro de parsing ou importação do projeto.

## Preocupações

- As sete cenas ainda estão ausentes por decisão de escopo; portanto, o teste de arquitetura deve continuar falhando até as tarefas seguintes implementarem os contratos.
- Nenhum commit foi criado, conforme solicitado, pois o Git não está utilizável neste ambiente.

## Fix round 1

- Arquivo alterado: `tests/test_scene_architecture.gd`.
- Adicionado contrato de grupos reais após instanciação: `player.tscn` → `player`, `enemy.tscn` → `enemies`, `resource_pickup.tscn` → `resources`, e `lighthouse.tscn`/`storage.tscn` → `structures`.
- Comando executado:

```text
XDG_DATA_HOME=/tmp/o-farol-task1 /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --script tests/test_scene_architecture.gd
```

- Resultado: exit 1 com exatamente as sete mensagens `Cena ausente`; não houve erros adicionais de grupo, pois as cenas ainda não existem.
- Validação de `project.godot`:

```text
XDG_DATA_HOME=/tmp/o-farol-task1 /home/theotonin/Documentos/godot/Godot_v4.7.1-stable_linux.x86_64 --headless --path . --quit
```

- Resultado: exit 0.
