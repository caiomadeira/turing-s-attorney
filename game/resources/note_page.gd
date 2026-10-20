class_name NotePage
extends Resource

## Folha desta página. Vazio usa o papel genérico do leitor.
@export var texture: Texture2D
## Texto desenhado por cima da folha.
@export_multiline var text: String = ""
