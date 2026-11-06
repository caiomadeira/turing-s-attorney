# Referência da API

API dos scripts em `game/` para Godot 4.7. A cena principal é `res://game/scenes/game.tscn`, em 1280×720. O Dialogic desenha o texto. Estes tipos aplicam ao jogo o que a timeline pede.

A ordem no `project.godot` é a ordem de inicialização. Um autoload enxerga os que foram registrados antes dele.

1. `Dialogic`
2. `GameState`
3. `Inventory`
4. `SceneRouter`
5. `DialogueDirector`

`DialogueDirector` é o único script que chama `Dialogic.start()`.

A raiz de `game.tscn` chama `SceneRouter.register_host()` com `%LocationHost`, abre `res://game/scenes/locations/office/office.tscn` e liga o botão Inventário a `InventoryPanel.toggle()`. O botão "Ir ao tribunal" fica no canto inferior direito e abre um `ConfirmationDialog`. "Ir" chama `SceneRouter.go_to()` com `locations/tribunal/tribunal.tscn`. "Ficar" e Esc cancelam. Ele só aparece depois que o jogador fecha o dossiê (`leu_dossie`). Em `dialogue_started`, esconde o painel, fecha a confirmação e desativa os dois botões. Em `dialogue_finished`, ativa de novo, salvo com a nota aberta. O botão some no tribunal, no veredito e no fim de jogo. No fim de jogo, as camadas `HUD`, `CredibilityLayer`, `NoteLayer` e `ToastLayer` ficam invisíveis: some o inventário, os losangos, a nota e o aviso de item. O layout do Dialogic, se ainda estiver na árvore, também some. `CanvasLayer.visible` não muda o `visible` de cada filho, então ao sair da tela o que já estava escondido continua escondido.

O ponteiro do mouse é a imagem em `display/mouse_cursor/custom_image` do `project.godot`.

`game.tscn` também tem a `CredibilityLayer` (camada 50) com a `CredibilityBar`, os losangos do julgamento.

O caminho do jogo, fase por fase, está em [Fluxo do jogo](#fluxo-do-jogo), no fim deste arquivo.

## Classes

| Classe | Herda | Resumo |
| --- | --- | --- |
| [GameState](#gamestate) | `Node` | Flags da história |
| [Inventory](#inventory) | `Node` | Catálogo e itens do jogador |
| [SceneRouter](#scenerouter) | `Node` | Troca de local |
| [DialogueDirector](#dialoguedirector) | `Node` | Timelines e sinais do Dialogic |
| [ItemData](#itemdata) | `Resource` | Definição de um item |
| [PassageLock](#passagelock) | `Resource` | Condição para atravessar uma saída |
| [ItemLock](#itemlock) | `PassageLock` | Passagem que exige um item |
| [Location](#location) | `Control` | Raiz de um local |
| [Interaction](#interaction) | `Button` | Troca o cursor ao passar o ponteiro |
| [Hotspot](#hotspot) | `Interaction` | Objeto clicável que abre uma timeline |
| [SceneExit](#sceneexit) | `Interaction` | Saída para outro local |
| [ExitArrow](#exitarrow) | `SceneExit` | Seta para outro local |
| [InventoryPanel](#inventorypanel) | `Control` | Painel do inventário |
| [ItemToast](#itemtoast) | `PanelContainer` | Aviso de item ou argumento |
| [CredibilityBar](#credibilitybar) | `Control` | Losangos de credibilidade no julgamento |
| [SpeakerLayer](#speakerlayer) | `DialogicLayoutLayer` | Só o retrato de quem fala, e a câmera do tribunal |

---

# GameState

**Herda:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Autoload:** `GameState`

**Script:** `res://game/autoload/game_state.gd`

Flags da história que não são itens do inventário, e a credibilidade do promotor no julgamento.

## Descrição

Guarda pares de nome e valor booleano, por exemplo `got_badge` e `met_witness`. A primeira chamada a `set_flag()` cria a flag. Hotspots e setas escutam `flag_changed` para aparecer ou sumir.

Uma condição do Dialogic pode ler a flag direto:

```gdscript
if GameState.has_flag("met_witness"):
	witness: Eu já contei o que vi.
else:
	witness: Vi alguém sair às pressas.
```

A linha de dentro da condição leva tab.

`has_flag()` devolve `true` quando o valor guardado é `true`. Uma flag ausente e uma flag gravada como `false` devolvem `false`.

`credibility` conta os losangos do promotor. O julgamento começa com `MAX_CREDIBILITY` e cada argumento errado tira um. A timeline confere quando acabou:

```gdscript
[signal arg="lose_credibility:1"]
if GameState.credibility <= 0:
	jump sem_credibilidade
```

## Constantes

### int MAX_CREDIBILITY = 5

Losangos com que o julgamento começa.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| int | credibility | `5` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| void | set_flag(flag: String, value: bool = true) |
| bool | has_flag(flag: String) |
| void | clear_flag(flag: String) |
| void | set_credibility(value: int) |
| void | lose_credibility(amount: int = 1) |
| void | clear_spoken_arguments() |
| void | speak_argument(argument_id: String) |
| bool | can_speak(argument_id: String) |
| bool | has_opening_argument() |
| bool | has_apartment_argument() |
| bool | has_proof() |
| void | reset() |

## Sinais

### flag_changed(flag: String, value: bool)

Emitido depois que `set_flag()` grava a flag. `value` é o valor novo. `clear_flag()` também emite este sinal, com `false`.

### credibility_changed(value: int)

Emitido depois que `set_credibility()` ou `lose_credibility()` mudam `credibility`. `CredibilityBar` escuta este sinal.

---

## Descrições dos métodos

### void set_flag(flag: String, value: bool = true)

Grava `flag` com `value` e emite `flag_changed`. Um nome vazio é ignorado e o sinal não é emitido.

Uma timeline marca a flag com o evento `[signal arg="set_flag:met_witness"]`. Esse caminho chama `set_flag()` com o valor padrão `true`.

### bool has_flag(flag: String)

Devolve `true` quando `flag` está guardada como `true`.

### void clear_flag(flag: String)

Equivale a `set_flag(flag, false)`.

### void set_credibility(value: int)

Grava `credibility` com `value`, preso entre `0` e `MAX_CREDIBILITY`, e emite `credibility_changed`. A timeline do julgamento chama com `[signal arg="set_credibility:5"]` ao começar, então tentar de novo volta aos 5 losangos.

### void lose_credibility(amount: int = 1)

Equivale a `set_credibility(credibility - amount)`. A timeline chama com `[signal arg="lose_credibility:1"]`.

### void clear_spoken_arguments()

Apaga as flags `falou_` de cada id em `SPOKEN_ARGUMENTS`. Não mexe nas flags da investigação nem nos itens. `julgamento.dtl` chama com `do GameState.clear_spoken_arguments()` ao abrir o tribunal, então "Tentar o julgamento de novo" devolve as falas.

### void speak_argument(argument_id: String)

Grava `falou_` mais o id. Um id fora de `SPOKEN_ARGUMENTS` gera um aviso e não grava nada. A timeline chama com `do GameState.speak_argument("aparencia")` no começo da escolha.

### bool can_speak(argument_id: String)

`true` quando a fala ainda não foi dita nesta tentativa e o jogador a coletou. `aparencia` não precisa de item. As outras exigem o item ou a flag da investigação (`depoimento_porteiro`, `olho_magico`, `porta_sem_girar`, `viu_filtro`, `viu_computador`, `dobradicas`, `chave_apartamento`).

### bool has_opening_argument()

`true` se ainda dá para falar de aparência, do porteiro ou de alguma pista do apartamento.

### bool has_apartment_argument()

`true` se ainda dá para falar do olho mágico, da porta, do filtro ou da conta de luz.

### bool has_proof()

`true` se ainda há uma prova não apresentada contra a desculpa do olho mágico.

### void reset()

Apaga todas as flags e devolve `credibility` a `MAX_CREDIBILITY`. Emite `flag_changed` com `false` para cada flag que existia, e `credibility_changed`. O botão "Reiniciar o jogo" na tela de fim de jogo chama este método.

---

# Inventory

**Herda:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Autoload:** `Inventory`

**Script:** `res://game/autoload/inventory.gd`

Itens que o jogador está carregando.

## Descrição

No `_ready`, lê cada `ItemData` em `ITEMS_DIR` e monta um catálogo pelo campo `id`. A lista do jogador começa vazia. `get_items()` devolve os itens na ordem em que foram ganhos.

Um arquivo sem `id`, ou que não seja `ItemData`, fica de fora do catálogo. Em exportação, o sufixo `.remap` é removido antes de carregar o `.tres`.

## Constantes

### String ITEMS_DIR = "res://game/data/items/"

Pasta varrida na inicialização. Cada item novo é um `.tres` nesta pasta.

---

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | add(item_id: String) |
| void | clear() |
| bool | remove(item_id: String) |
| bool | has(item_id: String) |
| Array[ItemData] | get_items() |
| ItemData | get_item(item_id: String) |

## Sinais

### changed()

Emitido depois que `add()`, `remove()` ou `clear()` alteram a lista do jogador. `InventoryPanel` escuta este sinal para redesenhar a lista.

### item_added(item: ItemData)

Emitido depois de um `add()` bem-sucedido. `item` é a definição do catálogo. `ItemToast` escuta este sinal.

---

## Descrições dos métodos

### bool add(item_id: String)

Coloca `item_id` na lista do jogador, uma vez. Emite `changed` e `item_added`. Devolve `true` quando o item entra na lista.

Devolve `false` quando o id está ausente do catálogo, ou quando o jogador já carrega esse item. Um id desconhecido também gera um aviso.

Uma timeline entrega o item com `[signal arg="give_item:attorneys_badge"]`.

### void clear()

Esvazia a lista do jogador e emite `changed`. Não emite `item_added`. Se a lista já está vazia, não faz nada. O botão "Reiniciar o jogo" chama este método.

### bool remove(item_id: String)

Tira `item_id` da lista e emite `changed`. Devolve `false` quando o jogador não está com o item.

Uma timeline remove o item com `[signal arg="remove_item:attorneys_badge"]`.

### bool has(item_id: String)

Devolve `true` quando o jogador está com `item_id`.

### Array[ItemData] get_items()

Devolve os `ItemData` que o jogador carrega, na ordem em que `add()` os inseriu.

### ItemData get_item(item_id: String)

Devolve a definição do catálogo. O jogador pode ainda não ter o item. Devolve `null` quando o id não está no catálogo.

---

# SceneRouter

**Herda:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Autoload:** `SceneRouter`

**Script:** `res://game/autoload/scene_router.gd`

Troca o local sob um nó hospedeiro para o HUD continuar na tela.

## Descrição

`register_host()` recebe o `LocationHost` de `game.tscn`. `go_to()` substitui o filho desse nó pela cena pedida. O HUD, irmão do host, permanece.

A troca é adiada com `call_deferred`, para o botão que emitiu `pressed` não ser liberado no meio do sinal. Se `go_to()` for chamado de novo antes da troca rodar, vale o último caminho.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | current_scene_path | `""` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| void | register_host(host: Node) |
| void | go_to(scene_path: String) |

## Sinais

### location_changed(scene_path: String)

Emitido depois que o local novo entra no host. `scene_path` é o caminho que ficou em `current_scene_path`.

---

## Descrições das propriedades

### String current_scene_path = ""

Caminho da cena instanciada no host. Fica vazio até a primeira troca concluir.

---

## Descrições dos métodos

### void register_host(host: Node)

Define o nó que recebe o local atual. A cena principal chama este método no `_ready`, com `%LocationHost`.

### void go_to(scene_path: String)

Agenda a troca para `scene_path`. Um caminho vazio é ignorado.

Na troca, cada filho do host é removido e liberado, e a cena nova é instanciada no lugar. Em seguida grava `current_scene_path` e emite `location_changed`.

Gera um erro quando o host ainda não foi registrado, quando o arquivo não existe, ou quando o recurso não é uma `PackedScene`.

`SceneExit` chama este método no clique, quando a passagem está aberta. O sinal `change_scene` de uma timeline também chega aqui, depois que a timeline termina, sem consultar a trava. Veja `DialogueDirector`.

---

# DialogueDirector

**Herda:** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Autoload:** `DialogueDirector`

**Script:** `res://game/autoload/dialogue_director.gd`

Inicia timelines do Dialogic e aplica os sinais delas ao jogo.

## Descrição

`start()` aceita um caminho `res://` terminado em `.dtl`, ou o nome registrado pelo Dialogic, como `intro`. No `_ready`, chama `DialogicResourceUtil.update()` para o Dialogic encontrar os `.dch` e `.dtl` do projeto.

Enquanto `is_running` é `true`, `Location` desliga os botões do local, e a cena principal fecha o inventário.

O identificador de uma fala é o nome do arquivo `.dch`, sem a extensão, com as mesmas maiúsculas: `Pericles`, `Testemunha`, `Juiz` e `Bert`. O Dialogic grava esses nomes em `dialogic/directories/dch_directory` do `project.godot` quando o editor abre. Um caminho como `Pericles/Pericles` não é encontrado, e a fala sai sem retrato.

```text
Pericles: Este é o escritório. Quieto, por enquanto.
```

A pose fica entre parênteses, antes dos dois-pontos. Sem pose, uma conversa nova começa na pose padrão do personagem, e a mesma pessoa falando de novo mantém a pose anterior. Não use `join`, `leave` nem `update`: quem aparece na tela é sempre quem fala. Veja [SpeakerLayer](#speakerlayer).

```text
Pericles (objecao): PROTESTO!
Juiz (bravo): Ordem no tribunal!
```

Um evento Signal do Dialogic manda o texto `ação:valor`. O diretor separa no primeiro `:`.

| Argumento | Efeito |
| --- | --- |
| `give_item:attorneys_badge` | `Inventory.add()` |
| `remove_item:attorneys_badge` | `Inventory.remove()` |
| `set_flag:met_witness` | `GameState.set_flag()` com `true` |
| `change_scene:res://game/scenes/locations/lobby.tscn` | `SceneRouter.go_to()` quando a timeline acabar |
| `lose_credibility:1` | `GameState.lose_credibility()` |
| `set_credibility:5` | `GameState.set_credibility()` |

`change_scene` espera `timeline_ended`. A fala segue até o fim, e o local só troca depois. Vários `change_scene` na mesma timeline deixam o último caminho.

Um argumento que não é `String`, sem os dois lados do `:`, ou com uma ação desconhecida, gera um aviso e é ignorado.

```text
Pericles: Meu distintivo de promotor. Vou levá-lo comigo.
[signal arg="give_item:attorneys_badge"]
[signal arg="set_flag:pegou_dossie"]
```

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| bool | is_running | `false` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | start(timeline: String) |

## Sinais

### dialogue_started()

Emitido no começo de `start()`, depois que a timeline foi encontrada e antes de `Dialogic.start()`.

### dialogue_finished()

Emitido quando a timeline que este diretor abriu termina. Se havia um `change_scene` pendente, `SceneRouter.go_to()` roda em seguida.

---

## Descrições das propriedades

### bool is_running = false

`true` do `start()` bem-sucedido até `timeline_ended`. `Hotspot`, `SceneExit` e `Location` leem esta propriedade para ignorar cliques.

---

## Descrições dos métodos

### bool start(timeline: String)

Abre a timeline e devolve `true`. Devolve `false` quando já existe diálogo, quando `timeline` está vazio, ou quando o arquivo não existe. Nesse caso, `is_running` permanece `false` e `dialogue_started` não é emitido.

Um caminho com `://` é usado como está, se o arquivo existir. Qualquer outra string é resolvida como identificador `.dtl` do Dialogic.

---

# ItemData

**Herda:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html) **<** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/resources/item_data.gd`

Definição de um item do inventário.

## Descrição

Cada arquivo em `res://game/data/items/` é um recurso desta classe. `Inventory` indexa pelo `id`. O exemplo do distintivo está em `res://game/data/items/attorneys_badge.tres`.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | id | `""` |
| String | display_name | `""` |
| String | description | `""` |
| Texture2D | icon | |
| Kind | kind | `Kind.ITEM` |

---

## Descrições das propriedades

### String id = ""

Identificador usado em `Inventory.add()`, `give_item` e `remove_item`. O jogador vê `display_name`. Um recurso com `id` vazio fica de fora do catálogo.

### String display_name = ""

Nome mostrado na lista do painel e no aviso de item ou argumento.

### String description = ""

Texto do detalhe, quando o jogador seleciona o item no `InventoryPanel`.

### Texture2D icon

Ícone ao lado do nome e no detalhe. Pode ficar vazio. O painel e o aviso escondem a imagem quando o valor é `null`.

### Kind kind = Kind.ITEM

`ITEM` entra na aba Itens. `ARGUMENT` entra na aba Argumentos. `Inventory.has()` e o julgamento enxergam os dois do mesmo jeito.

Distintivo, dossiê e chave do apartamento são `ITEM`. Olho mágico, dobradiças, porta que abriu sem girar e depoimento do porteiro são `ARGUMENT`. `office_key` fica como `ITEM`, mas nenhuma timeline entrega esse recurso.

---

# PassageLock

**Herda:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html) **<** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/resources/passage_lock.gd`

Condição para atravessar uma saída.

## Descrição

`SceneExit` guarda um recurso desta classe em `lock`. Sem recurso, a passagem está livre. Uma subclasse devolve `false` em `is_open()` enquanto a condição falta.

O recurso fica no inspetor do nó. O export tipado como `PassageLock` lista esta classe e as subclasses, como `ItemLock`. `class_name` registra a classe para o editor criar o recurso no próprio nó.

A trava não esconde a saída e não desativa o botão. `required_flag` continua sendo a regra que torna a área invisível. Uma porta fechada permanece clicável; o clique recusa a viagem.

`SceneRouter.go_to()` não lê esta classe. Uma timeline com `change_scene` troca de local mesmo com a trava fechada.

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | is_open() |

---

## Descrições dos métodos

### bool is_open()

Devolve `true` quando a passagem pode ser usada. Nesta classe, o retorno é sempre `true`.

---

# ItemLock

**Herda:** [PassageLock](#passagelock) **<** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html) **<** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/resources/item_lock.gd`

Passagem que só abre com um item do inventário.

## Descrição

`is_open()` devolve `Inventory.has(item_id)`. O item continua com o jogador: atravessar não chama `Inventory.remove()`.

Um `item_id` vazio deixa a passagem aberta.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | item_id | `""` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | is_open() |

---

## Descrições das propriedades

### String item_id = ""

Id do catálogo, o mesmo de `Inventory.has()` e `give_item`. Vazio, `is_open()` devolve `true`.

---

## Descrições dos métodos

### bool is_open()

Devolve `true` quando `item_id` está vazio ou o jogador carrega esse item.

---

# Location

**Herda:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/location.gd`

Raiz de cada cena em `res://game/scenes/locations/`.

## Descrição

No `_ready`, estica o controle para preencher o host (`Control.PRESET_FULL_RECT`) e escuta `dialogue_started` e `dialogue_finished`. Se o nó do grupo `note_viewer` já está na árvore, também escuta `opened` e `closed`.

A cada um desses sinais, percorre os `BaseButton` descendentes. Quem tem `refresh_state()` se atualiza sozinho. Os demais ficam com `disabled` igual a `DialogueDirector.is_running`. Se `is_input_locked()` for verdadeiro, todo botão fica desativado.

Um local novo reutiliza este script na raiz. A saída para outra cena é um `SceneExit` filho, com `target_scene` apontando para o `.tscn` do outro local. `ExitArrow` é essa saída com uma seta.

Com `enter_timeline` preenchido, o local abre essa timeline assim que entra na tela. O escritório, a portaria, o corredor e o apartamento usam isso para a fala de chegada, com `enter_timeline_once`. O tribunal usa para o julgamento inteiro, sem `enter_timeline_once`, para tocar de novo depois do fim de jogo.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | enter_timeline | `""` |
| bool | enter_timeline_once | `false` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | is_input_locked(tree: SceneTree) |

---

## Descrições das propriedades

### String enter_timeline = ""

Timeline aberta quando o local entra na tela, com `DialogueDirector.start()`, um frame depois do `_ready`. O export aceita arquivos `*.dtl`. Vazia, nada abre.

### bool enter_timeline_once = false

Com `true`, a timeline de entrada toca só na primeira visita. A visita fica guardada na flag `entrou:<caminho da timeline>` do `GameState`.

---

## Descrições dos métodos

### bool is_input_locked(tree: SceneTree)

Método estático. Devolve `true` quando `DialogueDirector.is_running` é `true`, ou quando o nó do grupo `note_viewer` está visível. Com `tree` nulo e sem diálogo, devolve `false`.

`SceneExit.refresh_state()` usa este método. Ganhar um item atualiza a saída sem reativar o botão enquanto a nota está aberta.

---

# Interaction

**Herda:** [Button](https://docs.godotengine.org/en/stable/classes/class_button.html) **<** [BaseButton](https://docs.godotengine.org/en/stable/classes/class_basebutton.html) **<** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/interaction.gd`

Botão que troca o cursor do mouse enquanto o ponteiro está em cima.

## Descrição

`Hotspot` e `SceneExit` herdam esta classe. `ExitArrow` herda `SceneExit`. `Hotspot` usa a troca de cursor; `ExitArrow` sobrescreve esse comportamento para manter o cursor padrão e desenhar sua seta no próprio botão.

No `_ready`, o botão fica com `focus_mode` em `FOCUS_NONE`. Enter e Espaço avançam as falas do Dialogic; com foco, o último ponto clicado seria apertado de novo quando a fala acaba.

Com o ponteiro em cima, e o botão ativo, o cursor passa a ser `icon_texture`, redimensionado para `proportions` com filtro nearest. O ponto de clique é `hotspot`, em pixels da textura original, escalado na mesma proporção. Nada é desenhado sobre o botão. Com o botão desativado, ou sem textura, o cursor volta à seta do projeto.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| Texture2D | icon_texture | `null` |
| Vector2 | proportions | `Vector2(64, 64)` |
| Vector2 | hotspot | `Vector2(0, 0)` |

---

## Descrições das propriedades

### Texture2D icon_texture = null

Cursor mostrado sobre este controle. Vazio, o ponteiro permanece a seta do projeto.

### Vector2 proportions = Vector2(64, 64)

Largura e altura do cursor, em pixels. A textura é redimensionada para este tamanho.

### Vector2 hotspot = Vector2(0, 0)

Ponto de clique, em pixels de `icon_texture`. Se `proportions` diferir do tamanho da textura, este ponto escala junto.

---

# Hotspot

**Herda:** [Interaction](#interaction) **<** [Button](https://docs.godotengine.org/en/stable/classes/class_button.html) **<** [BaseButton](https://docs.godotengine.org/en/stable/classes/class_basebutton.html) **<** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/hotspot.gd`

Botão que abre uma timeline do Dialogic.

## Descrição

As propriedades ficam no inspetor. O clique chama `DialogueDirector.start()` com a timeline escolhida. Uma conversa nova é um `.dtl` em `res://game/dialogue/timelines/`, colocado em `timeline`.

`texture` desenha um asset no retângulo do nó. Posicione e redimensione o controle no editor; a imagem preenche essa área e acompanha o tamanho. Sem textura, o botão não desenha caixa nem imagem, e o clique continua na área. O script é `@tool`, então a imagem aparece no editor ao atribuir a textura. Se o nó ainda não tem tamanho, o retângulo assume o tamanho da imagem.

O cursor de `Interaction` troca enquanto o ponteiro está dentro do botão. A cor do ícone fica branca em todo estado, inclusive com o botão desativado durante o diálogo.

A mesa do escritório usa `timeline` = `pegar_distintivo.dtl`. A testemunha do saguão usa `timeline` = `conversa_testemunha.dtl`.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| Texture2D | texture | `null` |
| String | timeline | `""` |
| String | timeline_if_flag | `""` |
| String | flag | `""` |
| String | required_flag | `""` |
| bool | one_shot | `false` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| void | refresh_state() |

---

## Descrições das propriedades

### Texture2D texture = null

Imagem deste ponto de interação. O retângulo do controle é o quadro: arraste o nó para posicionar e puxe as bordas para escalar. A textura estica para preencher o retângulo.

Vazia, nada é desenhado. A área definida pelos offsets continua clicável.

### String timeline = ""

Caminho ou identificador da timeline padrão. É o argumento de `DialogueDirector.start()` quando `timeline_if_flag` não se aplica.

O export aceita arquivos `*.dtl`.

### String timeline_if_flag = ""

Timeline usada quando `flag` já está definida em `GameState`. Vazia, o clique usa sempre `timeline`.

### String flag = ""

Nome da flag que troca o clique para `timeline_if_flag`. A troca exige `flag` e `timeline_if_flag` preenchidos, e `GameState.has_flag(flag)` verdadeiro.

### String required_flag = ""

Enquanto `GameState` não tiver esta flag, o botão fica invisível e desativado. Vazia, o botão nasce disponível.

### bool one_shot = false

Com `true`, o botão desativa depois do primeiro clique que conseguiu abrir uma timeline. Um `start()` que devolve `false` deixa o botão utilizável.

---

## Descrições dos métodos

### void refresh_state()

Atualiza `visible` e `disabled` a partir de `required_flag`, `one_shot` e `DialogueDirector.is_running`. Com o botão desativado, o cursor volta à seta do projeto.

`Location` chama este método quando o diálogo abre ou fecha. O próprio botão também chama, no `_ready` e em `GameState.flag_changed`.

---

# SceneExit

**Herda:** [Interaction](#interaction) **<** [Button](https://docs.godotengine.org/en/stable/classes/class_button.html) **<** [BaseButton](https://docs.godotengine.org/en/stable/classes/class_basebutton.html) **<** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/scene_exit.gd`

Área que troca de local.

## Descrição

O clique chama `SceneRouter.go_to(target_scene)` quando a passagem está aberta. `required_flag` e `lock` são regras diferentes. A flag ausente esconde a área e desativa o botão. A trava fechada deixa a área visível e habilitada: um botão desativado não emite `pressed`, e a porta precisa receber o clique para recusar.

Com a trava fechada, o clique chama `_on_locked()`. Se `locked_timeline` estiver preenchida, esse método abre a timeline. Vazia, o clique não faz nada. Uma porta futura estende esta classe, desenha o asset e sobrescreve `_on_locked()`; chamar o método da base preserva a timeline.

Durante o diálogo, ou com o leitor de notas visível, o clique não viaja. `refresh_state()` também escuta `Inventory.changed`, para o desenho acompanhar o item sem reativar o botão enquanto a nota está aberta.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | target_scene | `""` |
| String | required_flag | `""` |
| PassageLock | lock | `null` |
| String | locked_timeline | `""` |

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| bool | is_passage_open() |
| void | refresh_state() |
| void | _on_locked() |

---

## Descrições das propriedades

### String target_scene = ""

Cena aberta no clique, passada a `SceneRouter.go_to()`. O export aceita arquivos `*.tscn`.

### String required_flag = ""

Enquanto `GameState` não tiver esta flag, a área fica invisível e desativada. Vazia, a área nasce visível. Isto não é a trava da porta.

### PassageLock lock = null

Condição para atravessar. `null`, ou `is_open()` verdadeiro, libera `SceneRouter.go_to()`. Fechada, a área continua clicável.

### String locked_timeline = ""

Timeline de `DialogueDirector.start()` quando o clique encontra a trava fechada. O export aceita arquivos `*.dtl`. Vazia, a recusa é silenciosa.

---

## Descrições dos métodos

### bool is_passage_open()

Devolve `true` quando `lock` é `null` ou `lock.is_open()` é `true`.

### void refresh_state()

Atualiza `visible` e `disabled` a partir de `required_flag` e `Location.is_input_locked()`. A trava não entra nesse cálculo.

`Location` chama este método quando o diálogo ou a nota abrem ou fecham. A saída também chama, no `_ready`, em `GameState.flag_changed` e em `Inventory.changed`.

### void _on_locked()

Roda no clique com a passagem fechada. Abre `locked_timeline` quando o caminho não está vazio. Uma subclasse que substituir este método chama a base para manter essa timeline.

---

# ExitArrow

**Herda:** [SceneExit](#sceneexit) **<** [Interaction](#interaction) **<** [Button](https://docs.godotengine.org/en/stable/classes/class_button.html) **<** [BaseButton](https://docs.godotengine.org/en/stable/classes/class_basebutton.html) **<** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/exit_arrow.gd`

Seta sobre uma `SceneExit`.

## Descrição

O botão nasce sem caixa e sem texto (`flat`, estilos vazios, `focus_mode` em `FOCUS_NONE`). Ao passar o mouse sobre a área, a seta aparece centralizada no botão; `direction` escolhe para onde ela aponta. O cursor permanece a seta padrão do projeto. O clique, a flag e a trava ficam em `SceneExit`.

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| Direction | direction | `Direction.RIGHT` |

## Enumerações

### enum Direction

| Valor | Nome |
| --- | --- |
| `0` | LEFT |
| `1` | RIGHT |
| `2` | UP |
| `3` | DOWN |

**LEFT** marca uma saída para a esquerda.

**RIGHT** marca uma saída para a direita.

**UP** marca uma saída para cima.

**DOWN** marca uma saída para baixo.

---

## Descrições das propriedades

### Direction direction = Direction.RIGHT

Lado para o qual aponta a seta exibida no centro do botão durante o hover.

---

# InventoryPanel

**Herda:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/inventory_panel.gd`

**Cena:** `res://game/scenes/ui/inventory_panel.tscn`

Painel com as abas Itens e Argumentos.

## Descrição

Começa oculto. Um [TabBar](https://docs.godotengine.org/en/stable/classes/class_tabbar.html) no cabeçalho tem as abas "Itens" e "Argumentos". `tab_changed` e `Inventory.changed` redesenham a lista da aba atual, filtrando `Inventory.get_items()` por `ItemData.kind`. O ícone da lista tem tamanho fixo de 48×48.

Selecionar uma entrada mostra `icon`, `display_name` e `description`. Com a aba Itens vazia, o título fica "Itens" e o texto fica "Nada aqui ainda.". Com a aba Argumentos vazia, o título fica "Argumentos" e o texto fica "Nenhum argumento anotado.".

O botão Fechar e um clique no fundo escuro chamam `hide()`.

## Métodos

| Tipo de retorno | Método |
| --- | --- |
| void | toggle() |

---

## Descrições dos métodos

### void toggle()

Alterna `visible`. Ao abrir, relê a aba atual e seleciona a primeira entrada dela.

A cena principal liga o botão Inventário a este método. `dialogue_started` esconde o painel por `hide()`, sem passar por `toggle()`.

---

# ItemToast

**Herda:** [PanelContainer](https://docs.godotengine.org/en/stable/classes/class_panelcontainer.html) **<** [Container](https://docs.godotengine.org/en/stable/classes/class_container.html) **<** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/item_toast.gd`

Aviso temporário de item ou argumento.

## Descrição

Começa oculto e ignora o mouse (`MOUSE_FILTER_IGNORE`). Escuta `Inventory.item_added`.

Quando uma entrada chega ao inventário, mostra o `icon`. Um `ITEM` usa o texto "Item {display_name} adquirido". Um `ARGUMENT` usa "Argumento anotado: {display_name}". O aviso permanece 2,6 segundos e some em 0,35 segundos. Uma entrada nova nesse intervalo reinicia a contagem e mantém o aviso visível.

---

# CredibilityBar

**Herda:** [Control](https://docs.godotengine.org/en/stable/classes/class_control.html) **<** [CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/scripts/credibility_bar.gd`

Losangos de credibilidade do promotor, no canto superior esquerdo durante o julgamento, abaixo do botão Inventário.

## Descrição

Desenha `GameState.MAX_CREDIBILITY` losangos com `_draw()`, sem imagem. Os primeiros `GameState.credibility` ficam cheios e o resto fica escuro. Quando perde um losango, a barra pisca em vermelho.

Fica invisível até o `GameState` ter a flag `show_flag`. A timeline do julgamento grava `em_julgamento` no começo. Ignora o mouse (`MOUSE_FILTER_IGNORE`).

## Propriedades

| Tipo | Propriedade | Valor padrão |
| --- | --- | --- |
| String | show_flag | `"em_julgamento"` |
| float | diamond_size | `36.0` |
| float | spacing | `12.0` |

---

# SpeakerLayer

**Herda:** `DialogicLayoutLayer` (Dialogic) **<** [Node](https://docs.godotengine.org/en/stable/classes/class_node.html) **<** [Object](https://docs.godotengine.org/en/stable/classes/class_object.html)

**Script:** `res://game/dialogic/styles/speaker_layer.gd`

**Cena:** `res://game/dialogic/styles/speaker_layer.tscn`

Camada do estilo `textbox.tres` que mostra só o retrato de quem está falando, como no Ace Attorney.

## Descrição

A cena tem três nós, de baixo para cima: `CourtBackground` (fundo do tribunal), `SpeakerPortrait` (container do Dialogic no modo `SPEAKER`) e `CourtDesk` (bancada na frente do retrato). O Dialogic troca o retrato do `SpeakerPortrait` sozinho a cada fala. Fica entre a camada de retratos do Dialogic e a caixa de texto.

Com a flag `em_julgamento` no `GameState`, a camada escuta `Dialogic.Text.speaker_updated` e troca fundo e bancada pelo personagem que fala, conforme `COURT_CAMERAS`. Fora do julgamento, fundo e bancada ficam escondidos e o retrato aparece por cima do local.

As trocas são cortes secos: `dialogic/animations/join_default_length`, `leave_default_length` e `cross_fade_default_length` estão em `0.0` no `project.godot`.

## Constantes

### Dictionary COURT_CAMERAS

Câmera de cada personagem no julgamento. A chave é o nome do `.dch`; o valor é `[fundo, bancada]`.

| Personagem | Fundo | Bancada |
| --- | --- | --- |
| Juiz | `tribunal/camera_juiz.svg` | `tribunal/bancada_juiz.svg` |
| Pericles | `tribunal/camera_promotoria.svg` | `tribunal/bancada_promotoria.svg` |
| Bert | `tribunal/camera_reu.svg` | `tribunal/bancada_reu.svg` |

Os caminhos ficam em `res://game/scenes/locations/`.

### String COURT_FLAG = "em_julgamento"

Flag que liga as câmeras.

## Poses

Cada pose é um PNG com fundo transparente na pasta do personagem, registrado no `.dch`:

| Personagem | Poses (a primeira é a padrão) |
| --- | --- |
| Pericles | `normal`, `objecao`, `sem_graca`, `pensando` |
| Juiz | `normal`, `bravo`, `satisfeito` |
| Bert | `normal`, `abalado` |
| Testemunha | `normal`, `nervoso` |

O retrato é escalado para a altura da tela (720) e alinhado embaixo, no centro. Os PNGs atuais têm 1280×720, com o personagem já enquadrado. Para trocar uma arte, basta substituir o PNG com o mesmo nome. Para criar uma pose nova: coloque o PNG na pasta, adicione o retrato no editor de personagens do Dialogic e use `Nome (pose): fala` na timeline.

---

# Fluxo do jogo

Três fases: o caso chega, a investigação e o julgamento. O roteiro do julgamento vem do `jure.html` (Twine).

## Fase 1: o caso chega

| Local | Cena | O que acontece |
| --- | --- | --- |
| Escritório | `locations/office/office.tscn` | `intro.dtl` toca na chegada. A mesa (`timeline_1.dtl`) entrega `attorneys_badge` e `dossie` e grava `pegou_dossie`. O dossiê aparece ao lado da mesa e abre no leitor de notas. A saída para a portaria tem `ItemLock` com `dossie`. |

## Fase 2: investigação

| Local | Cena | O que acontece |
| --- | --- | --- |
| Portaria | `locations/lobby/lobby.tscn` | `portaria_entrada.dtl` na chegada. A testemunha (`timeline_2.dtl`) pode ser pressionada: rende `depoimento_porteiro` e grava `pressionou_porteiro`. |
| Corredor | `locations/corredor/corredor.tscn` | Olho mágico (`olho_magico.dtl`) rende `olho_magico`. Tapete (`tapete.dtl`) rende `chave_apartamento`. Porta (`porta.dtl`): sem a chave, só comenta; com a chave, rende `porta_sem_girar`, grava `abriu_porta` e entra no apartamento. |
| Apartamento | `locations/apartamento/apartamento.tscn` | Porta por dentro (`dobradicas.dtl`) rende `dobradicas`. Computador (`computador.dtl`) grava `viu_computador`. Filtro (`filtro.dtl`) grava `viu_filtro`. Os dois são pistas falsas: a fala descarta a conta de luz e a água do dossiê. |

O dossiê na mesa só abre com `pegou_dossie`. Ao fechar o leitor, a nota grava `leu_dossie`. Aí o botão "Ir ao tribunal" aparece no canto inferior direito, no escritório, na portaria, no corredor e no apartamento. O clique abre a confirmação. "Ir" muda para o tribunal. "Ficar" e Esc ficam na investigação. O botão some no tribunal, no veredito e no fim de jogo, e fica desligado durante diálogo e nota. No fim de jogo o restante do HUD também some.

Quando o jogador tem `olho_magico` e `dobradicas`, a timeline que deu o segundo item grava `investigacao_completa` e o Péricles avisa que já dá para acusar. A flag não trava a viagem.

## Fase 3: julgamento

`locations/tribunal/tribunal.tscn` abre `julgamento.dtl`. A timeline grava `em_julgamento` e `set_credibility:5`. A partir daí, cada fala troca a câmera para quem fala (veja [SpeakerLayer](#speakerlayer)).

| Escolha | Resultado |
| --- | --- |
| Aparência do suspeito | Uma vez. Perde 1 losango e volta aos argumentos |
| Testemunha | Uma vez, e só com `depoimento_porteiro`. Perde 1 losango e volta aos argumentos. Cita a Dona Rosinha. Se o jogador viu o computador, Péricles admite que a placa está inteira |
| Investigação | Enquanto restar pista não falada: `olho_magico`, `porta_sem_girar`, `viu_filtro` ou `viu_computador`. Sem `abriu_porta`, o Péricles não diz que entrou no apartamento |
| Investigação, a porta abriu sem girar a chave | Uma vez, e só com `porta_sem_girar`. Perde 1 losango. Se ainda houver pista do apartamento, volta a elas; senão, volta aos argumentos. Se houver depoimento, o juiz lembra a porta entreaberta da Rosinha |
| Investigação, filtro empoeirado | Uma vez, e só com `viu_filtro`. Perde 1 losango e segue a mesma volta da porta |
| Investigação, conta de luz | Uma vez, e só com `viu_computador`. Perde 1 losango e segue a mesma volta da porta |
| Investigação, olho mágico | Uma vez, e só com `olho_magico`. O réu se defende e o jogador apresenta uma prova |
| Não tenho mais nada, Meritíssimo | Só aparece quando não resta argumento de abertura. Encerra o caso em `locations/fim_de_jogo/fim_de_jogo.tscn` e a timeline para. Não toca a fala de credibilidade |
| Prova: dobradiças da porta | Uma vez, e só com `dobradicas`. Vence: veredito em `locations/veredito/veredito.tscn` |
| Qualquer outra prova | Uma vez, se o jogador tiver o item. O juiz recusa e o caso acaba na mesma derrota de "não tenho mais nada", sem tirar losango e sem a fala de credibilidade |

Sem losangos, a timeline pula para `sem_credibilidade` e vai para `locations/fim_de_jogo/fim_de_jogo.tscn`. Nessa tela o HUD some. O botão "Tentar o julgamento de novo" volta ao tribunal com 5 losangos e com as falas liberadas de novo; os itens continuam no inventário. O botão "Reiniciar o jogo" apaga flags e itens e abre o escritório de novo.
