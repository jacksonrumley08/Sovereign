extends Control

# E-001 stub: Face-to-face trade window. Two-panel layout.
# In P1, no other players exist → window opens on right-click of an Animal/NPC just to demo flow.

@onready var your_list: VBoxContainer = $Panel/MarginContainer/HSplit/YourSide/List
@onready var their_list: VBoxContainer = $Panel/MarginContainer/HSplit/TheirSide/List
@onready var your_confirm: Button = $Panel/MarginContainer/HSplit/YourSide/ConfirmButton
@onready var their_confirm: Button = $Panel/MarginContainer/HSplit/TheirSide/ConfirmButton
@onready var status: Label = $Panel/MarginContainer/Status

var your_offer: Array = []
var their_offer: Array = []
var your_confirmed: bool = false
var their_confirmed: bool = false


func _ready() -> void:
	visible = false


func open_with(_other_party_name: String = "Trader") -> void:
	visible = true
	your_offer.clear()
	their_offer.clear()
	your_confirmed = false
	their_confirmed = false
	status.text = "Trade with %s — drag items to offer  (P1 stub: no actual swap)" % _other_party_name


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = false
