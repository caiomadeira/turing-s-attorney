class_name ItemData
extends Resource

## ITEM fica na aba Itens. ARGUMENT é uma pista do caso, na aba Argumentos.
enum Kind { ITEM, ARGUMENT }

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var kind: Kind = Kind.ITEM
