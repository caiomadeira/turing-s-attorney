extends Node

## Flags da história que não são itens do inventário.
## Também guarda a credibilidade do promotor no julgamento (os losangos).

signal flag_changed(flag: String, value: bool)
signal credibility_changed(value: int)

## Quantidade de losangos com que o julgamento começa.
const MAX_CREDIBILITY := 5

## Falas do julgamento. Cada uma só pode ser dita uma vez por tentativa.
const SPOKEN_ARGUMENTS: Array[String] = [
	"aparencia",
	"porteiro",
	"olho_magico",
	"porta_sem_girar",
	"filtro",
	"conta_luz",
	"prova_dobradicas",
	"prova_olho",
	"prova_chave",
	"prova_porta",
	"prova_depoimento",
]

var credibility := MAX_CREDIBILITY

var _flags: Dictionary = {}


func set_flag(flag: String, value: bool = true) -> void:
	if flag.is_empty():
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(_flags.get(flag, false))


func clear_flag(flag: String) -> void:
	set_flag(flag, false)


## Grava a credibilidade, presa entre 0 e MAX_CREDIBILITY, e emite credibility_changed.
func set_credibility(value: int) -> void:
	credibility = clampi(value, 0, MAX_CREDIBILITY)
	credibility_changed.emit(credibility)


## Tira losangos. Uma timeline confere GameState.credibility <= 0 para ir ao fim de jogo.
func lose_credibility(amount: int = 1) -> void:
	set_credibility(credibility - amount)


## Apaga as falas desta tentativa. A timeline do julgamento chama ao começar, inclusive no "tentar de novo".
func clear_spoken_arguments() -> void:
	for argument_id in SPOKEN_ARGUMENTS:
		clear_flag(_spoken_flag(argument_id))


## Marca a fala como já dita. Uma fala desconhecida é ignorada.
func speak_argument(argument_id: String) -> void:
	if argument_id not in SPOKEN_ARGUMENTS:
		push_warning("GameState: unknown argument '%s'" % argument_id)
		return
	set_flag(_spoken_flag(argument_id))


## A fala ainda não foi dita nesta tentativa, e o jogador a coletou.
func can_speak(argument_id: String) -> bool:
	if has_flag(_spoken_flag(argument_id)):
		return false
	return _argument_collected(argument_id)


## Ainda há argumento para o juiz: aparência, porteiro ou alguma pista do apartamento.
func has_opening_argument() -> bool:
	return can_speak("aparencia") or can_speak("porteiro") or has_apartment_argument()


## Ainda há pista não dita entre olho mágico, porta, filtro e conta de luz.
func has_apartment_argument() -> bool:
	return (
		can_speak("olho_magico")
		or can_speak("porta_sem_girar")
		or can_speak("filtro")
		or can_speak("conta_luz")
	)


## Ainda há prova não apresentada contra a desculpa do olho mágico.
func has_proof() -> bool:
	return (
		can_speak("prova_dobradicas")
		or can_speak("prova_olho")
		or can_speak("prova_chave")
		or can_speak("prova_porta")
		or can_speak("prova_depoimento")
	)


func _spoken_flag(argument_id: String) -> String:
	return "falou_" + argument_id


func _argument_collected(argument_id: String) -> bool:
	match argument_id:
		"aparencia":
			return true
		"porteiro", "prova_depoimento":
			return Inventory.has("depoimento_porteiro")
		"olho_magico", "prova_olho":
			return Inventory.has("olho_magico")
		"porta_sem_girar", "prova_porta":
			return Inventory.has("porta_sem_girar")
		"filtro":
			return has_flag("viu_filtro")
		"conta_luz":
			return has_flag("viu_computador")
		"prova_dobradicas":
			return Inventory.has("dobradicas")
		"prova_chave":
			return Inventory.has("chave_apartamento")
		_:
			return false


## Volta flags e losangos ao começo da partida.
func reset() -> void:
	var names: Array = _flags.keys()
	_flags.clear()
	for flag in names:
		flag_changed.emit(str(flag), false)
	set_credibility(MAX_CREDIBILITY)
