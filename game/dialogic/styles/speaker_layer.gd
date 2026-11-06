extends DialogicLayoutLayer

## Camada do estilo "textbox": mostra só o retrato de quem está falando, como no Ace Attorney.
## O retrato muda pela pose escrita na fala, por exemplo: Pericles (objecao): PROTESTO!
## Se a timeline deu join nesse personagem, o palco é que mostra o retrato. Esta camada esconde a cópia.
## No julgamento, também troca o fundo e a bancada conforme quem fala (a "câmera").

## Câmera de cada personagem no tribunal: [fundo, bancada na frente do retrato].
## A chave é o nome do arquivo .dch, sem a extensão.
const COURT_CAMERAS := {
	"Juiz": [
		preload("res://game/scenes/locations/tribunal/camera_juiz.svg"),
		preload("res://game/scenes/locations/tribunal/bancada_juiz.svg"),
	],
	"Pericles": [
		preload("res://game/scenes/locations/tribunal/camera_promotoria.svg"),
		preload("res://game/scenes/locations/tribunal/bancada_promotoria.svg"),
	],
	"Bert": [
		preload("res://game/scenes/locations/tribunal/camera_reu.svg"),
		preload("res://game/scenes/locations/tribunal/bancada_reu.svg"),
	],
}

## Flag do GameState que liga as câmeras. A timeline do julgamento grava esta flag.
const COURT_FLAG := "em_julgamento"


@onready var _speaker_portrait: Control = $SpeakerPortrait


func _ready() -> void:
	super()
	var dialogic := DialogicUtil.autoload()
	dialogic.Text.speaker_updated.connect(_on_speaker_updated)
	dialogic.Portraits.character_joined.connect(_on_character_joined)
	dialogic.Portraits.character_left.connect(_on_character_left)
	_show_camera([])


func _on_speaker_updated(character: DialogicCharacter) -> void:
	_sync_speaker_slot(character)
	var camera: Array = []
	if character != null and GameState.has_flag(COURT_FLAG):
		camera = COURT_CAMERAS.get(character.get_identifier(), [])
	_show_camera(camera)


## join/update desenham o retrato no palco. Cada fala também pede uma cópia
## no container de quem fala. Se o personagem já está no palco, essa cópia sai.
func _sync_speaker_slot(character: DialogicCharacter) -> void:
	var on_stage := character != null and DialogicUtil.autoload().Portraits.is_character_joined(character)
	_speaker_portrait.visible = not on_stage


func _on_character_joined(_info: Dictionary) -> void:
	_sync_speaker_slot(DialogicUtil.autoload().Text.get_current_speaker())


func _on_character_left(info: Dictionary) -> void:
	var speaker := DialogicUtil.autoload().Text.get_current_speaker()
	if info.get("character") == speaker:
		_speaker_portrait.visible = false
		return
	_sync_speaker_slot(speaker)


## Sem câmera (fora do tribunal), fundo e bancada somem e aparece o local por trás.
func _show_camera(camera: Array) -> void:
	var court_background := %CourtBackground as TextureRect
	var court_desk := %CourtDesk as TextureRect
	court_background.visible = not camera.is_empty()
	court_desk.visible = not camera.is_empty()
	if not camera.is_empty():
		court_background.texture = camera[0]
		court_desk.texture = camera[1]
