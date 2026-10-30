extends Node

## Flags da história que não são itens do inventário.
## Também guarda a credibilidade do promotor no julgamento (os losangos).

signal flag_changed(flag: String, value: bool)
signal credibility_changed(value: int)

## Quantidade de losangos com que o julgamento começa.
const MAX_CREDIBILITY := 5

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
